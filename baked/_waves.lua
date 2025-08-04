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
--- @param formation string[]  -- Array of strings, each string is a row, numbers are unit indices in 'units'
--- @param location Vector     -- Center position of the formation
--- @param dir Vector          -- Direction the formation faces (forward)
--- @param units string[]      -- List of unit ODFs, indexed by number in formation
--- @param team TeamNum        -- Team to assign units to
--- @param seperation integer  -- Distance between units (optional, default 10)
--- @return GameObject[] units
--- @return GameObject|nil leader
local function spawnInFormation(formation, location, dir, units, team, seperation)
    seperation = seperation or 10

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
                
                -- Final position = location + (right * xOffset) - (forward * zOffset)
                local pos = xOffset * right + -zOffset * forward + location;

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

--- @param formation string[]  -- Array of strings, each string is a row, numbers are unit indices in 'units'
--- @param location string     -- Center position of the formation
--- @param units string[]      -- List of unit ODFs, indexed by number in formation
--- @param team TeamNum        -- Team to assign units to
--- @param seperation integer  -- Distance between units (optional, default 10)
local function spawnInFormation2(formation, location, units, team, seperation)
    local pos = GetPosition(location, 0);
    if not pos then error("Failed to get position of " .. location) end
    local pos2 = GetPosition(location, 1);
    if not pos2 then error("Failed to get position of " .. location) end
    local dir = pos2 - pos;
    return spawnInFormation(formation, pos, dir, units, team, seperation);
end





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
    return self



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
    local units, lead = spawnInFormation2(wave_table, ("%s_wave"):format(location), units[faction], 2)
    for _, v in pairs(units) do
        --local s = mission.TaskManager:sequencer(v)
        if v == lead then
            --s:queue2("Goto", ("%s_path"):format(location))
            v:Goto(("%s_path"):format(location));
        else
            --s:queue2("Follow", lead)
            if lead then
                v:Follow(lead);
            else
                v:Goto(("%s_path"):format(location));
            end
        end
        --s:queue3("FindTarget", "bdog_base")
    end
    hook.CallAllNoReturn("WaveSpawner:Spawned", name, units, lead)
    return units
end

--- Updates the WaveSpawner.
--- @param self WaveSpawner
--- @param dtime number
local function update(self, dtime)
    self.timer = self.timer + dtime
    local freq = self.wave_frequency + self.c_variance
    if self.timer * freq >= 1 then
        self.timer = self.timer - 1 / freq
        local f = self.wave_frequency * self.variance
        self.c_variance = f + 2 * f * math.random()
        self.waves_left = self.waves_left - 1

        local fac = choose(unpack(self.factions))
        local locations = {}
        for _, v in pairs(self.locations) do
            if (not isIn(v, self.factions)) or (isIn(v, self.factions) and fac == v) then
                table.insert(locations, v)
            end
        end
        local location = choose(unpack(locations))
        local w_type = chooseA(unpack(self.wave_types))
        spawnWave(self.name, w_type, fac, location)
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

return M
