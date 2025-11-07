--- BZ98R LUA Extended API Optional loader.
---
--- Load a lua module optionally.
---
--- @module '_optional'
--- @author John "Nielk1" Klein
--- ```lua
--- local optional = require("_optional");
--- local missingSuccess, missingMod = optional("_missing");
--- missingMod = missingSuccess and missingMod or nil;
--- 
--- local missing2Success, missingMod2 = require("_optional")("_missing2");
--- missingMod2 = missing2Success and missingMod2 or nil;
--- ```


local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_optional Loading");

--- @class _optional
local M = {};

-- [[START_IGNORE]]
M.__index = M;
-- [[END_IGNORE]]

local KnownFailedModules = {};

--- Attempt to load a module, if it fails return false and error, if succesful return true and the module.
--- @param table table The module table itself.
--- @param moduleName string Module name to load.
--- @return boolean success True if the module loaded successfully, false if it failed.
--- @return any ... The module return values or error string if failed
M.__call = function(table, moduleName)
    local priorError = KnownFailedModules[moduleName];
    if priorError ~= nil then
        return false, priorError;
    end
    local ok, result = pcall(require, moduleName);
    if not ok then
        KnownFailedModules[moduleName] = result;
    end
    return ok, result;
end

M = setmetatable(M, M);

--- @section Utility - Core

logger.print(logger.LogLevel.DEBUG, nil, "_optional Loaded");

return M;