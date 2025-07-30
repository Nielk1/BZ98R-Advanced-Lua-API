--- BZ98R LUA Extended API Optional loader.
---
--- Load a lua module optionally.
---
--- @module '_optional'
--- @author John "Nielk1" Klein
--- @usage local optional = require("_optional");
--- local missingSuccess, missingMod = optional("_missing");
--- missingMod = missingSuccess and missingMod or nil;
--- 
--- local missing2Success, missingMod2 = require("_optional")("_missing2");
--- missingMod2 = missing2Success and missingMod2 or nil;


local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_optional Loading");

local M = {};
local M_MT = {};

M_MT.__index = function(table, key)
    local retVal = rawget(table, key);
    if retVal ~= nil then
        return retVal; -- found in table
    end
    return rawget(M_MT, key); -- move on to base (looking for functions)
end

local KnownFailedModules = {};

--- __call
--- @function __call
--- Attempt to load a module, if it fails return false and error, if succesful return true and the module.
--- @param table table The module table itself.
--- @param moduleName string Module name to load.
--- @treturn boolean success True if the module loaded successfully, false if it failed.
--- @return ... The module return values or error if failed
M_MT.__call = function(table, moduleName)
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

M = setmetatable(M, M_MT);

-------------------------------------------------------------------------------
-- Utility - Core
-------------------------------------------------------------------------------
-- @section

logger.print(logger.LogLevel.DEBUG, nil, "_optional Loaded");

return M;