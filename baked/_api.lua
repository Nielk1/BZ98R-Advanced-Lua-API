--- BZ98R LUA Extended API.
---
--- This API creates a full OOP wrapper and replacement the mission
--- functions with an event based system for easier expansion.
---
--- @module '_api'
--- @author John "Nielk1" Klein

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_api Loading");

require("_fix");

local utility = require("_utility");
local hook = require("_hook");
local gameobject = require("_gameobject");
local customsavetype = require("_customsavetype");
local version = require("_version");

--local updateDelta;

--- Called when saving state to a save game file, allowing the script to preserve its state.
--
-- Any values returned by this function will be passed as parameters to Load when loading the save game file. Save supports nil, boolean, handle, integer, number, string, vector, and matrix data types. It does not support function, thread, or arbitrary userdata types.
--
-- The console window will print the saved values in human-readable format.
--
-- Call method: @{_hook.CallSave|CallSave}
-- @event Save
-- @return ... saved data
-- @see _hook.AddSaveLoad

--- Called when loading state from a save game file, allowing the script to restore its state.
--
-- Data values returned from Save will be passed as parameters to Load in the same order they were returned. Load supports nil, boolean, handle, integer, number, string, vector, and matrix data types. It does not support function, thread, or arbitrary userdata types.
--
-- The console window will print the loaded values in human-readable format.
--
-- Call method: @{_hook.CallLoad|CallLoad}
-- @event Load
-- @tparam ... loaded data
-- @see _hook.AddSaveLoad

--- Called when the mission starts for the first time.
--
-- Use this function to perform any one-time script initialization.
--
-- Call method: @{_hook.CallAllNoReturn|CallAllNoReturn}
-- @event Start
-- @see _hook.Add

--- Called any time a game key is pressed.
--
-- Key is a string that consisting of zero or more modifiers (Ctrl, Shift, Alt) and a base key.
--
-- The base key for keys corresponding to a printable ASCII character is the upper-case version of that character.
--
-- The base key for other keys is the label on the keycap (e.g. PageUp, PageDown, Home, End, Backspace, and so forth).
--
-- Call method: @{_hook.CallAllNoReturn|CallAllNoReturn}
-- @event GameKey
-- @tparam string key zero or more modifiers (Ctrl, Shift, Alt) and a base key
-- @see _hook.Add

--- Called once per tick after updating the network system and before simulating game objects.
--
-- This function performs most of the mission script's game logic.
--
-- Call method: @{_hook.CallAllNoReturn|CallAllNoReturn}
-- @event Update
-- @tparam float dtime Delta Time
-- @tparam float ttime Total Time
-- @see _hook.Add

--- Called after any game object is created.
--
-- Handle is the game object that was created.
--
-- This function will get a lot of traffic so it should not do too much work.
--
-- Call method: @{_hook.CallAllNoReturn|CallAllNoReturn}
-- @event CreateObject
-- @tparam GameObject object
-- @tparam[opt] bool isMapObject
-- @see _hook.Add

--- Called when a game object gets added to the mission
--
-- Handle is the game object that was added
--
-- This function is normally called for "important" game objects, and excludes things like Scrap pieces.
--
-- Call method: @{_hook.CallAllNoReturn|CallAllNoReturn}
-- @event AddObject
-- @tparam GameObject object
-- @see _hook.Add

--- Called before a game object is fully deleted.
--
-- This function will get a lot of traffic so it should not do too much work.
--
-- Note: This is called after the object is largely removed from the game, so most Get functions won't return a valid value.
--
-- Call method: @{_hook.CallAllNoReturn|CallAllNoReturn}
-- @event DeleteObject
-- @tparam GameObject object 
-- @see _hook.Add

--- Called when a player joins the session.
--
-- Players that join before the host launches trigger CreatePlayer just before the first Update.
--
-- Players that join joining after the host launches trigger CreatePlayer on entering the pre-game lobby.
--
-- This function gets called for the local player.
--
-- Call method: @{_hook.CallAllNoReturn|CallAllNoReturn}
-- @event CreatePlayer
-- @see _hook.Add
-- @tparam int id DPID number for this player
-- @tparam string name name for this player
-- @tparam int team Team number for this player

