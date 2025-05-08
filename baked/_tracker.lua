--- BZ98R LUA Extended API Tracker.
-- 
-- Manage navs
-- 
-- Dependencies: @{_config}, @{_utility}, @{_hook}, @{_gameobject}, @{_table_show}
-- @module _tracker
-- @author John "Nielk1" Klein
-- @todo deal with team swapping
-- @usage local tracker = require("_tracker");
-- 
-- -- if no filters are set all objects will be tracked
-- tracker.setFilterTeam(1, true);
-- tracker.setFilterClass("TANK", true);

local debugprint = debugprint or function(...) end;
local traceprint = traceprint or function(...) end;

debugprint("_tracker Loading");

local config = require("_config");
local utility = require("_utility");
local hook = require("_hook");
local gameobject = require("_gameobject");
local unsaved = require("_unsaved");
require("_table_show");

local _tracker = {};

local TrackerData_Class = {}; -- team -> class -> object
local TrackerData_Odf = {}; -- team -> odf -> object

local TrackerData_CountClass = {}; -- team -> class -> current count
local TrackerData_CountOdf = {}; -- team -> odf -> current count

local TrackerData_TotalClass = {}; -- team -> class -> total count
local TrackerData_TotalOdf = {}; -- team -> odf -> total count

local Desired_TrackerData_Filter_Teams = {};
local Desired_TrackerData_Filter_Classes = {};
local Desired_TrackerData_Filter_Odfs = {};

local Current_TrackerData_Filter_Teams = {};
local Current_TrackerData_Filter_Classes = {};
local Current_TrackerData_Filter_Odfs = {};

local function testprint()
    traceprint("TrackerData_Class: " .. table.show(TrackerData_Class, "TrackerData_Class"));
    traceprint("TrackerData_Odf: " .. table.show(TrackerData_Odf, "TrackerData_Odf"));
    traceprint("TrackerData_CountClass: " .. table.show(TrackerData_CountClass, "TrackerData_CountClass"));
    traceprint("TrackerData_CountOdf: " .. table.show(TrackerData_CountOdf, "TrackerData_CountOdf"));
    traceprint("TrackerData_TotalClass: " .. table.show(TrackerData_TotalClass, "TrackerData_TotalClass"));
    traceprint("TrackerData_TotalOdf: " .. table.show(TrackerData_TotalOdf, "TrackerData_TotalOdf"));
end

local function CreateObject(object, odf, sig, team)
    traceprint("CreateObject: " .. tostring(object:GetHandle()) .. " " .. tostring(odf) .. " " .. tostring(sig) .. " " .. tostring(team));

    if next(Current_TrackerData_Filter_Teams) ~= nil and Current_TrackerData_Filter_Teams[team] == nil then
        traceprint("CreateObject: Team " .. tostring(team) .. " is not being tracked, ignoring object.");
        return;
    end

    if next(Current_TrackerData_Filter_Classes) == nil or Current_TrackerData_Filter_Classes[sig] ~= nil then
        TrackerData_Class[team]              = TrackerData_Class[team] or {};
        TrackerData_Class[team][sig]         = TrackerData_Class[team][sig] or {};
        TrackerData_Class[team][sig][object] = true;

        TrackerData_CountClass[team]      = TrackerData_CountClass[team] or {};
        TrackerData_CountClass[team][sig] = (TrackerData_CountClass[team][sig] or 0) + 1;
        
        TrackerData_TotalClass[team]      = TrackerData_TotalClass[team] or {};
        TrackerData_TotalClass[team][sig] = (TrackerData_TotalClass[team][sig] or 0) + 1;
    end

    if next(Current_TrackerData_Filter_Odfs) == nil or Current_TrackerData_Filter_Odfs[odf] ~= nil then
        TrackerData_Odf[team]              = TrackerData_Odf[team] or {};
        TrackerData_Odf[team][odf]         = TrackerData_Odf[team][odf] or {};
        TrackerData_Odf[team][odf][object] = true;

        TrackerData_CountOdf[team]        = TrackerData_CountOdf[team] or {};
        TrackerData_CountOdf[team][odf]   = (TrackerData_CountOdf[team][odf] or 0) + 1;

        TrackerData_TotalOdf[team]        = TrackerData_TotalOdf[team] or {};
        TrackerData_TotalOdf[team][odf]   = (TrackerData_TotalOdf[team][odf] or 0) + 1;
    end

    object.tracker = unsaved(object.tracker)
    object.tracker.odf = odf;
    object.tracker.sig = sig;
    object.tracker.team = team;

    testprint();
