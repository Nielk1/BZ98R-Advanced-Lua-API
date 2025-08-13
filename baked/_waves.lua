--- BZ98R LUA Extended API Wave Spawner.
---
--- Wave Spawner
---
--- @module '_waves'
--- @author John "Nielk1" Klein
--- @author Janne Trollebø
--- @todo usage example

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_waves Loading");

local utility = require("_utility");
local config = require("_config");
local _api = require("_api");
local hook = require("_hook");
local customsavetype = require("_customsavetype");
local gameobject = require("_gameobject");
local paths = require("_paths");
local statemachine = require("_statemachine");

--- Called when a wave spawner has spawned a wave.
---
--- @diagnostic disable: undefined-doc-param
--- @hook Add CallAllNoReturn
--- @param name string The name of the wave spawner.
--- @param units GameObject[] The gameobjects that were spawned.
--- @param leader GameObject The leader gameobject.
--- @diagnostic disable-next-line: luadoc-miss-type-name
--- @alias WaveSpawner:Spawned fun(name: string, units: GameObject[], leader: GameObject)
--- @diagnostic enable: undefined-doc-param

--- @class _waves
local M = {}

--- @class WaveSpawner : StateMachineIter
--- @field name string The name of the wave spawner. "WaveSpawner:Spawned" event fired
--- @field frequency number The frequency of waves.
--- @field variance number The variance of wave frequency.
--- @field wait_time number The time to wait before the next wave.
--- @field factions table OLD: A list of factions from which a random will be selected.
--- @field locations table OLD: A list of locations where waves can spawn, considered if the name is not the same as a faction name, or it is the same as a selected faction.
--- @field wave_types table OLD: Array of weighted formation tables
--- @field waves_left number The number of waves left to spawn.
local WaveSpawner = {};

WaveSpawner.__index = function(tbl, key)
    -- local table takes priority
    local retVal = rawget(tbl, key);
    if retVal ~= nil then
        return retVal;
    end

    -- next check the metatable
    local mt = getmetatable(tbl)
    -- Check for method/property in this metatable
    local retVal = mt and rawget(mt, key)
    if retVal ~= nil then
        return retVal
    end

    -- next check the base metatable
    local __base = rawget(tbl, "__base")
    --if __base and __base.__index then
    --    return __base.__index(__base, key)
    --end
    if __base and __base[key] ~= nil then
        return __base[key]
    end

    return nil;
end
WaveSpawner.__newindex = function(tbl, key, value)
    --if key ~= "magic" then
    --else
    --    rawset(tbl, key, value);
    --end

    -- Call base class's __newindex if it exists
    -- This is correct as we store custom data in the base class's addonData subtable
    -- Our top level is only good for functions, nothing else
    local mt = getmetatable(tbl)
    local __base = mt and rawget(mt, "__base")
    if __base and __base.__newindex then
        return __base.__newindex(tbl, key, value)
    end

    -- fallback: rawset if base doesn't handle it
    rawset(tbl, key, value)
end

WaveSpawner.__type = "WaveSpawner";


local WaveSpawnerManagerWeakList_MT = {}
WaveSpawnerManagerWeakList_MT.__mode = "k"
--- @type table<WaveSpawner, boolean>
local WaveSpawnerManagerWeakList = setmetatable({}, WaveSpawnerManagerWeakList_MT)

local isIn
isIn = function(element, list)
  for _index_0 = 1, #list do
    local e = list[_index_0]
    if e == element then
      return true
    end
  end
  return false
end