--- Called when a player starts sending state updates.
--
-- This indicates that a player has finished loaded and started simulating.
--
-- This function is _not_ called for the local player.
--
-- Call method: @{_hook.CallAllNoReturn|CallAllNoReturn}
-- @event AddPlayer
-- @see _hook.Add
-- @tparam int id DPID number for this player
-- @tparam string name name for this player
-- @tparam int team Team number for this player

--- Called when a player leaves the session.
--
-- Call method: @{_hook.CallAllNoReturn|CallAllNoReturn}
-- @event DeletePlayer
-- @see _hook.Add
-- @tparam int id DPID number for this player
-- @tparam string name name for this player
-- @tparam int team Team number for this player

--- Called when a script-defined message arrives.
--
-- This function should return true if it handled the message and false, nil, or none if it did not.
--
-- Call method: @{_hook.CallAllPassReturn|CallAllPassReturn} (TODO consider changing call type to stop after first true)
-- @event Receive
-- @see _hook.Add
-- @tparam int from network player id of the sender.
-- @tparam string type an arbitrary one-character string indicating the script-defined message type.
-- @tparam ... data values passed as parameters to Send will arrive as parameters to Receive in the same order they were sent. Receive supports nil, boolean, handle, integer, number, string, vector, and matrix data types. It does not support function, thread, or arbitrary userdata types.
-- @tparam[opt] HookResult priorResult prior event handler's result

--- Called for any in-game chat command that was not handled by the system, allowing script-defined commands.
--
-- This function should return true if it handled the command and false, nil, or none if it did not.
--
-- LuaMission breaks the command into
--
-- Command is the string immediately following the '/'. For example, the command for "/foo" is "foo".
--
-- Arguments arrive as a string parameter to Command. For example "/foo 1 2 3" would receive "1 2 3".
--
-- The Lua string library provides several functions that can split the string into separate items.
--
-- You can use string.match with captures if you have a specific argument list:
-- <pre>local foo, bar, baz = string.match(arguments, "(%g+) (%g+) (%g+)")</pre>
--
-- You can use string.gmatch, which returns an iterator, if you want to loop through arguments:
-- <pre>for arg in string.gmatch(arguments, "%g+") do ... end</pre>
--
-- Check the Lua <a href="http://lua-users.org/wiki/PatternsTutorial">patterns tutorial</a> and <a href="http://www.lua.org/manual/5.2/manual.html#6.4.1">patterns manual</a> for more details.
--
-- Call method: @{_hook.CallAllPassReturn|CallAllPassReturn}
-- @event Command
-- @see _hook.Add
-- @tparam string command
-- @tparam ... parameters
-- @tparam[opt] HookResult priorResult prior event handler's result

--- #section Enums



--- #section Custom Types

local CustomTypeMap = nil; -- maps name to ID number
--local DuplicateAntiLoopMemo = nil;
--local DuplicateAntiLoopLookupMemo = nil;
--local DuplicateSourceReferenceMemo = nil;
--local DuplicateDestReferenceMemo = nil;

-- reset these when starting a save and ending a save
local RefUUIID = 0;

--- map of references to their UUIDs
--- @type table<table, integer>
local SaveUUIDMap = nil;

--- set of references that have started processing already
--- @type table<table, boolean>
local SaveLoopCheck = nil;

--- map of references that have finished first pass to their output table
--- @type table<table, table>
local SavePostCheck = nil;

--- @class _api
local _api = {};

