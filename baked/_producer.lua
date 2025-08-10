--- BZ98R LUA Extended API Producer.
---
--- Queues the building of objects by producers.
---
--- @module '_producer'
--- @author John "Nielk1" Klein

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_producer Loading");

local config = require("_config");
local utility = require("_utility");
local hook = require("_hook");
local gameobject = require("_gameobject");
local unsaved = require("_unsaved");
require("_table_show");
local deque = require("_deque");
local paramdb = require("_paramdb");
local color = require("_color");

--- Called when a producer as completed building an object.
--
-- Call method: @{_hook.CallAllNoReturn|CallAllNoReturn}
--
-- @event Producer:BuildComplete
-- @param object GameObject The object that was built.
-- @param producer GameObject The producer that built the object.
-- @param data any? The event data to be fired with the creation event.
-- @see _hook.Add

--- @class _producer
local M = {};

--- #section Producer - Data

--- @type TeamSlotInteger[]
local ProducerTeamSlots = {
    TeamSlot.RECYCLER,
    TeamSlot.FACTORY,
    TeamSlot.ARMORY,
    TeamSlot.CONSTRUCT,
};

--- @type table<ClassSig, string>
local ProducerTypeColors = {
    [utility.ClassSig.RECYCLER] = color.AnsiColorEscapeMap.CYAN,
    [utility.ClassSig.FACTORY] = color.AnsiColorEscapeMap.YELLOW,
    [utility.ClassSig.ARMORY] = color.AnsiColorEscapeMap.GREEN,
    [utility.ClassSig.CONSTRUCTIONRIG] = color.AnsiColorEscapeMap.MAGENTA,
};

--- @class ProductionQueue
--- @field odf string The ODF of the object to be built.
--- @field location Vector|string|PathWithIndex|nil The location where the object should be built, or "0 0 0" if not specified.
--- @field builder TeamSlotInteger? The producer that will build the object.
--- @field data any? The event data to be fired with the creation event.

--- A table mapping teams (0–15) to ProductionQueue lists.
--- This should be scanned every update if any producers are not busy to look for work for said producer.
--- Consider this a priority queue, even though right now it's just a normal queue.
--- Note that price is not a good reason to skip something, instead it should inject a block event into that build queue unless it's deemed impossible to get that much scrap.
--- @class ProducerQueue
--- @type table<TeamNum, Deque<ProductionQueue>>
local ProducerQueue = {}

--- Map producer to job it was ordered to build
--- We could store this into the GameObject instead but
---   it needs to detect when this object is removed so the order can be re-added, probably a the top of the queue
--- @type table<GameObject_producer, ProductionQueue>
local ProducerOrders = {};


-- When walking the queue, the following rules should be applied:
-- 1. If a producer is busy, it should not be considered for the queue.
-- 2. If the producer is available but the top priority item fails a pre-condition, it should skip to the next item.
--    * Not Enough Pilots
--    * Not Enough Max-Scrap
--    * TeamSlots Filled (no Offsense, Defense, or Utility room or 1-offs already exist)
-- 3. If the producer is available and the top priority item fails a soft-condition, it should do nothing and wait.
--    * Not Enough Scrap

--- #section Producer - Memos

--- Memo of sets of producer odfs keyed by the built odf.
--- @type table<string, table<string, boolean>>
local MemoOfProducersByProduced = {};

--- Memo of producer pdfs already scanned
--- @type table<string, boolean>
local ProducerOdfsScanned = {};

--- This contains the producer objects for each team by their slot
--- @type table<TeamNum, table<TeamSlotInteger, GameObject>>
local ProducerCache = {};

--- @type table<TeamNum, boolean?>
local ProducersDirty = {};

--- #section Producer - Logic
local c = color.AnsiColorEscapeMap;

