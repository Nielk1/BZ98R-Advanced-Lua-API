--- BZ98R LUA Extended API Optional loader.
---
--- Load a lua module optionally.
---
--- @module _optional
--- @author John "Nielk1" Klein
--- @alias _optional
--- @usage local optional = require("_optional");
--- local missingSuccess, missingMod = optional("_missing");
--- missingMod = missingSuccess and missingMod or nil;
--- 
--- local missing2Success, missingMod2 = require("_optional")("_missing2");
--- missingMod2 = missing2Success and missingMod2 or nil;


local debugprint = debugprint or function(...) end;

debugprint("__optional Loading");

local _optional_module = {};
local _optional_module_meta = {};

_optional_module_meta.__index = function(table, key)
    local retVal = rawget(table, key);
    if retVal ~= nil then
        return retVal; -- found in table
    end
    return rawget(_optional_module_meta, key); -- move on to base (looking for functions)
end

local KnownFailedModules = {};

--- __call
--- @function __call
--- Attempt to load a module, if it fails return false and error, if succesful return true and the module.
--- @param table table The module table itself.
--- @param moduleName string Module name to load.
--- @treturn boolean success True if the module loaded successfully, false if it failed.
--- @return The module return value or nil if failed
_optional_module_meta.__call = function(table, moduleName)
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

_optional_module = setmetatable(_optional_module, _optional_module_meta);

-------------------------------------------------------------------------------
-- Utility - Core
-------------------------------------------------------------------------------
-- @section

debugprint("__optional Loaded");

return _optional_module;