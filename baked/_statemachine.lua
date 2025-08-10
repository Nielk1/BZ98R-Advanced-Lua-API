--- BZ98R LUA Extended API StateMachineIter.
---
--- State Machine and State Machine Iterator for serial event sequences across game turns.
---
--- @module '_statemachine'
--- @author John "Nielk1" Klein
--- ```lua
--- local statemachine = require("_statemachine");
--- 
--- statemachine.Create("TestMachine",
--- {
---     ["state_a"] = function(state)
---         print("test " .. state.test1);
---         state:switch("state_b");
---     end,
---     ["state_b"] = statemachine.SleepSeconds(10,"state_c"),
---     ["state_c"] = function(state)
---         print("test " .. state.test2);
---         state:switch("state_d");
---     end,
---     ["state_d"] = statemachine.SleepSeconds(15,"state_e"),
---     ["state_e"] = function(state)
---         print("test " .. state.test3);
---         state:switch("state_f");
---     end
--- });
--- 
--- -- ordered state machine that supports state:next()
--- statemachine.Create("OrderedTestMachine",
--- {
---     -- named state function
---     { "state_a", function(state)
---         print("test " .. state.test1);
---         state:switch("state_b");
---     end },
---
---     -- named magic state function (SleepSeconds)
---     -- note nil next_state means next state by index
---     { "state_b", statemachine.SleepSeconds(10) },
---
---     -- named state function with automatic name
---     { nil, function(state)
---         print("test " .. state.test2);
---         state:switch("state_d");
---     end },
---
---     -- named state function with automatic name
---     { function(state)
---         print("test " .. state.test2);
---         state:switch("state_d");
---     end },
---
---     -- magic state function (SleepSeconds)
---     statemachine.SleepSeconds(15,"nonexistent_state"),
---
---     -- stsate function with automatic name
---     function(state)
---         print("test " .. state.test3);
---         state:next();
---     end
--- });
---
--- hook.Add("InitialSetup", "Custom_InitialSetup", function(turn)
---     MissionData.TestSMI1 = statemachine.Start("TestMachine","state_a",{test1='d',test2="e",test3="f"});
---     MissionData.TestSMI2 = statemachine.Start("OrderedTestMachine","state_a",{test1='d',test2="e",test3="f"});
--- end);
--- 
--- hook.Add("Update", "Custom_Update", function(turn)
---     MissionData.TestSMI1:run();
---     MissionData.TestSMI2:run();
--- end);
--- ```


local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_statemachine Loading");

--require("_table_show");

local utility = require("_utility");
local config = require("_config");
local _api = require("_api");
local hook = require("_hook");
local customsavetype = require("_customsavetype");

local ReadOnly_MT = {};
ReadOnly_MT.__newindex = function(dtable, key, value)
    error("Attempt to update a read-only table.", 2)
end

--- @class StateMachineIterWrappedResult
--- @field Abort boolean If true the machine should be considered aborted, allowing for cleanup
--- @field Fast boolean If true the machine will attempt to run the next state immediately

--- @class _statemachine
--- @field game_time number Game time in seconds, used for state machine timing
--- @field Machines table<string, StateMachineIter> Table of StateMachineIter instances, key is the template name and value is the StateMachineIter instance
--- @field MachineFlags table<string, { is_ordered:boolean, index_to_name:table, name_to_index:table }> Table of flags for each StateMachineIter template, key is the template name and value is the flags table
local M = {};
M.game_time = 0;

M.Machines = {};
M.MachineFlags = {};

--- Create an Abort HookResult
--- @vararg any Return values passed from hook function
--- @return StateMachineIterWrappedResult
function M.AbortResult(...)
    return setmetatable({
        Abort = true,
        Return = { ... },
        __type = "StateMachineIterWrappedResult" -- this could go in the metatable with some design control changes, but let's not
    }, ReadOnly_MT);
end

function M.FastResult(...)
    return setmetatable({
        Fast = true,
        Return = { ... },
        __type = "StateMachineIterWrappedResult" -- this could go in the metatable with some design control changes, but let's not
    }, ReadOnly_MT);
end

function M.isstatemachineiterwrappedresult(object)
    return (type(object) == "table" and object.__type == "StateMachineIterWrappedResult");
end

