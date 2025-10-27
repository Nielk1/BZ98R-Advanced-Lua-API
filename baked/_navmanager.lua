--- BZ98R LUA Extended API NavManager.
---
--- Manage navs
---
--- @module '_navmanager'
--- @author John "Nielk1" Klein
--- ```lua
--- local navmanager = require("_navmanager");
--- 
--- navmanager.SetCompactionStrategy(navmanager.CompactionStrategy.ImportantFirstChronologicalToGap);
--- ```
--- 
--- @todo Determine if network handling is needed.
--- @todo Look into soft-loading native module that gives nav data access.

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_navmanager Loading");

local config = require("_config");
local utility = require("_utility");
local gameobject = require("_gameobject");
local hook = require("_hook");
local paramdb = require("_paramdb");

--- Nav GameObjects swapped.
--- The old nav will be deleted after this event is called.
--- This event allows for scripts to replace their nav references or copy over custom data.
---
--- @diagnostic disable: undefined-doc-param
--- @hook Add CallAllNoReturn
--- @param old GameObject GameObject instance
--- @param new GameObject GameObject instance
--- @diagnostic disable-next-line: luadoc-miss-type-name
--- @alias NavManager:NavSwap fun(old:GameObject, new:GameObject)
--- @diagnostic enable: undefined-doc-param

--- @class _navmanager
local M = {};

local PendingNavs = {};
local PendingNavsMemo = {};
local PendingDirty = false;
local OverflowNavs = {};

local DisableAutomaticNavAdding = false; -- used to prevent navs from being added to the collection when they are built

local NationMemo = {};

--- @param nation string? Nation id character, will take the first character if longer
--- @return string ODF ODF of the default nav for the nation
local function GetDefaultNavOdf(nation)
    print("GetDefaultNavOdf called with nation: " .. tostring(nation));
    if nation == nil or #nation == 0 then
        print("No nation provided, defaulting to apcamr");
        return "apcamr";
    end
    
    nation = nation:sub(1, 1):lower();

    local odf = NationMemo[nation];
    if odf then
        print("Found nation in memo: " .. tostring(odf));
        return odf;
    end

    odf = nation .. "pcamr";

    if paramdb.IsGameObject(odf) then
        NationMemo[nation] = odf;
        print("Found nation odf: " .. tostring(odf));
        return odf;
    end

    if nation == "c" then
        NationMemo[nation] = "spcamr";
        print("Defaulting nation odf to spcamr");
        return "spcamr";
    end

    NationMemo[nation] = "apcamr";
    print("Defaulting nation odf to apcamr");
    return "apcamr";
end

--- Adds custom data to GameObject for this module.
--- @class GameObject_NavManager : GameObject
--- @field NavManager table A table containing custom data for this module.

--- Build an important nav and add it to the collection.
--- Important navs will push non-important navs out of the way in the list.
--- @param odf string? ODF of the nav to build, if nil uses the default nav ODF
--- @param team integer Team number of the nav to build
--- @param location Vector|Matrix|Handle|GameObject|string Position vector, Transform matrix, or Object.
--- @param point integer? path point index, defaults to 0.
--- @return GameObject? nav The nav object that was built
function M.BuildImportantNav(odf, team, location, point)
    --- @todo check params here
    --return BuildImportantNavInternal(odf, team, location, point);

    --- @todo Add a team manager to track team nations better such as scanning all the teamslots

    --- @type string?
    local nation = nil;
    if not odf then
        if not nation then
            local source = gameobject.GetPlayer(team);
            if source then
                local pilot = source:GetPilotClass();
                if pilot and #pilot > 0 then
                    nation = pilot:sub(1, 1):lower();
                else
                    nation = source:GetNation();
                end
            end
        end
        if not nation then
            local source = gameobject.GetRecycler(team);
            if source then
                nation = source:GetNation();
            end
        end
        if not nation then
            local source = gameobject.GetConstructor(team);
            if source then
                nation = source:GetNation();
            end
        end
        if not nation then
            local source = gameobject.GetFactory(team);
            if source then
                nation = source:GetNation();
            end
        end
        if not nation then
            local source = gameobject.GetArmory(team);
            if source then
                nation = source:GetNation();
            end
        end
        if not nation then
            for i = TeamSlot.MIN_COMM, TeamSlot.MAX_COMM do
                local source = gameobject.GetTeamSlot(i, team);
                if source then
                    nation = source:GetNation();
                    break;
                end
            end
        end
        if not nation then
            for i = TeamSlot.MIN_POWER, TeamSlot.MAX_POWER do
                local source = gameobject.GetTeamSlot(i, team);
                if source then
                    nation = source:GetNation();
                    break;
                end
            end
        end
    end

    --- @type GameObject?
    local nav = gameobject.BuildObject(odf or GetDefaultNavOdf(nation), team, location, point);
    if not nav then return nil; end -- failed to build nav

    --- @cast nav GameObject_NavManager
    nav.NavManager = { important = true; }

    -- this probably never needs to run
    if PendingNavsMemo[nav] then
        if not PendingNavs[team] then
            PendingNavs[team] = {};
        end
        table.insert(PendingNavs[team], nav);
        PendingNavsMemo[nav] = true;
        PendingDirty = true;
    end

    return nav;