--- @vararg any data
--- @return any ...
function SimplifyForSave(...)
    local output = {...}; -- output array
    local ArraySize = 0;
    for k,v in pairs(output) do
        if k > ArraySize then
            ArraySize = k;
        end
        if utility.istable(v) then -- it's a table, start special logic
            if not v.__nosave then
                local ORIG = v;
                local existingUUID = SaveUUIDMap[ORIG];
                local newTable = {};
                if existingUUID and not v.__noref then
                    if SavePostCheck[ORIG] then
                        SavePostCheck[ORIG].__refid = existingUUID;
                    else
                        SaveLoopCheck[ORIG] = true;
                    end
                    newTable = { __ref = existingUUID };
                else
                    local currentUUID = RefUUIID;
                    RefUUIID = RefUUIID + 1;
                    SaveUUIDMap[ORIG] = currentUUID;
                    if customsavetype.CustomSavableTypes[v.__type] ~= nil then
                        if not CustomTypeMap then error("CustomTypeMap is nil") end
                        local typeIndex = CustomTypeMap[v.__type];
                        logger.print(logger.LogLevel.DEBUG, nil, "Type index for " .. v.__type .. " is " .. tostring(typeIndex));
                        newTable["*custom_type"] = typeIndex;
                        if customsavetype.CustomSavableTypes[v.__type].Save ~= nil then
                            newTable["*data"] = {SimplifyForSave(customsavetype.CustomSavableTypes[v.__type].Save(v))};
                        end
                    else
                        -- we need to work with a clone of the table so we don't modify the original, as the mission will continue to run after saving so it must remain the same
                        for k2, v2 in pairs(v) do
                            newTable[SimplifyForSave(k2)] = SimplifyForSave(v2);
                        end
                    end
                    if SaveLoopCheck[ORIG] then
                        newTable.__refid = currentUUID;
                    end
                    SavePostCheck[ORIG] = newTable;
                end
                output[k] = newTable;
            else
                output[k] = nil;
            end
        end
    end
    return table.unpack(output, 1, ArraySize);
end

--- map UUIDs to their tables as they are encountered
--- @type table<integer, table>
local LoadUUIDToTable = nil;

--- @vararg any data
--- @return any ...
function DeSimplifyForLoad(...)
    local output = {...}; -- output array
    local ArraySize = 0;
    for k,v in pairs(output) do
        if k > ArraySize then
            ArraySize = k;
        end
        if utility.istable(v) then -- it's a table, start special logic
            local PriorData = v.__refid and LoadUUIDToTable[v.__refid] or v.__ref and LoadUUIDToTable[v.__ref] or nil;
            local TableFromLoad = nil;
            local metatableToApply = nil;
            if v["*custom_type"] ~= nil then
                if not CustomTypeMap then error("CustomTypeMap is nil") end
                local typeName = CustomTypeMap[v["*custom_type"]];
                local typeObj = customsavetype.CustomSavableTypes[typeName];
                if typeObj.Load ~= nil then
                    if v["*data"] ~= nil then

                        local args = v["*data"];
                        local ArraySize_ = 0;
                        for k,v in pairs(args) do if k > ArraySize_ then ArraySize_ = k; end end

                        TableFromLoad = typeObj.Load(DeSimplifyForLoad(table.unpack(args, 1, ArraySize_)));
                    else
                        TableFromLoad = typeObj.Load();
                    end
                    metatableToApply = getmetatable(TableFromLoad);
                end
            else
                -- since we're loading we don't have to worry about modifying the original, as the original came from the load function and will cease to exist after this
                TableFromLoad = {};
                for k2, v2 in pairs( v ) do
                    if v2 ~= nil then
                        -- if the value isn't nil, let it try to DeSimplifyForLoad and just stuff it right back in the table
                        TableFromLoad[DeSimplifyForLoad(k2)] = DeSimplifyForLoad(v2);
                    end
                end
            end
            if TableFromLoad then
                if TableFromLoad.__noref then
                    -- This table is not a reference, so we can just return it as is.
                    -- If we didn't do this, we would break the reference that types like GameObject hold lists of.
                    output[k] = TableFromLoad;
                else
                    -- merge the tables, taking in the new metatable too
                    local CompositeTable = PriorData or TableFromLoad;
                    if CompositeTable ~= TableFromLoad then
                        for k2, v2 in pairs(TableFromLoad) do
                            CompositeTable[k2] = v2;
                        end
                        if metatableToApply then
                            setmetatable(CompositeTable, metatableToApply);
                        end
                    end
                    output[k] = CompositeTable;

                    local refID = v.__refid or v.__ref;
                    if refID and not LoadUUIDToTable[refID] then
                        LoadUUIDToTable[refID] = CompositeTable;
                    end
                end
            else
                output[k] = nil;
            end
        end
    end
    return table.unpack(output, 1, ArraySize);