--- Is this object an instance of StateMachineIter?
--- @param object any Object in question
--- @return boolean
function M.isstatemachineiter(object)
    --return (type(object) == "table" and object.__type == "StateMachineIter");
    return customsavetype.Implements(object, "StateMachineIter");
end

--- An object containing all functions and data related to an StateMachineIter.
--- @class StateMachineIter : CustomSavableType
--- @field state_key string|integer|nil Current state, string name or integer index if state machine is ordered
--- @field template string StateMachineIter template name
--- @field index_to_name table StateMachineIter index to name mapping, only if the StateMachineIter is ordered
--- @field target_call integer? Timer's value, nil for not set
--- @field target_time number? Target time if sleeping, nil if not set
--- @field set_wait_time number? Time to wait before running next state, kept to allow altering target_time if set_wait_time changes
--- @field addonData table? Table of values embeded in the StateMachineIter
local StateMachineIter = {}; -- the table representing the class, which will double as the metatable for the instances

--- @alias StateMachineFunction fun(self:StateMachineIter, ...:any):any

--- @class WrappedObjectForStateMachineIter
--- @field f function State function to call
--- @field p table Parameters to pass to the state function

--- A simple name-only set of states
--- @class StateMachineStateUnorderedSet
--- @field [string] StateMachineFunction|WrappedObjectForStateMachineIter State function

--- A simple ordered set of states
--- @class StateMachineStateOrderedSet
--- @field [integer] StateMachineFunction|WrappedObjectForStateMachineIter|StateMachineNamedState|StateMachineNamedStateTruncated State function

--- Simple construct for a state function with a name
--- @class StateMachineNamedState
--- @field [1] string|nil name
--- @field [2] StateMachineFunction|WrappedObjectForStateMachineIter State function

--- A truncated version without the name, name is constructed at runtime from index
--- @class StateMachineNamedStateTruncated
--- @field [1] StateMachineFunction|WrappedObjectForStateMachineIter State function


--GameObject.__index = GameObject; -- failed table lookups on the instances should fallback to the class table, to get methods
StateMachineIter.__index = function(table, key)
  local retVal = rawget(table, key);
  if retVal ~= nil then return retVal; end
  if rawget(table, "addonData") ~= nil and rawget(rawget(table, "addonData"), key) ~= nil then return rawget(rawget(table, "addonData"), key); end
  return rawget(StateMachineIter, key); -- if you fail to get it from the subdata, move on to base (looking for functions)
end
StateMachineIter.__newindex = function(table, key, value)
  if key ~= "template" and key ~= "state_key" and key ~= "target_call" and key ~= "target_time" and key ~= "set_wait_time" and key ~= "addonData" then
    local addonData = rawget(table, "addonData");
    if addonData == nil then
      rawset(table, "addonData", {});
      addonData = rawget(table, "addonData");
    end
    rawset(addonData, key, value);
  else
    rawset(table, key, value);
  end
end
StateMachineIter.__type = "StateMachineIter";

--- Create StateMachineIter
--- @param name string StateMachineIter template
--- @param target_call integer? Timer's value, nil for not set
--- @param target_time number? TargetTurn's value, nil for not set
--- @param set_wait_time number? Time to wait before running next state, kept to allow altering target_time if set_wait_time changes
--- @param state_key string|integer|nil Current state, string name or integer index if state machine is ordered
--- @param values table? Table of values embeded in the StateMachineIter
local function CreateStateMachineIter(name, target_call, target_time, set_wait_time, state_key, values)
    local self = setmetatable({}, StateMachineIter);
    self.template = name;
    self.target_call = target_call;
    self.target_time = target_time;
    self.set_wait_time = set_wait_time;
    self.state_key = state_key;
    logger.print(logger.LogLevel.DEBUG, nil, "StateMachineIter '"..name.."' created with state '"..tostring(state_key).."'");
    
    if values and utility.istable(values) then
        for k, v in pairs( values ) do
            logger.print(logger.LogLevel.DEBUG, nil, "StateMachineIter: Adding value '"..tostring(k).."' = '"..tostring(v).."' to StateMachineIter '"..name.."'");
            self[k] = v;
        end
    end
    
    return self;
end