end

--- What to do when empty slots exist and excess navs exist
--- @enum CompactionStrategy
M.CompactionStrategy = {
    DoNothing = 1, -- Do nothing, leave excess navs in overflow
    ChronologicalToGap = 2, -- Excess navs inserted into gaps in order of creation
    ImportantFirstToGap = 3, -- Excess navs inserted into gaps in order of importance, then creation

    [1] = "DoNothing",
    [2] = "ChronologicalToGap",
    [3] = "ImportantFirstChronologicalToGap",
}

local CompactMode = M.CompactionStrategy.DoNothing; -- default to chronological

--- Set the compaction strategy for navs.
--- @param strategy string|integer The strategy to use. See `_navmanager.CompactionStrategy` for options.
function M.SetCompactionStrategy(strategy)
    local strat = strategy;
    if utility.IsString(strategy) then
        strat = M.CompactionStrategy[strategy];
        --- @cast strat integer
    end
    if M.CompactionStrategy[strat] == nil then error("Invalid compaction strategy: " .. tostring(strategy)); end
    CompactMode = strat;
end

--- Get the current compaction strategy for navs.
--- @return integer The current compaction strategy. See `_navmanager.CompactionStrategy` for options.
function M.GetCompactionStrategy()
    return CompactMode;
end

--- Enumerates all navs for a team.
--- At least 10 indexes will be iterated, even if there are no navs in those slots.
--- Navs not in the nav list, known internally as "Overflow Navs", will be returned with indexes above 10.
--- ```lua
--- for i, nav in navmanager.AllNavGameObjects(1, true) do
---     print("Nav " .. i .. ": " .. tostring(nav));
--- end
--- ```
--- ```lua
--- local active_navs = utility.IteratorToArray(navmanager.AllNavGameObjects(1));
--- ```
--- @param team integer Team number to enumerate
--- @param include_overflow boolean? If true "Overflow Navs" will be included in the enumeration after the initial 10.
--- @return fun(): (integer, GameObject?) Iterator function yielding index and nav object
function M.AllNavGameObjects(team, include_overflow)
    local slot_min = TeamSlot.MIN_BEACON
    local slot_max = TeamSlot.MAX_BEACON
    local overflow = include_overflow and OverflowNavs[team] or nil
    local overflow_count = overflow and #overflow or 0

    local i = 0
    local function iter()
        i = i + 1
        if i <= (slot_max - slot_min + 1) then
            local slot = slot_min + (i - 1)
            return i, gameobject.GetTeamSlot(slot, team)
        elseif overflow and (i <= (slot_max - slot_min + 1) + overflow_count) then
            local oi = i - (slot_max - slot_min + 1)
            return (slot_max - slot_min + 1) + oi, overflow[oi]
        else
            return nil
        end
    end
    return iter
end

--- @section NavManager - Core

local function CreateObject(object)
    if not DisableAutomaticNavAdding and object:GetClassSig() == "CPOD" then
        local team = object:GetTeamNum();
        if team == 0 then
            return; -- don't add to collection if team is 0, though this might change?
        end
        if object.NavManager == nil then
            object.NavManager = { important = false; };
        end
        if PendingNavsMemo[object] then
            if PendingNavs[team] == nil then
                PendingNavs[team] = {};
            end
            table.insert(PendingNavs[team], object);
            PendingNavsMemo[object] = true;
            PendingDirty = true;
        end
    end
end

