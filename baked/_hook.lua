--- BZ98R LUA Extended API Hook.
---
--- Event hook for event observer pattern.
---
--- @module '_hook'
--- @author John "Nielk1" Klein
--- ```lua
--- local hook = require("_hook");
--- 
--- -- optional priority overrides, only applies when adding hooks
--- -- consider removing this now that we have a centralized _config.lua
--- _api_hook_priority_override = {
---     ["Update"] = {
---         ["_statemachine_Update"] = 10000;
---         ["_funcarray_Update"] = 10000;
---     },
---     ["DeleteObject"] = {
---         ["GameObject_DeleteObject"] = -10000;
---     }
--- };
--- 
--- hook.Add("InitialSetup", "Custom_InitialSetup", function(turn)
---     
--- end);
--- 
--- hook.Add("Update", "Custom_Update", function(turn)
---     
--- end);
--
-- hook.AddSaveLoad("Custom_SaveLoad",
-- function()
--     return MissionData;
-- end,
-- function(savedData)
--     MissionData = savedData;
-- end);
-- 
-- -- 10% of the time players will just respawn instead of eject, this overrides all other event hooks
-- hook.Add("PlayerEjected", function(DeadObject)
--     if object:IsPlayer() and GetRandomFloat(10) > 9 then
--         return hook.AbortResult(EjectKillRetCodes.DoRespawnSafest);
--     end
-- end, 9999)
--- ```

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_hook Loading");

local utility = require("_utility");

--- @class _hook
local M = {};

--- @alias event_name string

--- @alias event_hook_identifier string

--- @class HookHandler
--- @field identifier event_hook_identifier Identifier for this hook observer.
--- @field priority number Higher numbers are higher priority.
--- @field func function Function to be executed when the event is triggered.

--- @type table<event_name, HookHandler[]>
local Hooks = {};

--- @type table<event_name, table<event_hook_identifier, HookHandler>>
local HookLookup = {};

--- @type table<event_hook_identifier, {Save: function, Load: function, PostLoad: function}>
local SaveLoadHooks = {};

--- Stack of hooks as they are called
--- @todo This can also be used to prevent recursive events if needed!
--- @type table<event_name, integer?>
local HookCallCounts = {};

--- Events to remove after the HookStack is empty.
--- @type {event: event_name, identifier: event_hook_identifier}[]
local RemoveAfterStack = {};

local function HookCallCountIncrement(event)
    local v = HookCallCounts[event] or 0;
    HookCallCounts[event] = v;
end

local function HookCallCountDecrement(event)
    local v = HookCallCounts[event];
    if v then
        if v > 1 then
            HookCallCounts[event] = v - 1;
        else
            HookCallCounts[event] = nil;
        end
    end
end

local function InternalRemove( event, identifier )
    -- deal with existing hook before replacing it?
    local found = HookLookup[ event ][ identifier ];
    HookLookup[ event ][ identifier ] = nil;

    -- delete the item from the sorted array
    --for i, v in ipairs(Hooks[ event ]) do
    --	if v.identifier == identifier then
    --		table.remove(Hooks[ event ], i)
    --		break;
    --	end
    --end

    -- Delete the item from the sorted array
    for i = #Hooks[event], 1, -1 do -- Iterate backward
        if Hooks[event][i].identifier == identifier then
            table.remove(Hooks[event], i)
            break
        end
    end
end

local function ProcPendingRemovals()
    if #RemoveAfterStack > 0 then
        for i = #RemoveAfterStack, 1, -1 do -- Iterate backward
            local item = RemoveAfterStack[i];
            if not HookCallCounts[item.event] then
                InternalRemove(item.event, item.identifier);
                table.remove(RemoveAfterStack, i);
            end
        end
    end
end

--- @class HookResult
--- @field Abort boolean Flag to abort the hook chain.
--- @field Return any[] Return values passed from hook function.
--- @field __type string Type of the object, used for type checking. "HookResult"