--- Run StateMachineIter.
--- @param self StateMachineIter FuncArrayIter instance
--- @vararg any Arguments to pass to the state function
--- @return boolean|StateMachineIterWrappedResult status True if the state function was called, false if the state function was not found, a wrapper instance if the state function was called and returned a wrapper
--- @return any ... The return value of the state function, if it was called. If the result was wrapped it's unwraped and returned here
function StateMachineIter.run(self, ...)
    if not M.isstatemachineiter(self) then error("Parameter self must be StateMachineIter instance."); end

    --logger.print(logger.LogLevel.DEBUG, nil, "Running StateMachineIter Template '"..self.template.."' with state '"..self.state_key.."'");
    local machine = M.Machines[self.template];
    if machine == nil then return false; end

    local statesCalled = nil;



    local runNext = true;
    while self.state_key and runNext do
        runNext = false;
        local currentState = self.state_key;
        if not currentState then break; end -- safety check
        local retValBuffer1, retValBuffer2 = false, {};
        if utility.isfunction(machine[currentState]) then
            local retVal = {machine[currentState](self, ...)};
            if #retVal > 0 and M.isstatemachineiterwrappedresult(retVal[1]) then
                -- unbox the return value and remove it from the wrapper, send the wrapper along
                if retVal[1].Abort then
                    -- ensure the state won't do anything, though we help the caller reacts to the abort and kills the StateMachineIter instead.
                    self.state_key = nil;
                end
                if retVal[1].Fast then
                    runNext = true;
                    
                    -- buffer the return value in case something fucky makes us abort anyway despite fast recall
                    local actual_return = retVal[1].Return;
                    retVal[1].Return = nil;
                    retValBuffer1, retValBuffer2 =  retVal[1], actual_return;
                else
                    local actual_return = retVal[1].Return;
                    retVal[1].Return = nil; -- carve the return value out of the wrapper
                    return retVal[1], table.unpack(actual_return);
                end
            end

            return true, table.unpack(retVal);
        elseif utility.istable(machine[currentState]) then
            if utility.isfunction(machine[currentState].f) then
                --logger.print(logger.LogLevel.DEBUG, nil, "StateMachineIter state '"..currentState.."' is "..type(machine[currentState].f).." '"..table.show(machine[currentState].p).."'");
                return true, machine[currentState].f(self, machine[currentState].p, ...);
            end
        end

        if runNext then
            -- we are in a tight state run, which means the next state will run immediately and we will eat the prior state's return value
            if currentState == self.state_key then
                -- we never targeted a diff state, so a fast loop is unacceptable
                return retValBuffer1, table.unpack(retValBuffer2);
            end
            statesCalled = statesCalled or {};
            if statesCalled[self.state_key] then
                -- we already ran the next state, so we might be in an infinate loop
                return retValBuffer1, table.unpack(retValBuffer2);
            end
            statesCalled[currentState] = true; -- remember we ran the current state before
        end
    end
    return false;
end

--- Get next state for StateMachineIter.
--- @param state StateMachineIter FuncArrayIter instance
--- @local
local function nextState(state)
    local flags = M.MachineFlags[ state.template ];
    if flags == nil or not flags.is_ordered then error("StateMachine is not ordered."); end

    local index = state.state_key;
    if flags.index_to_name ~= nil then
        -- we are an ordered state machine AND don't use numeric keys
        index = flags.name_to_index[ state.state_key ];
    end
    if index == nil then
        return nil;
    end

    index = index + 1;
    if flags.index_to_name == nil then
        -- we use numeric keys, so we can just return the index
        return index;
    end

    if index > #flags.index_to_name then
        return nil;
    end
    return flags.index_to_name[ index ];
end

--- Next StateMachineIter State.
--- This only works if the StateMachineIter is ordered.
--- @param self StateMachineIter StateMachineIter instance
function StateMachineIter.next(self)
    --local flags = _statemachine.MachineFlags[ self.template ];
    --if flags == nil or not flags.is_ordered then error("StateMachine is not ordered."); end
    --local index = flags.name_to_index[ self.state_key ];
    --if index == nil then
    --    self.state_key = nil;
    --    return;
    --end
    --index = index + 1;
    --if index > #flags.index_to_name then
    --    self.state_key = nil;
    --    return;
    --end
    --self.state_key = flags.index_to_name[ index ];

    local old_key = self.state_key
    self.state_key = nextState(self);

    logger.print(logger.LogLevel.DEBUG, nil, "StateMachineIter '"..self.template.."' next state '"..tostring(old_key).."' to '"..tostring(self.state_key).."'");
end