local function ToStringJobFragment(job)
    local queueString = job.odf;
    if job.data then
        queueString = queueString.."*";
    end
    if job.location then
        local location = job.location;
        --- @cast location PathWithIndex
        if utility.istable(location)
            and #location == 2
            and utility.isstring(location[1])
            and utility.isinteger(location[2]) then
            queueString = queueString.."@"..location[1]..":"..tostring(location[2]);
        elseif utility.isVector(location) then
            --- @cast location Vector
            queueString = queueString.."@"..tostring(location.x)..","..tostring(location.y)..","..tostring(location.z);
        else
            --- @cast location string|Vector
            queueString = queueString.."@"..tostring(location);
        end
    end
    return queueString;
end

local function PrintQueue(team)
    if logger.settings.level < logger.LogLevel.DEBUG then
        return; -- don't waste cycles building a string we can't see
    end
    local queue = ProducerQueue[team];
    if queue then
        local queueString = "";
        for job in queue:iter_left() do
            --- @cast job ProductionQueue
            queueString = queueString.."[";
            if job.builder then
                queueString = utility.TeamSlotString[job.builder]..">";
            end
            queueString = queueString..ToStringJobFragment(job);            
            queueString = queueString.."]";
        end

        local orderString = "";
        for producer, job in pairs(ProducerOrders) do
            if producer then
                orderString = orderString..ProducerTypeColors[producer:GetClassSig()].."["..producer:GetOdf()..">";
                orderString = orderString..ToStringJobFragment(job);
                orderString = orderString.."]"..c.RESET;
            end
        end

        logger.print(logger.LogLevel.DEBUG, "<PRODUCER>", "QUEUE|"..tostring(team).."|"..orderString.."|"..queueString);
    end
end

