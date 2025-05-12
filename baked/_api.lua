--- BZ98R LUA Extended API.
---
--- This API creates a full OOP wrapper and replacement the mission
--- functions with an event based system for easier expansion.
---
--- @module '_api'
--- @author John "Nielk1" Klein

--- @diagnostic disable: undefined-global
table.unpack = table.unpack or unpack; -- Lua 5.1 compatibility
SetLabel = SetLabel or SettLabel; -- BZ1.5 compatibility

local debugprint = debugprint or function(...) end;
local traceprint = traceprint or function(...) end;
--- @diagnostic enable: undefined-global

debugprint("_api Loading");

local utility = require("_utility");
local hook = require("_hook");
local gameobject = require("_gameobject");
local customsavetype = require("_customsavetype");

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

-------------------------------------------------------------------------------
-- Enums
-------------------------------------------------------------------------------
-- @section



-------------------------------------------------------------------------------
-- Custom Types
-------------------------------------------------------------------------------
-- @section

local CustomTypeMap = nil; -- maps name to ID number

local _api = {};


function SimplifyForSave(...)
    local output = {}; -- output array
    local count = select ("#", ...); -- get count of params
    for k = 1,count,1 do  -- loop params via count
        local v = select(k,...); -- get Kth Parameter, store in v
        if utility.istable(v) then -- it's a table, start special logic
            if not v.__nosave then
                if customsavetype.CustomSavableTypes[v.__type] ~= nil then
                    local specialTypeTable = {};
                    if not CustomTypeMap then error("CustomTypeMap is nil") end
                    local typeIndex = CustomTypeMap[v.__type];
                    debugprint("Type index for " .. v.__type .. " is " .. tostring(typeIndex));
                    specialTypeTable["*custom_type"] = typeIndex;
                    if customsavetype.CustomSavableTypes[v.__type].Save ~= nil then
                        specialTypeTable["*data"] = {SimplifyForSave(customsavetype.CustomSavableTypes[v.__type].Save(v))};
                    end
                    table.insert(output, specialTypeTable);
                else
                    local newTable = {};
                    for k2, v2 in pairs( v ) do 
                        newTable[k2] = SimplifyForSave(v2);
                    end
                    table.insert(output, newTable);
                end
            end
        else -- it's not a table, really simple
            table.insert(output, v);
        end
    end
    return table.unpack(output);
end

function DeSimplifyForLoad(...)
    local output = {}; -- output array
    local count = select ("#", ...); -- get count of params
    for k = 1,count,1 do  -- loop params via count
        local v = select(k,...); -- get Kth Parameter, store in v
        if utility.istable(v) then -- it's a table, start special logic
            if v["*custom_type"] ~= nil then
                if not CustomTypeMap then error("CustomTypeMap is nil") end
                local typeName = CustomTypeMap[v["*custom_type"]];
                local typeObj = customsavetype.CustomSavableTypes[typeName];
                if typeObj.Load ~= nil then
                    if v["*data"] ~= nil then
                        table.insert(output, typeObj.Load(DeSimplifyForLoad(table.unpack(v["*data"]))));
                    else
                        table.insert(output, typeObj.Load());
                    end
                end
            else
                local newTable = {};
                for k2, v2 in pairs( v ) do 
                    newTable[k2] = DeSimplifyForLoad(v2);
                end
                table.insert(output, newTable);
            end
        else -- it's not a table, really simple
            table.insert(output, v);
        end
    end
    return table.unpack(output);
end

-------------------------------------------------------------------------------
-- Hooks
-------------------------------------------------------------------------------
-- @section