--- Table of all hooks.
function M.GetTable() return Hooks end

M_MT = {};

--hookresult_meta.__index = function(table, key)
--    return nil;
--end
M_MT.__newindex = function(dtable, key, value)
    error("Attempt to update a read-only table.", 2)
end

--- Is this object an instance of HookResult?
--- @param object any Object in question
--- @return boolean
function M.isresult(object)
    return (type(object) == "table" and object.__type == "HookResult");
end

--- Create an Abort HookResult
--- @vararg any Return values passed from hook function
--- @return HookResult
--- @function _hook.AbortResult
function M.AbortResult(...)
    return setmetatable({
        Abort = true,
        Return = { ... },
        __type = "HookResult"
    }, M_MT);
end

--- Create an basic HookResult
---
--- This wraps a return value similarly to `_hook.AbortResult` and
--- can be used optionally to wrap return values. This is primarily used internally
--- to wrap the prior return value to be passed as the next Parameter in
--- `_hook.CallAllPassReturn` based event triggers as event
--- handler return values are auto-unwrapped by the event handler if wrapping is
--- detected but process fine if unwrapped.
--- @see _hook.AbortResult
--- @see _hook.CallAllPassReturn
--- @vararg any Return values passed from hook function
--- @return HookResult?
--- @function _hook.WrapResult
function M.WrapResult(...)
    --- @diagnostic disable-next-line: deprecated
    local vargs = table.pack( ... );
    local cvar = vargs.n;--select('#', ...);
    if cvar == 0 then
        return nil;
    end
    if cvar == 1 then
        local var1 = vargs[1];
        if M.isresult(var1) then
            return var1;
        end
    end
    return setmetatable({
        Return = { ... },
        __type = "HookResult"
    }, M_MT);
end

local function sort_handlers(item1, item2)
    if item1.priority == item1.priority then
        return item1.identifier < item2.identifier;
    end
    return item1.priority > item1.priority;
end

--- Add a hook to listen to the specified event.
--- @param event string Event to be hooked
--- @param identifier string Identifier for this hook observer
--- @param func function Function to be executed
--- @param priority number? Higher numbers are higher priority
--- @function _hook.Add
function M.Add( event, identifier, func, priority )
    if not utility.isstring(event) then error("Parameter event must be a string."); end
    if not utility.isstring(identifier) then error("Parameter identifier must be a string."); end
    if not utility.isfunction(func) then error("Parameter func must be a function."); end
    if priority == nil or not utility.isnumber(priority) then priority = 0; end

    --- @diagnostic disable-next-line: undefined-global
    priority = (_api_hook_priority_override and _api_hook_priority_override[event]) and _api_hook_priority_override[event][identifier] or priority;

    if Hooks[ event ] == nil then
        Hooks[ event ] = {};
    end
    if HookLookup[ event ] == nil then
        HookLookup[ event ] = {};
    end
    
    if HookLookup[ event ][ identifier ] ~= nil then
        local found = HookLookup[ event ][ identifier ];
        HookLookup[ event ][ identifier ] = nil;
		
		-- delete the item from the sorted array
		for i, v in ipairs(Hooks[ event ]) do
			if v.identifier == identifier then
				table.remove(Hooks[ event ], i)
				break;
			end
		end
    end

    local new_handler =  { identifier = identifier, priority = priority, func = func };
    HookLookup[ event ][ identifier ] = new_handler; -- store in lookup strong-table
    table.insert(Hooks[ event ], new_handler); -- store in priority weak-table
    table.sort(Hooks[ event ], sort_handlers);
  
    logger.print(logger.LogLevel.DEBUG, nil, "Added " .. event .. " hook for " .. identifier .. " with priority " .. priority );
end