end

--- #section Hooks

--- Save is called when you save a game
--- @local
function Save()
    logger.print(logger.LogLevel.DEBUG, nil, "_api::Save()");
    CustomTypeMap = {};
    RefUUIID = 1;
    SaveUUIDMap = {};
    SaveLoopCheck = {};
    SavePostCheck = {};

    logger.print(logger.LogLevel.DEBUG, nil, "Beginning save code");

    local saveData = {};
    logger.print(logger.LogLevel.DEBUG, nil, "Save Data Container ready");

    logger.print(logger.LogLevel.DEBUG, nil, "Saving custom types map");
    local CustomSavableTypesCounter = 1;
    local CustomSavableTypeTmpTable = {};
    for k,v in pairs(customsavetype.CustomSavableTypes) do
        CustomSavableTypeTmpTable[CustomSavableTypesCounter] = k;
        CustomTypeMap[k] = CustomSavableTypesCounter;
        logger.print(logger.LogLevel.DEBUG, nil, "[" .. CustomSavableTypesCounter .. "] = " .. k);
        CustomSavableTypesCounter = CustomSavableTypesCounter + 1;
    end
    saveData.CustomSavableTypes = CustomSavableTypeTmpTable; -- Write TmpID -> Name map
    logger.print(logger.LogLevel.DEBUG, nil, "Saved custom types map");
    
    logger.print(logger.LogLevel.DEBUG, nil, "Saving custom types");
    local CustomSavableTypeDataTmpTable = {};
    for idNum,name in ipairs(CustomSavableTypeTmpTable) do
        local entry = customsavetype.CustomSavableTypes[name];
        if entry.BulkSave ~= nil and utility.isfunction(entry.BulkSave) then
            logger.print(logger.LogLevel.DEBUG, nil, "Saved " .. entry.__type);
            CustomSavableTypeDataTmpTable[idNum] = {SimplifyForSave(entry.BulkSave())};
        else
            logger.print(logger.LogLevel.DEBUG, nil, "Saved " .. entry.__type .. " (nothing to save)");
            CustomSavableTypeDataTmpTable[idNum] = {};
        end
    end
    saveData.CustomSavableTypeData = CustomSavableTypeDataTmpTable; -- Write TmpID -> Data map
    CustomSavableTypeDataTmpTable = nil;
    CustomSavableTypeTmpTable = nil;
    logger.print(logger.LogLevel.DEBUG, nil, "Saved custom types");
    
    logger.print(logger.LogLevel.DEBUG, nil, "Calling all hooked save functions");
    table.insert(saveData,saveData.Hooks)
    local hookResults = hook.CallSave();
    if hookResults ~= nil then
      saveData.HooksData = {SimplifyForSave(hookResults)};
    else
      saveData.HooksData = {};
    end
    
    logger.print(logger.LogLevel.DEBUG, nil, table.show(saveData));
    
    CustomTypeMap = nil;
    RefUUIID = 0;
    --- @diagnostic disable: cast-local-type
    SaveUUIDMap = nil;
    SaveLoopCheck = nil;
    SavePostCheck = nil;
    --- @diagnostic enable: cast-local-type

    logger.print(logger.LogLevel.DEBUG, nil, "_api::/Save");
    return saveData;
end

--- Load is called when you load a game, or when a Resync is loaded.
--- @local
function Load(...)
    logger.print(logger.LogLevel.DEBUG, nil, "_api::Load()");
    local args = ...;

--    str = table.show(args);
--    for s in str:gmatch("[^\r\n]+") do
--        logger.print(logger.LogLevel.DEBUG, nil, s);
--    end
    logger.print(logger.LogLevel.DEBUG, nil, table.show(args));

