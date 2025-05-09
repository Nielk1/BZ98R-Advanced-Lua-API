--- BZ98R LUA Extended API NavManager.
--- 
--- Manage navs
--- 
--- Dependencies: @{_config}, @{_utility}, @{_gameobject}, @{_api}, @{_hook}
--- @module _navmanager
--- @author John "Nielk1" Klein
--- @usage local navmanager = require("_navmanager");
--- 
--- navmanager.SetCompactionStrategy(navmanager.CompactionStrategy.ImportantFirstChronologicalToGap);
--- 
--- @todo Determine if network handling is needed.
--- @todo Look into soft-loading native module that gives nav data access.

local debugprint = debugprint or function(...) end;

debugprint("_navmanager Loading");

local config = require("_config");
local utility = require("_utility");
local gameobject = require("_gameobject");
local _api = require("_api");
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

local _navmanager = {};

local PendingNavs = {};
local PendingNavsMemo = {};
local PendingDirty = false;
local OverflowNavs = {};

local DisableAutomaticNavAdding = false; -- used to prevent navs from being added to the collection when they are built

--- Build an important nav and add it to the collection.
--- Important navs will push non-important navs out of the way in the list.
--- @tparam string odf ODF of the nav to build, if nil uses the default nav ODF
--- @tparam integer team Team number of the nav to build
--- @tparam vector position
--- @treturn GameObject The nav object that was built
--- @function _navmanager.BuildImportantNav

--- Build an important nav and add it to the collection.
--- Important navs will push non-important navs out of the way in the list.
--- @tparam string odf ODF of the nav to build, if nil uses the default nav ODF
--- @tparam integer team Team number of the nav to build
--- @tparam matrix transform
--- @treturn GameObject The nav object that was built
--- @function _navmanager.BuildImportantNav

--- Build an important nav and add it to the collection.
--- Important navs will push non-important navs out of the way in the list.
--- @tparam string odf ODF of the nav to build, if nil uses the default nav ODF
--- @tparam integer team Team number of the nav to build
--- @tparam string path path name to build the nav
--- @tparam[opt] integer point Path point number
--- @treturn GameObject The nav object that was built
--- @function _navmanager.BuildImportantNav

function _navmanager.BuildImportantNav(odf, team, location, point)
    -- @todo check params h ere, don't allow GameObject on location here, that's internal only
    --return BuildImportantNavInternal(odf, team, location, point);

    local nav = gameobject.BuildGameObject(odf or "apcamr", team, location, point);

    nav.NavManager = { important = true; }

    -- this probably never needs to run
    if PendingNavsMemo[nav] then
        table.insert(PendingNavs, nav);
        PendingNavsMemo[nav] = true;
        PendingDirty = true;
    end

    return nav;
end

--- What to do when empty slots exist and excess navs exist
--- @table _navmanager.CompactionStrategy
_navmanager.CompactionStrategy = {
    DoNothing = 1, -- Do nothing, leave excess navs in overflow
    ChronologicalToGap = 2, -- Excess navs inserted into gaps in order of creation
    ImportantFirstToGap = 3, -- Excess navs inserted into gaps in order of importance, then creation

    [1] = "DoNothing", -- DoNothing
    [2] = "ChronologicalToGap", -- ChronologicalToGap
    [3] = "ImportantFirstChronologicalToGap", -- ImportantFirstChronologicalToGap
}

local CompactMode = _navmanager.CompactionStrategy.DoNothing; -- default to chronological

--- Set the compaction strategy for navs.
--- @tparam string strategy The strategy to use. See @{_navmanager.CompactionStrategy} for options.
--- @function _navmanager.SetCompactionStrategy

--- Set the compaction strategy for navs.
--- @tparam integer strategy The strategy to use. See @{_navmanager.CompactionStrategy} for options.
--- @function _navmanager.SetCompactionStrategy
function _navmanager.SetCompactionStrategy(strategy)
    local strat = strategy;
    if utility.isstring(strategy) then
        strat = _navmanager.CompactionStrategy[strategy];
    end
    if _navmanager.CompactionStrategy[strat] == nil then error("Invalid compaction strategy: " .. tostring(strategy)); end
    CompactMode = strat;
end

--- Get the current compaction strategy for navs.
--- @treturn integer The current compaction strategy. See @{_navmanager.CompactionStrategy} for options.
function _navmanager.GetCompactionStrategy()
    return CompactMode;
end

--- Enumerates all navs for a team.
--- At least 10 indexes will be iterated, even if there are no navs in those slots.
--- Navs not in the nav list, known internally as "Overflow Navs", will be returned with indexes above 10.
--- @tparam integer team Team number to enumerate
--- @tparam[opt] bool include_overflow If true "Overflow Navs" will be included in the enumeration after the initial 10.
--- @treturn integer index The index of the nav in the enumeration
--- @treturn GameObject nav The nav object at the index
--- @usage for i, nav in navmanager.AllNavGameObjects(1, true) do
---     print("Nav " .. i .. ": " .. tostring(nav));
--- end
--- @usage local active_navs = utility.IteratorToArray(navmanager.AllNavGameObjects(1));
function _navmanager.AllNavGameObjects(team, include_overflow)
    for slot = TeamSlot.MIN_BEACON, TeamSlot.MAX_BEACON do
        return (slot - TeamSlot.MIN_BEACON + 1), gameobject.GetTeamSlot(slot, team);
    end
    if includeOverflow and OverflowNavs[team] then
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
            for i = 1, #PendingNavs[team] do
                local nav = PendingNavs[team];
                if nav and nav:IsValid() then
                    table.insert(PendingNavsForTeam, nav);
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
                if CompactMode == _navmanager.CompactionStrategy.DoNothing then
                    NewNavOverflow = PendingNavsForTeam; -- we are set to do nothing, so we just leave the navs in overflow and make sure the new pendings are added too
                elseif CompactMode == _navmanager.CompactionStrategy.ChronologicalToGap then
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
                                    local newNav = gameobject.BuildGameObject(nav:GetOdf(), team, nav:GetTransform());
                                                            
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
                elseif CompactMode == _navmanager.CompactionStrategy.ImportantFirstToGap then
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
                                        local newNav = gameobject.BuildGameObject(nav:GetOdf(), team, nav:GetTransform());
                                        
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
                                        local newNav = gameobject.BuildGameObject(nav:GetOdf(), team, nav:GetTransform());
                                        
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

debugprint("_navmanager Loaded");

return _navmanager;