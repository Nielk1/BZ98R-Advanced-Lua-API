--- BZ98R LUA Extended API Hook.
-- 
-- Event hook for event observer pattern.
-- 
-- Dependencies: @{_utility}
-- @module _hook
-- @author John "Nielk1" Klein
-- @usage local hook = require("_hook");
-- 
-- -- optional priority overrides, only applies when adding hooks
-- -- consider removing this now that we have a centralized _config.lua
-- _api_hook_priority_override = {
--     ["Update"] = {
--         ["_statemachine_Update"] = 10000;
--         ["_funcarray_Update"] = 10000;
--     },
--     ["DeleteObject"] = {
--         ["GameObject_DeleteObject"] = -10000;
--     }
-- };
-- 
-- hook.Add("InitialSetup", "Custom_InitialSetup", function(turn)
--     
-- end);
-- 
-- hook.Add("Update", "Custom_Update", function(turn)
--     
-- end);
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

table.unpack = table.unpack or unpack; -- Lua 5.1 compatibility

local debugprint = debugprint or function(...) end;

debugprint("_hook Loading");

local utility = require("_utility");

local hook = {};

hook.Hooks = {};
hook.HookLookup = {};

hook.SaveLoadHooks = {};

--- Table of all hooks.
function hook.GetTable() return hook.Hooks end

hookresult_meta = {};

--hookresult_meta.__index = function(table, key)
--    return nil;
--end
hookresult_meta.__newindex = function(dtable, key, value)
    error("Attempt to update a read-only table.", 2)
end

--- Is this object an instance of HookResult?
-- @param object Object in question
-- @treturn bool
function hook.isresult(object)
    return (type(object) == "table" and object.__type == "HookResult");
end

--- Create an Abort HookResult
-- @param ... Return values passed from hook function
-- @treturn HookResult
function hook.AbortResult(...)
    return setmetatable({
        Abort = true,
        Return = { ... },
        __type = "HookResult"
    }, hookresult_meta);
end

--- Create an basic HookResult
--
-- This wraps a return value similarly to @{_hook.AbortResult|AbortResult} and
-- can be used optionally to wrap return values. This is primarily used internally
-- to wrap the prior return value to be passed as the next Parameter in
-- @{_hook.CallAllPassReturn|CallAllPassReturn} based event triggers as event
-- handler return values are auto-unwrapped by the event handler if wrapping is
-- detected but process fine if unwrapped.
-- @param ... Return values passed from hook function
-- @treturn HookResult
function hook.WrapResult(...)
    local vargs = table.pack( ... );
    local cvar = vargs.n;--select('#', ...);
    if cvar == 0 then
        return nil;
    end
    if cvar == 1 then
        local var1 = vargs[1];
        if hook.isresult(var1) then
            return var1;
        end
    end
    return setmetatable({
        Return = { ... },
        __type = "HookResult"
    }, hookresult_meta);
end

function sort_handlers(item1, item2)
    if item1.priority == item1.priority then
        return item1.identifier < item2.identifier;
    end
    return item1.priority > item1.priority;
end

--- Add a hook to listen to the specified event.
-- @tparam string event Event to be hooked
-- @tparam string identifier Identifier for this hook observer
-- @tparam function func Function to be executed
-- @tparam[opt=0] number priority Higher numbers are higher priority
function hook.Add( event, identifier, func, priority )
    if not utility.isstring(event) then error("Parameter event must be a string."); end
    if not utility.isstring(identifier) then error("Parameter identifier must be a string."); end
    if not utility.isfunction(func) then error("Parameter func must be a function."); end
    if priority == nil or not utility.isnumber(priority) then priority = 0; end

    priority = (_api_hook_priority_override and _api_hook_priority_override[event]) and _api_hook_priority_override[event][identifier] or priority;

    if (hook.Hooks[ event ] == nil) then
        hook.Hooks[ event ] = {};
    end
    if (hook.HookLookup[ event ] == nil) then
        hook.HookLookup[ event ] = {};
    end
    
    if (hook.HookLookup[ event ][ identifier ] ~= nil) then
        local found = hook.HookLookup[ event ][ identifier ];
        hook.HookLookup[ event ][ identifier ] = nil;
		
		-- delete the item from the sorted array
		for i, v in ipairs(hook.Hooks[ event ]) do
			if v.identifier == identifier then
				table.remove(hook.Hooks[ event ], i)
				break;
			end
		end
    end

    local new_handler =  { identifier = identifier, priority = priority, func = func };
    hook.HookLookup[ event ][ identifier ] = new_handler; -- store in lookup strong-table
    table.insert(hook.Hooks[ event ], new_handler); -- store in priority weak-table
    table.sort(hook.Hooks[ event ], sort_handlers);
  
    debugprint("Added " .. event .. " hook for " .. identifier .. " with priority " .. priority );