--    logger.print(logger.LogLevel.DEBUG, nil, "Beginning load code");

    LoadUUIDToTable = {};

    logger.print(logger.LogLevel.TRACE, nil, "Loading custom types map");
    CustomTypeMap = args.CustomSavableTypes
    logger.print(logger.LogLevel.TRACE, nil, "Loaded custom types map");
    
    logger.print(logger.LogLevel.TRACE, nil, "Loading custom types data");
    for idNum,data in ipairs(args.CustomSavableTypeData) do
        local entry = customsavetype.CustomSavableTypes[CustomTypeMap[idNum]];
        if entry.BulkLoad ~= nil and utility.isfunction(entry.BulkLoad) then
            logger.print(logger.LogLevel.TRACE, nil, "Loaded " .. entry.__type);

            local ArraySize = 0;
            for k,v in pairs(data) do if k > ArraySize then ArraySize = k; end end

            -- maybe we should load DeSimplifyForLoad multiple times until we know for sure the data has no more refs?
            entry.BulkLoad(DeSimplifyForLoad(table.unpack(data, 1, ArraySize)));
            logger.print(logger.LogLevel.TRACE, nil, "BulkLoad ran for " .. entry.__type);
        end
    end
    logger.print(logger.LogLevel.TRACE, nil, "Loaded custom types data");

    logger.print(logger.LogLevel.TRACE, nil, "Calling all hooked load functions");

    local ArraySize = 0;
    for k,_ in pairs(args.HooksData) do if utility.isinteger(k) and k > ArraySize then ArraySize = k; end end

    local loadParams = { DeSimplifyForLoad(table.unpack(args.HooksData, 1, ArraySize)) };

    -- clean up the old references
    for _, dat in pairs(LoadUUIDToTable) do
        dat.__refid = nil;
        dat.__ref = nil;
    end

    ArraySize = 0;
    for k,_ in pairs(loadParams) do if utility.isinteger(k) and k > ArraySize then ArraySize = k; end end
    hook.CallLoad(table.unpack(loadParams, 1, ArraySize));

    CustomTypeMap = nil;
    --- @diagnostic disable-next-line: unused-local, cast-local-type
    LoadUUIDToTable = nil;

    logger.print(logger.LogLevel.DEBUG, nil, "_api::/Load");
end

--- Called when the mission starts for the first time.
--- Use this function to perform any one-time script initialization.
--- @local
function Start()
    logger.print(logger.LogLevel.DEBUG, nil, "_api::Start()");
    
    --- @diagnostic disable-next-line: deprecated
    for h in AllObjects() do
        hook.CallAllNoReturn( "CreateObject", gameobject.FromHandle(h), true );
    end

    hook.CallAllNoReturn( "Start" );
    logger.print(logger.LogLevel.DEBUG, nil, "_api::/Start");
end

--- Called any time a game key is pressed.
--- Key is a string that consisting of zero or more modifiers (Ctrl, Shift, Alt) and a base key.
--- The base key for keys corresponding to a printable ASCII character is the upper-case version of that character.
--- The base key for other keys is the label on the keycap (e.g. PageUp, PageDown, Home, End, Backspace, and so forth).
--- @local
function GameKey(key)
    logger.print(logger.LogLevel.TRACE, nil, "_api::GameKey('" .. key .. "')");
    hook.CallAllNoReturn( "GameKey", key );
    logger.print(logger.LogLevel.TRACE, nil, "_api::/GameKey");
end

--- Called after any game object is created.
--- Handle is the game object that was created.
--- This function will get a lot of traffic so it should not do too much work.
--- Note that many game object functions may not work properly here.
--- @local
function CreateObject(h)
    logger.print(logger.LogLevel.TRACE, nil, "_api::CreateObject(" .. tostring(h) .. ")");
    hook.CallAllNoReturn( "CreateObject", gameobject.FromHandle(h) );
    logger.print(logger.LogLevel.TRACE, nil, "_api::/CreateObject");
end

--- Called after any game object is created.
--- Handle is the game object that was created.
--- This function will get a lot of traffic so it should not do too much work.
--- Note that many game object functions may not work properly here.
--- @local
function AddObject(h)
    logger.print(logger.LogLevel.TRACE, nil, "_api::AddObject(" .. tostring(h) .. ")");
    hook.CallAllNoReturn( "AddObject", gameobject.FromHandle(h) );
    logger.print(logger.LogLevel.TRACE, nil, "_api::/AddObject");
end