--- Switch StateMachineIter State.
--- @param self StateMachineIter StateMachineIter instance
--- @param key string|integer|nil State to switch to (will also accept state index if the StateMachineIter is ordered)
function StateMachineIter.switch(self, key)
    if utility.isinteger(key) then
        local flags = M.MachineFlags[ self.template ];
        if flags ~= nil and flags.is_ordered and flags.index_to_name ~= nil then
            -- we are an ordered state machine AND don't use numeric indexes
            key = self.index_to_name[key];
        end
    end
    local old_key = self.state_key
    self.state_key = key;

    logger.print(logger.LogLevel.DEBUG, nil, "StateMachineIter '"..self.template.."' switch state '"..tostring(old_key).."' to '"..tostring(self.state_key).."'");
end

--- Creates an StateMachineIter Template with the given indentifier.
--- @param name string Name of the StateMachineIter Template (string)
--- @vararg StateMachineNamedState|StateMachineNamedStateTruncated|StateMachineStateOrderedSet|WrappedObjectForStateMachineIter|StateMachineFunction State descriptor and/or state descriptor collections, can be a table of named state functions or an array of state descriptors.
--- State descriptors are tables with the first element being the state name and the second element being the state function.
--- If the second element is nil, the first element is considered the state function and the state name is generated automatically.
--- If the state descriptor is instead a function it is treated as a nil state and the state name is generated automatically.
--- The first paramater of the state function is the StateMachineIter itself where the current state may be accessed via `self.state_key`.
function M.Create( name, ... )
    if not utility.isstring(name) then error("Parameter name must be a string."); end
    
    logger.print(logger.LogLevel.DEBUG, nil, "Creating StateMachineIter Template '"..name.."'");

    --if (_statemachine.Machines[ name ] == nil) then
    --    _statemachine.Machines[ name ] = {};
    --end

    --logger.print(logger.LogLevel.DEBUG, nil, table.show({...}, "StateMachineIter states: "));

    local is_ordered = true;
    local has_any_named = false;
    local super_states = {};
    for _, v in ipairs({...}) do
        if utility.isfunction(v) then
            -- we are a bare function, so we are ordered but have no name
            -- func
            --- @cast v function
            table.insert(super_states, {v}); -- wrap the state into an array of 1
        elseif utility.istable(v) then
            -- we have a table, it could be an array, a map, or a special state function like sleep
            -- { ... }
            --- @cast v table
            if utility.isfunction(v.f) and utility.istable(v.p) then
                -- this is a special state function like sleep, so we are ordered but have no name
                -- { f = func, p = { ... } } -- special state function
                --- @cast v WrappedObjectForStateMachineIter
                table.insert(super_states, {v}); -- wrap the state into an array of 1
            elseif v[1] ~= nil then
                -- this is probably an array so there's a few options
                -- { ... }

                if #v == 1 then
                    -- only one item
                    if utility.isfunction(v[1]) then
                        -- function wrapped in a state descriptor that lacks a name
                        -- { func }
                        --- @cast v StateMachineNamedStateTruncated
                        table.insert(super_states, {v}); -- wrap the state into an array of 1
                    elseif utility.isfunction(v[1].f) and utility.istable(v[1].p) then
                        -- special state function wrapped in a state descriptor that lacks a name
                        -- { { f = func, p = { ... } } } -- special state function
                        --- @cast v StateMachineNamedStateTruncated
                        table.insert(super_states, {v}); -- wrap the state into an array of 1
                    else
                        error("StateMachineIter state descriptor must be a function, a special state function, or collection there of.");
                    end
                elseif #v == 2 then
                    -- two items
                    -- { ?, ? }
                    --- @cast v table
                    if v[1] == nil then
                        -- actually the name is nil, so nevermind
                        -- { nil, ? }
                        --- @cast v StateMachineNamedState
                        table.insert(super_states, {v}); -- wrap the state into an array of 1
                    elseif utility.isstring(v[1]) then
                        -- the first item is a string so we are a named state descriptor
                        -- { "name", ? }
                        has_any_named = true;
                        --- @cast v StateMachineNamedState
                        table.insert(super_states, {v}); -- wrap the state into an array of 1
                    else
                        -- an array of items that happens to be length 2 and didn't fit another known structure
                        -- { ?, ? }
                        --- @cast v table
                        table.insert(super_states, v); -- no need to wrap

                        -- double check if we have any named state descriptors in this array of state descriptors
                        if not has_any_named then
                            for _, v2 in ipairs(v) do
                                if utility.istable(v2) and utility.isstring(v2[1]) then
                                    has_any_named = true;
                                    break;
                                end
                            end
                        end
                    end
                else
                    -- we are an array of state descriptors
                    -- { ?, ?, ... }
                    --- @cast v table
                    table.insert(super_states, v);

                    -- double check if we have any named state descriptors in this array of state descriptors
                    if not has_any_named then
                        for _, v2 in ipairs(v) do
                            if utility.istable(v2) and utility.isstring(v2[1]) then
                                has_any_named = true;
                                break;
                            end
                        end 
                    end
                end
            else
                -- at this point we have to be a table that is not an array and not a special state function
                -- { ... }
                if next(v) == nil then
                    -- empty table so let's just stuff it to be safe
                    -- { }
                    table.insert(super_states, {v}); -- wrap the state into an array of 1
                else
                    is_ordered = false; -- we aren't ordered, we know this since we're not a single item or an array, we're a map
                    has_any_named = true; -- assume we have named state descriptors since we are a map
                    table.insert(super_states, v);
                end
            end
        else
            error("StateMachineIter state paramaters must be a collection of state descriptors or state descriptor.");
        end
    end

    local new_states = {};
    local state_order = nil;
    local state_indexes = nil;

    if is_ordered and has_any_named then
        -- we need mappings since there are names
        state_order = {};
        state_indexes = {};
        --- @cast state_order table
        --- @cast state_indexes table
    end

    local accumulator = 1;
    for iCol, states in ipairs(super_states) do
        if states[1] ~= nil then
            -- the first item in the state exists, so we're an array
            for i, v in ipairs(states) do
                local state_name = nil;
                local state_func = nil;

                if utility.istable(v) then
                    state_name = v[1]; -- first item
                    state_func = v[2]; -- second item

                    -- if state_func isn't set and the state_name isn't a string, move it over to state_func
                    if state_func == nil and state_name ~= nil and not utility.isstring(state_name) then
                        state_func = state_name
                        state_name = nil;
                    end

                    if state_func == nil and state_name == nil then
                        -- we might have a rich state descriptor here
                        if utility.isfunction(v.f) and utility.istable(v.p) then
                            state_func = v
                            state_name = nil; -- no name since we got
                        else
                            error("StateMachineIter state must be n array of state descriptors");
                        end
                    end
                elseif utility.isfunction(v) then
                    state_name = nil; -- no name since we got a bare function
                    state_func = v;
                end

                if state_name == nil then
                    state_name = "state_" .. iCol .. "_" .. i;
                end

                if state_func == nil then
                    error("StateMachineIter state must be n array of state descriptors");
                end

                logger.print(logger.LogLevel.DEBUG, nil, "StateMachineIter state '"..state_name.."' is "..type(state_func).." '"..tostring(state_func).."'");

                if has_any_named then
                    -- we have named states in addition to be ordered, so we'll use the lookup table
                    new_states[state_name] = state_func;
                    state_indexes[state_name] = accumulator;
                    table.insert(state_order, state_name);
                    accumulator = accumulator + 1;
                else
                    -- we don't have named states, so we'll just be an array
                    table.insert(new_states, state_func);
                end
            end
        else
            -- we're in a table so just stuff them into the state collection
            for state_name, state_func in pairs(states) do
                if not utility.isstring(state_name) then
                    error("StateMachineIter state must be a map of state descriptors");
                end

                logger.print(logger.LogLevel.DEBUG, nil, "StateMachineIter state '"..state_name.."' is "..type(state_func).." '"..tostring(state_func).."'");

                new_states[state_name] = state_func;
                state_indexes[state_name] = accumulator;
                table.insert(state_order, state_name);
                accumulator = accumulator + 1;
            end
        end
    end
    M.Machines[ name ] = new_states;
    M.MachineFlags[ name ] = {
        is_ordered = is_ordered,
        index_to_name = state_order,
        name_to_index = state_indexes
    };

    --logger.print(logger.LogLevel.DEBUG, nil, table.show(_statemachine.Machines[ name ], "StateMachineIter stated(2): "));
    --logger.print(logger.LogLevel.DEBUG, nil, table.show(_statemachine.MachineFlags[ name ], "StateMachineIter flags: "));
    
    --_statemachine.Machines[ name ] = states;
    --_statemachine.MachineFlags[ name ] = {};

    --logger.print(logger.LogLevel.DEBUG, nil, table.show(_statemachine.Machines[ name ], "StateMachineIter stated(2): "));
