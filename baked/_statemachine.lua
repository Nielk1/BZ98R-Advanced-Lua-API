--- BZ98R LUA Extended API StateMachineIter.
-- 
-- State Machine and State Machine Iterator for serial event sequences across game turns.
-- 
-- Dependencies: @{_api}, @{_hook}
-- @module _statemachine
-- @author John "Nielk1" Klein
-- @usage local statemachine = require("_statemachine");
-- 
-- statemachine.Create("TestMachine",
-- {
--     ["state_a"] = function(state)
--         print("test " .. state.test1);
--         state:switch("state_b");
--     end,
--     ["state_b"] = statemachine.SleepSeconds(10,"state_c"),
--     ["state_c"] = function(state)
--         print("test " .. state.test2);
--         state:switch("state_d");
--     end,
--     ["state_d"] = statemachine.SleepSeconds(15,"state_e"),
--     ["state_e"] = function(state)
--         print("test " .. state.test3);
--         state:switch("state_f");
--     end
-- });
-- 
-- -- ordered state machine that supports state:next()
-- statemachine.Create("OrderedTestMachine",
-- {
--     -- named state function
--     { "state_a", function(state)
--         print("test " .. state.test1);
--         state:switch("state_b");
--     end },
--
--     -- named magic state function (SleepSeconds)
--     -- note nil next_state means next state by index
--     { "state_b", statemachine.SleepSeconds(10) },
--
--     -- named state function with automatic name
--     { nil, function(state)
--         print("test " .. state.test2);
--         state:switch("state_d");
--     end },
--
--     -- named state function with automatic name
--     { function(state)
--         print("test " .. state.test2);
--         state:switch("state_d");
--     end },
--
--     -- magic state function (SleepSeconds)
--     statemachine.SleepSeconds(15,"nonexistent_state"),
--
--     -- stsate function with automatic name
--     function(state)
--         print("test " .. state.test3);
--         state:next();
--     end
-- });
--
-- hook.Add("InitialSetup", "Custom_InitialSetup", function(turn)
--     MissionData.TestSMI = statemachine.Start("TestMachine","state_a",{test1='d',test2="e",test3="f"});
--     MissionData.TestSMI = statemachine.Start("OrderedTestMachine","state_a",{test1='d',test2="e",test3="f"});
-- end);
-- 
-- hook.Add("Update", "Custom_Update", function(turn)
--     MissionData.TestSMI:run();
-- end);

table.unpack = table.unpack or unpack; -- Lua 5.1 compatibility

local debugprint = debugprint or function() end;

debugprint("_statemachine Loading");

--require("_table_show");

local _api = require("_api");
local hook = require("_hook");

local _statemachine = {};
_statemachine.game_time = 0;

_statemachine.Machines = {};
_statemachine.MachineFlags = {};

--- Is this object an instance of StateMachineIter?
-- @param object Object in question
-- @treturn bool
function isstatemachineiter(object)
  return (type(object) == "table" and object.__type == "StateMachineIter");
end

--- StateMachineIter.
-- An object containing all functions and data related to an StateMachineIter.
local StateMachineIter = {}; -- the table representing the class, which will double as the metatable for the instances
--GameObject.__index = GameObject; -- failed table lookups on the instances should fallback to the class table, to get methods
StateMachineIter.__index = function(table, key)
  local retVal = rawget(table, key);
  if retVal ~= nil then return retVal; end
  if rawget(table, "addonData") ~= nil and rawget(rawget(table, "addonData"), key) ~= nil then return rawget(rawget(table, "addonData"), key); end
  return rawget(StateMachineIter, key); -- if you fail to get it from the subdata, move on to base (looking for functions)
end
StateMachineIter.__newindex = function(table, key, value)
  if key ~= "template" and key ~= "state_key" and key ~= "timer" and key ~= "target_time" and key ~= "addonData" then
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
-- @tparam string name StateMachineIter template
-- @tparam int timer Timer's value, -1 for not set
-- @tparam int target_time TargetTurn's value, -1 for not set
-- @tparam string state_key Current state
-- @tparam table values Table of values embeded in the StateMachineIter
local CreateStateMachineIter = function(name, timer, target_time, state_key, values)
  local self = setmetatable({}, StateMachineIter);
  self.template = name;
  self.timer = timer;
  self.target_time = target_time;
  self.state_key = state_key;
  
  if istable(values) then
    for k, v in pairs( values ) do 
      self[k] = v;
    end
  end
  
  return self;
end

