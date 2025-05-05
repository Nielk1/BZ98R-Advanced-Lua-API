--- BZ98R LUA Extended API NavManager.
-- 
-- Manage navs
-- 
-- Dependencies: @{_api}, @{_hook}
-- @module _navmanager
-- @author John "Nielk1" Klein
-- @usage local navmanager = require("_navmanager");
-- 
-- 
-- 
-- @todo Determine if network handling is needed.
-- @todo Look into soft-loading native module that gives nav data access.

local debugprint = debugprint or function() end;

debugprint("_navmanager Loading");

local config = require("_config");
require("_gameobject");
local _api = require("_api");
local hook = require("_hook");

--- Nav Collection
-- One entry per team, maintains a list of navs for that team.
-- While this may appear as an array, it is actually a table with team numbers as keys.
-- While the nav list may appear an array, is is also a table with nav indexes as values.
local NavCollection = {};

function AddNavToCollection(nav)
    if nav.NavManager ~= nil then
        debugprint("Nav already in collection for team "..tostring(nav.NavManager.team)..".", nav:GetHandle());
        return;
    end

    local team = nav:GetTeamNum();
    if not NavCollection[team] then
        NavCollection[team] = {};
    end

    -- Find the first gap in the table
    local inserted = false
    for i = 1, #NavCollection[team] + 1 do
        if not NavCollection[team][i] then
            NavCollection[team][i] = nav
            nav.NavManager = { team = team, index = i };
            inserted = true
            break
        end
    end

    -- If no gaps were found, append to the end (fallback)
    if not inserted then
        table.insert(NavCollection[team], nav)
        nav.NavManager = { team = team, index = #NavCollection[team] };
    end

    debugprint("Add nav to collection for team "..tostring(team)..".", nav:GetHandle());
    
    PrintNavCollection(debugprint)
end

function RemoveNavFromCollection(nav)
    NavCollection[nav.NavManager.team][nav.NavManager.index] = nil;

    debugprint("Remove nav from collection for team "..tostring(nav.NavManager.team)..".", nav:GetHandle());
    
    PrintNavCollection(debugprint)
end

function PrintNavCollection(func)
    for team, list in pairs(NavCollection) do
        for i, nav in pairs(list) do
            func("NavCollection["..team.."]["..i.."] = <"..tostring(nav:GetHandle()).."> ["..nav:GetOdf().."] "..nav:GetObjectiveName());
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- NavManager - Core
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

hook.Add("CreateObject", "_navmanager_CreateObject", function(object)
    if object:GetClassSig() == "CPOD" then
        AddNavToCollection(object);
    end
end, config.get("hook_priority.CreateObject.NavManager"));
hook.Add("DeleteObject", "_navmanager_DeleteObject", function(object)
    -- we can't get the signiture by this point so we have to use saved data
    if object.NavManager ~= nil then
        RemoveNavFromCollection(object);
    end
end, config.get("hook_priority.DeleteObject.NavManager"));

hook.AddSaveLoad("_navmanager", function()
    return NavCollection;
end,
function(_NavCollection)
    NavCollection = _NavCollection;
end);

debugprint("_navmanager Loaded");

return _stateset;