end

local function DeleteObject(object, odf, sig, team, remove_from_total)
    traceprint("DeleteObject: " .. tostring(object:GetHandle()) .. " " .. tostring(odf) .. " " .. tostring(sig) .. " " .. tostring(team));

    -- Remove the object from the TeamClass and TeamOdf tracking tables
    if TrackerData_Class[team] and TrackerData_Class[team][sig] then
        TrackerData_Class[team][sig][object] = nil
        -- Remove the team-class entry if it's empty
        if next(TrackerData_Class[team][sig]) == nil then
            TrackerData_Class[team][sig] = nil
        end
    end
    if TrackerData_Odf[team] and TrackerData_Odf[team][odf] then
        TrackerData_Odf[team][odf][object] = nil
        -- Remove the team-odf entry if it's empty
        if next(TrackerData_Odf[team][odf]) == nil then
            TrackerData_Odf[team][odf] = nil
        end
    end

    -- Decrement the team-specific counts
    if TrackerData_CountClass[team] and TrackerData_CountClass[team][sig] then
        TrackerData_CountClass[team][sig] = TrackerData_CountClass[team][sig] - 1
        if TrackerData_CountClass[team][sig] <= 0 then
            TrackerData_CountClass[team][sig] = nil
        end
    end
    if TrackerData_CountOdf[team] and TrackerData_CountOdf[team][odf] then
        TrackerData_CountOdf[team][odf] = TrackerData_CountOdf[team][odf] - 1
        if TrackerData_CountOdf[team][odf] <= 0 then
            TrackerData_CountOdf[team][odf] = nil
        end
    end

    if remove_from_total then
        if TrackerData_TotalClass[team] and TrackerData_TotalClass[team][sig] then
            TrackerData_TotalClass[team][sig] = TrackerData_TotalClass[team][sig] - 1
            if TrackerData_TotalClass[team][sig] <= 0 then
                TrackerData_TotalClass[team][sig] = nil
            end
        end
        if TrackerData_TotalOdf[team] and TrackerData_TotalOdf[team][odf] then
            TrackerData_TotalOdf[team][odf] = TrackerData_TotalOdf[team][odf] - 1
            if TrackerData_TotalOdf[team][odf] <= 0 then
                TrackerData_TotalOdf[team][odf] = nil
            end
        end
    end

    object.tracker = nil; -- remove the tracker data from the object

    testprint();
end

local function compareTables(desired, current)
    local hasNew = false
    local areDifferent = false

    -- Check if Desired has new items or if tables are different
    for k, v in pairs(desired) do
        if not current[k] then
            hasNew = true -- Desired has a new item not in Current
        end
        if current[k] ~= v then
            areDifferent = true -- Tables differ in value
        end
        if hasNew and areDifferent then
            break -- No need to continue if both conditions are true
        end
    end

    -- Check if Current has extra keys not in Desired
    for k, v in pairs(current) do
        if desired[k] == nil then
            areDifferent = true -- Current has extra items
            break -- No need to continue
        end
    end

    return hasNew, areDifferent
end

local CheckUpdated = function()
    local hasNew1, areDifferent1 = compareTables(Desired_TrackerData_Filter_Teams, Current_TrackerData_Filter_Teams);
    local hasNew2, areDifferent2 = compareTables(Desired_TrackerData_Filter_Classes, Current_TrackerData_Filter_Classes);
    local hasNew3, areDifferent3 = compareTables(Desired_TrackerData_Filter_Odfs, Current_TrackerData_Filter_Odfs);

    local hasNew = hasNew1 or hasNew2 or hasNew3;
    local areDifferent = areDifferent1 or areDifferent2 or areDifferent3;

    if areDifferent then
        debugprint("TrackerData Filter changed, updating tracker data")
        
        Current_TrackerData_Filter_Teams = utility.shallowCopy(Desired_TrackerData_Filter_Teams);
        Current_TrackerData_Filter_Classes = utility.shallowCopy(Desired_TrackerData_Filter_Classes);
        Current_TrackerData_Filter_Odfs = utility.shallowCopy(Desired_TrackerData_Filter_Odfs);

        if hasNew then
            debugprint("TrackerData Filter has new items, updating tracker data")
            for h in AllObjects() do
                local object = gameobject.FromHandle(h);
                CreateObject(object, object:GetOdf(), object:GetClassSig(), object:GetTeamNum());
            end
        end
    end