--- Run StateMachineIter.
-- @tparam StateMachineIter self FuncArrayIter instance
function StateMachineIter.run(self, ...)
    if not isstatemachineiter(self) then error("Parameter self must be StateMachineIter instance."); end
    
    --debugprint("Running StateMachineIter Template '"..self.template.."' with state '"..self.state_key.."'");

    local machine = _statemachine.Machines[self.template];
    if machine == nil then return false; end

    if isfunction(machine[self.state_key]) then
        return true, machine[self.state_key](self, ...);
    end
    if istable(machine[self.state_key]) then
        if isfunction(machine[self.state_key].f) then
            --print("StateMachineIter state '"..self.state_key.."' is "..type(machine[self.state_key].f).." '"..table.show(machine[self.state_key].p).."'");
            return true, machine[self.state_key].f(self, table.unpack(machine[self.state_key].p), ...);
        end
    end
    return false;
end

--- Get next state for StateMachineIter.
-- @tparam StateMachineIter state FuncArrayIter instance
-- @local
function nextState(state)
    local flags = _statemachine.MachineFlags[ state.template ];
    if flags == nil or not flags.is_ordered then error("StateMachine is not ordered."); end
    --if flags == nil or not flags.is_ordered then return nil; end
    local index = flags.name_to_index[ state.state_key ];
    if index == nil then
        return nil;
    end
    index = index + 1;
    if index > #flags.index_to_name then
        return nil;
    end
    return flags.index_to_name[ index ];
end

--- Next StateMachineIter State.
-- This only works if the StateMachineIter is ordered.
-- @tparam StateMachineIter self StateMachineIter instance
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

    debugprint("StateMachineIter '"..self.template.."' next state '"..old_key.."' to '"..self.state_key.."'");
end

--- Switch StateMachineIter State.
-- @tparam StateMachineIter self StateMachineIter instance
-- @tparam string key State to switch to
function StateMachineIter.switch(self, key)
    local old_key = self.state_key
    self.state_key = key;

    debugprint("StateMachineIter '"..self.template.."' switch state '"..old_key.."' to '"..self.state_key.."'");
end

--- Creates an StateMachineIter Template with the given indentifier.
-- @param name Name of the StateMachineIter Template (string)
-- @param states State function table, can be a table of named state functions or an array of state descriptors.
-- State descriptors are tables with the first element being the state name and the second element being the state function.
-- If the second element is nil, the first element is considered the state function and the state name is generated automatically.
-- If the state descriptor is instead a function it is treated as a nil state and the state name is generated automatically.
function _statemachine.Create( name, states )
    if not isstring(name) then error("Parameter name must be a string."); end
    
    debugprint("Creating StateMachineIter Template '"..name.."'");

    --if (_statemachine.Machines[ name ] == nil) then
    --    _statemachine.Machines[ name ] = {};
    --end

    --debugprint(table.show(states, "StateMachineIter states: "));

    if states[1] ~= nil then
        -- this is probably an array instead of just a table

        debugprint("StateMachineIter states appear to be array");

        local new_states = {};
        local state_order = {};
        local state_indexes = {};
        for i, v in ipairs(states) do
            local state_name = nil;
            local state_func = nil;

            if istable(v) then
                state_name = v[1]; -- first item
                state_func = v[2]; -- second item

                -- if state_func isn't set and the state_name isn't a string, move it over to state_func
                if state_func == nil and state_name ~= nil and not isstring(state_name) then
                    state_func = state_name
                    state_name = nil;
                end

                if state_func == nil and state_name == nil then
                    -- we might have a rich state descriptor here
                    if isfunction(v.f) and istable(v.p) then
                        state_func = v
                        state_name = nil; -- no name since we got
                    else
                        error("StateMachineIter state must be n array of state descriptors");
                    end
                end
            elseif isfunction(v) then
                state_name = nil; -- no name since we got a bare function
                state_func = v;
            end

            if state_name == nil then
                state_name = "state_" .. i;
            end

            if state_func == nil then
                error("StateMachineIter state must be n array of state descriptors");
            end

            debugprint("StateMachineIter state '"..state_name.."' is "..type(state_func).." '"..tostring(state_func).."'");

            new_states[state_name] = state_func;
            state_indexes[state_name] = i;
            table.insert(state_order, state_name);
        end
        _statemachine.Machines[ name ] = new_states;
        _statemachine.MachineFlags[ name ] = {
            is_ordered = true,
            index_to_name = state_order,
            name_to_index = state_indexes
        };

        --debugprint(table.show(_statemachine.Machines[ name ], "StateMachineIter stated(2): "));
        --debugprint(table.show(_statemachine.MachineFlags[ name ], "StateMachineIter flags: "));
        return;
    end
    
    _statemachine.Machines[ name ] = states;
    --_statemachine.MachineFlags[ name ] = {};

    --debugprint(table.show(_statemachine.Machines[ name ], "StateMachineIter stated(2): "));
end

