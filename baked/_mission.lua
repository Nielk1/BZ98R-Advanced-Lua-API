--- BZ98R LUA Extended API Mission Data.
---
--- Test
---
--- @module '_mission'
--- @author John "Nielk1" Klein

local logger = require("_logger");
local bzn = require("_bzn");
local paramdb = require("_paramdb");

logger.print(logger.LogLevel.DEBUG, nil, "_mission Loading");

--- @class _mission
--- @field Bzn FileReferenceBZN?
--- @field MissionClass MissionClass?
--- @field MapModType ModType? Type of mod the map is a part of if found (set to override)
--- @field MapType MapType? Type of map if multiplayer (set to override)
--- @field CampaignIndex integer? Index of the campaign mission if part of a campaign (set to override, 0 or less to clear)
--- @field MissionType MapBaseType? Type of map based on the Mission Class logic
local M = {};

--- @type FileReferenceBZN?
local bznFile = nil;

--- @type boolean
local bznFileAttempted = false;

--- Try to load the BZN file for the current mission.
--- {INTERNAL USE}
local function TryLoadBZNFile()
    if not bznFileAttempted then
        bznFileAttempted = true;
        bznFile = bzn.Open(GetMissionFilename());
    end
end

--- @enum MapBaseType
M.MapBaseType = {
    Deathmatch    = "D", -- Deathmatch
    KingOfTheHill = "K", -- King of the Hill
    Strategy      = "S", -- Strategy
    Single        = "*", -- Single Player
};

--- @enum ModType
M.ModTypes = {
    Multiplayer   = "multiplayer",
    InstantAction = "instant_action",
    Campaign      = "campaign",
    Mod           = "mod",
};

--- @enum MapType
M.MapTypes = {
    Action        = "A", -- Action
    Deathmatch    = "D", -- Deathmatch
    KingOfTheHill = "K", -- King of the Hill
    Mission       = "M", -- Mission
    Strategy      = "S", -- Strategy
};

--- @type ModType?
local modTypeOverride = nil;

--- @type MapType?
local mapTypeOverride = nil;

--- @type integer?
local campaignIndexOverride = nil;

--- @param mapBzn string
--- @return ModType? modType Mod type if found
--- @return MapType|nil|integer mapType Map type code if multiplayer or campaign mission index if campaign
local function GetMissionTypeIndicated(mapBzn)
    -- change the .* extension to .ini if present, else just append .ini
    local mapIni = mapBzn:gsub("%.%w+$", ".ini");

    --- @todo consider how to handle stock maps if at all

    local modType = paramdb.GetValueString(mapIni, "WORKSHOP", "mapType");
    if modType == "multiplayer" then
        local gameType = paramdb.GetValueString(mapIni, "MULTIPLAYER", "gameType");
        if gameType then
            gameType = gameType:sub(1,1);
            return modType, gameType;
        end
    elseif modType == "instant_action" then
        return modType;
    end

    for i = 1, 1000 do
        --- @diagnostic disable-next-line: deprecated
        local ini, success = paramdb.GetValueString("_api.cfg", "Mission", "campaign"..tostring(i));
        if not success or not ini then
            break;
        end
        local modTypeCandidate = paramdb.GetValueString(ini, "WORKSHOP", "mapType");
        if modTypeCandidate == "campaign" then
            for j = 1, 1000 do
                local bzn, success2 = paramdb.GetValueString(ini, "MISSION"..tostring(j), "missionBZN");
                if not success2 or not bzn then
                    break;
                end
                if bzn == mapBzn then
                    return "campaign", j;
                end
            end
        end
    end

    return nil;
end

--local function GetMissionType()
--    M.MissionClass
--    return nil;
--end

local MissionClassLookup = {
    ["Inst03Mission"] = M.MapBaseType.Single,
    ["Inst04Mission"] = M.MapBaseType.Single,
    ["MultSTMission"] = M.MapBaseType.Strategy,
    ["MultDMMission"] = M.MapBaseType.Deathmatch,
    ["LuaMission"]    = M.MapBaseType.Single,
}

-- I think these are actually only used when creating a mission from nothing to set the default
--local MissionClassPathCheck = {
--    ["Inst03Mission"] = { "^play.*"   },
--    ["Inst04Mission"] = { "^UsrMsn.*" },
--}

local M_MT = {}
M_MT.__index = function(t, k)
    if k == "Bzn" then
        TryLoadBZNFile();
        return bznFile;
    end
    if k == "MissionClass" then
        TryLoadBZNFile();
        if bznFile then
            if bznFile.Mission then
                return bznFile.Mission;
            else
                -- If the game fails to construct a class it forces LuaMission
                -- We know we must be in something that supports lua right now
                -- so if the BZN did parse, and we still don't know the MissionClass
                -- it must mean it was auto-forced to LuaMission in Load
                return "LuaMission";
            end
        end
        return nil;
    end
    if k == "MapModType" then
        if modTypeOverride then
            return modTypeOverride;
        end
        local modType, _ = GetMissionTypeIndicated(GetMissionFilename());
        return modType;
    end
    if k == "MapType" then
        if mapTypeOverride then
            return mapTypeOverride;
        end
        local modType, mapType = GetMissionTypeIndicated(GetMissionFilename());
        if modType ~= M.ModTypes.Multiplayer then
            return nil;
        end
        return mapType;
    end
    if k == "CampaignIndex" then
        if campaignIndexOverride then
            if campaignIndexOverride < 1 then
                return nil;
            end
            return campaignIndexOverride;
        end
        local modType, cIndex = GetMissionTypeIndicated(GetMissionFilename());
        if modType ~= M.ModTypes.Campaign then
            return nil;
        end
        return cIndex;
    end
    if k == "MissionType" then
        TryLoadBZNFile();
        if bznFile then
            if bznFile.Mission then
                if bznFile.Mission == "MultDMMission" then
                    if bznFile.AiPaths then
                        for _, path in ipairs(bznFile.AiPaths) do
                            if path.label and path.label:sub(1, 4) == "king" then
                                return M.MapBaseType.KingOfTheHill;
                            end
                        end
                    end
                    return M.MapBaseType.Deathmatch;
                else
                    return MissionClassLookup[bznFile.Mission];
                end
            end
        end
        return nil;
    end
    return rawget(t, k);
end
M_MT.__newindex = function(t, k, v)
    if k == "Bzn" or k == "MissionClass" then
        error(k.." is read-only");
    end
    if k == "MapModType" then
        modTypeOverride = v;
        return;
    end
    if k == "MapType" then
        mapTypeOverride = v;
        return;
    end
    if k == "CampaignIndex" then
        campaignIndexOverride = v;
        return;
    end
    if k == "MissionType" then
        error("MissionType is read-only");
    end

    rawset(t, k, v);
end

setmetatable(M, M_MT);

logger.print(logger.LogLevel.DEBUG, nil, "_mission Loaded");

return M;