end

--- Count object by ClassSig
-- @tparam string sig ClassSig name to count.
-- @tparam[opt] integer team Team number to count for.
-- @todo add protections
function _tracker.countByClassSig(sig, team)
    if team == nil then
        local count = 0;
        for i = 0, 15 do
            if(TrackerData_CountClass[i] and TrackerData_CountClass[i][sig]) then
                count = count + TrackerData_CountClass[i][sig];
            end
        end
        return count;
    end
    if(TrackerData_CountClass[team] and TrackerData_CountClass[team][sig]) then
        return TrackerData_CountClass[team][sig];
    end
    return 0;
end

--- Count object by ClassName
-- @tparam string classname ClassName name to count.
-- @tparam[opt] integer team Team number to count for.
-- @todo add protections
function _tracker.countByClassName(classname, team)
    local sig = utility.ClassLabel[classname];
    if team == nil then
        local count = 0;
        for i = 0, 15 do
            if(TrackerData_CountClass[i] and TrackerData_CountClass[i][sig]) then
                count = count + TrackerData_CountClass[i][sig];
            end
        end
        return count;
    end
    if(TrackerData_CountClass[team] and TrackerData_CountClass[team][sig]) then
        return TrackerData_CountClass[team][sig];
    end
    return 0;
end

--- Count object by class
-- @tparam string odf Odf name to count.
-- @tparam[opt] integer team Team number to count for.
-- @todo add protections
function _tracker.countByOdf(odf, team)
    if team == nil then
        local count = 0;
        for i = 0, 15 do
            if(TrackerData_CountOdf[i] and TrackerData_CountOdf[i][odf]) then
                count = count + TrackerData_CountClass[i][odf];
            end
        end
        return count;
    end
    if(TrackerData_CountOdf[team] and TrackerData_CountOdf[team][odf]) then
        return TrackerData_CountOdf[team][odf];
    end
    return 0;
end

--- Enable tracking for a team.
-- Note that items that no longer fit the filter will remain in the tracker.
-- Note that on the next update if needed an AllObjects scan will be performed to update the tracker for new filtered items.
-- @tparam integer team Team number to track.
-- @tparam[opt] boolean enabled Enable or disable tracking for the team. Defaults to true.
function _tracker.setFilterTeam(team, enabled)
    if not utility.isinteger(team) then error("Team must be an integer") end
    if team > 15 or team < 0 then error("Team must be between 0 and 15") end
    if enabled == nil then enabled = true end
    if not utility.isboolean(enabled) then error("Enabled must be a boolean") end
    
    Desired_TrackerData_Filter_Teams[team] = enabled or nil;
end