--- Spawns units in a specified formation at a location, facing a direction.
--- @param formation string[]                    Array of strings, each string is a row, numbers are unit indices in 'units'
--- @param location Vector|string|PathWithIndex  Center position of the formation
--- @param dir Vector?                           Direction the formation faces (forward)
--- @param units string[]                        List of unit ODFs, indexed by number in formation
--- @param team TeamNum                          Team to assign units to
--- @param seperation integer?                   Distance between units (optional, default 10)
--- @return GameObject[] units
--- @return GameObject? leader
function M.SpawnInFormation(formation, location, dir, units, team, seperation)
    seperation = seperation or 10

    --- @type Vector?
    local locationVector = nil;
    if utility.isVector(location) then
        --- @cast location Vector
        locationVector = location;
    elseif utility.isstring(location) then
        --- @cast location string
        local pathSize = GetPathPointCount(location);
        if pathSize <= 0 then
            error("path index is out of bounds");
        end
        locationVector = GetPosition(location, 0);
        if not dir then
            -- If no direction is given, use the next point in the path to determine direction
            if pathSize <= 1 then
                error("path index for direction is out of bounds");
            end
            local pos2 = GetPosition(location, 1);
            dir = pos2 - locationVector;
        end
    elseif paths.isPathWithString(location) then
        --- @cast location PathWithIndex
        local pathSize = GetPathPointCount(location[1]);
        if pathSize <= location[2] then
            error("path index is out of bounds");
        end
        locationVector = GetPosition(location[1], location[2]);
        if not dir then
            -- If no direction is given, use the next point in the path to determine direction
            if pathSize <= (location[2] + 1) then
                error("path index for direction is out of bounds");
            end
            local pos2 = GetPosition(location[1], location[2] + 1);
            dir = pos2 - locationVector;
        end
    else
        error("location must be a Vector, string, or PathWithIndex");
    end

    if dir ~= nil and not utility.isVector(dir) then
        error("dir must be a Vector or nil if derived from path");
    end

    if not utility.istable(units) or #units == 0 or #units > 9 then
        error("units must be a non-empty array of no more than 9 unit ODFs");
    end

    --- @cast dir Vector
    dir = Normalize(dir);

    local spawnedUnits = {};
    local leadUnit = nil;

    -- Calculate normalized forward and right vectors for the formation
    local forward = Normalize(SetVector(dir.x, 0, dir.z));
    local right = Normalize(SetVector(-dir.z, 0, dir.x));

    for rowIndex, row in ipairs(formation) do
        local rowLength = row:len();
        local colIndex = 1;

        -- Iterate over each character in the row string
        for char in row:gmatch(".") do
            local unitIdx = tonumber(char);
            if unitIdx then
                -- Calculate position offset for this unit
                -- X: left/right offset, centered on row
                -- Z: forward offset, each row is further forward
                local xOffset = (colIndex - (rowLength / 2)) * seperation;
                local zOffset = rowIndex * seperation * 2;
                
                -- Final position = locationVector + (right * xOffset) - (forward * zOffset)
                local pos = xOffset * right + -zOffset * forward + locationVector;

                -- Spawn the unit
                local h = gameobject.BuildObject(units[unitIdx], team, pos);
                if not h then error("Failed to build object " .. units[unitIdx] .. " at " .. tostring(pos)) end

                -- Set the unit's facing direction
                local t = BuildDirectionalMatrix(h:GetPosition(), forward);
                h:SetTransform(t);

                -- First unit spawned becomes the 'lead'
                if not leadUnit then
                    leadUnit = h;
                end

                table.insert(spawnedUnits, h);
            end
            colIndex = colIndex+1;
        end
    end

    return spawnedUnits, leadUnit;
end

--- @todo move these out of this module as some are mod items
local units = {
    nsdf = {"avfigh","avtank","avrckt","avhraz","avapc","avwalk", "avltnk"},
    cca = {"svfigh","svtank","svrckt","svhraz","svapc","svwalk", "svltnk"},
    fury = {"hvsat","hvngrd"}
};

--- Spawns a wave of units.
--- @param name string
--- @param wave_table table
--- @param faction string
--- @param location string
--- @return table
local function spawnWave(name, wave_table, faction, location)
    print("Spawn Wave", wave_table, faction, location)
    local units, lead = M.SpawnInFormation(wave_table, ("%s_wave"):format(location), nil, units[faction], 2)
    for _, v in pairs(units) do
        if v == lead then
            v:Goto(("%s_path"):format(location));
        else
            if lead then
                v:Follow(lead);
            else
                v:Goto(("%s_path"):format(location));
            end
        end
    end
    hook.CallAllNoReturn("WaveSpawner:Spawned", name, units, lead)
    return units
end