--- Starts an StateMachineIter based on the StateMachineIter Template with the given indentifier.
-- @tparam string name Name of the StateMachineIter Template
-- @tparam string state_key Initial state
-- @tparam table init Initial data
function _statemachine.Start( name, state_key, init )
    if not isstring(name) then error("Parameter name must be a string."); end
    if init ~= nil and not istable(init) then error("Parameter init must be table or nil."); end
    if (_statemachine.Machines[ name ] == nil) then error('StateMachineIter Template "' .. name .. '" not found.'); end

    if state_key == nil then
        state_key = _statemachine.MachineFlags[ name ].index_to_name[1];
    end

    debugprint("Starting StateMachineIter Template '"..name.."' with state '"..state_key.."'");

    return CreateStateMachineIter(name, nil, nil, state_key, init);
end

--- Wait a set period of time on this state.
-- @tparam int calls How many calls to wait
-- @tparam string next_state Next state when timer hits zero
-- @tparam[opt] function early_exit Function to check if the state should be exited early, return false, true, or next state name
function _statemachine.SleepCalls( calls, next_state, early_exit )
    if not isinteger(calls) then error("Parameter calls must be an integer."); end
    if not isstring(next_state) then error("Parameter next_state must be a string."); end
    if early_exit ~= nil and not isfunction(early_exit) then error("Parameter early_exit must be a function or nil."); end

    return { f = function(state, calls, next_state, early_exit, ...)
        if early_exit ~= nil then
            local early_exit_result = early_exit(state, ...);
            if (early_exit_result) then
                if isstring(early_exit_result) then
                    state:switch(early_exit_result);
                else
                    state:switch(next_state);
                end
                return;
            end
        end
        if state.timer == nil then
            state.timer = calls;
        elseif state.timer == 0 then
            state:switch(next_state);
            state.timer = nil; -- ensure that the timer is reset
        else
            state.timer = state.timer - 1;
        end
    end, p = {calls, next_state, early_exit} };
end

--- Check if a set period of time has passed.
-- This first time this is called the target time is latched in until true is returned.
-- Ensure you call state:SecondsHavePassed() or state:SecondsHavePassed(nil) to clear the timer if it did not return true and you need to move on.
-- @tparam StateMachineIter self StateMachineIter instance
-- @tparam[opt] number seconds How many seconds to wait
-- @treturn bool True if the time is up
function StateMachineIter.SecondsHavePassed(self, seconds)
    if seconds == nil then
        self.target_time = nil;
        return true;
    end
    if self.target_time == nil then
        self.target_time = _statemachine.game_time + seconds;
        return false; -- start sleeping
    elseif self.target_time <= _statemachine.game_time  then
        debugprint(_statemachine.game_time.." > "..self.target_time.." = "..tostring(_statemachine.game_time > self.target_time));
        self.target_time = nil; -- ensure that the timer is reset
        return true; -- time is up
    end
    return false; -- still sleeping
end

--- Wait a set period of time on this state.
-- @tparam number seconds How many seconds to wait
-- @tparam string next_state Next state when timer hits zero
-- @tparam[opt] function early_exit Function to check if the state should be exited early, return false, true, or next state name
function _statemachine.SleepSeconds(seconds, next_state, early_exit )
    if not isnumber(seconds) then error("Parameter seconds must be a number."); end
    if next_state ~= nil and not isstring(next_state) then error("Parameter next_state must be a string or nil if StateMachine is ordered."); end
    if early_exit ~= nil and not isfunction(early_exit) then error("Parameter early_exit must be a function or nil."); end

    return { f = function(state, seconds, next_state, early_exit, ...)
        if next_state == nil then
            -- next_state is nil, so try to go to the next state by index
            next_state = nextState(state);
        end
        
        if early_exit ~= nil then
            local early_exit_result = early_exit(state, ...);
            if (early_exit_result) then
                if isstring(early_exit_result) then
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

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- StateMachineIter - Core
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

--- Save event function.
--
-- INTERNAL USE.
-- @param self StateMachineIter instance
-- @return ...
function StateMachineIter.Save(self)
    return self;
end

--- Load event function.
--
-- INTERNAL USE.
-- @param data
function StateMachineIter.Load(data)
    return CreateStateMachineIter(data.template, data.timer, data.target_time, data.state_key, data.addonData);
end

--- BulkLoad event function.
--
-- INTERNAL USE.
function StateMachineIter.BulkLoad()
    _statemachine.game_time = GetTime();
end

hook.Add("Update", "_statemachine_Update", function(dtime, ttime)
    -- consider accessing total game time instead
    _statemachine.game_time = ttime;
end, 9999);

_api.RegisterCustomSavableType(StateMachineIter);

debugprint("_statemachine Loaded");

return _statemachine;