--- Enable tracking for a class.
-- Note that items that no longer fit the filter will remain in the tracker.
-- Note that on the next update if needed an AllObjects scan will be performed to update the tracker for new filtered items.
--- Note that the odf and class filters are independent, so if you set a class filter to true and an odf filter to false, the class will be tracked but the odf will not.
-- @tparam string class Class name to track.
-- @tparam[opt] boolean enabled Enable or disable tracking for the class. Defaults to true.
function _tracker.setFilterClass(class, enabled)
    if not utility.isstring(class) then error("Class must be a string") end
    if enabled == nil then enabled = true end
    if not utility.isboolean(enabled) then error("Enabled must be a boolean") end
    local classItem = utility.ClassLabel[class];
    if classItem == nil then error("Class does not exist") end

    if classItem:match("^[A-Z]+%z{0,3}$") ~= nil then
        -- input was ClassName that was mapped to ClassSig, use Sig.
        class = classItem;
    end
    class = class .. string.rep("\0", 4 - #class); -- pad to 4 bytes

    Desired_TrackerData_Filter_Classes[class] = enabled or nil;
end

--- Enable tracking for an odf.
--- Note that items that no longer fit the filter will remain in the tracker.
--- Note that on the next update if needed an AllObjects scan will be performed to update the tracker for new filtered items.
--- Note that the odf and class filters are independent, so if you set a class filter to true and an odf filter to false, the class will be tracked but the odf will not.
--- @tparam string odf Odf name to track.
--- @tparam[opt] boolean enabled Enable or disable tracking for the odf. Defaults to true.
function _tracker.setFilterOdf(odf, enabled)
    if not utility.isstring(odf) then error("Odf must be a string") end
    if enabled == nil then enabled = true end

    Desired_TrackerData_Filter_Odfs[odf] = enabled or nil;
end

local HaveStarted = false;

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Tracker - Core
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

hook.Add("Start", "_tracker_Start", function(object, isMapObject)
    if not HaveStarted then
        CheckUpdated();
        HaveStarted = true;
    end
end, config.get("hook_priority.Start.Tracker"));


hook.Add("CreateObject", "_tracker_CreateObject", function(object, isMapObject)

    -- we're getting map objects, this means Start event hasn't fired yet but we're already looking at things to filter, bake the filters now
    if not HaveStarted and isMapObject then
        CheckUpdated();
        HaveStarted = true;
    end

    CreateObject(object, object:GetOdf(), object:GetClassSig(), object:GetTeamNum());
end, config.get("hook_priority.CreateObject.Tracker"));

hook.Add("DeleteObject", "_tracker_DeleteObject", function(object)
    if object.tracker == nil then return end -- object was not created by us, ignore it
    DeleteObject(object, object.tracker.odf, object.tracker.sig, object.tracker.team);
    -- consder holding on to dead objects or something? but their data is gone by now unless we start holding it too
    -- if we have stuff hang around though the counts will be wrong
end, config.get("hook_priority.DeleteObject.Tracker"));

hook.Add("Update", "_tracker_Update", function(dtime, ttime)
    CheckUpdated();
end, config.get("hook_priority.Update.Tracker"));

hook.AddSaveLoad("_tracker", function()
    return Desired_TrackerData_Filter_Teams, Desired_TrackerData_Filter_Classes, Desired_TrackerData_Filter_Odfs;
end,
function(filter_teams, filter_classes, filter_odfs)
    Desired_TrackerData_Filter_Teams = filter_teams or {};
    Desired_TrackerData_Filter_Classes = filter_classes or {};
    Current_TrackerData_Filter_Teams = utility.shallowCopy(Desired_TrackerData_Filter_Teams);
    Current_TrackerData_Filter_Teams = {};
    Current_TrackerData_Filter_Classes = {};
    Current_TrackerData_Filter_Odfs = {};
    CheckUpdated();
    HaveStarted = true;
end);

hook.Add("GameObject:SwapObjectReferences", "GameObject:SwapObjectReferences_tracker", function(objectA, objectB)
    local trackerA = objectA.tracker;
    local odfA = trackerA and trackerA.odf or objectA:GetOdf()
    local sigA = trackerA and trackerA.sig or objectA:GetClassSig()
    local teamA = trackerA and trackerA.team or  objectA:GetTeamNum()

    local trackerB = objectB.tracker;
    local odfB = trackerB and trackerB.odf or objectB:GetOdf()
    local sigB = trackerB and trackerB.sig or objectB:GetClassSig()
    local teamB = trackerB and trackerB.team or objectB:GetTeamNum()

    -- @todo consider implementing an update function that moves the item or something

    if teamA == teamB and odfA == odfB and sigA == sigB then
        -- reference swap is fine since keying data is the same
        return;
    end

    -- delete the objects from the tracker, account for their swapped keys
    DeleteObject(objectB, odfA, sigA, teamA, true)
    DeleteObject(objectA, odfB, sigB, teamB, true)

    CreateObject(objectA, odfA, sigA, teamA)
    CreateObject(objectB, odfB, sigB, teamB)
end, config.get("hook_priority.GameObject_SwapObjectReferences.Tracker"));

debugprint("_tracker Loaded");

return _tracker;