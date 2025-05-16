--- BZ98R LUA Extended API Patrol Engine.
---
--- Patrol Engine
---
--- @module '_patrol'
--- @author John "Nielk1" Klein
--- @author Janne Trollebø
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

local PatrolEngine_MT -- Forward declaration of the class

local M = {}


local PatrolManagerWeakList_MT = {};
PatrolManagerWeakList_MT.__mode = "k";
local PatrolManagerWeakList = setmetatable({}, PatrolManagerWeakList_MT);




--- Called when an object is added.
--- @param path_map table<string, table>
--- @param patrol_units table<GameObject, table>
--- @param locations table<string>
--- @param forcedAlert boolean
--- @return PatrolEngine
local function Construct(path_map, patrol_units, locations, forcedAlert)
    local self = setmetatable({}, PatrolEngine_MT)
    self.path_map = path_map
    self.patrol_units = patrol_units
    self.locations = locations
    self.forcedAlert = forcedAlert
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
--- @field patrol_units table<GameObject, table>
--- @field locations table<string>
--- @field forcedAlert boolean
local PatrolEngine = {}
local PatrolEngine_MT = {}
PatrolEngine_MT.__type = "PatrolEngine"
PatrolEngine.__index = PatrolEngine




--- Checks if the controller is alive.
--- @param self PatrolEngine
--- @return boolean
function PatrolEngine_MT.isAlive(self)
    return true
end

--- Registers a location.
--- @param self PatrolEngine
--- @param locationName string
function PatrolEngine_MT.registerLocation(self, locationName)
    self.path_map[locationName] = {}
    table.insert(self.locations, locationName)
end

--- Registers multiple locations.
--- @param self PatrolEngine
--- @param locations string[]
function PatrolEngine_MT.registerLocations(self, locations)
    for _, location in pairs(locations) do
        PatrolEngine.registerLocation(self, location)
    end
end

--- Connects paths between locations.
--- @param self PatrolEngine
--- @param startpoint string
--- @param path string
--- @param endpoint string
function PatrolEngine_MT._connectPaths(self, startpoint, path, endpoint)
    table.insert(self.path_map[startpoint], { path = path, location = endpoint })
end

--- Defines routes for a location.
--- @param self PatrolEngine
--- @param location string
--- @param routes table<string, string>
function PatrolEngine_MT.defineRoutes(self, location, routes)
    for path, endpoint in pairs(routes) do
        PatrolEngine._connectPaths(self, location, path, endpoint)
    end
end

--- Gets a random route for a location.
--- @param self PatrolEngine
--- @param location string
--- @return table
function PatrolEngine_MT.getRandomRoute(self, location)
    if #self.path_map[location] < 2 then
        return self.path_map[location][1]
    end
    local randomIndex = math.random(1, #self.path_map[location])
    return self.path_map[location][randomIndex]
end

--- Assigns a route to a patrol unit.
--- @param self PatrolEngine
--- @param handle GameObject
function PatrolEngine_MT.giveRoute(self, handle)
    local unit = self.patrol_units[handle]
    local route = PatrolEngine.getRandomRoute(self,unit.location)
    local attempts = 0

    while route and route.location == unit.oldLocation and #self.path_map[unit.location] > 1 do
        route = PatrolEngine.getRandomRoute(self,unit.location)
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
--- @param self PatrolEngine
--- @param handle GameObject
--- @function addGameObject
function PatrolEngine_MT.addGameObject(self, handle)
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
    PatrolEngine.giveRoute(self,handle)
end

--- Gets all patrol unit handles.
--- @param self PatrolEngine
--- @return table
function PatrolEngine_MT.getGameObjects(self)
    return self.patrol_units
end

--- Removes a handle from the patrol units.
--- @param self PatrolEngine
--- @param handle GameObject
local function removeGameObject(self, handle)
    self.patrol_units[handle] = nil
end

-- INTERNAL USE.
-- @param self PatrolController instance
-- @return ...
function PatrolEngine_MT.Save(self)
    return self.path_map, self.patrol_units, self.locations, self.forcedAlert
end

--- Load event function.
--
-- INTERNAL USE.
-- @param patrol_units table
-- @param locations table
-- @param path_map table
-- @param forcedAlert boolean
function PatrolEngine_MT.Load(patrol_units, locations, path_map, forcedAlert)
    return Construct(path_map, patrol_units, locations, forcedAlert)
end

--- Updates the patrol controller.
--- @param self PatrolEngine
--- @param dtime number
local function update(self, dtime)
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
                PatrolEngine.giveRoute(self, handle)
            elseif unit.busy and currentCommand == AiCommand["NONE"] then
                unit.busy = false
                handle:Goto(unit.path)
            end
        end
    end
end

hook.Add("Update", "_patrol_Update", function(dtime, ttime)
    for manager, _ in pairs(PatrolManagerWeakList) do
        if manager then
            update(manager, dtime);
        end
    end
end, config.get("hook_priority.Update.Patrol"));

hook.Add("DeleteObject", "_patrol_DeleteObject", function(object)
    for manager, _ in pairs(PatrolManagerWeakList) do
        if manager then
            removeGameObject(manager, object);
        end
    end
end, config.get("hook_priority.DeleteObject.Patrol"));


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


customsavetype.Register(PatrolEngine);

debugprint("_patrol Loaded");

return M