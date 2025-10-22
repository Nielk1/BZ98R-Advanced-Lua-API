--- BZ98R LUA Extended API Lua Bug Fixer.
---
--- Contains fixes for bugs in the game's lua implementation and other polyfils.
--- 
--- * **Polyfill:** `table.unpack` for Lua 5.1 compatibility
--- * **Fix/Polyfill:** Remap `SettLabel` to `SetLabel` for BZ1.5
--- * **Fix:** Works around the possible stuck iterator in `ObjectiveObjects`
--- * **Fix/Polyfill:** TeamSlot missing "PORTAL" = 90
--- * **Fix:** Tugs not respecting DropOff command due to invalid deploy state
--- * **Fix/Polyfill:** Fix for broken `Formation` order function
--- * **Fix:** Powerups not using thrusters when falling if on an AI team
---
--- @module '_fix'
--- @author John "Nielk1" Klein

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_fix Loading");

local version = require("_version");
local hook = require("_hook");
local utility = require("_utility");
local paramdb = require("_paramdb");
local config = require("_config");
local gameobject = require("_gameobject");

local pre_patch = version.Compare(version.game, "2.2.315") < 0;

-- [Polyfill] table.unpack for Lua 5.1 compatibility
if not _G.table.unpack then
    logger.print(logger.LogLevel.DEBUG, nil, " - Polyfill: table.unpack");
    _G.table.unpack = _G.table.unpack or _G.unpack; -- Lua 5.1 compatibility
end

-- [Polyfill] Remap SettLabel to SetLabel for BZ1.5
logger.print(logger.LogLevel.DEBUG, nil, " - Fix/Polyfill: SetLabel");
--- @diagnostic disable-next-line: undefined-field
if not _G.SetLabel and _G.SettLabel then
--- [[START_IGNORE]]
    --- @diagnostic disable-next-line: undefined-field
    _G.SetLabel = _G.SetLabel or _G.SettLabel; -- BZ1.5 compatibility
-- [[END_IGNORE]]
end

-- [Fix] Broken ObjectiveObjects iterator
if pre_patch then
    logger.print(logger.LogLevel.DEBUG, nil, " - Fix: ObjectiveObjects iterator");
    local old_ObjectiveObjects = _G.ObjectiveObjects;

--- [[START_IGNORE]]
    _G.ObjectiveObjects = function ()
        return coroutine.wrap(function()
            local iter = old_ObjectiveObjects();
            if not iter then error("ObjectiveObjects iterator is nil"); end

            local object1 = iter();
            --print("ObjectiveObjects[1]", object1, GetObjectiveName(handle));
            if object1 == nil then return nil; end

            local object2 = iter();
            --print("ObjectiveObjects[2]", object1, GetObjectiveName(handle));

            if object2 ~= object1 then
                --print("ObjectiveObjects bug not detected, returning results and then unpatching");
                -- The function works fine because it managed to iterate
                --coroutine.yield(object1);
                --coroutine.yield(object2);
                --if object2 ~= nil then
                --    for handle in iter() do
                --        coroutine.yield(handle)
                --    end
                --end
                -- Unpatch the function
                _G.ObjectiveObjects = old_ObjectiveObjects;
                return _G.ObjectiveObjects();
            else
                -- The function is broken, so we need to handle it manually
                --print("ObjectiveObjects is bugged");
                
                local Objectified = {};
                table.insert(Objectified, object1);
                --- @diagnostic disable-next-line: deprecated
                _G.SetObjectiveOff(object1);

                local handle = iter();
                while handle ~= nil do
                    --print("ObjectiveObjects[*in*]", handle, GetObjectiveName(handle));
                    table.insert(Objectified, handle);
                    --- @diagnostic disable-next-line: deprecated
                    _G.SetObjectiveOff(handle);
                    handle = iter();
                end

                -- Re-enable the objectives
                for i = 1, #Objectified do
                    local handle = Objectified[i];
                    if handle ~= nil then
                        --print("ObjectiveObjects[*fix*]", handle, GetObjectiveName(handle));
                        --- @diagnostic disable-next-line: deprecated
                        _G.SetObjectiveOn(handle);
                    end
                end

                -- Yield the objects
                for i = 1, #Objectified do
                    local handle = Objectified[i];
                    if handle ~= nil then
                        --print("ObjectiveObjects[*out*]", handle, GetObjectiveName(handle));
                        coroutine.yield(handle);
                    end
                end
            end
        end);
    end;
-- [[END_IGNORE]]
end

-- [Fix][Polyfill] TeamSlot missing "PORTAL" = 90 / ["90"] = "PORTAL"
if not _G.TeamSlot.PORTAL then
    logger.print(logger.LogLevel.DEBUG, nil, " - Fix/Polyfill: TeamSlot PORTAL");
    --- @diagnostic disable-next-line: inject-field
    _G.TeamSlot.PORTAL = 90;
    _G.TeamSlot[90] = "PORTAL";