end

-- Removes the hook with the given identifier.
-- @tparam string event Event to be hooked
-- @tparam string identifier Identifier for this hook observer
function hook.Remove( event, name )
    if not utility.isstring(event) then error("Parameter event must be a string."); end
    if not utility.isstring(identifier) then error("Parameter identifier must be a string."); end

    if (hook.HookLookup[ event ][ identifier ] ~= nil) then
        -- deal with existing hook before replacing it?
        local found = hook.HookLookup[ event ][ identifier ];
        hook.HookLookup[ event ][ identifier ] = nil;
		
		-- delete the item from the sorted array
		for i, v in ipairs(hook.Hooks[ event ]) do
			if v.identifier == identifier then
				table.remove(hook.Hooks[ event ], i)
				break;
			end
		end
    end

    debugprint("Removed " .. event .. " hook for " .. identifier);
end

--- Add a hook to listen to the Save and Load event.
-- @tparam string identifier Identifier for this hook observer
-- @tparam[opt] function save Function to be executed for Save
-- @tparam[opt] function load Function to be executed for Load
function hook.AddSaveLoad( identifier, save, load )
    if not utility.isstring(identifier) then error("Parameter identifier must be a string."); end
    if save == nil and load == nil then error("At least one of Parameters save or load must be supplied."); end
    if save ~= nil and not utility.isfunction(save) then error("Parameter save must be a function."); end
    if load ~= nil and not utility.isfunction(load) then error("Parameter load must be a function."); end
    
    if (hook.SaveLoadHooks[ identifier ] == nil) then
        hook.SaveLoadHooks[identifier ] = {};
    end

    hook.SaveLoadHooks[ identifier ]['Save'] = save;
    hook.SaveLoadHooks[ identifier ]['Load'] = load;
    
    debugprint("Added Save/Load hooks for " .. identifier);
end

--- Removes the Save and Load hooks with the given identifier.
-- @tparam string identifier Identifier for this hook observer
function hook.RemoveSaveLoad( identifier )
    if not utility.isstring(identifier) then error("Parameter identifier must be a string."); end
    if ( not hook.SaveLoadHooks[ identifier ] ) then return; end
    hook.SaveLoadHooks[ identifier ] = nil;
    
    debugprint("Removed Save/Load hooks for " .. identifier);
end

--- Calls hooks associated with Save.
function hook.CallSave()
    if ( hook.SaveLoadHooks ~= nil ) then
        local ret = {};
        for k, v in pairs( hook.SaveLoadHooks ) do 
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
function hook.CallLoad(SaveData)
    if ( hook.SaveLoadHooks ~= nil ) then
        local ret = {};
        for k, v in pairs( hook.SaveLoadHooks ) do
            if v.Load ~= nil and utility.isfunction(v.Load) then
                v.Load(table.unpack(SaveData[k]));
            end
        end
        return ret
    end
    return
end

local range = function(from, to, step)
  step = step or 1
  return function(_, lastvalue)
    local nextvalue = lastvalue + step
    if step > 0 and nextvalue <= to or step < 0 and nextvalue >= to or
       step == 0
    then
      return nextvalue
    end
  end, nil, from - step
end


--- Calls hooks associated with the hook name ignoring any return values.
-- @tparam string event Event to be hooked
-- @param ... Parameters passed to every hooked function
-- @treturn bool Return true if stopped early, else nil
function hook.CallAllNoReturn( event, ... )
    local HookTable = hook.Hooks[ event ]
    if ( HookTable ~= nil ) then
        for i, v in ipairs(HookTable) do
			local lastreturn = { v.func( ... ) };
			-- ignore the result value and just check Abort flag
			if select('#', lastreturn) == 1 and hook.isresult(lastreturn[1]) and lastreturn[1].Abort then
				break;
			end
        end
    end
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
-- Hooked functions may return multiple values. The return value is always passed
-- to the next hook wrapped in an EventResult. If the value is generated by one
-- of the hook library's event functions it will be parsed and passed along without
-- wrapping. This allows for the hook chain to be broken early through the use of
-- the AbortResult function. The best action here is to nil check and test your last
-- Parameter with hook.isresult before processing it.
-- @tparam string event Event to be hooked
-- @param ... Parameters passed to every hooked function
function hook.CallAllPassReturn( event, ... )
    local HookTable = hook.Hooks[ event ]
    local lastreturn = nil;
    if ( HookTable ~= nil ) then
        for i, v in ipairs(HookTable) do
			lastreturn = { v.func(appendvargs(hook.WrapResult(lastreturn), ... )) };
			-- preserve the Abort flag, then unwrap the result
			if select('#', lastreturn) == 1 and hook.isresult(lastreturn[1]) then
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

return hook;