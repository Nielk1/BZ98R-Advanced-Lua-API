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

local _navmanager = {};

--- Nav Collection
-- One entry per team, maintains a list of navs for that team.
-- While this may appear as an array, it is actually a table with team numbers as keys.
-- While the nav list may appear an array, is is also a table with nav indexes as values.
local NavCollection = {};

function _navmanager.BuildImportantNav(odf, team, path, point)
    -- make room for the nav
    local oldNav = nil;
    if NavCollection[team] then
        for i = 1, #NavCollection[team] + 1 do
            oldNav = NavCollection[team][i];
            if not oldNav then
                debugprint("\27[34mGap Found ["..i.."]\27[0m");
                break; -- we've got a gap, so do nothing
            end

            -- change nav team temporarily
            -- @todo: preserve target data
            debugprint(table.show(oldNav.NavManager));
            if not oldNav.NavManager.important then
                debugprint("\27[34mNon-critical Nav Found ["..i.."]\27[0m");
                oldNav:SetTeamNum(0);
                NavCollection[team][i] = nil;
                break;
            else
                debugprint("\27[34mCritical Nav Found ["..i.."]\27[0m");
            end
        end
    end

    -- build the nav
    local nav = BuildGameObject(odf or "apcamr", team, path, point);
    -- AddObject hook fires here, not sure about network though
    nav.NavManager.important = true;

    -- restore old navs, this will probably lose gaps but we're in hell anyway
    --while next(OldNavs) do
    while oldNav do
        --debugprint("\27[34Nav Shuffle Inserting ["..tostring(oldNav.NavManager.index).."]\27[0m");
        for i = oldNav.NavManager.index + 1, #NavCollection[team] + 1 do
            --debugprint("\27[34Nav Shuffle Testing ["..tostring(oldNav.NavManager.index).."]\27[0m");
            local currentNav = NavCollection[team][i];
            if not currentNav then
                -- open spot found, restore nav
                --debugprint("\27[34mNav Restored ["..tostring(oldNav.NavManager.index).."]>["..i.."]\27[0m");
                
                local newNav = BuildGameObject(oldNav:GetOdf(), team, oldNav:GetTransform());
                newNav:SetObjectiveName(oldNav:GetObjectiveName());
                newNav:SetMaxHealth(oldNav:GetMaxHealth());
                newNav:SetCurHealth(oldNav:GetCurHealth());

                if oldNav:IsObjectiveOn() then
                    newNav:SetObjectiveOn();
                end

                -- @todo make this multi-team logic
                if GetUserTarget() == oldNav:GetHandle() then
                    SetUserTarget(newNav:GetHandle());
                end

                oldNav.NavManager = nil;
                oldNav:RemoveObject();
                oldNav = nil; -- no more old navs to restore
                break;
            else
                if not currentNav.NavManager.important then
                    --debugprint("\27[34mNav Bumped ["..tostring(oldNav.NavManager.index).."]>["..i.."]\27[0m");
                    currentNav:SetTeamNum(0); -- make room
                    NavCollection[team][i] = nil;

                    -- new nav clone
                    local newNav = BuildGameObject(oldNav:GetOdf(), team, oldNav:GetTransform());
                    newNav:SetObjectiveName(oldNav:GetObjectiveName());
                    newNav:SetMaxHealth(oldNav:GetMaxHealth());
                    newNav:SetCurHealth(oldNav:GetCurHealth());

                    if oldNav:IsObjectiveOn() then
                        newNav:SetObjectiveOn();
                    end

                    -- @todo make this multi-team logic
                    if GetUserTarget() == oldNav:GetHandle() then
                        SetUserTarget(newNav:GetHandle());
                    end

                    oldNav.NavManager = nil;
                    oldNav:RemoveObject();
                    oldNav = currentNav;
                    break; -- start over again until old list is empty or we fail to fix anything
                --else
                --    debugprint("\27[34mNav Not Restored ["..tostring(oldNav.NavManager.index).."]>["..i.."]\27[0m");
                end
            end
        end
    end

    --debugprint("\27[34m----TEST----\27[0m");
    --PrintNavCollection(debugprint);
    return nav;
end

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
        if not NavCollection[team][i] or NavCollection[team][i] == nav then
            NavCollection[team][i] = nav
            nav.NavManager = { team = team, index = i };
            inserted = true;
            break;
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
            func("NavCollection["..team.."]["..i.."] = <"..tostring(nav:GetHandle()).."> ["..nav:GetOdf().."] "..nav:GetObjectiveName().." "..tostring(nav._IsObjectiveOn or 'false').." "..tostring(nav:IsObjectiveOn()));
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

return _navmanager;