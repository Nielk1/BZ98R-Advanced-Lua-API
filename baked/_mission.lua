--- BZ98R LUA Extended API Mission Data.
---
--- Test
---
--- @module '_mission'
--- @author John "Nielk1" Klein

local logger = require("_logger");
local bzn = require("_bzn");

logger.print(logger.LogLevel.DEBUG, nil, "_mission Loading");

--- @class _mission
--- @field Bzn FileReferenceBZN?
--- @field MissionClass MissionClass?
local M = {};

local bznFile = nil;
local bznFileAttempted = false;
local function TryLoadBZNFile()
    if not bznFileAttempted then
        bznFileAttempted = true;
        bznFile = bzn.Open(GetMissionFilename());
    end
end

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
    return rawget(t, k);
end

setmetatable(M, M_MT);

logger.print(logger.LogLevel.DEBUG, nil, "_mission Loaded");

return M;