--- Called before a game object is deleted.
--- Handle is the game object to be deleted.
--- This function will get a lot of traffic so it should not do too much work.
--- Note: This is called after the object is largely removed from the game, so most Get functions won't return a valid value.
--- @local
function DeleteObject(h)
    logger.print(logger.LogLevel.TRACE, nil, "_api::DeleteObject(" .. tostring(h) .. ")");
    hook.CallAllNoReturn( "DeleteObject", gameobject.FromHandle(h) );
    logger.print(logger.LogLevel.TRACE, nil, "_api::/DeleteObject");
end

--- Called once per tick after updating the network system and before simulating game objects.
--- This function performs most of the mission script's game logic.
--- @local
function Update(dtime)
    logger.print(logger.LogLevel.TRACE, nil, "_api::Update()");

    --local start = GetTimeNow();

    local ttime = GetTime();
    hook.CallAllNoReturn( "Update", dtime, ttime);
    logger.print(logger.LogLevel.TRACE, nil, "_api::/Update");
    --local delta = GetTimeNow() - start;

    --print("Script Update Load: "..string.format("%.2f%%", (updateDelta or delta) / dtime / 10));
    --updateDelta = delta;
end

--- Called when a player joins the game world.
--- @param id integer DPID number for this player
--- @param name string name for this player
--- @param team integer Team number for this player
--- @local
function CreatePlayer(id, name, team)
    logger.print(logger.LogLevel.DEBUG, nil, "_api::CreatePlayer(" .. tostring(id) .. ", '" .. name .. "', " .. tostring(team) .. ")");
    hook.CallAllNoReturn("CreatePlayer", id, name, team);
    logger.print(logger.LogLevel.DEBUG, nil, "_api::/CreatePlayer");
end

--- Called when a player joins the game world.
--- @param id integer DPID number for this player
--- @param name string name for this player
--- @param team integer Team number for this player
--- @local
function AddPlayer(id, name, team)
    logger.print(logger.LogLevel.DEBUG, nil, "_api::AddPlayer(" .. tostring(id) .. ", '" .. name .. "', " .. tostring(team) .. ")");
    hook.CallAllNoReturn("AddPlayer", id, name, team);
    logger.print(logger.LogLevel.DEBUG, nil, "_api::/AddPlayer");
end

--- Called when a player leaves the game world.
--- @param id integer DPID number for this player
--- @param name string name for this player
--- @param team integer Team number for this player
--- @local
function DeletePlayer(id, name, team)
    logger.print(logger.LogLevel.DEBUG, nil, "_api::DeletePlayer(" .. tostring(id) .. ", '" .. name .. "', " .. tostring(team) .. ")");
    hook.CallAllNoReturn("DeletePlayer", id, name, team);
    logger.print(logger.LogLevel.DEBUG, nil, "_api::/DeletePlayer");
end

--- Command
--- @param command string the command string
--- @local
function Command(command, ...)
    logger.print(logger.LogLevel.TRACE, nil, "_api::Command('" .. command .. "')");
    local args = ...;
    logger.print(logger.LogLevel.DEBUG, nil, table.show(args));
    
    local retVal = nil;
    retVal = hook.CallAllPassReturn("Command", command, table.unpack(args));
    logger.print(logger.LogLevel.TRACE, nil, "_api::/Command");
    return retVal;
end

--- Receive
--- @param from integer x
--- @param type string x
--- @tparam ... data
--- @local
function Receive(from, type, ...)
    logger.print(logger.LogLevel.TRACE, nil, "_api::Receive(" .. from .. ", '" .. type .. "')");
    local args = ...;
    logger.print(logger.LogLevel.DEBUG, nil, table.show(args));
    
    local retVal = nil;
    retVal = hook.CallAllPassReturn("Receive", from, type, table.unpack(args));
    logger.print(logger.LogLevel.TRACE, nil, "_api::/Receive");
    return retVal;
end


--- #section Script Run

logger.print(logger.LogLevel.DEBUG, nil, "_api Loaded");

print("Versions:")
for _,l,v in version.All() do
    if v then
        print("  " .. l .. ": " .. tostring(v));
    else
        print("  " .. l .. ": ????");
    end
end

return _api;