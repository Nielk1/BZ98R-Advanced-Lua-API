--- BZ98R LUA Extended API Paths.
---
--- @module '_paths'
--- @author John "Nielk1" Klein

local logger = require("_logger");
local hook = require("_hook");
local bzn = require("_bzn");

logger.print(logger.LogLevel.DEBUG, nil, "_paths Loading");

--- @class _paths
local M = {};

local bznFile = nil;
local bznFileAttempted = false;
local function TryLoadBZNFile()
    if not bznFileAttempted then
        bznFileAttempted = true;
        bznFile = bzn.Open(GetMissionFilename());
    end
    return bznFile;
end

--- Paths that shouldn't be considered linear but instead as point clouds.
--- These are paths that are never followed but instead of just locations.
--- @type table<string, boolean>
local path_is_cloud = {};

local path_name_cache = {};
local function GetPathNames()
    local bznFile = TryLoadBZNFile();
    if bznFile then
        if bznFile.AiPaths then
            for _, path in ipairs(bznFile.AiPaths) do
                path_name_cache[path.label] = true;
            end
        end
    end

    local keys = {}
    for k, _ in pairs(path_name_cache) do
        table.insert(keys, k)
    end
    table.sort(keys)

    return keys;
end

--- Mark path as cloud or not.
--- Cloud paths aren't followed and are just a collection of points.
--- @param path string Path name
--- @param flag boolean? Set to true to mark as cloud path, default as true
function M.PathIsCloud(path, flag)
    if flag == nil then
        path_is_cloud[path] = true;
    else
        path_is_cloud[path] = flag;
    end

    -- trigger path logging as the path is updated
    M.LogPathToData(path);
end

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

--- @section Paths - Logging

--- Log the path points to the data store
--- @param path string Path name
--- @param level LogLevel? Log level
function M.LogPathToData(path, level)
    if logger.IsDataMode() then
        local path_points = {}
        for _, point in M.IteratePath(path) do
            table.insert(path_points, string.format("%f,%f", point.x, point.z));
        end
        local is_cloud = path_is_cloud[path];
        logger.print(level or logger.LogLevel.DEBUG, nil,
            string.format("Path|%s|%d|%d|%s",
                path,
                GetPathType(path),
                is_cloud == nil and 0 or (is_cloud and 1 or 0),
                table.concat(path_points, "|")));
    end
end

--- @section Paths - Other

--- @section Paths - Core

--- @section Paths - Hooks

local function LogAllPaths()
    if logger.IsDataMode() and logger.DoLogLevel(logger.LogLevel.DEBUG) then
        for _, path_name in ipairs(GetPathNames()) do
            M.LogPathToData(path_name);
        end
    end
end
hook.Add("Start", "_paths_Start", function()
    LogAllPaths();
end);
hook.Add("Load", "_paths_Load", function()
    LogAllPaths();
end);

logger.print(logger.LogLevel.DEBUG, nil, "_paths Loaded");

return M;

--- @section Paths - Types

--- @alias PathName string
--- @alias PathWithIndex { [1]: PathName, [2]: integer }