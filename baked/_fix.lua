--- BZ98R LUA Extended API Lua Bug Fixer
---
--- Contains fixes for bugs in the game's lua implementation and other polyfils.
---
--- Fix 1: Works around the possible stuck iterator in ObjectiveObjects
---
--- @module '_fix'
--- @author John "Nielk1" Klein

-- consider checking the game version if we know what version it's fixed in
local old_ObjectiveObjects = ObjectiveObjects;

ObjectiveObjects = function ()
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
            ObjectiveObjects = old_ObjectiveObjects;
            return ObjectiveObjects();
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