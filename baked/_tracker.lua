--- BZ98R LUA Extended API Tracker.
---
--- Tracks objects by class and odf.
---
--- @module '_tracker'
--- @author John "Nielk1" Klein
--- @todo deal with team swapping
--- @usage local tracker = require("_tracker");
--- 
--- -- if no filters are set all objects will be tracked
--- tracker.setFilterTeam(1, true);
--- tracker.setFilterClass("TANK", true);

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_tracker Loading");

local config = require("_config");
local utility = require("_utility");
local hook = require("_hook");
local gameobject = require("_gameobject");
local unsaved = require("_unsaved");
require("_table_show");

local M = {};

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
    logger.print(logger.LogLevel.TRACE, nil, "TrackerData_Class: " .. table.show(TrackerData_Class, "TrackerData_Class"));
    logger.print(logger.LogLevel.TRACE, nil, "TrackerData_Odf: " .. table.show(TrackerData_Odf, "TrackerData_Odf"));
    logger.print(logger.LogLevel.TRACE, nil, "TrackerData_CountClass: " .. table.show(TrackerData_CountClass, "TrackerData_CountClass"));
    logger.print(logger.LogLevel.TRACE, nil, "TrackerData_CountOdf: " .. table.show(TrackerData_CountOdf, "TrackerData_CountOdf"));
    logger.print(logger.LogLevel.TRACE, nil, "TrackerData_TotalClass: " .. table.show(TrackerData_TotalClass, "TrackerData_TotalClass"));
    logger.print(logger.LogLevel.TRACE, nil, "TrackerData_TotalOdf: " .. table.show(TrackerData_TotalOdf, "TrackerData_TotalOdf"));
end

local function AddTrackedObject(object, odf, sig, team)
    logger.print(logger.LogLevel.TRACE, nil, "AddTrackedObject: " .. tostring(object:GetHandle()) .. " " .. tostring(odf) .. " " .. tostring(sig) .. " " .. tostring(team));

    if next(Current_TrackerData_Filter_Teams) ~= nil and not Current_TrackerData_Filter_Teams[team] then
        logger.print(logger.LogLevel.TRACE, nil, "AddTrackedObject: Team " .. tostring(team) .. " is not being tracked, ignoring object.");
        return;
    end

    local hasAnyFilters = next(Current_TrackerData_Filter_Classes) ~= nil or next(Current_TrackerData_Filter_Odfs) ~= nil;
    local trackedObject = false;

    if not hasAnyFilters or Current_TrackerData_Filter_Classes[sig] then
        TrackerData_Class[team]              = TrackerData_Class[team] or {};
        TrackerData_Class[team][sig]         = TrackerData_Class[team][sig] or {};
        TrackerData_Class[team][sig][object] = true;

        TrackerData_CountClass[team]      = TrackerData_CountClass[team] or {};
        TrackerData_CountClass[team][sig] = (TrackerData_CountClass[team][sig] or 0) + 1;
        
        TrackerData_TotalClass[team]      = TrackerData_TotalClass[team] or {};
        TrackerData_TotalClass[team][sig] = (TrackerData_TotalClass[team][sig] or 0) + 1;

        trackedObject = true;
    end

    if not hasAnyFilters or Current_TrackerData_Filter_Odfs[odf] then
        TrackerData_Odf[team]              = TrackerData_Odf[team] or {};
        TrackerData_Odf[team][odf]         = TrackerData_Odf[team][odf] or {};
        TrackerData_Odf[team][odf][object] = true;

        TrackerData_CountOdf[team]        = TrackerData_CountOdf[team] or {};
        TrackerData_CountOdf[team][odf]   = (TrackerData_CountOdf[team][odf] or 0) + 1;

        TrackerData_TotalOdf[team]        = TrackerData_TotalOdf[team] or {};
        TrackerData_TotalOdf[team][odf]   = (TrackerData_TotalOdf[team][odf] or 0) + 1;

        trackedObject = true;
    end

    if trackedObject then
        object.tracker = unsaved(object.tracker)
        object.tracker.odf = odf;
        object.tracker.sig = sig;
        object.tracker.team = team;
    end

    testprint();
end

