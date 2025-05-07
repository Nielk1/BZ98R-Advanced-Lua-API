--- BZ98R LUA Extended API NavManager.
-- 
-- Manage navs
-- 
-- Dependencies: @{_config}, @{_gameobject}, @{_api}, @{_hook}
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
local gameobject = require("_gameobject");
local _api = require("_api");
local hook = require("_hook");

local _navmanager = {};

--- Nav Collection
-- One entry per team, maintains a list of navs for that team.
-- While this may appear as an array, it is actually a table with team numbers as keys.
-- While the nav list may appear an array, is is also a table with nav indexes as values.
local NavCollection = {};

local DisableAutomaticNavAdding = false; -- used to prevent navs from being added to the collection when they are built

--- Build an important nav and add it to the collection.
-- Important navs will push non-important navs out of the way in the list.
-- @tparam string odf ODF of the nav to build
-- @tparam number team Team number of the nav to build
-- @param location vector position, matrix transform, or string path name to build the nav or nav GameObject to clone and delete
-- @tparam[opt] string point Path point number for the nav to build on if using a path
-- @treturn GameObject The nav object that was built
-- @treturn number The index of the nav in the NavCollection for the team
function _navmanager.BuildImportantNav(odf, team, location, point)
    -- @todo check params h ere, don't allow GameObject on location here, that's internal only
    return BuildImportantNavInternal(odf, team, location, point);
end
function BuildImportantNavInternal(odf, team, location, point)
    -- make room for the nav
    local shuffledOutNav = nil;
    if NavCollection[team] then
        for i = 1, #NavCollection[team] + 1 do
            shuffledOutNav = NavCollection[team][i];
            if not shuffledOutNav then
                --debugprint("\27[34mGap Found ["..i.."]\27[0m");
                break; -- we've got a gap, so do nothing
            end

            -- change nav team temporarily
            -- @todo: preserve target data
            --debugprint(table.show(shuffledOutNav.NavManager));
            if not shuffledOutNav.NavManager.important then
                --debugprint("\27[34mNon-critical Nav Found ["..i.."]\27[0m");
                shuffledOutNav:SetTeamNum(0);
                NavCollection[team][i] = nil;
                break;
            --else
            --    debugprint("\27[34mCritical Nav Found ["..i.."]\27[0m");
            end
        end
    end

    -- build the nav
    local sourceNav = nil;
    local preservedNavData = nil;
    if isgameobject(location) then
        -- clone the nav and remove the old one
        sourceNav = location;
        location = location:GetTransform();
        sourceNav:SetTeamNum(0); -- make room for the new nav
        preservedNavData = sourceNav.NavManager;
        NavCollection[preservedNavData.team][preservedNavData.index] = nil;
        DisableAutomaticNavAdding = true; -- doing an object swap, so we are doing a delayed insert
    end
    local nav = BuildGameObject(odf or "apcamr", team, location, point);
    -- AddObject hook fires here, not sure about network though
    if sourceNav then
        DisableAutomaticNavAdding = false;

        nav:SetObjectiveName(sourceNav:GetObjectiveName());
        nav:SetMaxHealth(sourceNav:GetMaxHealth());
        nav:SetCurHealth(sourceNav:GetCurHealth());

        if sourceNav:IsObjectiveOn() then
            nav:SetObjectiveOn();
        end

        -- @todo make this multi-team logic
        if GetUserTarget() == sourceNav:GetHandle() then
            SetUserTarget(nav:GetHandle());
        end

        nav:SwapObjectReferences(sourceNav);
        AddNavToCollection(sourceNav); -- now that we swapped the refs, add the new nav, via the old ref, back in
        sourceNav.NavManager.important = true;

        -- remove the old nav
        nav.NavManager = nil; -- remove our data so RemoveObject doesn't cause issues with the data
        nav:RemoveObject(); -- this is now the old nav, even though it's in the new reference

        nav = sourceNav;
    else
        nav.NavManager.important = true;
    end

    -- restore old navs, this will probably lose gaps but we're in hell anyway
    --while next(OldNavs) do
    while shuffledOutNav do
        --debugprint("\27[34Nav Shuffle Inserting ["..tostring(oldNav.NavManager.index).."]\27[0m");
        for i = shuffledOutNav.NavManager.index + 1, #NavCollection[team] + 1 do
            --debugprint("\27[34Nav Shuffle Testing ["..tostring(oldNav.NavManager.index).."]\27[0m");
            local currentNav = NavCollection[team][i];
            if not currentNav then
                -- open spot found, restore nav
                --debugprint("\27[34mNav Restored ["..tostring(oldNav.NavManager.index).."]>["..i.."]\27[0m");

                DisableAutomaticNavAdding = true; -- ensure we don't add the new nav to the collection yet
                local newNav = BuildGameObject(shuffledOutNav:GetOdf(), team, shuffledOutNav:GetTransform());
                DisableAutomaticNavAdding = false;

                newNav:SetObjectiveName(shuffledOutNav:GetObjectiveName());
                newNav:SetMaxHealth(shuffledOutNav:GetMaxHealth());
                newNav:SetCurHealth(shuffledOutNav:GetCurHealth());

                if shuffledOutNav:IsObjectiveOn() then
                    newNav:SetObjectiveOn();
                end

                -- @todo make this multi-team logic
                if GetUserTarget() == shuffledOutNav:GetHandle() then
                    SetUserTarget(newNav:GetHandle());
                end

                newNav:SwapObjectReferences(shuffledOutNav); -- all references pointing to the old nav object now point to the new one
                AddNavToCollection(shuffledOutNav); -- now that we swapped the refs, add the new nav, via the old ref, back in

                newNav.NavManager = nil; -- remove our data so RemoveObject doesn't cause issues with the data
                newNav:RemoveObject(); -- this is now the old nav, even though it's in the new reference
                shuffledOutNav = nil; -- no more old navs to restore

                break;
            else
                if not currentNav.NavManager.important then
                    --debugprint("\27[34mNav Bumped ["..tostring(oldNav.NavManager.index).."]>["..i.."]\27[0m");
                    currentNav:SetTeamNum(0); -- make room
                    NavCollection[team][i] = nil;

                    DisableAutomaticNavAdding = true; -- ensure we don't add the new nav to the collection yet
                    local newNav = BuildGameObject(shuffledOutNav:GetOdf(), team, shuffledOutNav:GetTransform());
                    DisableAutomaticNavAdding = false;

                    newNav:SetObjectiveName(shuffledOutNav:GetObjectiveName());
                    newNav:SetMaxHealth(shuffledOutNav:GetMaxHealth());
                    newNav:SetCurHealth(shuffledOutNav:GetCurHealth());

                    if shuffledOutNav:IsObjectiveOn() then
                        newNav:SetObjectiveOn();
                    end

                    -- @todo make this multi-team logic
                    if GetUserTarget() == shuffledOutNav:GetHandle() then
                        SetUserTarget(newNav:GetHandle());
                    end

                    newNav:SwapObjectReferences(shuffledOutNav); -- all references pointing to the old nav object now point to the new one
                    AddNavToCollection(shuffledOutNav); -- now that we swapped the refs, add the new nav, via the old ref, back in

                    newNav.NavManager = nil; -- remove our data so RemoveObject doesn't cause issues with the data
                    newNav:RemoveObject(); -- this is now the old nav, even though it's in the new reference
                    shuffledOutNav = currentNav;

                    break; -- start over again until old list is empty or we fail to fix anything
                --else
                --    debugprint("\27[34mNav Not Restored ["..tostring(oldNav.NavManager.index).."]>["..i.."]\27[0m");
                end
            end
        end
    end

    --debugprint("\27[34m----TEST----\27[0m");
    --PrintNavCollection(debugprint);
    return nav, nav.NavManager.index;
