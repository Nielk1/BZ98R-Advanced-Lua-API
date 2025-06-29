--- BZ98R LUA Extended API Lua Bug Fixer.
---
--- Contains fixes for bugs in the game's lua implementation and other polyfils.
--- 
--- <ul>
--- <li><b>Polyfill:</b> <code>table.unpack</code> for Lua 5.1 compatibility</li>
--- <li><b>Fix/Polyfill:</b> Remap <code>SettLabel</code> to <code>SetLabel</code> for BZ1.5</li>
--- <li><b>Fix:</b> Works around the possible stuck iterator in <code>ObjectiveObjects</code></li>
--- <li><b>Fix/Polyfill:</b> TeamSlot missing "PORTAL" = 90</li>
--- <li><b>Fix:</b> Tugs not respecting DropOff command due to invalid deploy state</li>
--- <li><b>Fix/Polyfill:</b> Fix for broken <code>Formation</code> order function</li>
--- </ul>
---
--- @module '_fix'
--- @author John "Nielk1" Klein

--- @diagnostic disable: undefined-global
local debugprint = debugprint or function(...) end;
local traceprint = traceprint or function(...) end;
--- @diagnostic enable: undefined-global

debugprint("_fix Loading");

local version = require("_version");
local hook = require("_hook");

local pre_patch = version.Compare(version.game, "2.2.315") < 0;

-- [Polyfill] table.unpack for Lua 5.1 compatibility
if not _G.table.unpack then
    debugprint(" - Polyfill: table.unpack");
    _G.table.unpack = _G.table.unpack or _G.unpack; -- Lua 5.1 compatibility
end

-- [Polyfill] Remap SettLabel to SetLabel for BZ1.5
debugprint(" - Fix/Polyfill: SetLabel");
--- @diagnostic disable-next-line: undefined-field
if not _G.SetLabel and _G.SettLabel then
    --- @diagnostic disable-next-line: undefined-field
    _G.SetLabel = _G.SetLabel or _G.SettLabel; -- BZ1.5 compatibility
end

-- [Fix] Broken ObjectiveObjects iterator
if pre_patch then
    debugprint(" - Fix: ObjectiveObjects iterator");
    local old_ObjectiveObjects = _G.ObjectiveObjects;

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
end

-- [Fix][Polyfill] TeamSlot missing "PORTAL" = 90 / ["90"] = "PORTAL"
if not _G.TeamSlot.PORTAL then
    debugprint(" - Fix/Polyfill: TeamSlot PORTAL");
    --- @diagnostic disable-next-line: inject-field
    _G.TeamSlot.PORTAL = 90;
    _G.TeamSlot[90] = "PORTAL";
end

-- [Fix] Tugs not respecting DropOff command due to invalid deploy state
if pre_patch then
    debugprint(" - Fix: Tugs DropOff");
    local function fixTugs()
        --- @diagnostic disable: deprecated
        for v in AllCraft() do
            if(HasCargo(v)) then
                Deploy(v);
            end
        end
        --- @diagnostic enable: deprecated
    end
    hook.Add("Start", "Fix:Start", function()
        fixTugs();
        hook.Remove("Start", "Fix:Start");
        hook.RemoveSaveLoad("Fix");
    end);
    hook.AddSaveLoad("Fix", nil, function()
        fixTugs();
        hook.Remove("Start", "Fix:Start");
        hook.RemoveSaveLoad("Fix");
    end);
end

-- [Fix][Polyfill] Fix for broken Formation order function
if pre_patch then
    debugprint(" - Fix/Polyfill: Formation");
    _G.Formation = Formation or function(me, him, priority)
        if(priority == nil) then
            priority = 1;
        end
        --- @diagnostic disable-next-line: deprecated
        _G.SetCommand(me, AiCommand["FORMATION"], priority, him);
    end
end

debugprint("_fix Loaded");