hook.Add("MapObject", "_navmanager_MapObject", CreateObject, config.lock().hook_priority.CreateObject.NavManager);
hook.Add("CreateObject", "_navmanager_CreateObject", CreateObject, config.lock().hook_priority.CreateObject.NavManager);
hook.Add("DeleteObject", "_navmanager_DeleteObject", function(object)
    -- we can't get the signiture by this point so we have to use saved data
    if object.NavManager ~= nil then
        PendingDirty = true;
    end
end, config.lock().hook_priority.DeleteObject.NavManager);
hook.Add("Update", "_navmanager_Update", function(dtime, ttime)
    if PendingDirty then
        DisableAutomaticNavAdding = true;
        --- @todo this isn't supposed to be global, broke the code somewhere
        local NavSwapPairs = {}; -- old navs paired with thier new navs
        for team = 1, 15 do
            -- grab the known overflow and pending navs for this team
            local PendingNavsForTeam = {};
            if OverflowNavs[team] then
                for i = 1, #OverflowNavs[team] do
                    local nav = OverflowNavs[team][i];
                    if nav then
                        PendingNavsMemo[nav] = true; -- add to memo so we can remove it from the pending list later
                    end
                end
            end
            if PendingNavs[team] then
                for i = 1, #PendingNavs[team] do
                    local nav = PendingNavs[team];
                    if nav and nav:IsValid() then
                        table.insert(PendingNavsForTeam, nav);
                    end
                end
            end

            local CountOpenSlots = 0;
            local OpenSlotList = {};
            -- quickscan actual navs to remove them from pending list
            for slot = TeamSlot.MIN_BEACON, TeamSlot.MAX_BEACON do
                local existingNav = gameobject.GetTeamSlot(slot, team);
                if existingNav then
                    PendingNavsMemo[existingNav] = nil;
                else
                    table.insert(OpenSlotList, slot);
                    CountOpenSlots = CountOpenSlots + 1; -- count open slots
                end
            end

            local NewNavOverflow = {};

            -- for now we're hard coding this, but it will be the strategy by which overflow navs are moved into open slots
            if CountOpenSlots > 0 then
                if CompactMode == M.CompactionStrategy.DoNothing then
                    NewNavOverflow = PendingNavsForTeam; -- we are set to do nothing, so we just leave the navs in overflow and make sure the new pendings are added too
                elseif CompactMode == M.CompactionStrategy.ChronologicalToGap then
                    -- chronological, so we just add the navs in order
                    local SlotListIndex = 1;
                    for i = 1, #PendingNavsForTeam do
                        local nav = PendingNavsForTeam[i];
                        if nav and nav:IsValid() then
                            if CountOpenSlots > 0 then -- should be impossible to fail this but whatever
                                if utility.IsFunction(nav.SetTeamSlot) then
                                    nav:SetTeamSlot(OpenSlotList[SlotListIndex], team); -- this will add the nav to the collection and set the slot
                                    SlotListIndex = SlotListIndex + 1;
                                else
                                    -- build a new nav in the now open slot
                                    local newNav = gameobject.BuildObject(nav:GetOdf(), team, nav:GetTransform());
                                    if not newNav then error("Failed to build nav in slot " .. tostring(OpenSlotList[SlotListIndex])); end -- failed to build nav

                                    -- sync properties
                                    newNav:SetObjectiveName(nav:GetObjectiveName());
                                    newNav:SetMaxHealth(nav:GetMaxHealth());
                                    newNav:SetCurHealth(nav:GetCurHealth());
                                    -- @todo if we get teamwise targets, handle it here
                                    if nav:IsObjectiveOn() then
                                        newNav:SetObjectiveOn();
                                        nav.SetObjectiveOff();
                                    end
                                    -- @todo make this multi-team logic
                                    if gameobject.GetUserTarget() == nav then
                                        newNav:SetAsUserTarget();
                                    end

                                    table.insert(NavSwapPairs, { nav, newNav });
                                end
                                CountOpenSlots = CountOpenSlots - 1;
                            else
                                -- no more open slots, so we need to overflow the navs
                                table.insert(NewNavOverflow, nav);
                            end
                        end
                    end
                elseif CompactMode == M.CompactionStrategy.ImportantFirstToGap then
                    -- important first, so we add the important navs first, then the normal navs

                    -- temporary holding for overflow navs left over after first insert pass
                    local PendingNavsForTeamAfterFirstPass = {};
                    local SlotListIndex = 1;
                    for i = 1, #PendingNavsForTeam do
                        local nav = PendingNavsForTeam[i];
                        if nav and nav:IsValid() then
                            if nav.NavManager and nav.NavManager.important then
                                if CountOpenSlots > 0 then
                                    if utility.IsFunction(nav.SetTeamSlot) then
                                        nav:SetTeamSlot(OpenSlotList[SlotListIndex], team); -- this will add the nav to the collection and set the slot
                                        SlotListIndex = SlotListIndex + 1;
                                    else
                                        -- build a new nav in the now open slot
                                        local newNav = gameobject.BuildObject(nav:GetOdf(), team, nav:GetTransform());
                                        if not newNav then error("Failed to build nav in slot " .. tostring(OpenSlotList[SlotListIndex])); end -- failed to build nav
                                        
                                        -- sync properties
                                        newNav:SetObjectiveName(nav:GetObjectiveName());
                                        newNav:SetMaxHealth(nav:GetMaxHealth());
                                        newNav:SetCurHealth(nav:GetCurHealth());
                                        -- @todo if we get teamwise targets, handle it here
                                        if nav:IsObjectiveOn() then
                                            newNav:SetObjectiveOn();
                                            nav.SetObjectiveOff();
                                        end
                                        -- @todo make this multi-team logic
                                        if gameobject.GetUserTarget() == nav then
                                            newNav:SetAsUserTarget();
                                        end

                                        table.insert(NavSwapPairs, { nav, newNav });
                                    end
                                    CountOpenSlots = CountOpenSlots - 1;
                                else
                                    -- no more open slots, so we need to overflow the navs
                                    table.insert(PendingNavsForTeamAfterFirstPass, nav);
                                end
                            else
                                -- not an important nav, so save it for next loop
                                table.insert(PendingNavsForTeamAfterFirstPass, nav);
                            end
                        end
                    end
                    if CountOpenSlots > 0 then
                        for i = 1, #PendingNavsForTeamAfterFirstPass do
                            local nav = PendingNavsForTeamAfterFirstPass[i];
                            if nav and nav:IsValid() then
                                if CountOpenSlots > 0 then
                                    if utility.IsFunction(nav.SetTeamSlot) then
                                        nav:SetTeamSlot(OpenSlotList[SlotListIndex], team); -- this will add the nav to the collection and set the slot
                                        SlotListIndex = SlotListIndex + 1;
                                    else
                                        -- build a new nav in the now open slot
                                        local newNav = gameobject.BuildObject(nav:GetOdf(), team, nav:GetTransform());
                                        if not newNav then error("Failed to build nav in slot " .. tostring(OpenSlotList[SlotListIndex])); end -- failed to build nav
                                        
                                        -- sync properties
                                        newNav:SetObjectiveName(nav:GetObjectiveName());
                                        newNav:SetMaxHealth(nav:GetMaxHealth());
                                        newNav:SetCurHealth(nav:GetCurHealth());
                                        -- @todo if we get teamwise targets, handle it here
                                        if nav:IsObjectiveOn() then
                                            newNav:SetObjectiveOn();
                                            nav.SetObjectiveOff();
                                        end
                                        -- @todo make this multi-team logic
                                        if gameobject.GetUserTarget() == nav then
                                            newNav:SetAsUserTarget();
                                        end

                                        table.insert(NavSwapPairs, { nav, newNav });
                                    end
                                    CountOpenSlots = CountOpenSlots - 1;
                                else
                                    -- no more open slots, so we need to overflow the navs
                                    table.insert(NewNavOverflow, nav);
                                end
                            end
                        end
                    else
                        NewNavOverflow = PendingNavsForTeamAfterFirstPass; -- no open slots, so all navs go into overflow
                    end
                end
            else
                NewNavOverflow = PendingNavsForTeam; -- no open slots, so all navs go into overflow
            end
            
            OverflowNavs[team] = NewNavOverflow; -- save the overflow navs for the future
        end

        for i = 1, #NavSwapPairs do
            local oldNav = NavSwapPairs[i][1];
            local newNav = NavSwapPairs[i][2];
            hook.CallAllNoReturn("NavManager:NavSwap", oldNav, newNav); -- call the nav swap hook so scripts can handle reference changes
            oldNav:RemoveObject(); -- remove the old nav, this will call the delete object hook but we're ignoring those here atm
        end

        PendingNavs = {}; -- clear the pending navs
        PendingNavsMemo = {}; -- clear the pending navs memo

        PendingDirty = false;
        DisableAutomaticNavAdding = false;
    end
end, config.lock().hook_priority.Update.NavManager);

hook.AddSaveLoad("_navmanager", function()
    return PendingNavs, PendingNavsMemo, PendingDirty, OverflowNavs;
    -- should we leave CompactMode out and leave it to script parse?
end,
function(_PendingNavs, _PendingNavsMemo, _PendingDirty, _OverflowNavs)
    PendingNavs = _PendingNavs;
    PendingNavsMemo = _PendingNavsMemo;
    PendingDirty = _PendingDirty;
    OverflowNavs = _OverflowNavs;
    -- should we leave CompactMode out and leave it to script parse?
end);

logger.print(logger.LogLevel.DEBUG, nil, "_navmanager Loaded");

return M;