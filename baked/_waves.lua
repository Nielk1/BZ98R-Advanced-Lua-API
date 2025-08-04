--- BZ98R LUA Extended API Wave Spawner.
---
--- Wave Spawner
---
--- @module '_waves'
--- @author John "Nielk1" Klein
--- @author Janne Trollebø
--- @usage local waves = require("_waves");

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_waves Loading");

local utility = require("_utility");
local config = require("_config");
local _api = require("_api");
local hook = require("_hook");
local customsavetype = require("_customsavetype");
local gameobject = require("_gameobject");
local paths = require("_paths");

--- Called when a wave spawner has spawned a wave.
--
-- Call method: @{_hook.CallAllNoReturn|CallAllNoReturn}
--
-- @event WaveSpawner:Spawned
-- @param name string The name of the wave spawner.
-- @param units GameObject[] The gameobjects that were spawned.
-- @param leader GameObject The leader gameobject.
-- @see _hook.Add

local M = {}

local WaveSpawnerManagerWeakList_MT = {}
WaveSpawnerManagerWeakList_MT.__mode = "k"
local WaveSpawnerManagerWeakList = setmetatable({}, WaveSpawnerManagerWeakList_MT)

local WaveSpawner;

local function choose(...)
    local t = {...};
    local rn = math.random(#t);
    return t[rn];
end

local function chooseA(...)
    local t = {...};
    local m = 0;
    for i, v in pairs(t) do
        m = m + v.chance; 
    end
    local rn = math.random()*m;
    local n = 0;
    for i, v in ipairs(t) do
        if (v.chance+n) > rn then
        return v.item;
        end
        n = n + v.chance;
    end
end

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
--- @param formation string[]                       -- Array of strings, each string is a row, numbers are unit indices in 'units'
--- @param location Vector|string|PathWithIndex     -- Center position of the formation
--- @param dir Vector?                              -- Direction the formation faces (forward)
--- @param units string[]                           -- List of unit ODFs, indexed by number in formation
--- @param team TeamNum                             -- Team to assign units to
--- @param seperation integer?                      -- Distance between units (optional, default 10)
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

--- Constructs a new WaveSpawner instance.
--- @param name string
--- @param factions table
--- @param locations table
--- @param wave_frequency number
--- @param waves_left number
--- @param variance number
--- @param wave_types table
--- @return WaveSpawner
local function Construct(name, factions, locations, wave_frequency, waves_left, variance, wave_types)
    local self = {}
    self.name = name;
    self.factions = factions or {}
    self.locations = locations or {}
    self.waves_left = waves_left or 0
    self.wave_frequency = wave_frequency or 0
    self.timer = 0
    self.variance = variance or 0
    --self.c_variance = 0
    local f = self.wave_frequency * self.variance
    self.c_variance = f + 2 * f * math.random()
    self.wave_types = wave_types or {}
    self = setmetatable(self, { __index = WaveSpawner })
    WaveSpawnerManagerWeakList[self] = true
    return self;
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
    return Construct(name, factions, locations, wave_frequency, waves_left, variance, wave_types)
end

--- @class WaveSpawner : CustomSavableType
--- @field name string
--- @field waves_left number
--- @field wave_frequency number
--- @field timer number
--- @field variance number
--- @field c_variance number
--- @field wave_types table
--- @field factions table
--- @field locations table
local WaveSpawner = { __type = "WaveSpawner" }

--- Checks if the WaveSpawner is alive.
--- @param self WaveSpawner
--- @return boolean
function WaveSpawner.IsAlive(self)
    return self.waves_left > 0
end

--- Saves the WaveSpawner state.
--- 
--- INTERNAL USE.
--- @param self WaveSpawner
--- @return string, table, table, number, number, number, number, number, table
function WaveSpawner.Save(self)
    return self.name,
        self.factions,
        self.locations,
        self.wave_frequency,
        self.waves_left,
        self.timer,
        self.variance,
        self.c_variance,
        self.wave_types
end

--- Loads the WaveSpawner state.
--- 
--- INTERNAL USE.
--- @param name string
--- @param factions table
--- @param locations table
--- @param wave_frequency number
--- @param waves_left number
--- @param timer number
--- @param variance number
--- @param c_variance number
--- @param wave_types table
function WaveSpawner.Load(name, factions, locations, wave_frequency, waves_left, timer, variance, c_variance, wave_types)
    local retVal = Construct(name, factions, locations, wave_frequency, waves_left, variance, wave_types);
    retVal.timer = timer;
    retVal.c_variance = c_variance;
    return retVal;
end

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

--- Updates the WaveSpawner.
--- Spawns a wave if enough time has passed, choosing a unit list and location.
--- @param self WaveSpawner
--- @param dtime number
local function update(self, dtime)
    -- Advance the internal timer
    self.timer = self.timer + dtime

    -- Calculate the current spawn frequency (base + variance)
    local current_frequency = self.wave_frequency + self.c_variance

    -- If enough time has passed, spawn a new wave
    if self.timer * current_frequency >= 1 then
        -- Reset timer for next wave
        self.timer = self.timer - 1 / current_frequency

        -- Recalculate variance for next wave
        local variance_base = self.wave_frequency * self.variance
        self.c_variance = variance_base + 2 * variance_base * math.random()

        -- Decrement remaining waves
        self.waves_left = self.waves_left - 1

        -- Choose a unit list (e.g., a faction name) at random
        local unit_list_name = choose(unpack(self.factions))

        -- Build a list of valid spawn locations for this wave
        local valid_locations = {}
        for _, location_name in pairs(self.locations) do
            -- If the location is NOT a unit list name, it's always valid.
            -- If the location IS a unit list name, it's only valid if it matches the chosen unit list.
            if (not isIn(location_name, self.factions)) or (unit_list_name == location_name) then
                table.insert(valid_locations, location_name)
            end
        end

        -- Pick a random valid location
        local chosen_location = choose(unpack(valid_locations))

        -- Pick a random wave type (weighted random)
        local wave_type = chooseA(unpack(self.wave_types))

        -- Spawn the wave using the chosen parameters
        spawnWave(self.name, wave_type, unit_list_name, chosen_location)
    end
end

hook.Add("Update", "_waveSpawner_Update", function(dtime, ttime)
    for manager, _ in pairs(WaveSpawnerManagerWeakList) do
        if manager then
            update(manager, dtime)
        end
    end
end)

customsavetype.Register(WaveSpawner)

logger.print(logger.LogLevel.DEBUG, nil, "_waves Loaded");

return M;