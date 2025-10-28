--- BZ98R LUA Extended API Patrol Engine.
---
--- Patrol Engine
---
--- @module '_patrol'
--- @author John "Nielk1" Klein
--- @author Janne Trollebø
--- @todo usage example


local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_patrol Loading");

local utility = require("_utility");
local config = require("_config");
local _api = require("_api");
local hook = require("_hook");
local customsavetype = require("_customsavetype");
local gameobject = require("_gameobject");




--- @class _patrol
local M = {}


local PatrolManagerWeakList_MT = {};
PatrolManagerWeakList_MT.__mode = "k";
local PatrolManagerWeakList = setmetatable({}, PatrolManagerWeakList_MT);


local PatrolEngine;


--- Called when an object is added.
--- @param path_map table<string, table>
--- @param patrol_units table<GameObject, boolean>
--- @param locations table<string>
--- @param forcedAlert boolean
--- @return PatrolEngine
local function Construct(path_map, patrol_units, locations, forcedAlert)
    local self = {};
    self.path_map = path_map
    self.patrol_units = patrol_units
    self.locations = locations
    self.forcedAlert = forcedAlert
    self = setmetatable(self, { __index = PatrolEngine })
    PatrolManagerWeakList[self] = true
    return self
end

--- Creates a new PatrolEngine instance.
--- @return PatrolEngine
function M.new()
    return Construct({}, {}, {}, false)
end

--- @class PatrolEngine : CustomSavableType
--- @field path_map table<string, table>
--- @field patrol_units table<GameObject_patrol, boolean>
--- @field locations table<string>
--- @field forcedAlert boolean
PatrolEngine = { __type = "PatrolEngine" };

--- Registers a location.
--- @param self PatrolEngine
--- @param locationName string
function PatrolEngine.RegisterLocation(self, locationName)
    self.path_map[locationName] = {}
    table.insert(self.locations, locationName)
end

--- Registers multiple locations.
--- @param self PatrolEngine
--- @param locations string[]
function PatrolEngine.RegisterLocations(self, locations)
    for _, location in pairs(locations) do
        PatrolEngine.RegisterLocation(self, location)
    end
end

--- Connects paths between locations.
--- @param self PatrolEngine
--- @param startpoint string
--- @param path string
--- @param endpoint string
local function _connectPaths(self, startpoint, path, endpoint)
    table.insert(self.path_map[startpoint], { path = path, location = endpoint })
end

--- Defines routes for a location.
--- @param self PatrolEngine
--- @param location string
--- @param routes table<string, string>
function PatrolEngine.DefineRoutes(self, location, routes)
    for path, endpoint in pairs(routes) do
        _connectPaths(self, location, path, endpoint)
    end
end