end


--- Move important navs up in the list.
-- This will move all important navs to the top of the list, pushing unimportant navs down.
-- This works by recreating navs so be sure to re-grab your navs.
-- @tparam number team Team number of the nav to move
function _navmanager.MoveImportantNavsUp(team)
    debugprint("\27[35mMoveImportantNavsUp("..tostring(team)..")\27[0m");
    if not NavCollection[team] then return; end
    debugprint("\27[35mtest\27[0m");

    local foundGapOrUnimportant = false;
    -- loop all navs in the team using pairs
    local MaxKey = 0;
    for k, _ in pairs(NavCollection[team]) do
        if k > MaxKey then
            MaxKey = k;
        end
    end
    for i = 1, MaxKey do
        local nav = NavCollection[team][i];
        debugprint("\27[35mi = "..tostring(i).." nav = "..tostring(nav).."\27[0m");
        if foundGapOrUnimportant then
            debugprint("\27[35mPostgap Check\27[0m");
            if nav and nav.NavManager and nav.NavManager.important then
                debugprint("\27[35mIMPORTANT\27[0m");
                _navmanager.BuildImportantNav(nav:GetOdf(), team, nav);
            end
        elseif not nav or not nav.NavManager.important then
            debugprint("\27[35mGAP FOUND\27[0m");
            foundGapOrUnimportant = true;
        end
    end
end

--- Get the nav for a team and index.
-- @tparam number team Team number of the nav to get
-- @tparam number index Index of the nav to get
-- @treturn GameObject The nav object at the specified index for the team
function _navmanager.GetNav(team, index)
    if not NavCollection[team] then return nil; end
    return NavCollection[team][index];
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
            func("NavCollection["..team.."]["..i.."] = <"..tostring(nav:GetHandle()).."> ["..nav:GetOdf().."] "..nav:GetObjectiveName().." "..tostring(nav._IsObjective or 'false').." "..tostring(nav:IsObjectiveOn()));
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- NavManager - Core
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

hook.Add("CreateObject", "_navmanager_CreateObject", function(object)
    if not DisableAutomaticNavAdding and object:GetClassSig() == "CPOD" then
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