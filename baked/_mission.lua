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
--- @field ModType ModType? Type of mod the map is a part of if found, can be overridden
--- @field MapType MapType? Type of map if multiplayer, can be overridden
--- @field MissionType BaseMapType? Type of map based on the Mission Class logic
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

--- @alias BaseMapType "A"|"D"|"K"|"M"|"S"

--- @alias ModType "multiplayer"|"instant_action"|"campaign"|"mod"

--- @alias MapType BaseMapType|"B"|"C"|"E"|"F"|"G"|"H"|"I"|"J"|"L"|"N"|"O"|"P"|"Q"|"R"|"T"|"U"|"V"|"W"|"X"|"Y"|"Z"

--- @type ModType?
local modTypeOverride = nil;

--- @type MapType?
local mapTypeOverride = nil;

--- @param mapBzn string
--- @return ModType? modType Mod type if found
--- @return MapType? mapType Map type code if multiplayer
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
    elseif modType == "campaign" then
        -- how did we get a campaign ini from a map BZN?
        return nil;
    elseif modType == "mod" then
        return nil;
    end

    return nil;
end

--local function GetMissionType()
--    M.MissionClass
--    return nil;
--end

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
                -- it must mean it was auto-forced to LuaMission
                return "LuaMission";
            end
        end
    end
    if k == "ModType" then
        local modType, _ = GetMissionTypeIndicated(GetMissionFilename());
        return modTypeOverride or modType;
    end
    if k == "MapType" then
        local _, mapType = GetMissionTypeIndicated(GetMissionFilename());
        return mapTypeOverride or mapType;
    end
    if k == "MissionType" then
        TryLoadBZNFile();
        if bznFile then
            if bznFile.Mission then
                if bznFile.Mission == "MultDMMission" then
                    if bznFile.AiPaths then
                        for _, path in ipairs(bznFile.AiPaths) do
                            if path.label and path.label:sub(1, 4) == "king" then
                                return 'K';
                            end
                        end
                    end
                    return 'D';
                elseif bznFile.Mission == "MultSTMission" then
                    return 'S';
                end
            end
        end
    end
    return rawget(t, k);
end
M_MT.__newindex = function(t, k, v)
    if k == "Bzn" or k == "MissionClass" then
        error(k.." is read-only");
    end
    if k == "ModType" then
        modTypeOverride = v;
        return;
    end
    if k == "MapType" then
        mapTypeOverride = v;
        return;
    end

    rawset(t, k, v);
end

setmetatable(M, M_MT);

logger.print(logger.LogLevel.DEBUG, nil, "_mission Loaded");

return M;