--- BZ98R LUA Extended API NavManager.
---
--- Manage navs
---
--- @module '_navmanager'
--- @author John "Nielk1" Klein
--- @usage local navmanager = require("_navmanager");
--- 
--- navmanager.SetCompactionStrategy(navmanager.CompactionStrategy.ImportantFirstChronologicalToGap);
--- 
--- @todo Determine if network handling is needed.
--- @todo Look into soft-loading native module that gives nav data access.

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_navmanager Loading");

local config = require("_config");
local utility = require("_utility");
local gameobject = require("_gameobject");
local hook = require("_hook");

--- Nav GameObjects swapped.
--- The old nav will be deleted after this event is called.
--- This event allows for scripts to replace their nav references or copy over custom data.
--
-- Call method: @{_hook.CallAllNoReturn|CallAllNoReturn}
--
-- @event NavManager:NavSwap
-- @tparam GameObject old GameObject instance
-- @tparam GameObject new GameObject instance
-- @see _hook.Add

local M = {};

local PendingNavs = {};
local PendingNavsMemo = {};
local PendingDirty = false;
local OverflowNavs = {};

local DisableAutomaticNavAdding = false; -- used to prevent navs from being added to the collection when they are built

local NationMemo = {};
function GetDefaultNavOdf(nation)
    if nation == nil or #nation == 0 then
        return "apcamr";
    end

    local odf = NationMemo[nation[1]];
    if odf then
        return odf;
    end

    odf = nation[1] .. "pcamr";

    -- OpenODF hoping to mirror game behavior, UseItem is also an option
    if OpenODF(odf) then
        NationMemo[nation[1]] = odf;
        return odf;
    end

    if nation[1] == "c" then
        NationMemo[nation[1]] = "spcamr";
        return "spcamr";
    end

    NationMemo[nation[1]] = "apcamr";
    return "apcamr";
end

--- Adds custom data to GameObject for this module.
--- @class GameObject
--- @field NavManager table A table containing custom data for this module.

--- Build an important nav and add it to the collection.
-- Important navs will push non-important navs out of the way in the list.
-- @param odf string? ODF of the nav to build, if nil uses the default nav ODF
-- @param team integer Team number of the nav to build
-- @param location Vector|Matrix|GameObject|Handle Position vector, ransform matrix, or Object
-- @return GameObject? nav The nav object that was built
-- @function BuildImportantNav

--- Build an important nav and add it to the collection.
-- Important navs will push non-important navs out of the way in the list.
-- @param odf string? ODF of the nav to build, if nil uses the default nav ODF
-- @param team integer Team number of the nav to build
-- @param location string path name
-- @param point? integer path point index, defaults to 0.
-- @return GameObject? nav The nav object that was built
-- @function BuildImportantNav

--- Build an important nav and add it to the collection.
--- Important navs will push non-important navs out of the way in the list.
--- @overload fun(odf: string, team: integer, location: Vector|Matrix|GameObject|Handle): GameObject?
--- @overload fun(odf: string, team: integer, name: string, point?: integer): GameObject?
--- @diagnostic disable: undefined-doc-param
--- @param odf string? ODF of the nav to build, if nil uses the default nav ODF
--- @param team integer Team number of the nav to build
--- @param location Vector|Matrix|Handle|string Position vector, ransform matrix, or Object.
--- @param name string path name
--- @param point? integer path point index, defaults to 0.
--- @diagnostic enable: undefined-doc-param
--- @return GameObject? nav The nav object that was built
function M.BuildImportantNav(...)
    local odf, team, location, point = ...;
    -- @todo check params here
    --return BuildImportantNavInternal(odf, team, location, point);

    --- @todo Add a team manager to track team nations better such as scanning all the teamslots
    
    local nation = nil;
    if odf then
        if not nation then
            local source = gameobject.GetPlayer(team);
            if source then
                local pilot = source:GetPilotClass();
                if pilot and #pilot > 0 then
                    nation = pilot[1];
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
--- @table _navmanager.CompactionStrategy
M.CompactionStrategy = {
    DoNothing = 1, -- Do nothing, leave excess navs in overflow
    ChronologicalToGap = 2, -- Excess navs inserted into gaps in order of creation
    ImportantFirstToGap = 3, -- Excess navs inserted into gaps in order of importance, then creation

    [1] = "DoNothing", -- DoNothing
    [2] = "ChronologicalToGap", -- ChronologicalToGap
    [3] = "ImportantFirstChronologicalToGap", -- ImportantFirstChronologicalToGap
}

