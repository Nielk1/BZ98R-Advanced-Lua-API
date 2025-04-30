--- BZ98R LUA Extended API StateMachineIter.
-- 
-- State Machine and State Machine Iterator for serial event sequences across game turns.
-- 
-- Dependencies: @{_api}, @{_hook}
-- @module _statemachine
-- @author John "Nielk1" Klein
-- @usage local statemachine = require("_statemachine");
-- 
-- statemachine.Create("TestMachine2",
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
-- hook.Add("InitialSetup", "Custom_InitialSetup", function(turn)
--     MissionData.TestSMI = statemachine.Start("TestMachine2","state_a",{test1='d',test2="e",test3="f"});
-- end);
-- 
-- hook.Add("Update", "Custom_Update", function(turn)
--     MissionData.TestSMI:run();
-- end);

local debugprint = debugprint or function() end;

debugprint("_statemachine Loading");

local _api = require("_api");
local hook = require("_hook");

local _statemachine = {};
_statemachine.game_time = 0;

_statemachine.Machines = {};

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
  if key ~= "template" and key ~= "state_key" and key ~= "timer" and key ~= "target_turn" and key ~= "addonData" then
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
-- @tparam int target_turn TargetTurn's value, -1 for not set
-- @tparam string state_key Current state
-- @tparam table values Table of values embeded in the StateMachineIter
local CreateStateMachineIter = function(name, timer, target_turn, state_key, values)
  local self = setmetatable({}, StateMachineIter);
  self.template = name;
  self.timer = timer;
  self.target_turn = target_turn;
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
function StateMachineIter.run(self)
    if not isstatemachineiter(self) then error("Paramater self must be StateMachineIter instance."); end
    
    local machine = _statemachine.Machines[self.template];
    if machine == nil then return false; end

    if isfunction(machine[self.state_key]) then
        return true, machine[self.state_key](self);
    end
    if istable(machine[self.state_key]) then
        if isfunction(machine[self.state_key][1]) then
            return true, machine[self.state_key][1](self, table.unpack(machine[self.state_key][2]));
        end
    end
    return false;
end

--- Switch StateMachineIter State.
-- @tparam StateMachineIter self StateMachineIter instance
-- @tparam string key State to switch to
function StateMachineIter.switch(self, key)
    self.state_key = key;
end

-- Creates an StateMachineIter Template with the given indentifier.
-- @param name Name of the StateMachineIter Template (string)
-- @param states State function table
function _statemachine.Create( name, states )
    if not isstring(name) then error("Paramater name must be a string."); end
    
    if (_statemachine.Machines[ name ] == nil) then
        _statemachine.Machines[ name ] = {};
    end
    
    _statemachine.Machines[ name ] = states;
end

-- Starts an StateMachineIter based on the StateMachineIter Template with the given indentifier.
-- @tparam string event Name of the StateMachineIter Template
-- @tparam string state_key Initial state
-- @tparam table init Initial data
function _statemachine.Start( name, state_key, init )
    if not isstring(name) then error("Paramater name must be a string."); end
    if init ~= nil and not istable(init) then error("Paramater init must be table or nil."); end
    if (_statemachine.Machines[ name ] == nil) then error('StateMachineIter Template "' .. name .. '" not found.'); end

    return CreateStateMachineIter(name, -1, -1, state_key, init);
end

-- Wait a set period of time on this state.
-- @tparam StateMachineIter state StateMachineIter data
-- @tparam int calls How many calls to wait
-- @tparam string next_state Next state when timer hits zero
function _statemachine.SleepCalls( calls, next_state )
    if not isinteger(seconds) then error("Paramater seconds must be an integer."); end
    if not isstring(next_state) then error("Paramater next_state must be a string."); end

    return {(function(state, ...)
        local seconds, next_state = ...;
        if state.timer == -1 then
            state.timer = calls;
        elseif state.timer == 0 then
            state:switch(next_state);
            state.timer = -1;
        else
            state.timer = state.timer - 1;
        end
    end), {seconds, next_state}};
end

-- Wait a set period of time on this state.
-- @tparam StateMachineIter state StateMachineIter data
-- @tparam int seconds How many seconds to wait
-- @tparam string next_state Next state when timer hits zero
function _statemachine.SleepSeconds( seconds, next_state )
    if not isnumber(seconds) then error("Paramater seconds must be a number."); end
    if not isstring(next_state) then error("Paramater next_state must be a string."); end

    return {(function(state, ...)
        local seconds, next_state = ...;
        if state.target_turn == -1 then
            state.target_turn = _statemachine.game_time + seconds);
        elseif state.target_turn <= _statemachine.game_time  then
            state:switch(next_state);
            state.target_turn = -1;
        end
    end), {seconds, next_state}};
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
    return CreateStateMachineIter(data.template, data.timer, data.target_turn, data.state_key, data.addonData);
end

--- BulkSave event function.
--
-- INTERNAL USE.
-- @return data to save in bulk
function StateMachineIter.BulkSave()
    return _statemachine.game_time;
end

--- BulkLoad event function.
--
-- INTERNAL USE.
-- @param data
function StateMachineIter.BulkLoad(data)
    _statemachine.game_time = data;
end

--- BulkPostLoad event function.
--
-- INTERNAL USE.
function StateMachineIter.BulkPostLoad()
    
end

hook.Add("Update", "_statemachine_Update", function(dtime, ttime)
    -- consider accessing total game time instead
    _statemachine.game_time = ttime;
end, 9999);

_api.RegisterCustomSavableType(StateMachineIter);

debugprint("_statemachine Loaded");

return _statemachine;