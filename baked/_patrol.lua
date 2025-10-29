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

--- @class PathDescription
--- @field weight number
--- @field enabled boolean

--- @class PatrolEngineCacheData
--- @field startpoints table<string, table<string, boolean>>
--- @field destination table<string, table<string, boolean>>
--- @field locations table<string, Vector> approximate vector positions of locations
--- @field location_sizes table<string, number> approximate size of locations for possible future use

--- @class PatrolEngine : CustomSavableType
--- @field patrol_units table<GameObject_patrol, boolean> Set of units managed by the PatrolEngine
--- @field forcedAlert boolean Do units latch onto and attack enemies encountered?
--- @field graph table<string, table<string, table<PathName, PathDescription>>>
--- @field cache PatrolEngineCacheData
local PatrolEngine = { __type = "PatrolEngine" };

--- Called when an object is added.
--- @param graph table<string, table<string, table<PathName, PathDescription>>>
--- @param patrol_units GameObject[]
--- @param forcedAlert boolean
--- @return PatrolEngine
local function Construct(graph, patrol_units, forcedAlert)
    local self = {};
    self.patrol_units = {}
    self.forcedAlert = forcedAlert
    self.graph = {}

    self.cache = customsavetype.NoSave();
    self.cache.startpoints = {};
    self.cache.destination = {};
    self.cache.locations = {};
    self.cache.location_sizes = {};

    for _, unit in ipairs(patrol_units) do
        self.patrol_units[unit] = true;
    end

    --- loop graph entries to call AddRoute for each
    for startpoint, endpoint_data in pairs(graph) do
        for endpoint, paths in pairs(endpoint_data) do
            for path_name, path_data in pairs(paths) do
                self:AddRoute(startpoint, endpoint, path_name, path_data.weight, path_data.enabled);
            end
        end
    end

    self = setmetatable(self, { __index = PatrolEngine });
    PatrolManagerWeakList[self] = true;
    return self;
end

--- Creates a new PatrolEngine instance.
--- @return PatrolEngine
function M.new()
    return Construct({}, {}, false)
end