--- Save is called when you save a game
--- @local
function Save()
    debugprint("_api::Save()");
    CustomTypeMap = {};

    debugprint("Beginning save code");

    local saveData = {};
    debugprint("Save Data Container ready");

    debugprint("Saving custom types map");
    local CustomSavableTypesCounter = 1;
    local CustomSavableTypeTmpTable = {};
    for k,v in pairs(customsavetype.CustomSavableTypes) do
        CustomSavableTypeTmpTable[CustomSavableTypesCounter] = k;
        CustomTypeMap[k] = CustomSavableTypesCounter;
        debugprint("[" .. CustomSavableTypesCounter .. "] = " .. k);
        CustomSavableTypesCounter = CustomSavableTypesCounter + 1;
    end
    saveData.CustomSavableTypes = CustomSavableTypeTmpTable; -- Write TmpID -> Name map
    debugprint("Saved custom types map");
    
    debugprint("Saving custom types");
    local CustomSavableTypeDataTmpTable = {};
    for idNum,name in ipairs(CustomSavableTypeTmpTable) do
        local entry = customsavetype.CustomSavableTypes[name];
        if entry.BulkSave ~= nil and utility.isfunction(entry.BulkSave) then
            debugprint("Saved " .. entry.TypeName);
            CustomSavableTypeDataTmpTable[idNum] = {SimplifyForSave(entry.BulkSave())};
        else
            debugprint("Saved " .. entry.TypeName .. " (nothing to save)");
            CustomSavableTypeDataTmpTable[idNum] = {};
        end
    end
    saveData.CustomSavableTypeData = CustomSavableTypeDataTmpTable; -- Write TmpID -> Data map
    CustomSavableTypeDataTmpTable = nil;
    CustomSavableTypeTmpTable = nil;
    debugprint("Saved custom types");
    
    debugprint("Calling all hooked save functions");
    table.insert(saveData,saveData.Hooks)
    local hookResults = hook.CallSave();
    if hookResults ~= nil then
      saveData.HooksData = {SimplifyForSave(hookResults)};
    else
      saveData.HooksData = {};
    end
    
    debugprint(table.show(saveData));
    
    debugprint("_api::/Save");
    return saveData;
end

--- Load is called when you load a game, or when a Resync is loaded.
--- @local
function Load(...)
    debugprint("_api::Load()");
    local args = ...;

--    str = table.show(args);
--    for s in str:gmatch("[^\r\n]+") do
--        debugprint(s);
--    end
    debugprint(table.show(args));

--    debugprint("Beginning load code");

    traceprint("Loading custom types map");
    CustomTypeMap = args.CustomSavableTypes
    traceprint("Loaded custom types map");
    
    traceprint("Loading custom types data");
    for idNum,data in ipairs(args.CustomSavableTypeData) do
        local entry = customsavetype.CustomSavableTypes[CustomTypeMap[idNum]];
        if entry.BulkLoad ~= nil and utility.isfunction(entry.BulkLoad) then
            traceprint("Loaded " .. entry.TypeName);
            entry.BulkLoad(DeSimplifyForLoad(table.unpack(data)));
            traceprint("BulkLoad ran for " .. entry.TypeName);
        end
    end
    traceprint("Loaded custom types data");

    traceprint("Calling all hooked load functions");
    hook.CallLoad(DeSimplifyForLoad(table.unpack(args.HooksData)));
    debugprint("_api::/Load");
end

--- Called when the mission starts for the first time.
--- Use this function to perform any one-time script initialization.
--- @local
function Start()
    debugprint("_api::Start()");
    
    --- @diagnostic disable-next-line: deprecated
    for h in AllObjects() do
        hook.CallAllNoReturn( "CreateObject", gameobject.FromHandle(h), true );
    end

    hook.CallAllNoReturn( "Start" );
    debugprint("_api::/Start");
end

--- Called any time a game key is pressed.
--- Key is a string that consisting of zero or more modifiers (Ctrl, Shift, Alt) and a base key.
--- The base key for keys corresponding to a printable ASCII character is the upper-case version of that character.
--- The base key for other keys is the label on the keycap (e.g. PageUp, PageDown, Home, End, Backspace, and so forth).
--- @local
function GameKey(key)
    traceprint("_api::GameKey('" .. key .. "')");
    hook.CallAllNoReturn( "GameKey", key );
    traceprint("_api::/GameKey");