--- Gets a random route for a location.
--- @param self PatrolEngine
--- @param location string
--- @return table
function PatrolEngine.GetRandomRoute(self, location)
    if #self.path_map[location] < 2 then
        return self.path_map[location][1]
    end
    local randomIndex = math.random(1, #self.path_map[location])
    return self.path_map[location][randomIndex]
end

--- Assigns a route to a patrol unit.
--- @param self PatrolEngine
--- @param handle GameObject_patrol
function PatrolEngine.GiveRoute(self, handle)
    local route = PatrolEngine.GetRandomRoute(self,handle._patrol.location)
    local attempts = 0

    while route and route.location == handle._patrol.oldLocation and #self.path_map[handle._patrol.location] > 1 do
        route = PatrolEngine.GetRandomRoute(self,handle._patrol.location)
        attempts = attempts + 1
        if attempts > 10 then
            break
        end
    end

    if route then
        handle._patrol.oldLocation = handle._patrol.location
        handle._patrol.location = route.location
        handle._patrol.timeout = math.random() * 5 + 1
        handle._patrol.path = route.path
        handle._patrol.busy = false
        handle:Goto(route.path)
    end
end

--- Adds a handle to the patrol units.
--- @param self PatrolEngine
--- @param object GameObject
function PatrolEngine.AddGameObject(self, object)
    if gameobject.IsGameObject(object) == false then
        error("PatrolEngine.AddGameObject: object is not a GameObject");
    end
    --- @cast object GameObject
    object = customsavetype.Cast(object, "GameObject");
    if object == nil then
        error("PatrolEngine.AddGameObject: object is not a GameObject");
    end

    --- @cast object GameObject_patrol
    local nearestLocation = nil
    local location = nil
    local pos = object:GetPosition()

    for _, loc in pairs(self.locations) do
        local locPos = GetPosition(loc)
        if not nearestLocation or Length(locPos - pos) < Length(pos - nearestLocation) then
            nearestLocation = locPos
            location = loc
        end
    end

    object._patrol = {
        --handle = handle,
        location = location,
        oldLocation = nil,
        timeout = 1,
        path = nil,
        busy = false
    };
    self.patrol_units[object] = true;
    PatrolEngine.GiveRoute(self,object)
end

local function keylist(t)
    local r = {};
    for k in pairs(t) do
        table.insert(r, k);
    end
    return r;
end

--- Gets all patrol unit handles.
--- @param self PatrolEngine
--- @return table
function PatrolEngine.GetGameObjects(self)
    return keylist(self.patrol_units);
end

--- Removes a handle from the patrol units.
--- @param self PatrolEngine
--- @param object GameObject
function PatrolEngine.RemoveGameObject(self, object)
    if gameobject.IsGameObject(object) == false then
        error("PatrolEngine.RemoveGameObject: object is not a GameObject");
    end
    --- @cast object GameObject
    object = customsavetype.Cast(object, "GameObject");
    if object == nil then
        error("PatrolEngine.RemoveGameObject: object is not a GameObject");
    end
    --- @cast object GameObject_patrol
    object._patrol = nil
    self.patrol_units[object] = nil
end

--- {INTERNAL USE}
--- @param self PatrolEngine instance
--- @return ...
function PatrolEngine.Save(self)
    return self.path_map, keylist(self.patrol_units), self.locations, self.forcedAlert
end

--- Load event function.
---
--- {INTERNAL USE}
--- @param path_map table
--- @param patrol_units table
--- @param locations table
--- @param forcedAlert boolean
--- @return PatrolEngine
function PatrolEngine.Load(path_map, patrol_units, locations, forcedAlert)
    local patrol_units_set = {};
    for _, unit in pairs(patrol_units) do
        patrol_units_set[unit] = true;
    end
    return Construct(path_map, patrol_units_set, locations, forcedAlert)
end

--- Updates the patrol controller.
--- @param self PatrolEngine
--- @param dtime number
local function update(self, dtime)
    for unit, _ in pairs(self.patrol_units) do
        unit._patrol.timeout = unit._patrol.timeout - dtime
        if unit._patrol.timeout <= 0 then
            local nearestEnemy = unit:GetNearestEnemy()
            local currentCommand = unit:GetCurrentCommand()

            if self.forcedAlert then
                if currentCommand ~= AiCommand["ATTACK"] and nearestEnemy and nearestEnemy:IsAlive() and unit:IsWithin(nearestEnemy, 125) then
                    unit:Attack(nearestEnemy)
                    unit._patrol.busy = true
                end
            end

            if not unit._patrol.busy and currentCommand == AiCommand["NONE"] then
                PatrolEngine.GiveRoute(self, unit)
            elseif unit._patrol.busy and currentCommand == AiCommand["NONE"] then
                unit._patrol.busy = false
                unit:Goto(unit._patrol.path)
            end
        end
    end
end

hook.Add("Update", "_patrol:Update", function(dtime, ttime)
    for manager, _ in pairs(PatrolManagerWeakList) do
        if manager then
            update(manager, dtime);
        end
    end
end, config.lock().hook_priority.Update.Patrol);

hook.Add("DeleteObject", "_patrol:DeleteObject", function(object)
    for manager, _ in pairs(PatrolManagerWeakList) do
        if manager then
            PatrolEngine.RemoveGameObject(manager, object);
        end
    end
end, config.lock().hook_priority.DeleteObject.Patrol);


-- --- Initializes the patrol controller.
-- --- @param self PatrolController
-- --- @param handles table
-- --- @param forcedAlert boolean
-- function M.onInit(self, handles, forcedAlert)
--     for _, handle in pairs(handles or {}) do
--         M.AddGameObject(self, handle)
--     end
--     self.forcedAlert = not not forcedAlert
-- end


customsavetype.Register(PatrolEngine);

logger.print(logger.LogLevel.DEBUG, nil, "_patrol Loaded");

return M

--- @class GameObject_patrol : GameObject
--- @field _patrol table