local CompactMode = M.CompactionStrategy.DoNothing; -- default to chronological

--- Set the compaction strategy for navs.
--- @param strategy string|integer The strategy to use. See @{_navmanager.CompactionStrategy} for options.
--- @function _navmanager.SetCompactionStrategy
function M.SetCompactionStrategy(strategy)
    local strat = strategy;
    if utility.isstring(strategy) then
        strat = M.CompactionStrategy[strategy];
        --- @cast strat integer
    end
    if M.CompactionStrategy[strat] == nil then error("Invalid compaction strategy: " .. tostring(strategy)); end
    CompactMode = strat;
end

--- Get the current compaction strategy for navs.
--- @return integer The current compaction strategy. See @{_navmanager.CompactionStrategy} for options.
function M.GetCompactionStrategy()
    return CompactMode;
end

--- Enumerates all navs for a team.
--- At least 10 indexes will be iterated, even if there are no navs in those slots.
--- Navs not in the nav list, known internally as "Overflow Navs", will be returned with indexes above 10.
--- @param team integer Team number to enumerate
--- @param include_overflow? boolean If true "Overflow Navs" will be included in the enumeration after the initial 10.
--- @return integer index The index of the nav in the enumeration
--- @return GameObject nav The nav object at the index
--- @usage for i, nav in navmanager.AllNavGameObjects(1, true) do
---     print("Nav " .. i .. ": " .. tostring(nav));
--- end
--- @usage local active_navs = utility.IteratorToArray(navmanager.AllNavGameObjects(1));
function M.AllNavGameObjects(team, include_overflow)
    for slot = TeamSlot.MIN_BEACON, TeamSlot.MAX_BEACON do
        return (slot - TeamSlot.MIN_BEACON + 1), gameobject.GetTeamSlot(slot, team);
    end
    if include_overflow and OverflowNavs[team] then
        for i = 1, #OverflowNavs[team] do
            return (10 + i), OverflowNavs[team][i];
        end
    end
    return nil; -- End of iteration
end

-------------------------------------------------------------------------------
-- NavManager - Core
-------------------------------------------------------------------------------
-- @section

hook.Add("CreateObject", "_navmanager_CreateObject", function(object, isMapObject)
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
end, config.get("hook_priority.CreateObject.NavManager"));
hook.Add("DeleteObject", "_navmanager_DeleteObject", function(object)
    -- we can't get the signiture by this point so we have to use saved data
    if object.NavManager ~= nil then
        PendingDirty = true;
    end
end, config.get("hook_priority.DeleteObject.NavManager"));
hook.Add("Update", "_navmanager_Update", function(dtime, ttime)
    if PendingDirty then
        DisableAutomaticNavAdding = true;
        NavSwapPairs = {}; -- old navs paired with thier new navs
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
                                if utility.isfunction(nav.SetTeamSlot) then
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
                                    if GetUserTarget() == nav:GetHandle() then
                                        SetUserTarget(newNav:GetHandle());
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
                                    if utility.isfunction(nav.SetTeamSlot) then
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
                                        if GetUserTarget() == nav:GetHandle() then
                                            SetUserTarget(newNav:GetHandle());
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
                                    if utility.isfunction(nav.SetTeamSlot) then
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
                                        if GetUserTarget() == nav:GetHandle() then
                                            SetUserTarget(newNav:GetHandle());
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
end, config.get("hook_priority.Update.NavManager"));

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