end

--- Called after any game object is created.
--- Handle is the game object that was created.
--- This function will get a lot of traffic so it should not do too much work.
--- Note that many game object functions may not work properly here.
--- @local
function CreateObject(h)
    traceprint("_api::CreateObject(" .. tostring(h) .. ")");
    hook.CallAllNoReturn( "CreateObject", gameobject.FromHandle(h) );
    traceprint("_api::/CreateObject");
end

--- Called after any game object is created.
--- Handle is the game object that was created.
--- This function will get a lot of traffic so it should not do too much work.
--- Note that many game object functions may not work properly here.
--- @local
function AddObject(h)
    traceprint("_api::AddObject(" .. tostring(h) .. ")");
    hook.CallAllNoReturn( "AddObject", gameobject.FromHandle(h) );
    traceprint("_api::/AddObject");
end

--- Called before a game object is deleted.
--- Handle is the game object to be deleted.
--- This function will get a lot of traffic so it should not do too much work.
--- Note: This is called after the object is largely removed from the game, so most Get functions won't return a valid value.
--- @local
function DeleteObject(h)
    traceprint("_api::DeleteObject(" .. tostring(h) .. ")");
    hook.CallAllNoReturn( "DeleteObject", gameobject.FromHandle(h) );
    traceprint("_api::/DeleteObject");
end

--- Called once per tick after updating the network system and before simulating game objects.
--- This function performs most of the mission script's game logic.
--- @local
function Update(dtime)
    traceprint("_api::Update()");
    local ttime = GetTime();
    hook.CallAllNoReturn( "Update", dtime, ttime);
    traceprint("_api::/Update");
end

--- Called when a player joins the game world.
--- @param id integer DPID number for this player
--- @param name string name for this player
--- @param team integer Team number for this player
--- @local
function CreatePlayer(id, name, team)
    debugprint("_api::CreatePlayer(" .. tostring(id) .. ", '" .. name .. "', " .. tostring(team) .. ")");
    hook.CallAllNoReturn("CreatePlayer", id, name, team);
    debugprint("_api::/CreatePlayer");
end

--- Called when a player joins the game world.
--- @param id integer DPID number for this player
--- @param name string name for this player
--- @param team integer Team number for this player
--- @local
function AddPlayer(id, name, team)
    debugprint("_api::AddPlayer(" .. tostring(id) .. ", '" .. name .. "', " .. tostring(team) .. ")");
    hook.CallAllNoReturn("AddPlayer", id, name, team);
    debugprint("_api::/AddPlayer");
end

--- Called when a player leaves the game world.
--- @param id integer DPID number for this player
--- @param name string name for this player
--- @param team integer Team number for this player
--- @local
function DeletePlayer(id, name, team)
    debugprint("_api::DeletePlayer(" .. tostring(id) .. ", '" .. name .. "', " .. tostring(team) .. ")");
    hook.CallAllNoReturn("DeletePlayer", id, name, team);
    debugprint("_api::/DeletePlayer");
end

--- Command
--- @param command string the command string
--- @local
function Command(command, ...)
    traceprint("_api::Command('" .. command .. "')");
    local args = ...;
    debugprint(table.show(args));
    
    local retVal = nil;
    retVal = hook.CallAllPassReturn("Command", command, table.unpack(args));
    traceprint("_api::/Command");
    return retVal;
end

--- Receive
--- @param from integer x
--- @param type string x
--- @tparam ... data
--- @local
function Receive(from, type, ...)
    traceprint("_api::Receive(" .. from .. ", '" .. type .. "')");
    local args = ...;
    debugprint(table.show(args));
    
    local retVal = nil;
    retVal = hook.CallAllPassReturn("Receive", from, type, table.unpack(args));
    traceprint("_api::/Receive");
    return retVal;
end


-- @section Script Run

debugprint("_api Loaded");

if GameVersion ~= nil then
    print("GameVersion " .. GameVersion .. " detected");
else
    print("GameVersion unknown");
end

return _api;