--- Process the queues for each team.
local function ProcessQueues()
    -- iterate the queue until either the end of the queue or all producers are busy
    for team, queue in pairs(ProducerQueue) do
        --logger.print(logger.LogLevel.DEBUG, nil, table.show(queue:contents(), "queue["..tostring(team).."]"));
        if not queue:is_empty() and ProducerCache[team] ~= nil then
            local producerTypes = {};
            --- @cast producerTypes table<string, GameObject>
            for slot, producer in pairs(ProducerCache[team]) do
                if producer
                and producer:IsValid()
                and producer:CanBuild()
                and not producer:IsBusy() then
                    local producerOdf = producer:GetOdf();
                    producerTypes[producerOdf] = producer;
                end
            end
            if next(producerTypes) then
                -- iterate the queue until jobs found for all items or out of queue
                -- use indexes for multi-remove on queue
                local MaxScrap = GetMaxScrap(team);
                local Scrap = GetScrap(team);
                --local MaxPilot = GetMaxPilot(team);
                local Pilot = GetPilot(team);
                local indexesToRemove = {};
                for job, idx in queue:iter_left() do
                    --logger.print(logger.LogLevel.DEBUG, nil, "\27[34m".."Candidate "..job.odf.."\27[0m")
                    --logger.print(logger.LogLevel.DEBUG, nil, "\27[34m"..table.show(MemoOfProducersByProduced).."\27[0m")
                    --- @cast job ProductionQueue
                    local hasPosition = job.location and job.location ~= "" and true or false;
                    if not hasPosition then
                        job.location = nil;
                    end
                    local possibleProducers = nil;
                    if job.builder and ProducerCache[team] then
                        local builder = ProducerCache[team][job.builder];
                        --- @cast builder GameObject?
                        if builder then
                            possibleProducers = {};
                            possibleProducers[builder:GetOdf()] = true;
                        end
                    end
                    if not possibleProducers then
                        possibleProducers = MemoOfProducersByProduced[job.odf];
                    end
                    if possibleProducers and next(producerTypes) then
                        for producerOdf, _ in pairs(possibleProducers) do
                            --logger.print(logger.LogLevel.DEBUG, nil, "\27[34m".."Candidate Builder "..producerOdf.."\27[0m")
                            local producerObject = producerTypes[producerOdf];
                            if producerObject and not ProducerOrders[producerObject] then
                                --logger.print(logger.LogLevel.DEBUG, nil, table.show(queue:contents(), "queue["..tostring(team).."]"));
                                logger.print(logger.LogLevel.DEBUG, nil, c.BLUE.."Candidate Found "..producerOdf.." > "..job.odf..c.RESET)
                                local producerSig = producerObject:GetClassSig();
                                local needsPosition = producerSig == utility.ClassSig.armory or producerSig == utility.ClassSig.constructionrig;
                                if hasPosition == needsPosition then

                                    -- queue in producer if possible
                                    -- 1. If a producer is busy, it should not be considered for the queue.
                                    -- 2. If the producer is available but the top priority item fails a pre-condition, it should skip to the next item.
                                    --    * Not Enough Pilots
                                    --    * Not Enough Max-Scrap
                                    --    * TeamSlots Filled (no Offsense, Defense, or Utility room or 1-offs already exist)
                                    -- 3. If the producer is available and the top priority item fails a soft-condition, it should do nothing and wait.
                                    --    * Not Enough Scrap

                                    --- @todo make positions require armory
                                    local scrapCost = paramdb.GetScrapCost(job.odf);
                                    local pilotCost = paramdb.GetPilotCost(job.odf);

                                    if scrapCost <= MaxScrap and pilotCost <= Pilot then
                                        local sig = paramdb.GetClassSig(job.odf);
                                        local range = utility.TeamSlotRange[sig];
                                        local valid_slot = not range or range[1] == TeamSlot.UNDEFINED or range[2] == TeamSlot.UNDEFINED and true or false;
                                        -- slot validity check disabled as it's not needed, consider making it optional
                                        valid_slot = true;
                                        --if not valid_slot then
                                        --    for i = range[1], range[2] do
                                        --        local object = gameobject.GetTeamSlot(i, team);
                                        --        if not object or not object:IsValid() then
                                        --            valid_slot = true;
                                        --            break;
                                        --        end
                                        --    end
                                        --end
                                        if valid_slot then
                                            -- if we have enough scrap, start building
                                            if scrapCost <= Scrap then
                                                if hasPosition then
                                                    local location = job.location;
                                                    --- @cast location PathWithIndex
                                                    if utility.istable(location)
                                                        and #location == 2
                                                        and utility.isstring(location[1])
                                                        and utility.isinteger(location[2]) then
                                                        location = GetPosition(location[1], location[2]);
                                                    end
                                                    --- @cast location string|Vector
                                                    producerObject:BuildAt(job.odf, location);
                                                else
                                                    producerObject:Build(job.odf);
                                                end
                                                ProducerOrders[producerObject] = job; -- save the producer and its job so we can check it later, either if the producer dies or the target is built
                                                table.insert(indexesToRemove, idx);
                                                logger.print(logger.LogLevel.DEBUG, nil, c.CYAN.."BUILD "..producerOdf.." > "..job.odf..c.RESET)
                                            else
                                                logger.print(logger.LogLevel.DEBUG, nil, c.YELLOW.."WAIT "..producerOdf.." > "..job.odf..c.RESET)
                                            end
                                            producerTypes[producerOdf] = nil; -- remove the producer from the list so we don't use it again as it's either building or waiting for scrap
                                            break; -- break out of producer checking loop since we found a producer for this job
                                        else
                                            logger.print(logger.LogLevel.DEBUG, nil, c.DKYELLOW.."SKIP NoSlot "..producerOdf.." > "..job.odf..c.RESET)
                                        end
                                    else
                                        logger.print(logger.LogLevel.DEBUG, nil, c.DKYELLOW.."SKIP NoResource "..producerOdf.." > "..job.odf..c.RESET)
                                    end
                                else
                                    logger.print(logger.LogLevel.DEBUG, nil, c.DKYELLOW.."SKIP "..(needsPosition and "NeedPos " or "NoPos ")..producerOdf.." > "..job.odf..c.RESET)
                                end
                            end
                        end
                    end
                end
                -- remove the items from the queue
                queue:remove_multiple(indexesToRemove);
                if #indexesToRemove > 0 then
                    PrintQueue(team);
                end
            end
        end
    end