end

-- [Fix] Tugs not respecting DropOff command due to invalid deploy state
if pre_patch then
    logger.print(logger.LogLevel.DEBUG, nil, " - Fix: Tugs DropOff");
    local function fixTugs()
        --- @diagnostic disable: deprecated
        for v in AllCraft() do
            if(HasCargo(v)) then
                Deploy(v);
            end
        end
        --- @diagnostic enable: deprecated
    end
    hook.Add("Start", "Fix:Tug:Start", function()
        fixTugs();
        hook.Remove("Start", "Fix:Tug:Start");
        hook.RemoveSaveLoad("Fix:Tug");
    end);
    hook.AddSaveLoad("Fix:Tug", nil, function()
        fixTugs();
        hook.Remove("Start", "Fix:Tug:Start");
        hook.RemoveSaveLoad("Fix:Tug");
    end);
end

-- [Fix][Polyfill] Fix for broken Formation order function
if pre_patch then
    logger.print(logger.LogLevel.DEBUG, nil, " - Fix/Polyfill: Formation");
--- [[START_IGNORE]]
    _G.Formation = function(me, him, priority)
        if(priority == nil) then
            priority = 1;
        end
        --- @diagnostic disable-next-line: deprecated
        _G.SetCommand(me, AiCommand.FORMATION, priority, him);
    end
-- [[END_IGNORE]]
end

-- [Fix] Powerups not using thrusters when falling if on an AI team
if pre_patch then
    logger.print(logger.LogLevel.DEBUG, nil, " - Fix: Powerups not using thrusters when falling if on an AI team");
    
    --- @class GameObject_FixFallingPowerup : GameObject
    --- @field PowerupFixes_team integer
    --- @field PowerupFixes_wrecker boolean?
    --- @local

    --- @type table<GameObject_FixFallingPowerup, boolean>
    local PowerupFixes = {};

    hook.Add("Update", "Fix:PowerupAi2:Update", function (dtime, ttime)
        for object, _ in pairs(PowerupFixes) do
            if not object:IsLocal() or not object then
                --- @todo this might cause issues if something changes the owner, but then that other thing would need to fix the team
                PowerupFixes[object] = nil;
            elseif object:GetCurrentCommand() == AiCommand.GO then
                object:SetTeamNum(object.PowerupFixes_team);
                PowerupFixes[object] = nil;
            elseif object.PowerupFixes_wrecker then
                if object:GetVelocity().y < 0 and GetFloorHeightAndNormal(object:GetHandle()) + 10 < object:GetPosition().y then
                    object:SetTeamNum(object.PowerupFixes_team);
                    PowerupFixes[object] = nil;
                end
            end
        end
    end, config.get("hook_priority.Update.FixPowerupAi2"));

    hook.Add("CreateObject", "Fix:PowerupAi2:CreateObject", function(object)
        -- we can safely assume we have a GameObject here, no need to test or extract

        --- @cast object GameObject_FixFallingPowerup
        
        -- ignore objects that are not local ( can't be done in CreateObject, too early)
        --if not object:IsLocal() then return; end

        -- ignore objects that are not powerups
        if object:GetClassId() ~= ClassId.POWERUP then return; end
        if object:GetClassSig() == utility.ClassSig.TORPEDO then return; end
        
        -- we only care about objects that aren't on a player team
        local currentTeam = object:GetTeamNum();
        if gameobject.GetPlayer(currentTeam) ~= nil then return; end

        if paramdb.GetValueString(object:GetOdf(), "GameObjectClass", "aiName2", "") ~= "" then return; end

        local sig = object:GetClassSig();
        if sig == utility.ClassSig.DAYWRECKER then
            logger.print(logger.LogLevel.WARN, nil, "Powerup is a wrecker but has no aiName2, fall-fix could cause issues with damage credit.");
            object.PowerupFixes_wrecker = true;
        end
        logger.print(logger.LogLevel.DEBUG, nil, "Falling AI Powerup detected!");
        object.PowerupFixes_team = currentTeam;
        PowerupFixes[object] = true;
        if not IsNetGame() and IsTeamAllied(currentTeam, 1) and IsTeamAllied(1, currentTeam) then
            if sig == utility.ClassSig.POWERUP_CAMERA then
                -- camera pods are annoying because you can see from them
                object:SetTeamNum(0);
            else
                object:SetTeamNum(1);
            end
        else
            object:SetTeamNum(0);
        end
    end, config.get("hook_priority.CreateObject.FixPowerupAi2"));

    hook.AddSaveLoad(
        "Fix:PowerupAi2",
        function() return PowerupFixes; end,
        function(data) PowerupFixes = data; end);
end

logger.print(logger.LogLevel.DEBUG, nil, "_fix Loaded");