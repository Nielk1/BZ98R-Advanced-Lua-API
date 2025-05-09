--- BZ98R LUA Extended API StateSetRunner.
---
--- Simplistic system to run multiple functions or "states" in a single call.
--- The main use case of this is to hold multiple toggelable objectives.
--- If you want to do something more complex, use the hook module instead.
--- Like most similar constructs State Set Runners have internal data storage and can be saved and loaded.
---
--- @module '_stateset'
--- @author John "Nielk1" Klein
--- @usage local stateset = require("_stateset");
--- 
--- stateset.Create("TestSet")
---     :Add("state_a", function(runner, a, b)
---         print("test " .. runner.test1 .. " " .. tostring(a) .. " " .. tostring(b));
---     end)
---     :Add("state_a", function(runner, a, b)
---         print("test " .. runner.test2 .. " " .. tostring(a) .. " " .. tostring(b));
---     end, true);
--
-- hook.Add("InitialSetup", "Custom_InitialSetup", function(turn)
--     MissionData.TestSet = statemachine.Start("TestSet",{test1='d',test2="e");
--     MissionData.TestSet:on("state_a"); -- state true
--     MissionData.TestSet:on("state_b"); -- state 1
--     MissionData.TestSet:on("state_b"); -- state 2
--     MissionData.TestSet:off("state_b"); -- state 1, still on as this is a permit based state
-- end);
-- 
-- hook.Add("Update", "Custom_Update", function(turn)
--     MissionData.TestSMI:run(1, 2);
-- end);

--- @diagnostic disable: undefined-global
table.unpack = table.unpack or unpack; -- Lua 5.1 compatibility

local debugprint = debugprint or function(...) end;
--- @diagnostic enable: undefined-global

debugprint("_stateset Loading");

local utility = require("_utility");
local customsavetype = require("_customsavetype");
local statemachine = require("_statemachine");

local M = {};

M.Sets = {};

--- @class StateSet
--- @field template string Name of the StateSet template

--- @class StateSetRunner
--- @field template string Name of the StateSet template the runner is using
--- @field active_states table Table of active states, key is the state name and value is the state activation flag or permit count
--- @field addonData table Custom context data stored in the StateSetRunner

local StateSet = {};
StateSet.__index = StateSet;

--- Add a state to the StateSet.
--- If the state is basic either active or inactive based on last on/off call.
--- If the state is permit based it is active if the on count is greater than 0.
--- @param self StateSet StateSet instance
--- @param name string Name of the state
--- @param state function Function to be called when the state is active, should return true if the state did something.
--- @param permitBased? boolean If true, the state is permit based
--- @treturn StateSet For function chaining
function StateSet.Add(self, name, state, permitBased)
    debugprint("Add state '"..name.."' to StateSet '"..self.template.."'.", permitBased);
    if permitBased then
        M.Sets[self.template][name] = { f = state, p = true };
    else
        M.Sets[self.template][name] = { f = state };
    end
    return self;
end

--- Is this object an instance of StateSetRunner?
--- @param object any Object in question
--- @treturn bool
function M.isstatesetrunner(object)
  return (type(object) == "table" and object.__type == "StateSetRunner");
end

--- StateSetRunner.
--- An object containing all functions and data related to an StateSetRunner.
local StateSetRunner = {}; -- the table representing the class, which will double as the metatable for the instances
StateSetRunner.__index = function(table, key)
  local retVal = rawget(table, key);
  if retVal ~= nil then return retVal; end
  if rawget(table, "addonData") ~= nil and rawget(rawget(table, "addonData"), key) ~= nil then return rawget(rawget(table, "addonData"), key); end
  return rawget(StateSetRunner, key); -- if you fail to get it from the subdata, move on to base (looking for functions)
end
StateSetRunner.__newindex = function(table, key, value)
  if key ~= "template" and key ~= "active_states" and key ~= "addonData" then
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
StateSetRunner.__type = "StateSetRunner";

--- Create StateSetRunner
--- @param name string StateSetRunner template
--- @param values table Table of values embeded in the StateSetRunner
local function CreateStateSetRunner(name, values)
  local self = setmetatable({}, StateSetRunner);
  self.template = name;
  self.active_states = {};
  
  if utility.istable(values) then
    for k, v in pairs(values) do
      self[k] = v;
    end
  end
  
  return self;
end

--- Run StateSetRunner.
--- @param self StateSetRunner StateSetRunner instance
--- @param ... any Arguments to pass to the state function
--- @return boolean True if at least one state was found and executed and returned true
function StateSetRunner.run(self, ...)
    if not M.isstatesetrunner(self) then error("Parameter self must be StateSetRunner instance."); end

    local foundState = false;
    local sets = M.Sets[ self.template ];
    if not utility.istable(sets) then error("StateSetRunner Template '"..self.template.."' not found."); end
    for name,v in pairs(self.active_states) do
        if v then
            local state = sets[name].f;
            if utility.isfunction(state) then
                foundState = foundState or state(self, ...);
            elseif statemachine.isstatemachineiter(state) then
                foundState = foundState or state:run(self, ...);
            end
        end
    end

    return foundState;
end

--- Set state on.
--- @param self StateSetRunner StateSetRunner instance
--- @param name string Name of the state
--- @treturn StateSetRunner For function chaining
function StateSetRunner.on(self, name)
    if not M.isstatesetrunner(self) then error("Parameter self must be StateSetRunner instance."); end
    if not utility.isstring(name) then error("Parameter name must be string."); end
    local sets = M.Sets[ self.template ];
    if not utility.istable(sets) then error("StateSetRunner Template '"..self.template.."' not found."); end
    local state = sets[name];
    if state == nil then error("State '"..name.."' not found in StateSetRunner Template '"..self.template.."'."); end
    if state.p then
        if self.active_states[name] == nil then
            self.active_states[name] = 0;
        end
        self.active_states[name] = self.active_states[name] + 1;
    else
        if self.active_states[name] == nil then
            self.active_states[name] = true;
        end
    end
    return self;
end

--- Set state off.
--- @param self StateSetRunner StateSetRunner instance
--- @param name string Name of the state
--- @param force? boolean If true, the state is set off regardless of the current permits
--- @treturn StateSetRunner For function chaining
function StateSetRunner.off(self, name, force)
    if not M.isstatesetrunner(self) then error("Parameter self must be StateSetRunner instance."); end
    if not utility.isstring(name) then error("Parameter name must be string."); end
    local sets = M.Sets[ self.template ];
    if not utility.istable(sets) then error("StateSetRunner Template '"..self.template.."' not found."); end
    local state = sets[name];
    if state == nil then error("State '"..name.."' not found in StateSetRunner Template '"..self.template.."'."); end
    if state.p and not force then
        local activation = self.active_states[name];
        if activation ~= nil then
            self.active_states[name] = activation - 1;
        elseif activation == 1 then
            self.active_states[name] = nil;
        end
    else
        self.active_states[name] = nil;
    end
    return self;
end

--- Creates an StateSetRunner Template with the given indentifier.
--- @param name string Name of the StateSetRunner Template
--- @treturn StateSet StateSet for calling Add and AddPermit, can not be saved.
function M.Create( name )
    if not utility.isstring(name) then error("Parameter name must be a string."); end

    debugprint("Create StateSetRunner Template '"..name.."'.", M.Sets[name] ~= nil);
    
    --if (_stateset.Machines[ name ] == nil) then
    --    _stateset.Machines[ name ] = {};
    --end
    
    local state = setmetatable({}, StateSet);
    state.template = name;
    M.Sets[ name ] = state;
    return state;
end

--- Starts an StateSetRunner based on the StateSetRunner Template with the given indentifier.
--- @param name string Name of the StateSetRunner Template
--- @param init table Initial data
function M.Start( name, init )
    if not utility.isstring(name) then error("Parameter name must be a string."); end
    if init ~= nil and not utility.istable(init) then error("Parameter init must be table or nil."); end
    if (M.Sets[ name ] == nil) then error('StateSetRunner Template "' .. name .. '" not found.'); end

    return CreateStateSetRunner(name, init);
end

-------------------------------------------------------------------------------
-- StateSetRunner - Core
-------------------------------------------------------------------------------
-- @section

--- Save event function.
--
-- INTERNAL USE.
-- @param self StateSetRunner instance
-- @return ...
function StateSetRunner.Save(self)
    return self.template, self.active_states, self.addonData;
end

--- Load event function.
--
-- INTERNAL USE.
-- @param template
-- @param active_states
-- @param addonData
function StateSetRunner.Load(template, active_states, addonData)
    local stateRunner = CreateStateSetRunner(template, addonData);
    --for k, v in pairs(active_states) do
    --    if type(v) == "number" then
    --        --stateRunner.active_states[k] = v;
    --        for i = 1, v do
    --            stateRunner:on(k);
    --        end
    --    elseif v == true then
    --        --stateRunner.active_states[k] = true;
    --        stateRunner:on(k);
    --    end
    --end
    stateRunner.active_states = active_states; -- if this doesn't work use the loop above instead
    return stateRunner;
end

customsavetype.Register(StateSetRunner);

debugprint("_stateset Loaded");

return M;