--- Removes the hook with the given identifier.
--- @param event string Event to be hooked
--- @param identifier string Identifier for this hook observer
--- @function _hook.Remove
function M.Remove( event, identifier )
    if not utility.isstring(event) then error("Parameter event must be a string."); end
    if not utility.isstring(identifier) then error("Parameter identifier must be a string."); end

    if HookLookup[ event ][ identifier ] ~= nil then
        if HookCallCounts[event] then
            -- this event is currently being processed so buffer the removal
            table.insert(RemoveAfterStack, { event = event, identifier = identifier });
        else
            InternalRemove(event, identifier);
        end
    end

    logger.print(logger.LogLevel.DEBUG, nil, "Removed " .. event .. " hook for " .. identifier);
end

--- Add a hook to listen to the Save and Load event.
--- @param identifier string Identifier for this hook observer
--- @param save function? Function to be executed for Save
--- @param load function? Function to be executed for Load
--- @param postload function? Function to be executed after all Load hooks are called
--- @function _hook.AddSaveLoad
function M.AddSaveLoad( identifier, save, load, postload )
    if not utility.isstring(identifier) then error("Parameter identifier must be a string."); end
    if save == nil and load == nil then error("At least one of Parameters save or load must be supplied."); end
    if save ~= nil and not utility.isfunction(save) then error("Parameter save must be a function."); end
    if load ~= nil and not utility.isfunction(load) then error("Parameter load must be a function."); end
    if postload ~= nil and not utility.isfunction(postload) then error("Parameter postload must be a function."); end

    if SaveLoadHooks[ identifier ] == nil then
        SaveLoadHooks[identifier ] = {};
    end

    SaveLoadHooks[ identifier ]['Save'] = save;
    SaveLoadHooks[ identifier ]['Load'] = load;
    SaveLoadHooks[ identifier ]['PostLoad'] = postload;
    
    logger.print(logger.LogLevel.DEBUG, nil, "Added Save/Load hooks for " .. identifier);
end

--- Removes the Save and Load hooks with the given identifier.
--- @param identifier string Identifier for this hook observer
--- @function _hook.RemoveSaveLoad
function M.RemoveSaveLoad( identifier )
    if not utility.isstring(identifier) then error("Parameter identifier must be a string."); end
    if not SaveLoadHooks[ identifier ] then return; end

    -- This should be safe since they are stored by identifier, no arrays being looped
    -- Ff it does become an issue having the execution loop use a copy of the key list would solve it
    SaveLoadHooks[ identifier ] = nil;
    
    logger.print(logger.LogLevel.DEBUG, nil, "Removed Save/Load hooks for " .. identifier);
end

--- Calls hooks associated with Save.
--- @function _hook.CallSave
function M.CallSave()
    if SaveLoadHooks ~= nil then
        HookCallCounts["Save"] = (HookCallCounts["Save"] or 0) + 1;
        local ret = {};
        for k, v in pairs( SaveLoadHooks ) do 
            if v.Save ~= nil and utility.isfunction(v.Save) then
                ret[k] = {v.Save()};
            end
        end
        HookCallCounts["Save"] = (HookCallCounts["Save"] or 1) - 1;
        HookCallCounts["Save"] = HookCallCounts["Save"] > 0 and HookCallCounts["Save"] or nil;
        ProcPendingRemovals();
        return ret
    end
    return
end