end

--- Starts an StateMachineIter based on the StateMachineIter Template with the given indentifier.
--- @param name string Name of the StateMachineIter Template
--- @param state_key string|integer|nil Initial state, if nil the first state will be used if the StateMachineIter is ordered, can be an integer is the StateMachineIter is ordered
--- @param init table? Initial data
--- @return StateMachineIter
function M.Start( name, state_key, init )
    if not utility.isstring(name) then error("Parameter name must be a string."); end
    if init ~= nil and not utility.istable(init) then error("Parameter init must be table or nil."); end
    if (M.Machines[ name ] == nil) then error('StateMachineIter Template "' .. name .. '" not found.'); end

    if state_key == nil then
        local flags = M.MachineFlags[ name ];
        if flags ~= nil and flags.is_ordered then
            if flags.index_to_name ~= nil then
                -- we are an ordered state machine AND don't use numeric keys
                state_key = flags.index_to_name[1];
            else
                -- we use numeric keys, so we can just set it to 1
                state_key = 1;
            end
        end
    end

    logger.print(logger.LogLevel.DEBUG, nil, "Starting StateMachineIter Template '"..name.."' with state '"..tostring(state_key).."'");

    return CreateStateMachineIter(name, nil, nil, nil, state_key, init);
end

--- Wait a set period of time on this state.
--- @param calls integer How many calls to wait
--- @param next_state string Next state when timer hits zero
--- @param early_exit function? Function to check if the state should be exited early, return false, true, or next state name
--- @return WrappedObjectForStateMachineIter
function M.SleepCalls( calls, next_state, early_exit )
    if not utility.isinteger(calls) then error("Parameter calls must be an integer."); end
    if not utility.isstring(next_state) then error("Parameter next_state must be a string."); end
    if early_exit ~= nil and not utility.isfunction(early_exit) then error("Parameter early_exit must be a function or nil."); end

    return { f = function(state, params, ...)
        local calls = params[1];
        local next_state = params[2];
        local early_exit = params[3];
        if early_exit ~= nil then
            local early_exit_result = early_exit(state, ...);
            if (early_exit_result) then
                if utility.isstring(early_exit_result) then
                    state:switch(early_exit_result);
                else
                    state:switch(next_state);
                end
                return;
            end
        end
        if state.target_call == nil then
            state.target_call = calls;
        elseif state.target_call == 0 then
            state:switch(next_state);
            state.target_call = nil; -- ensure that the timer is reset
        else
            state.target_call = state.target_call - 1;
        end
    end, p = {calls, next_state, early_exit} };
