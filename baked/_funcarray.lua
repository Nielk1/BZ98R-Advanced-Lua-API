--- BZ98R LUA Extended API FuncArrayIter.
-- 
-- Function Array and Function Array Iterator for serial event sequences across game turns.
-- 
-- Dependencies: @{_api}, @{_hook}
-- @module _funcarray
-- @author John "Nielk1" Klein
-- @usage local funcarray = require("_funcarray");
-- 
-- funcarray.Create("TestMachine",
--     function(state)
--         print("test " .. state.test1);
--         state:next();
--     end,
--     funcarray.SleepSeconds(10),
--     function(state)
--         print("test " .. state.test2);
--         state:next();
--     end,
--     funcarray.SleepSeconds(15),
--     function(state)
--         print("test " .. state.test3);
--         state:next();
--     end);
-- 
-- hook.Add("InitialSetup", "Custom_InitialSetup", function(turn)
--     MissionData.TestFAI = funcarray.Start("TestMachine",{test1='a',test2="b",test3="c"});
-- end);
-- 
-- hook.Add("Update", "Custom_Update", function(turn)
--     MissionData.TestFAI:run();
-- end);

local debugprint = debugprint or function() end;

debugprint("_funcarray Loading");

local _api = require("_api");
local hook = require("_hook");

local _funcarray = {};
_funcarray.game_time = 0;

_funcarray.Machines = {};

--- Is this object an instance of FuncArrayIter?
-- @param object Object in question
-- @treturn bool
function isfuncarrayiter(object)
  return (type(object) == "table" and object.__type == "FuncArrayIter");
end

--- FuncArrayIter.
-- An object containing all functions and data related to an FuncArrayIter.
local FuncArrayIter = {}; -- the table representing the class, which will double as the metatable for the instances
--GameObject.__index = GameObject; -- failed table lookups on the instances should fallback to the class table, to get methods
FuncArrayIter.__index = function(table, key)
  local retVal = rawget(table, key);
  if retVal ~= nil then return retVal; end
  if rawget(table, "addonData") ~= nil and rawget(rawget(table, "addonData"), key) ~= nil then return rawget(rawget(table, "addonData"), key); end
  return rawget(FuncArrayIter, key); -- if you fail to get it from the subdata, move on to base (looking for functions)
end
FuncArrayIter.__newindex = function(table, key, value)
  if key ~= "template" and key ~= "state_index" and key ~= "timer" and key ~= "target_time" and key ~= "addonData" then
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
FuncArrayIter.__type = "FuncArrayIter";

--- Create FuncArrayIter
-- @tparam string name FuncArrayIter template
-- @tparam int timer Timer's value, -1 for not set
-- @tparam int target_time TargetTurn's value, -1 for not set
-- @tparam int state_index Current state
-- @tparam table values Table of values embeded in the FuncArrayIter
local CreateFuncArrayIter = function(name, timer, target_time, state_index, values)
  local self = setmetatable({}, FuncArrayIter);
  self.template = name;
  self.timer = timer;
  self.target_time = target_time;
  self.state_index = state_index;
  
  if istable(values) then
    for k, v in pairs( values ) do 
      self[k] = v;
    end
  end
  
  return self;
end

--- Run FuncArrayIter.
-- @tparam FuncArrayIter self FuncArrayIter instance
function FuncArrayIter.run(self)
    if not isfuncarrayiter(self) then error("Parameter self must be FuncArrayIter instance."); end
    
    local machine = _funcarray.Machines[self.template];
    if machine == nil then return false; end
    if #machine < self.state_index then return false; end
    
    if isfunction(machine[self.state_index]) then
        return true, machine[self.state_index](self);
    end
    if istable(machine[self.state_index]) then
        if isfunction(machine[self.state_index][1]) then
            return true, machine[self.state_index][1](self, table.unpack(machine[self.state_index][2]));
        end
    end
    return false;
end

--- Next FuncArrayIter State.
-- @tparam FuncArrayIter self FuncArrayIter instance
function FuncArrayIter.next(self)
    self.state_index = self.state_index + 1;
end

--- Creates an FuncArrayIter Template with the given indentifier.
-- @tparam string name Name of the FuncArrayIter Template
-- @tparam function ... State functions
function _funcarray.Create( name, ... )
    if not isstring(name) then error("Parameter name must be a string."); end
    
    if (_funcarray.Machines[ name ] == nil) then
        _funcarray.Machines[ name ] = {};
    end
    
    _funcarray.Machines[ name ] = { ... };
end

--- Starts an FuncArrayIter based on the FuncArrayIter Template with the given indentifier.
-- @tparam string name Name of the FuncArrayIter Template
-- @tparam table init Initial data
function _funcarray.Start( name, init )
    if not isstring(name) then error("Parameter name must be a string."); end
    if init ~= nil and not istable(init) then error("Parameter init must be table or nil."); end
    if (_funcarray.Machines[ name ] == nil) then error('FuncArrayIter Template "' .. name .. '" not found.'); end

    return CreateFuncArrayIter(name, -1, -1, 1, init);
end

--- Wait a set period of time on this state.
-- @tparam number calls How many calls to wait
-- @tparam[opt] function early_exit Boolean function to check if the state should be exited early
function _funcarray.SleepCalls( calls, early_exit )
    if not isinteger(calls) then error("Parameter calls must be an integer."); end
    if early_exit ~= nil and not isfunction(early_exit) then error("Parameter early_exit must be a function or nil."); end

    return {(function(state, ...)
        local calls, early_exit = ...;
        if early_exit ~= nil and early_exit(state) then
            state:next();
            return;
        end
        if state.timer == nil then
            state.timer = calls;
        elseif state.timer == 0 then
            state:next();
            state.timer = nil; -- ensure that the timer is reset
        else
            state.timer = state.timer - 1;
        end
    end), {calls, early_exit}};
end

--- Wait a set period of time on this state.
-- @tparam number seconds How many seconds to wait
-- @tparam[opt] function early_exit Boolean function to check if the state should be exited early
function _funcarray.SleepSeconds( seconds, early_exit )
    if not isnumber(seconds) then error("Parameter seconds must be a number."); end
    if early_exit ~= nil and not isfunction(early_exit) then error("Parameter early_exit must be a function or nil."); end

    return {(function(state, ...)
        local seconds, early_exit = ...;
        if early_exit ~= nil and early_exit(state) then
            state:next();
            return;
        end
        if state.target_time == nil then
            state.target_time = _funcarray.game_time + seconds;
        elseif state.target_time <= _funcarray.game_time  then
            state:next();
            state.target_time = nil; -- ensure that the timer is reset
        end
    end), {seconds, early_exit}};
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FuncArrayIter - Core
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

--- Save event function.
--
-- INTERNAL USE.
-- @param self FuncArrayIter instance
-- @return ...
function FuncArrayIter.Save(self)
    return self;
end

--- Load event function.
--
-- INTERNAL USE.
-- @param data
function FuncArrayIter.Load(data)
    return CreateFuncArrayIter(data.template, data.timer, data.target_time, data.state_index, data.addonData);
end

--- BulkLoad event function.
--
-- INTERNAL USE.
function FuncArrayIter.BulkLoad()
    _funcarray.game_time = GetTime();
end

hook.Add("Update", "_funcarray_Update", function(dtime, ttime)
    -- consider accessing total game time instead
    _funcarray.game_time = ttime;
end, 9999);

_api.RegisterCustomSavableType(FuncArrayIter);

debugprint("_funcarray Loaded");

return _funcarray;