--- Add path between two locations to graph.
--- @param self PatrolEngine
--- @param startpoint string
--- @param endpoint string
--- @param path PathName
--- @param weight number?
--- @param enabled boolean?
--- @return PatrolEngine self
function PatrolEngine:AddRoute(startpoint, endpoint, path, weight, enabled)
    if startpoint == enabled then
        return self;
    end

    if not self.graph[startpoint] then
        self.graph[startpoint] = {};
    end
    if not self.graph[startpoint][endpoint] then
        self.graph[startpoint][endpoint] = {};
    end
    self.graph[startpoint][endpoint][path] = {
        weight = weight or 1,
        --- @cast enabled boolean
        enabled = (enabled == nil) and true or enabled,
    };

    if not self.cache.startpoints[startpoint] then
        self.cache.startpoints[startpoint] = {};
    end
    self.cache.startpoints[startpoint][path] = true;

    if not self.cache.destination[endpoint] then
        self.cache.destination[endpoint] = {};
    end
    self.cache.destination[endpoint][path] = true;
    
    -- Recalculate approximate location vectors
    local start_pos = SetVector(0, 0, 0);
    local start_corner_min = nil;
    local start_corner_max = nil;
    local start_count = 0;
    for path_name, _ in pairs(self.cache.startpoints[startpoint]) do
        local pos = GetPosition(path_name, 0);
        if pos then
            start_pos = start_pos + pos;
            start_count = start_count + 1;

            start_corner_min = start_corner_min or pos;
            start_corner_max = start_corner_max or pos;
            start_corner_min = SetVector(
                math.min(start_corner_min.x, pos.x),
                math.min(start_corner_min.y, pos.y),
                math.min(start_corner_min.z, pos.z)
            );
            start_corner_max = SetVector(
                math.max(start_corner_max.x, pos.x),
                math.max(start_corner_max.y, pos.y),
                math.max(start_corner_max.z, pos.z)
            );
        end
    end
    if self.cache.destination[startpoint] then
        for path_name, _ in pairs(self.cache.destination[startpoint]) do
            local pos = GetPosition(path_name, GetPathPointCount(path_name) - 1);
            if pos then
                start_pos = start_pos + pos;
                start_count = start_count + 1;

                start_corner_min = start_corner_min or pos;
                start_corner_max = start_corner_max or pos;
                start_corner_min = SetVector(
                    math.min(start_corner_min.x, pos.x),
                    math.min(start_corner_min.y, pos.y),
                    math.min(start_corner_min.z, pos.z)
                );
                start_corner_max = SetVector(
                    math.max(start_corner_max.x, pos.x),
                    math.max(start_corner_max.y, pos.y),
                    math.max(start_corner_max.z, pos.z)
                );
            end
        end
    end
    self.cache.locations[startpoint] = start_count > 0 and (start_pos / start_count) or SetVector(0, 0, 0);
    if start_corner_min and start_corner_max then
        self.cache.location_sizes[startpoint] = Length(start_corner_max - start_corner_min);
    end

    -- Recalculate approximate location vectors
    local end_pos = SetVector(0, 0, 0);
    local end_corner_min = nil;
    local end_corner_max = nil;
    local end_count = 0;
    if self.cache.startpoints[endpoint] then
        for path_name, _ in pairs(self.cache.startpoints[endpoint]) do
            local pos = GetPosition(path_name, 0);
            if pos then
                end_pos = end_pos + pos;
                end_count = end_count + 1;

                end_corner_min = end_corner_min or pos;
                end_corner_max = end_corner_max or pos;
                end_corner_min = SetVector(
                    math.min(end_corner_min.x, pos.x),
                    math.min(end_corner_min.y, pos.y),
                    math.min(end_corner_min.z, pos.z)
                );
                end_corner_max = SetVector(
                    math.max(end_corner_max.x, pos.x),
                    math.max(end_corner_max.y, pos.y),
                    math.max(end_corner_max.z, pos.z)
                );
            end
        end
    end
    for path_name, _ in pairs(self.cache.destination[endpoint]) do
        local pos = GetPosition(path_name, GetPathPointCount(path_name) - 1);
        if pos then
            end_pos = end_pos + pos;
            end_count = end_count + 1;

            end_corner_min = end_corner_min or pos;
            end_corner_max = end_corner_max or pos;
            end_corner_min = SetVector(
                math.min(end_corner_min.x, pos.x),
                math.min(end_corner_min.y, pos.y),
                math.min(end_corner_min.z, pos.z)
            );
            end_corner_max = SetVector(
                math.max(end_corner_max.x, pos.x),
                math.max(end_corner_max.y, pos.y),
                math.max(end_corner_max.z, pos.z)
            );
        end
    end
    self.cache.locations[endpoint] = end_count > 0 and (end_pos / end_count) or SetVector(0, 0, 0);
    if end_corner_min and end_corner_max then
        self.cache.location_sizes[endpoint] = Length(end_corner_max - end_corner_min);
    end

    logger.print(logger.LogLevel.DEBUG, nil, "AddRoute " .. tostring(self) .. " '" .. startpoint .. "' -> '" .. path .. "' -> '" .. endpoint .. "'");

    return self;
end

--- @class PathProbabilityWrapper
--- @field location string
--- @field totalWeight number
--- @field path_name PathName
--- @field path PathDescription Might not be needed
--- @local

--- Gets a random route for a location.
--- @param self PatrolEngine
--- @param location string
--- @param avoid_locations string[]?
--- @return string? destination
--- @return PathName? path_data
function PatrolEngine:GetRandomRouteFrom(location, avoid_locations)
    local destinations = self.graph[location]
    if not destinations or not next(destinations) then
        return nil
    end

    --- @type table<string, boolean>
    local avoids = {};
    if avoid_locations then
        for _, avoid in ipairs(avoid_locations) do
            avoids[avoid] = true;
        end
    end

    --- @type PathProbabilityWrapper[]
    local path_options = {};
    local totalWeight = 0;
    local path_options_with_avoids = {};
    local totalWeightWithAvoids = 0;
    for destination, paths in pairs(destinations) do
        if avoids[destination] then
            for path_name, path_data in pairs(paths) do
                local p = { location = destination, path_name = path_name, totalWeight = totalWeight, path = path_data};
                totalWeight = totalWeight + (path_data.weight or 1);
                table.insert(path_options, p);
                totalWeightWithAvoids = totalWeightWithAvoids + (path_data.weight or 1);
                table.insert(path_options_with_avoids, p);
            end
        else
            for path_name, path_data in pairs(paths) do
                totalWeight = totalWeight + (path_data.weight or 1);
                table.insert(path_options, { location = destination, path_name = path_name, totalWeight = totalWeight, path = path_data});
            end
        end
    end

    if totalWeight == 0 then
        totalWeight = totalWeightWithAvoids;
        path_options = path_options_with_avoids;
    end

    if totalWeight == 0 then
        return nil, nil;
    end

    local randomValue = math.random(0, totalWeight)
    for _, path_data in ipairs(path_options) do
        if path_data.totalWeight >= randomValue then
            return path_data.location, path_data.path_name;
        end
    end

    return nil, nil;
