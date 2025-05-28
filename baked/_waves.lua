--- BZ98R LUA Extended API Wave Spawner.
---
--- Wave Spawner
---
--- @module '_waves'
--- @author John "Nielk1" Klein
--- @author Janne Trollebø
--- @usage local waves = require("_waves");


--- @diagnostic disable-next-line: undefined-global
local debugprint = debugprint or function(...) end;

debugprint("_waves Loading");

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




--- @param formation string[]
--- @param location Vector
--- @param dir Vector
--- @param units string[]
--- @param team TeamNum
--- @param seperation integer?
--- @return GameObject[] units
--- @return GameObject|nil leader
local function spawnInFormation(formation,location,dir,units,team,seperation)
    if(seperation == nil) then
        seperation = 10;
    end
    local tempH = {};
    local lead;
    local directionVec = Normalize(SetVector(dir.x,0,dir.z));
    local formationAlign = Normalize(SetVector(-dir.z,0,dir.x));
    for i2, v2 in ipairs(formation) do
        local length = v2:len();
        local i3 = 1;
        for c in v2:gmatch(".") do
        local n = tonumber(c);
        if(n) then
            local x = (i3-(length/2))*seperation;
            local z = i2*seperation*2;
            local pos = x*formationAlign + -z*directionVec + location;
            local h = gameobject.BuildObject(units[n],team,pos);
            if not h then error("Failed to build object " .. units[n] .. " at " .. tostring(pos)) end
            local t = BuildDirectionalMatrix(h:GetPosition(),directionVec);
            h:SetTransform(t);
            if(not lead) then
                lead = h;
            end
            table.insert(tempH,h);
        end
        i3 = i3+1;
        end
    end
    return tempH, lead;
end

--- @param formation string[]
--- @param location string
--- @param units string[]
--- @param team TeamNum
--- @param seperation integer?
local function spawnInFormation2(formation,location,units,team,seperation)
    local pos = GetPosition(location,0);
    if not pos then error("Failed to get position of " .. location) end
    local pos2 = GetPosition(location,1);
    if not pos2 then error("Failed to get position of " .. location) end
    local dir = pos2 - pos;
    return spawnInFormation(formation,pos,dir,units,team,seperation);
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
function WaveSpawner.isAlive(self)
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

debugprint("_waves Loaded");

return M