--- Calls hooks associated with Load.
--- @function _hook.CallLoad
function M.CallLoad(SaveData)
    if SaveLoadHooks ~= nil then
        HookCallCounts["Load"] = (HookCallCounts["Load"] or 0) + 1;
        for k, v in pairs( SaveLoadHooks ) do
            if v.Load ~= nil and utility.isfunction(v.Load) then
                if SaveData[k] ~= nil then
                    local ArraySize = 0;
                    for k2, _ in pairs(SaveData[k]) do
                        if utility.isinteger(k2) and k2 > ArraySize then
                            ArraySize = k2;
                        end
                    end
                    v.Load(table.unpack(SaveData[k], 1, ArraySize));
                else
                    v.Load();
                end
            end
        end
        HookCallCounts["Load"] = (HookCallCounts["Load"] or 1) - 1;
        HookCallCounts["Load"] = HookCallCounts["Load"] > 0 and HookCallCounts["Load"] or nil;

        -- PostLoad
        HookCallCounts["PostLoad"] = (HookCallCounts["PostLoad"] or 0) + 1;
        for k, v in pairs( SaveLoadHooks ) do
            if v.PostLoad ~= nil and utility.isfunction(v.PostLoad) then
                v.PostLoad();
            end
        end
        HookCallCounts["PostLoad"] = (HookCallCounts["PostLoad"] or 1) - 1;
        HookCallCounts["PostLoad"] = HookCallCounts["PostLoad"] > 0 and HookCallCounts["PostLoad"] or nil;
        
        ProcPendingRemovals();
    end
    return
end

--- Calls hooks associated with the hook name ignoring any return values.
--- @todo Consider redoing the return value as nothing uses it right now.
--- @param event string Event to be hooked
--- @vararg any Parameters passed to every hooked function
--- @return boolean? Return true if stopped early, else nil
--- @function _hook.CallAllNoReturn
function M.CallAllNoReturn( event, ... )
    local HookTable = Hooks[ event ]
    if ( HookTable ~= nil ) then
        HookCallCountIncrement(event);
        for i, v in ipairs(HookTable) do
			local lastreturn = { v.func( ... ) };
			-- ignore the result value and just check Abort flag
			if select('#', lastreturn) == 1 and M.isresult(lastreturn[1]) and lastreturn[1].Abort then
				return true;
			end
        end
        HookCallCountDecrement(event);
        ProcPendingRemovals();
    end
    return nil;
end

--- @todo this might be able to be replaced using table.pack to get accurate length, but that might waste speed/memory
local function appendhelper(a, n, b, ...)
  if   n == 0 then return a
  else             return b, appendhelper(a, n-1, ...) end
end
local function appendvargs(a, ...)
  return appendhelper(a, select('#', ...), ...)
end

--- Calls hooks associated with the hook name passing each return to the next.
--- Hooked functions may return multiple values. The return value is always passed
--- to the next hook wrapped in an EventResult. If the value is generated by one
--- of the hook library's event functions it will be parsed and passed along without
--- wrapping. This allows for the hook chain to be broken early through the use of
--- the AbortResult function. The best action here is to nil check and test your last
--- Parameter with hook.isresult before processing it.
--- @param event string Event to be hooked
--- @vararg any Parameters passed to every hooked function
--- @return nil|HookResult|any ... `nil` if no hooks are called, a `HookResult` if the chain is aborted, or the return values from the last hook function.
--- @function _hook.CallAllPassReturn
function M.CallAllPassReturn( event, ... )
    local HookTable = Hooks[ event ]
    local lastreturn = nil;
    if ( HookTable ~= nil ) then
        HookCallCountIncrement(event);
        for i, v in ipairs(HookTable) do
			lastreturn = { v.func(appendvargs(M.WrapResult(lastreturn), ... )) };
			-- preserve the Abort flag, then unwrap the result
			if select('#', lastreturn) == 1 and M.isresult(lastreturn[1]) then
				local abort = lastreturn[1].Abort;
				lastreturn = lastreturn[1].Return;
				if abort then
					break;
				end
			end
        end
        HookCallCountDecrement(event);
        ProcPendingRemovals();
    end
    if lastreturn ~= nil then
        local ArraySize = 0;
        for k, _ in pairs(lastreturn) do
            if utility.isinteger(k) and k > ArraySize then
                ArraySize = k;
            end
        end
        return table.unpack(lastreturn, 1, ArraySize);
    end
    return lastreturn;
end

logger.print(logger.LogLevel.DEBUG, nil, "_hook Loaded");

return M;