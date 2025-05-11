--- BZ98R LUA Extended API Hook.
---
--- Event hook for event observer pattern.
---
--- @module '_hook'
--- @author John "Nielk1" Klein
--- @usage local hook = require("_hook");
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

--- @diagnostic disable-next-line: undefined-global
table.unpack = table.unpack or unpack; -- Lua 5.1 compatibility

--- @diagnostic disable-next-line: undefined-global
local debugprint = debugprint or function(...) end;

debugprint("_hook Loading");

local utility = require("_utility");

local M = {};

M.Hooks = {};
M.HookLookup = {};

M.SaveLoadHooks = {};

--- @class HookResult
--- @field Abort boolean Flag to abort the hook chain.
--- @field Return any[] Return values passed from hook function.
--- @field __type string Type of the object, used for type checking. "HookResult"

--- Table of all hooks.
function M.GetTable() return M.Hooks end

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
--- @param priority? number Higher numbers are higher priority
--- @function _hook.Add
function M.Add( event, identifier, func, priority )
    if not utility.isstring(event) then error("Parameter event must be a string."); end
    if not utility.isstring(identifier) then error("Parameter identifier must be a string."); end
    if not utility.isfunction(func) then error("Parameter func must be a function."); end
    if priority == nil or not utility.isnumber(priority) then priority = 0; end

    --- @diagnostic disable-next-line: undefined-global
    priority = (_api_hook_priority_override and _api_hook_priority_override[event]) and _api_hook_priority_override[event][identifier] or priority;

    if (M.Hooks[ event ] == nil) then
        M.Hooks[ event ] = {};
    end
    if (M.HookLookup[ event ] == nil) then
        M.HookLookup[ event ] = {};
    end
    
    if (M.HookLookup[ event ][ identifier ] ~= nil) then
        local found = M.HookLookup[ event ][ identifier ];
        M.HookLookup[ event ][ identifier ] = nil;
		
		-- delete the item from the sorted array
		for i, v in ipairs(M.Hooks[ event ]) do
			if v.identifier == identifier then
				table.remove(M.Hooks[ event ], i)
				break;
			end
		end
    end

    local new_handler =  { identifier = identifier, priority = priority, func = func };
    M.HookLookup[ event ][ identifier ] = new_handler; -- store in lookup strong-table
    table.insert(M.Hooks[ event ], new_handler); -- store in priority weak-table
    table.sort(M.Hooks[ event ], sort_handlers);
  
    debugprint("Added " .. event .. " hook for " .. identifier .. " with priority " .. priority );
end

--- Removes the hook with the given identifier.
--- @param event string Event to be hooked
--- @param identifier string Identifier for this hook observer
--- @function _hook.Remove
function M.Remove( event, identifier )
    if not utility.isstring(event) then error("Parameter event must be a string."); end
    if not utility.isstring(identifier) then error("Parameter identifier must be a string."); end

    if (M.HookLookup[ event ][ identifier ] ~= nil) then
        -- deal with existing hook before replacing it?
        local found = M.HookLookup[ event ][ identifier ];
        M.HookLookup[ event ][ identifier ] = nil;
		
		-- delete the item from the sorted array
		for i, v in ipairs(M.Hooks[ event ]) do
			if v.identifier == identifier then
				table.remove(M.Hooks[ event ], i)
				break;
			end
		end
    end

    debugprint("Removed " .. event .. " hook for " .. identifier);
end

--- Add a hook to listen to the Save and Load event.
--- @param identifier string Identifier for this hook observer
--- @param save? function Function to be executed for Save
--- @param load? function Function to be executed for Load
--- @function _hook.AddSaveLoad
function M.AddSaveLoad( identifier, save, load )
    if not utility.isstring(identifier) then error("Parameter identifier must be a string."); end
    if save == nil and load == nil then error("At least one of Parameters save or load must be supplied."); end
    if save ~= nil and not utility.isfunction(save) then error("Parameter save must be a function."); end
    if load ~= nil and not utility.isfunction(load) then error("Parameter load must be a function."); end
    
    if (M.SaveLoadHooks[ identifier ] == nil) then
        M.SaveLoadHooks[identifier ] = {};
    end

    M.SaveLoadHooks[ identifier ]['Save'] = save;
    M.SaveLoadHooks[ identifier ]['Load'] = load;
    
    debugprint("Added Save/Load hooks for " .. identifier);
end

--- Removes the Save and Load hooks with the given identifier.
--- @param identifier string Identifier for this hook observer
--- @function _hook.RemoveSaveLoad
function M.RemoveSaveLoad( identifier )
    if not utility.isstring(identifier) then error("Parameter identifier must be a string."); end
    if ( not M.SaveLoadHooks[ identifier ] ) then return; end
    M.SaveLoadHooks[ identifier ] = nil;
    
    debugprint("Removed Save/Load hooks for " .. identifier);
end

--- Calls hooks associated with Save.
--- @function _hook.CallSave
function M.CallSave()
    if ( M.SaveLoadHooks ~= nil ) then
        local ret = {};
        for k, v in pairs( M.SaveLoadHooks ) do 
            if v.Save ~= nil and utility.isfunction(v.Save) then
                ret[k] = {v.Save()};
            else
                ret[k] = {};
            end
        end
        return ret
    end
    return
end

--- Calls hooks associated with Load.
--- @function _hook.CallLoad
function M.CallLoad(SaveData)
    if ( M.SaveLoadHooks ~= nil ) then
        local ret = {};
        for k, v in pairs( M.SaveLoadHooks ) do
            if v.Load ~= nil and utility.isfunction(v.Load) then
                v.Load(table.unpack(SaveData[k]));
            end
        end
        return ret
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
    local HookTable = M.Hooks[ event ]
    if ( HookTable ~= nil ) then
        for i, v in ipairs(HookTable) do
			local lastreturn = { v.func( ... ) };
			-- ignore the result value and just check Abort flag
			if select('#', lastreturn) == 1 and M.isresult(lastreturn[1]) and lastreturn[1].Abort then
				return true;
			end
        end
    end
    return nil;
end

-- @todo this might be able to be replaced using table.pack to get accurate length, but that might waste speed/memory
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
    local HookTable = M.Hooks[ event ]
    local lastreturn = nil;
    if ( HookTable ~= nil ) then
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
    end
    if lastreturn ~= nil then
        return table.unpack(lastreturn);
    end
    return lastreturn;
end

debugprint("_hook Loaded");

return M;