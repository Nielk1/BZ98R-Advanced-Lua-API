--- BZ98R LUA Extended API Paths.
---
--- @module '_paths'
--- @author John "Nielk1" Klein

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_paths Loading");

--- @class _paths
local M = {};

--- Is this object a table?
--- @param object any Object in question
--- @return boolean
function M.IsPathWithString(object)
    return type(object) == 'table' and object[1] and type(object[1]) == 'string' and object[2] and type(object[2]) == 'number';
end

--- @section Paths - Iterator Operations

--- Iterate the vectors along the path.
--- Return LUA style 1 based indexes for the path points.
--- @param path string Path name
--- @return fun(): (integer, Vector)
function M.IteratePath(path)
    local count = GetPathPointCount(path);
    local i = 0;
    local iterator = function()
        if i < count then
            local position = GetPosition(path, i);
            i = i + 1;
            return i, position;
        end
        return nil;
    end
    return iterator;
end

--- @section Paths - Other


--- @section Paths - Core

--utility_module = setmetatable(utility_module, utility_module_meta);

logger.print(logger.LogLevel.DEBUG, nil, "_paths Loaded");

return M;

--- @alias PathWithIndex { [1]: string, [2]: integer }