local function DeleteTrackedObject(object, odf, sig, team, remove_from_total)
    logger.print(logger.LogLevel.TRACE, nil, "DeleteTrackedObject: " .. tostring(object:GetHandle()) .. " " .. tostring(odf) .. " " .. tostring(sig) .. " " .. tostring(team));

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
        logger.print(logger.LogLevel.DEBUG, nil, "TrackerData Filter changed, updating tracker data")
        
        Current_TrackerData_Filter_Teams = utility.shallowCopy(Desired_TrackerData_Filter_Teams);
        Current_TrackerData_Filter_Classes = utility.shallowCopy(Desired_TrackerData_Filter_Classes);
        Current_TrackerData_Filter_Odfs = utility.shallowCopy(Desired_TrackerData_Filter_Odfs);

        if hasNew then
            logger.print(logger.LogLevel.DEBUG, nil, "TrackerData Filter has new items, updating tracker data")
            for object in gameobject.AllObjects() do
                AddTrackedObject(object, object:GetOdf(), object:GetClassSig(), object:GetTeamNum());
            end
        end
    end
end

--- Count object by ClassSig
--- @param sig string ClassSig name to count.
--- @param team? integer Team number to count for.
--- @todo add protections
function M.countByClassSig(sig, team)
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
--- @param classname string ClassName name to count.
--- @param team? integer Team number to count for.
--- @todo add protections
function M.countByClassName(classname, team)
    local sig = utility.GetClassSig(classname);
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
--- @param odf string Odf name to count.
--- @param team? integer Team number to count for.
--- @todo add protections
function M.countByOdf(odf, team)
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
--- Note that items that no longer fit the filter will remain in the tracker.
--- Note that on the next update if needed an AllObjects scan will be performed to update the tracker for new filtered items.
--- @param team integer Team number to track.
--- @param enabled? boolean Enable or disable tracking for the team. Defaults to true.
function M.setFilterTeam(team, enabled)
    if not utility.isinteger(team) then error("Team must be an integer") end
    if team > 15 or team < 0 then error("Team must be between 0 and 15") end
    if enabled == nil then enabled = true end
    if not utility.isboolean(enabled) then error("Enabled must be a boolean") end
    
    Desired_TrackerData_Filter_Teams[team] = enabled or nil;
end

--- Enable tracking for a class.
--- Note that items that no longer fit the filter will remain in the tracker.
--- Note that on the next update if needed an AllObjects scan will be performed to update the tracker for new filtered items.
--- Note that the odf and class filters are independent, so if you set a class filter to true and an odf filter to false, the class will be tracked but the odf will not.
--- @param class ClassSig|ClassLabel Class name to track.
--- @param enabled? boolean Enable or disable tracking for the class. Defaults to true.
function M.setFilterClass(class, enabled)
    if not utility.isstring(class) then error("Class must be a string") end
    if enabled == nil then enabled = true end
    if not utility.isboolean(enabled) then error("Enabled must be a boolean") end
    local classItem = utility.GetClassSig(class);
    if classItem == nil then error("Class does not exist") end

    Desired_TrackerData_Filter_Classes[classItem] = enabled or nil;
end

--- Enable tracking for an odf.
--- Note that items that no longer fit the filter will remain in the tracker.
--- Note that on the next update if needed an AllObjects scan will be performed to update the tracker for new filtered items.
--- Note that the odf and class filters are independent, so if you set a class filter to true and an odf filter to false, the class will be tracked but the odf will not.
--- @param odf string Odf name to track.
--- @param enabled? boolean Enable or disable tracking for the odf. Defaults to true.
function M.setFilterOdf(odf, enabled)
    if not utility.isstring(odf) then error("Odf must be a string") end
    if enabled == nil then enabled = true end

    Desired_TrackerData_Filter_Odfs[odf] = enabled or nil;
end

local HaveStarted = false;

-------------------------------------------------------------------------------
-- Tracker - Core
-------------------------------------------------------------------------------
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

    AddTrackedObject(object, object:GetOdf(), object:GetClassSig(), object:GetTeamNum());
end, config.get("hook_priority.CreateObject.Tracker"));

hook.Add("DeleteObject", "_tracker_DeleteObject", function(object)
    if object.tracker == nil then return end -- object was not created by us, ignore it
    DeleteTrackedObject(object, object.tracker.odf, object.tracker.sig, object.tracker.team);
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
    Desired_TrackerData_Filter_Odfs = filter_odfs or {};

    Current_TrackerData_Filter_Teams = {};
    Current_TrackerData_Filter_Classes = {};
    Current_TrackerData_Filter_Odfs = {};

    CheckUpdated();
    HaveStarted = true;
end);

logger.print(logger.LogLevel.DEBUG, nil, "_tracker Loaded");

return M;