end

local function ProcessCreated(object)
    -- try to figure out which producer made it so if it is part of our system

    local odf = object:GetOdf();
    --local distance =  2^53;
    local distance =  100; -- if we're over 100 away we likely weren't produced by the producer
    local closestProducer = nil;
    local matchingJob = nil;

    for producer, job in pairs(ProducerOrders) do
        if not producer or not producer:IsValid() then
            ProducerOrders[producer] = nil; -- remove the producer from the list
            --- @todo eject jobs waiting on this producer?
        else
            if job.odf == odf then
                -- attempt to double check producer is valid by if a destination was set, as that's a diff kind of build
                local producerSig = producer:GetClassSig();
                local valid = true;
                if job.location then
                    valid = producerSig == utility.ClassSig.armory or producerSig == utility.ClassSig.constructionrig and true or false;
                else
                    valid = producerSig == utility.ClassSig.recycler or producerSig == utility.ClassSig.factory and true or false;
                end
                if valid then
                    local dist = producer:GetDistance(object);
                    if dist < distance then
                        distance = dist;
                        closestProducer = producer;
                        matchingJob = job;
                    end
                end
            end
        end
    end

    if closestProducer and matchingJob then
        local currentBusy = closestProducer:IsBusy();
        local currentCanBuild = closestProducer:CanBuild();
        local producerSig = closestProducer:GetClassSig();
        if currentCanBuild then
            if producerSig == utility.ClassSig.armory and not currentBusy then
                -- armories are special and somehow aren't still busy after a build
                logger.print(logger.LogLevel.DEBUG, nil, c.GREEN.."BuildComplete FIND&DONE ("..tostring(math.floor(distance)).."m)"..closestProducer:GetOdf().."["..tostring(closestProducer:GetTeamNum()).."] > "..odf..c.RESET);
                PrintQueue(closestProducer:GetTeamNum());
                hook.CallAllNoReturn("Producer:BuildComplete", object, closestProducer, matchingJob.data);
                ProducerOrders[closestProducer] = nil; -- remove the producer from the list
            elseif currentBusy then
                -- Recycler, Factory, and Construction Rig change Busy flag on a delay
                --logger.print(logger.LogLevel.DEBUG, nil, c.DKGREEN.."BuildComplete FIND ("..tostring(math.floor(distance)).."m) "..closestProducer:GetOdf().."["..tostring(closestProducer:GetTeamNum()).."] > "..odf..c.RESET);

                --PrintQueue(closestProducer:GetTeamNum());
                --hook.CallAllNoReturn("Producer:BuildComplete", object, closestProducer, ProducerOrders[closestProducer]);
    
                if closestProducer._producer == nil then
                    closestProducer._producer = {};
                end
                closestProducer._producer.post_build_check = object;
                --ProducerOrders[closestProducer] = nil; -- remove the producer from the list
            end
        end
    end
end