statemachine.Create("_waves:machine",
    { "setup", function (state)
        --- @cast state WaveSpawner

        -- Calculate next spawn time with variance
        local next_spawn = (1 / state.frequency);
        next_spawn = next_spawn + next_spawn * (math.random() - 0.5) * state.variance;
        state.wait_time = next_spawn;

        state:next();
        return statemachine.FastResult();
    end },
    { "waiting", function (state)
        --- @cast state WaveSpawner
        if state:SecondsHavePassed(state.wait_time, true, false) then
            state:next();
            return statemachine.FastResult();
        end
    end },
    { "spawning", function (state)
        --- @cast state WaveSpawner

        -- Choose a unit list (e.g., a faction name) at random
        local unit_list_name = utility.ChooseOne(unpack(state.factions))

        -- Build a list of valid spawn locations for this wave
        local valid_locations = {}
        for _, location_name in pairs(state.locations) do
            -- If the location is NOT a unit list name, it's always valid.
            -- If the location IS a unit list name, it's only valid if it matches the chosen unit list.
            if (not isIn(location_name, state.factions)) or (unit_list_name == location_name) then
                table.insert(valid_locations, location_name)
            end
        end

        -- Pick a random valid location
        local chosen_location = utility.ChooseOne(unpack(valid_locations))

        -- Pick a random wave type (weighted random)
        local wave_type = utility.ChooseOneWeighted(unpack(state.wave_types))

        -- Spawn the wave using the chosen parameters
        spawnWave(state.name, wave_type, unit_list_name, chosen_location)

        state.waves_left = state.waves_left - 1

        if state.waves_left <= 0 then
            state:switch(nil);
            return;
        end
        state:switch("setup");
    end });

--- Constructs a new WaveSpawner instance.
--- @param machine StateMachineIter
--- @return WaveSpawner
local function Construct(machine)
    local spawner = setmetatable({ __base = machine }, WaveSpawner);
    WaveSpawnerManagerWeakList[spawner] = true
    return spawner;
end

--- Creates a new WaveSpawner instance.
--- @param name string
--- @param factions table
--- @param locations table
--- @param wave_frequency number
--- @param waves_left number
--- @param variance number
--- @param wave_types table
--- @return WaveSpawner
function M.new(name, factions, locations, wave_frequency, waves_left, variance, wave_types)
    local machine = statemachine.Start("_waves:machine", nil, {
        name = name,
        frequency = wave_frequency or 30,
        variance = variance or 0,
        wait_time = 0,
        factions = factions or {},
        locations = locations or {},
        wave_types = wave_types or {},
        waves_left = waves_left or 0
    });
    return Construct(machine)
end


--- Checks if the WaveSpawner is alive. (Has waves left to spawn)
--- @param self WaveSpawner
--- @return boolean
function WaveSpawner.IsAlive(self)
    return self.waves_left > 0
end

--- Saves the WaveSpawner state.
--- {INTERNAL USE}
--- @param self WaveSpawner
--- @return table StateMachineIter
function WaveSpawner:Save(self)
    return self.base;
end

--- Loads the WaveSpawner state.
--- {INTERNAL USE}
--- @param machine StateMachineIter
--- @return WaveSpawner
function WaveSpawner.Load(machine)
    local retVal = Construct(machine);
    return retVal;
end

local strong_list = nil;

hook.Add("Update", "_waves:Update", function(dtime, ttime)
    for manager, _ in pairs(WaveSpawnerManagerWeakList) do
        if manager then
            manager:run();
        end
    end
end, config.get("hook_priority.Update.WaveSpawner"));

hook.AddSaveLoad("_waves",
    function()
        local ret = {};
        for k, _ in pairs(WaveSpawnerManagerWeakList) do
            if k then
                table.insert(ret, k);
            end
        end
        return ret;
    end,
    function(state)
        strong_list = state or {};
        
        for k, v in pairs(strong_list) do
            if not WaveSpawnerManagerWeakList[k] then
                WaveSpawnerManagerWeakList[k] = v;
                table.insert(strong_list, k);
            end
        end 
    end,
    function()
        strong_list = nil;
    end)

logger.print(logger.LogLevel.DEBUG, nil, "_waves Loaded");

return M;