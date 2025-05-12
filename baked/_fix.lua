--- BZ98R LUA Extended API Lua Bug Fixer
---
--- Contains fixes for bugs in the game's lua implementation and other polyfils.
---
--- <ul>
--- <li><b>Polyfill:</b> <code>table.unpack</code> for Lua 5.1 compatibility</li>
--- <li><b>Fix/Polyfill:</b> Remap <code>SettLabel</code> to <code>SetLabel</code> for BZ1.5</li>
--- <li><b>Fix:</b> Works around the possible stuck iterator in <code>ObjectiveObjects</code></li>
--- </ul>
---
--- @module '_fix'
--- @author John "Nielk1" Klein


local utility = require("_utility");

_G.table.unpack = _G.table.unpack or _G.unpack; -- Lua 5.1 compatibility

--- @diagnostic disable-next-line: undefined-field
_G.SetLabel = _G.SetLabel or _G.SettLabel; -- BZ1.5 compatibility

if utility.CompareVersion(GameVersion, "2.2.315") < 0 then
    local old_ObjectiveObjects = _G.ObjectiveObjects;

    _G.ObjectiveObjects = function ()
        return coroutine.wrap(function()
            local iter = old_ObjectiveObjects();
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
                SetObjectiveOff(object1);

                local handle = iter();
                while handle ~= nil do
                    --print("ObjectiveObjects[*in*]", handle, GetObjectiveName(handle));
                    table.insert(Objectified, handle);
                    --- @diagnostic disable-next-line: deprecated
                    SetObjectiveOff(handle);
                    handle = iter();
                end

                -- Re-enable the objectives
                for i = 1, #Objectified do
                    local handle = Objectified[i];
                    if handle ~= nil then
                        --print("ObjectiveObjects[*fix*]", handle, GetObjectiveName(handle));
                        --- @diagnostic disable-next-line: deprecated
                        SetObjectiveOn(handle);
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