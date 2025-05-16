--- BZ98R LUA Extended API Patrol Engine.
---
--- Patrol Engine
---
--- @module '_patrol'
--- @author John "Nielk1" Klein
--- @usage local statemachine = require("_patrol");


--- @diagnostic disable-next-line: undefined-global
local debugprint = debugprint or function(...) end;

debugprint("_patrol Loading");

require("_fix");
local utility = require("_utility");
local config = require("_config");
local _api = require("_api");
local hook = require("_hook");
local customsavetype = require("_customsavetype");
local gameobject = require("_gameobject");

local M = {}
M.__index = M

--- @class PatrolController
--- @field path_map table<string, table>
--- @field patrol_units table<GameObject, table>
--- @field locations table<string>
--- @field forcedAlert boolean

--- Constructor for PatrolController
--- @return PatrolController
function M.new()
    local self = setmetatable({}, M)
    self.path_map = {}
    self.patrol_units = {}
    self.locations = {}
    self.forcedAlert = false
    return self
end

--- Called when an object is deleted.
--- @param self PatrolController
--- @param handle GameObject
function M.onDeleteObject(self, handle)
    M.removeHandle(self, handle)
end

--- Checks if the controller is alive.
--- @param self PatrolController
--- @return boolean
function M.isAlive(self)
    return true
end

--- Registers a location.
--- @param self PatrolController
--- @param locationName string
function M.registerLocation(self, locationName)
    self.path_map[locationName] = {}
    table.insert(self.locations, locationName)
end

--- Registers multiple locations.
--- @param self PatrolController
--- @param locations string[]
function M.registerLocations(self, locations)
    for _, location in pairs(locations) do
        M.registerLocation(self, location)
    end
end

--- Connects paths between locations.
--- @param self PatrolController
--- @param startpoint string
--- @param path string
--- @param endpoint string
function M._connectPaths(self, startpoint, path, endpoint)
    table.insert(self.path_map[startpoint], { path = path, location = endpoint })
end

--- Defines routes for a location.
--- @param self PatrolController
--- @param location string
--- @param routes table<string, string>
function M.defineRoutes(self, location, routes)
    for path, endpoint in pairs(routes) do
        M._connectPaths(self, location, path, endpoint)
    end
end

--- Gets a random route for a location.
--- @param self PatrolController
--- @param location string
--- @return table
function M.getRandomRoute(self, location)
    if #self.path_map[location] < 2 then
        return self.path_map[location][1]
    end
    local randomIndex = math.random(1, #self.path_map[location])
    return self.path_map[location][randomIndex]
end

--- Assigns a route to a patrol unit.
--- @param self PatrolController
--- @param handle GameObject
function M.giveRoute(self, handle)
    local unit = self.patrol_units[handle]
    local route = M.getRandomRoute(self,unit.location)
    local attempts = 0

    while route and route.location == unit.oldLocation and #self.path_map[unit.location] > 1 do
        route = M.getRandomRoute(self,unit.location)
        attempts = attempts + 1
        if attempts > 10 then
            break
        end
    end

    if route then
        unit.oldLocation = unit.location
        unit.location = route.location
        unit.timeout = math.random() * 5 + 1
        unit.path = route.path
        unit.busy = false
        handle:Goto(route.path)
    end
end

--- Adds a handle to the patrol units.
--- @param self PatrolController
--- @param handle GameObject
--- @function addGameObject
function M.addGameObject(self, handle)
    local nearestLocation = nil
    local location = nil
    local pos = handle:GetPosition()

    for _, loc in pairs(self.locations) do
        local locPos = GetPosition(loc)
        if not nearestLocation or Length(locPos - pos) < Length(pos - nearestLocation) then
            nearestLocation = locPos
            location = loc
        end
    end

    self.patrol_units[handle] = {
        handle = handle,
        location = location,
        oldLocation = nil,
        timeout = 1,
        path = nil,
        busy = false
    }
    M.giveRoute(self,handle)
end

--- Gets all patrol unit handles.
--- @param self PatrolController
--- @return table
function M.getHandles(self)
    return self.patrol_units
end

--- Removes a handle from the patrol units.
--- @param self PatrolController
--- @param handle GameObject
function M.removeHandle(self, handle)
    self.patrol_units[handle] = nil
end

--- Saves the state of the controller.
--- @param self PatrolController
--- @return table, table, table, boolean
function M.save(self)
    return self.patrol_units, self.locations, self.path_map, self.forcedAlert
end

--- Loads the state of the controller.
--- @param self PatrolController
--- @param patrol_units table
--- @param locations table
--- @param path_map table
--- @param forcedAlert boolean
function M.load(self, patrol_units, locations, path_map, forcedAlert)
    self.patrol_units = patrol_units
    self.locations = locations
    self.path_map = path_map
    self.forcedAlert = forcedAlert
end

--- Updates the patrol controller.
--- @param self PatrolController
--- @param dtime number
function M.update(self, dtime)
    for handle, unit in pairs(self.patrol_units) do
        unit.timeout = unit.timeout - dtime
        if unit.timeout <= 0 then
            local nearestEnemy = gameobject.FromHandle(GetNearestEnemy(handle:GetHandle()))
            local currentCommand = handle:GetCurrentCommand()

            if self.forcedAlert then
                if currentCommand ~= AiCommand["ATTACK"] and nearestEnemy:IsAlive() and handle:IsWithin(nearestEnemy, 125) then
                    handle:Attack(nearestEnemy)
                    unit.busy = true
                end
            end

            if not unit.busy and currentCommand == AiCommand["NONE"] then
                M.giveRoute(self, handle)
            elseif unit.busy and currentCommand == AiCommand["NONE"] then
                unit.busy = false
                handle:Goto(unit.path)
            end
        end
    end
end

hook.Add("Update", "_patrol_Update", function(dtime, ttime)
end, 4999);

hook.Add("CreateObject", "_patrol_CreateObject", function(object, isMapObject)
end, 4999);

-- --- Initializes the patrol controller.
-- --- @param self PatrolController
-- --- @param handles table
-- --- @param forcedAlert boolean
-- function M.onInit(self, handles, forcedAlert)
--     for _, handle in pairs(handles or {}) do
--         M.addGameObject(self, handle)
--     end
--     self.forcedAlert = not not forcedAlert
-- end

M.__type = "PatrolController"

customsavetype.Register(M);

debugprint("_patrol Loaded");

return M