local function PostBuildCheck()
    -- confirm builds because the producer is now no longer busy 1 frame later
    for producer, job in pairs(ProducerOrders) do
        if not producer or not producer:IsValid() then
            ProducerOrders[producer] = nil; -- remove the producer from the list
            if producer._producer and producer._producer.post_build_check then
                ----logger.print(logger.LogLevel.DEBUG, nil, c.RED..table.show(job)..job.odf..c.RESET);
                local object = producer._producer.post_build_check;
                --- @cast object GameObject
                producer._producer.post_build_check = nil;
                logger.print(logger.LogLevel.DEBUG, nil, c.GREEN.."BuildComplete DONE "..producer:GetOdf().."["..tostring(object:GetTeamNum()).."] > "..object:GetOdf()..c.RESET);
                PrintQueue(producer:GetTeamNum());
                hook.CallAllNoReturn("Producer:BuildComplete", object, producer, job.data);
                ProducerOrders[producer] = nil; -- remove the producer from the list
            end
        elseif not producer:IsBusy() then
            ProducerOrders[producer] = nil; -- remove the producer from the list
            if producer._producer and producer._producer.post_build_check then
                ----logger.print(logger.LogLevel.DEBUG, nil, c.RED..table.show(job)..job.odf..c.RESET);
                local object = producer._producer.post_build_check;
                --- @cast object GameObject
                producer._producer.post_build_check = nil;
                logger.print(logger.LogLevel.DEBUG, nil, c.GREEN.."BuildComplete DONE "..producer:GetOdf().."["..tostring(object:GetTeamNum()).."] > "..object:GetOdf()..c.RESET);
                PrintQueue(producer:GetTeamNum());
                hook.CallAllNoReturn("Producer:BuildComplete", object, producer, job.data);
                ProducerOrders[producer] = nil; -- remove the producer from the list
            end
        end
    end
end

--- Update the producer memo cache if needed for the given team.
--- @param team TeamNum
local function ScanProducers(team)
    for _, p in pairs(ProducerTeamSlots) do
        local producer = gameobject.GetTeamSlot(p, team); -- Ensure the producer is loaded
        if not ProducerCache[team] then
            ProducerCache[team] = {};
        end
        ProducerCache[team][p] = producer; -- save it now so it's free
        if producer then
            local producerOdf = producer:GetOdf();
            if producerOdf and not ProducerOdfsScanned[producerOdf] then
                local label = producer:GetClassSig();
                if label == utility.ClassSig.recycler
                or label == utility.ClassSig.factory
                or label == utility.ClassSig.constructionrig
                or label == utility.ClassSig.armory then
                    local producerOdfFile = OpenODF(producerOdf);
                    if producerOdfFile then
                        for i=1, 9 do
                            local builableOdf = GetODFString(producerOdfFile, "ProducerClass", "buildItem" .. tostring(i));
                            if builableOdf and builableOdf ~= "" then
                                if not MemoOfProducersByProduced[builableOdf] then
                                    MemoOfProducersByProduced[builableOdf] = {};
                                end
                                MemoOfProducersByProduced[builableOdf][producerOdf] = true;
                            end
                        end
                        if label == utility.ClassSig.armory then
                            for _, v in ipairs({"cannonItem","rocketItem","mortarItem","specialItem"}) do
                                for i=1, 9 do
                                    local builableOdf = GetODFString(producerOdfFile, "ArmoryClass", v .. tostring(i));
                                    if builableOdf and builableOdf ~= "" then
                                        if not MemoOfProducersByProduced[builableOdf] then
                                            MemoOfProducersByProduced[builableOdf] = {};
                                        end
                                        MemoOfProducersByProduced[builableOdf][producerOdf] = true;
                                    end
                                end
                            end
                        end
                    end
                end
                ProducerOdfsScanned[producerOdf] = true;
            end
        end
    end

    ProducersDirty[team] = nil;
end