end

--- Check if a set period of time has passed.
--- This first time this is called the target time is latched in until true is returned.
--- Ensure you call state:SecondsHavePassed() or state:SecondsHavePassed(nil) to clear the timer if it did not return true and you need to move on.
--- @param self StateMachineIter StateMachineIter instance
--- @param seconds number? How many seconds to wait
--- @param lap boolean? If true the timer will still return true when the time has passed, but will "lap" instead of "stop" and keep counting.
--- @param first boolean? If true the timer returns true when it starts, requires lap to be true.
--- @return boolean timeup True if the time is up
function StateMachineIter.SecondsHavePassed(self, seconds, lap, first)
    if seconds == nil then
        self.target_time = nil;
        self.set_wait_time = nil;
        --logger.print(logger.LogLevel.DEBUG, "<StateMachineIter>", "Clear Wait Time");
        --logger.print(logger.LogLevel.DEBUG, "<StateMachineIter>", "TRIGGER");
        return true;
    end

    if self.target_time and self.set_wait_time ~= seconds then
        -- we are already sleeping, but the time has changed
        local delta = seconds - self.set_wait_time;
        self.set_wait_time = seconds;
        --logger.print(logger.LogLevel.DEBUG, "<StateMachineIter>", "Add Wait Time "..tostring(delta));
        self.target_time = self.target_time + delta;
    end

    if self.target_time == nil then
        self.target_time = M.game_time + seconds;
        self.set_wait_time = seconds;
        --logger.print(logger.LogLevel.DEBUG, "<StateMachineIter>", "Set Wait Time "..tostring(seconds));
        --if lap and first and true or false then
        --    logger.print(logger.LogLevel.DEBUG, "<StateMachineIter>", "TRIGGER");
        --end
        return lap and first and true or false; -- start sleeping
    elseif self.target_time <= M.game_time  then
        --logger.print(logger.LogLevel.DEBUG, nil, M.game_time.." > "..self.target_time.." = "..tostring(M.game_time > self.target_time));
        if lap then
            self.target_time = self.target_time + seconds; -- reset the timer to the next lap
            --logger.print(logger.LogLevel.DEBUG, "<StateMachineIter>", "Lap Cycle");
        else
            self.target_time = nil; -- ensure that the timer is reset
            self.set_wait_time = nil;
            --logger.print(logger.LogLevel.DEBUG, "<StateMachineIter>", "Clear Wait Time");
        end
        --logger.print(logger.LogLevel.DEBUG, "<StateMachineIter>", "TRIGGER");
        return true; -- time is up
    end
    return false; -- still sleeping