end

--- Assigns a route to a patrol unit.
--- @param self PatrolEngine
--- @param object GameObject_patrol
function PatrolEngine:GiveRoute(object)
    local destination, path = self:GetRandomRouteFrom(object._patrol.location, object._patrol.prior_location and {object._patrol.prior_location} or nil)

    if destination and path then
        object._patrol.prior_location = object._patrol.location
        object._patrol.location = destination
        object._patrol.timeout = math.random() * 5 + 1
        object._patrol.path = path
        object._patrol.busy = false
        object:Goto(path)
    end
end

--- Adds a handle to the patrol units.
--- @param self PatrolEngine
--- @param object GameObject
function PatrolEngine:AddGameObject(object)
    if gameobject.IsGameObject(object) == false then
        error("object is not a GameObject");
    end
    --- @cast object GameObject
    object = customsavetype.Cast(object, "GameObject");
    if object == nil then
        error("object is not a GameObject");
    end

    --- @cast object GameObject_patrol
    local nearestLocation = nil
    local location = nil
    local pos = object:GetPosition()

    -- find the closest start location via checking each path's start point's distance
    -- note this uses 3D distance
    for source, destination_data in pairs(self.graph) do
        for destination, path_data in pairs(destination_data) do
            for path_name, _ in pairs(path_data) do
                local path_start_pos = GetPosition(path_name, 0)
                if not nearestLocation or Length(path_start_pos - pos) < Length(pos - nearestLocation) then
                    nearestLocation = path_start_pos;
                    location = source;
                end
            end
        end
    end

    object._patrol = {
        --handle = handle,
        location = location,
        prior_location = nil,
        timeout = 1,
        path = nil,
        busy = false
    };
    self.patrol_units[object] = true;
    self:GiveRoute(object)
end

--- Gets a list of keys from a table.
--- @param t table
--- @return any[]
local function keylist(t)
    local r = {};
    for k,_ in pairs(t) do
        table.insert(r, k);
    end
    return r;
end

--- Gets all patrol unit handles.
--- @param self PatrolEngine
--- @return table
function PatrolEngine:GetGameObjects()
    return keylist(self.patrol_units);
end

--- Removes a handle from the patrol units.
--- @param self PatrolEngine
--- @param object GameObject
function PatrolEngine:RemoveGameObject(object)
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
--- @return table<string, table<string, table<PathName, PathDescription>>> graph
--- @return GameObject[] patrol_units
--- @return boolean forcedAlert
function PatrolEngine:Save()
    --- @type GameObject[]
    local kl = keylist(self.patrol_units);
    return self.graph, kl, self.forcedAlert
end

--- Load event function.
---
--- {INTERNAL USE}
--- @param graph table<string, table<string, table<PathName, PathDescription>>>
--- @param patrol_units GameObject[]
--- @param forcedAlert boolean
--- @return PatrolEngine
function PatrolEngine.Load(graph, patrol_units, forcedAlert)
    return Construct(graph, patrol_units, forcedAlert)
end

--- Updates the patrol controller.
--- @param self PatrolEngine
--- @param dtime number
local function update(self, dtime)
    for unit, _ in pairs(self.patrol_units) do
        unit._patrol.timeout = unit._patrol.timeout - dtime;
        if unit._patrol.timeout <= 0 then
            local nearestEnemy = unit:GetNearestEnemy();
            local currentCommand = unit:GetCurrentCommand();

            if self.forcedAlert then
                if currentCommand ~= AiCommand.ATTACK and nearestEnemy and nearestEnemy:IsAlive() and unit:IsWithin(nearestEnemy, 125) then
                    unit:Attack(nearestEnemy);
                    unit._patrol.busy = true;
                end
            end

            if not unit._patrol.busy and currentCommand == AiCommand.NONE then
                self:GiveRoute(unit);
            elseif unit._patrol.busy and currentCommand == AiCommand.NONE then
                unit._patrol.busy = false;
                unit:Goto(unit._patrol.path);
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
            manager:RemoveGameObject(object);
        end
    end
end, config.lock().hook_priority.DeleteObject.Patrol);

customsavetype.Register(PatrolEngine);

logger.print(logger.LogLevel.DEBUG, nil, "_patrol Loaded");

return M;

--- @class PatrolData
--- @field busy boolean
--- @field timeout number
--- @field path string?
--- @field location string?
--- @field prior_location string?

--- @class GameObject_patrol : GameObject
--- @field _patrol PatrolData