--- @param odf string Object to build.
--- @param team TeamNum Team number to build the object.
--- @param location Vector|Matrix|string|PathWithIndex|GameObject|Handle|nil Location to build the object if from an armory or constructor.
--- @param builder TeamSlotInteger? The producer that will build the object.
--- @param data any? Event data to be fired with the creation event.
function M.QueueJob(odf, team, location, builder, data)
    if not odf or not team then
        error("QueueJob requires an odf and a team number.");
    end

    -- very agressive caching of producers
    -- instead of doing this every enqueue it could be done when a producer class is created via CreateObject (waiting till next update perhapse?)
    ScanProducers(team);

    ---- get the possible producers for this ODF
    --local KnownProducerODFs = MemoOfProducersByProduced[odf];
    --if not KnownProducerODFs then
    --    logger.print(logger.LogLevel.DEBUG, nil, "No producers found for ODF: " .. odf);
    --    return false; -- No producers can build this ODF
    --end
    --
    ---- loop the known producers for this team
    --local ProducersForTeam = ProducerCache[team];
    --if not ProducersForTeam then
    --    logger.print(logger.LogLevel.DEBUG, nil, "No producers found for team: " .. tostring(team));
    --    return false;
    --end
    --
    ---- find a producer that can build this ODF
    --local ProducerForThisOdf = nil;
    --local ProducerTeamSlot = nil;
    --for slot, producer in pairs(ProducersForTeam) do
    --    if producer and producer:IsValid() and KnownProducerODFs[producer:GetOdf()] then
    --        ProducerForThisOdf = producer;
    --        ProducerTeamSlot = slot;
    --        break; -- we found a producer that can build this ODF
    --    end
    --end
    --
    --if ProducerTeamSlot == nil then
    --    logger.print(logger.LogLevel.DEBUG, nil, "No producer found for ODF: " .. odf .. " on team: " .. tostring(team));
    --    return false; -- No producer can build this ODF
    --end

    local queue = ProducerQueue[team];
    if not queue then
        queue = deque.new();
        ProducerQueue[team] = queue;
    end
    queue:push_right({
        odf = odf,
        location = location,
        builder = builder,
        data = data,
    });
    --for i = 0, 15 do
    --    if ProducerQueue[i] then
    --        logger.print(logger.LogLevel.DEBUG, nil, table.show(ProducerQueue[i]:contents(), "ProducerQueue["..tostring(i).."]"));
    --    end
    --end

    PrintQueue(team);
end

--- #section Producer - Core

hook.Add("CreateObject", "_producer_CreateObject", function(object, isMapObject)
    --- @cast object GameObject
    --- @cast isMapObject boolean
    local sig = object:GetClassSig();
    if sig == utility.ClassSig.recycler
    or sig == utility.ClassSig.factory
    or sig == utility.ClassSig.constructionrig
    or sig == utility.ClassSig.armory then
        ProducersDirty[object:GetTeamNum()] = true; -- mark the team as dirty so we can scan it next update
    end

    if not isMapObject then
        ProcessCreated(object);
    end
end, config.get("hook_priority.CreateObject.Producer"));

hook.Add("DeleteObject", "_producer_DeleteObject", function(object)

end, config.get("hook_priority.DeleteObject.Producer"));

hook.Add("Update", "_producer_Update", function(dtime, ttime)
    PostBuildCheck();

    for i = 0, 15 do
        if ProducersDirty[i] then
            ScanProducers(i);
        end
    end

    ProcessQueues();
end, config.get("hook_priority.Update.Producer"));

hook.Add("Start", "_producer_Start", function()
    for i = 0, 15 do
        ScanProducers(i);
    end
end, config.get("hook_priority.Start.Producer"));

hook.AddSaveLoad("_producer", function()
    ProducerOrdersRemapped = {};
    for producer, job in pairs(ProducerOrders) do
        if producer then
            ProducerOrdersRemapped[producer:GetHandle()] = job;
        end
    end
    return ProducerQueue, ProducerOrdersRemapped, ProducerCommandHistory;
end,
function(_ProducerQueue, _ProducerOrdersRemapped, _ProducerCommandHistory)
    ProducerQueue = _ProducerQueue or {};
    for i = 0, 15 do
        ScanProducers(i);
    end
    ProducerOrders = {};
    for handle, job in pairs(_ProducerOrdersRemapped) do
        local producer = gameobject.FromHandle(handle);
        if producer then
            ProducerOrders[producer] = job;
        end
    end
    ProducerCommandHistory = _ProducerCommandHistory or {};
end);

logger.print(logger.LogLevel.DEBUG, nil, "_producer Loaded");

return M;

--- @class ProducerData
--- @field post_build_check GameObject?

--- @class GameObject_producer : GameObject
--- @field _producer ProducerData?