end

--- Wait a set period of time on this state.
--- @param seconds number How many seconds to wait
--- @param next_state string|nil Next state when timer hits zero
--- @param early_exit StateMachineFunction? Function to check if the state should be exited early, return false, true, or next state name
function M.SleepSeconds(seconds, next_state, early_exit )
    if not utility.isnumber(seconds) then error("Parameter seconds must be a number."); end
    if next_state ~= nil and not utility.isstring(next_state) then error("Parameter next_state must be a string or nil if StateMachine is ordered."); end
    if early_exit ~= nil and not utility.isfunction(early_exit) then error("Parameter early_exit must be a function or nil."); end

    --- @todo change this to use closures instead of passing the params in an array, as there's actually no need
    return { f = function(state, params, ...)
        local seconds = params[1];
        local next_state = params[2];
        local early_exit = params[3];
        if next_state == nil then
            -- next_state is nil, so try to go to the next state by index
            next_state = nextState(state);
        end

        if early_exit ~= nil then
            local early_exit_result = early_exit(state, ...);
            if (early_exit_result) then
                if utility.isstring(early_exit_result) then
                    state:switch(early_exit_result);
                else
                    state:switch(next_state);
                end
                return;
            end
        end
        --if state.target_time == nil then
        --    state.target_time = _statemachine.game_time + seconds;
        --elseif state.target_time <= _statemachine.game_time  then
        --    state.target_time = nil; -- ensure that the timer is reset
        --    state:switch(next_state);
        --end
        if state:SecondsHavePassed(seconds) then
            state:switch(next_state);
        end
    end, p = {seconds, next_state, early_exit} };
end

--- #section StateMachineIter - Core

--- Save event function.
--
-- {INTERNAL USE}
-- @param self StateMachineIter instance
-- @return template string StateMachineIter template name
-- @return target_call integer? Timer's value, nil for not set
-- @return target_time number? TargetTurn's value, nil for not set
-- @return set_wait_time number? Time to wait before running next state, kept to allow altering target_time if set_wait_time changes
-- @return state_key string|integer|nil Current state, string name or integer index if state machine is ordered
-- @return addonData table Addon data, if any
function StateMachineIter.Save(self)
    return self.template, self.target_call, self.target_time, self.set_wait_time, self.state_key, self.addonData;
end

--- Load event function.
--
-- {INTERNAL USE}
-- @param template string StateMachineIter template name
-- @param target_call integer? Timer's value, nil for not set
-- @param target_time number? TargetTurn's value, nil for not set
-- @param set_wait_time number? Time to wait before running next state, kept to allow altering target_time if set_wait_time changes
-- @param state_key string|integer|nil Current state, string name or integer index if state machine is ordered
-- @param addonData table Addon data, if any
function StateMachineIter.Load(template, target_call, target_time, set_wait_time, state_key, addonData)
    return CreateStateMachineIter(template, target_call, target_time, set_wait_time, state_key, addonData);
end

--- BulkLoad event function.
--
-- {INTERNAL USE}
function StateMachineIter.BulkLoad()
    M.game_time = GetTime();
end

hook.Add("Update", "_statemachine_Update", function(dtime, ttime)
    M.game_time = ttime;
end, config.get("hook_priority.Update.StateMachine"));

customsavetype.Register(StateMachineIter);

logger.print(logger.LogLevel.DEBUG, nil, "_statemachine Loaded");

return M;