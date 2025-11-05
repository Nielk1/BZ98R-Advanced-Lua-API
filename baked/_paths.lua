--- BZ98R LUA Extended API Paths.
---
--- Test
---
--- @module '_paths'
--- @author John "Nielk1" Klein

local api = require("_api");
local logger = require("_logger");
local hook = require("_hook");
local bzn = require("_bzn");
local paramdb = require("_paramdb");

local LOG_LEVEL_PRINT_ALL_PATHS = logger.LogLevel.DEBUG;
logger.print(logger.LogLevel.DEBUG, nil, "_paths Loading");

--- @alias PathName string

--- @alias PathWithIndex { [1]: PathName, [2]: integer }

--- @class _paths
local M = {};

--- @section Enums

--- @enum PathType
M.PathType = {
    OneWay = 0,
    RoundTrip = 1,
    Loop = 2,
}

--- @enum SpecialPathType
M.SpecialPathType = {
    None = 0,
    Bounds = 1, -- used for area bounds like edge_path
    Area = 2, -- used in Point-in-Polygon tests
    --Spawn = 3, -- used by the game
    Cloud = 3, -- just a collection of points
}

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
--- @type table<string, integer>
local path_special_type = {};

--- Set of paths in the mission
--- @type table<string, boolean>
local path_name_cache = {};

--- Store data from the BZN until internal functions start working
--- @type table<string, { pathType: PathType, points: Vector[] }>
local path_short_term_cache = {};

--- Paths pending a log of their data
--- @type table<string, boolean>
local paths_pending_log = {};

--- Try to load data from BZN file into memory cache, will only try once
local function LoadDataFromBzn()
    local bznFile = TryLoadBZNFile();
    if bznFile then
        if bznFile.AiPaths then
            for _, path in ipairs(bznFile.AiPaths) do
                path_name_cache[path.label] = true;
                if not api.CurrentCall[#api.CurrentCall + 1] then
                    local points = {};
                    for _, point in ipairs(path.points) do
                        table.insert(points, { x = point.x, y = GetTerrainHeightAndNormal(point), z = point.z });
                    end
                    path_short_term_cache[path.label] = { pathType = path.pathType, points = points };
                end
            end
        end
    end
end

--- Get a sorted list of path names
--- @return PathName[]
local function GetPathNames()
    if next(path_name_cache) == nil then
        LoadDataFromBzn();
    end

    local keys = {}
    for k, _ in pairs(path_name_cache) do
        table.insert(keys, k)
    end
    table.sort(keys)

    return keys;
end

--- @section PathType Operations

--- Changes the named path to the given path type.
--- {VERSION 2.0+}
--- @param path PathName|PathName[]
--- @param type PathType
function M.SetPathType(path, type)
    if type(path) == "table" then
        for _, p in ipairs(path) do
            --- @diagnostic disable-next-line: deprecated
            SetPathType(p, type);
        end
    else
        --- @diagnostic disable-next-line: deprecated
        SetPathType(path, type);
    end
end

--- Returns the type of the named path.
--- {VERSION 2.0+}
--- @param path PathName
--- @return PathType
function M.GetPathType(path)
    --- @diagnostic disable-next-line: deprecated
    return GetPathType(path);
end

--- Changes the named path to one-way. Once a unit reaches the end of the path, it will stop.
--- @param path PathName|PathName[]
function M.SetPathOneWay(path)
    if type(path) == "table" then
        for _, p in ipairs(path) do
            --- @diagnostic disable-next-line: deprecated
            SetPathOneWay(p);
        end
    else
        --- @diagnostic disable-next-line: deprecated
        SetPathOneWay(path);
    end 
end

--- Changes the named path to round-trip. Once a unit reaches the end of the path, it will follow the path backwards to the start and begin again.
--- @param path PathName|PathName[]
function M.SetPathRoundTrip(path)
    if type(path) == "table" then
        for _, p in ipairs(path) do
            --- @diagnostic disable-next-line: deprecated
            SetPathRoundTrip(p);
        end
    else
        --- @diagnostic disable-next-line: deprecated
        SetPathRoundTrip(path);
    end
end

--- Changes the named path to looping. Once a unit reaches the end of the path, it will continue along to the start and begin again.
--- @param path PathName|PathName[]
function M.SetPathLoop(path)
    if type(path) == "table" then
        for _, p in ipairs(path) do
            --- @diagnostic disable-next-line: deprecated
            SetPathLoop(p);
        end
    else
        --- @diagnostic disable-next-line: deprecated
        SetPathLoop(path);
    end
end

--- Get special path type.
--- @param path PathName Path name
--- @return SpecialPathType
function M.GetSpecialPathType(path)
    if path == "edge_path" then
        return M.SpecialPathType.Bounds;
    end
    return path_special_type[path] or M.SpecialPathType.None;
end

--- Mark path as cloud or not.
--- Cloud paths aren't followed and are just a collection of points.
--- @param path PathName|PathName[] Path name
--- @param stype SpecialPathType? Special path type defaulting to None
function M.SetSpecialPathType(path, stype)
    if stype == M.SpecialPathType.None then
        stype = nil;
    end
    if type(path) == "table" then
        for _, p in ipairs(path) do
            if p ~= "edge_path" then
                path_special_type[p] = stype;
                paths_pending_log[p] = true;
            end
        end
    else
        if path ~= "edge_path" then
            path_special_type[path] = stype;
            paths_pending_log[path] = true;
        end
    end
end

--- Mark path as normal path.
--- @param path PathName|PathName[] Path name
function M.SetPathNotSpecial(path)
    M.SetSpecialPathType(path, M.SpecialPathType.None);
end

--- Mark path as bounds path.
--- @param path PathName|PathName[] Path name
function M.SetPathBounds(path)
    M.SetSpecialPathType(path, M.SpecialPathType.Bounds);
end

--- Mark path as area path.
--- @param path PathName|PathName[] Path name
function M.SetPathArea(path)
    M.SetSpecialPathType(path, M.SpecialPathType.Area);
end

--- Mark path as cloud path.
--- @param path PathName|PathName[] Path name
function M.SetPathCloud(path)
    M.SetSpecialPathType(path, M.SpecialPathType.Cloud);
end

--- Extracts the name and number from a string.
--- @param str string
--- @return string
--- @return integer?
local function extract_name_and_number(str)
    local name, after = str:match("^([A-Za-z0-9 !#$%%&'()%+,;=@%[%]^`{}~%.%-]{1,9})(.*)")
    local num = nil
    if after and after:sub(1,1) == "_" then
        local digits = after:match("^_(%d+)")
        if digits then
            num = tonumber(digits)
        else
            num = 0
        end
    end
    return name:lower(), num
end

--- Is the path a PathSpawn path?
--- For all mission types that Lua can be used in paths
--- with a specific name structure can be used for spawns.
--- Objects spawned this way use the path name as their label.
--- You can bind the `MapObject` and `AddObject` events to
--- search for spawned objects.
--- @param path PathName
--- @return boolean
--- @return string? odf ODF filename without extension
--- @return number? seconds respawn time
function M.IsSpawnPath(path)
    if path == "edge_path" then
        return false;
    end

    if string.sub(path, 1, 5) == "path_" then
        return false;
    end

    local bznFile = TryLoadBZNFile();
    if bznFile then
        if bznFile.Mission == "LuaMission" then
            -- LuaMission is the only Lua running mission that doesn't use spawn paths
            return false;
        end
    else
        -- low accuracy mode would be here, just assume it's not LuaMission for now
    end

    local name, num = extract_name_and_number(path);
    local classlabel, success = paramdb.GetClassLabel(name .. ".odf")
    if not success or #classlabel == 0 then
        return true;
    end

    if num ~= nil then
        -- had time so fix the time
        if num == 0 then
            num = 10;
        end
    end

    return false, name, num;
end

--- Returns the number of points in the named path, or 0 if the path does not exist.
--- @param path PathName
--- @return integer
function M.GetPathPointCount(path)
    --- @diagnostic disable-next-line: deprecated
    return GetPathPointCount(path);
end

--- @diagnostic disable-next-line: deprecated
if not _G.GetPathPointCount then
    local point_count_cache = {};
    function M.GetPathPointCount(path)
        if point_count_cache[path] then
            return point_count_cache[path];
        end
        local count = 0;
        local lastPoint = nil;
        -- if _G.GetPathPointCount is not available IteratePath to count points instead of IteratePath relying on GetPathPointCount
        for i, point in M.IteratePath(path) do
            if lastPoint and point.x == lastPoint.x and point.y == lastPoint.y and point.z == lastPoint.z then
                -- the point is 100% identical to the last point, so we've reached the end
                break;
            end
            count = i;
            lastPoint = point;
        end
        point_count_cache[path] = count;
        return count;
    end
end

--- Returns the path point's position vector. Returns nil if none exists.
--- @param path PathName
--- @param point integer? Zero based point index, defaults to 0.
--- @return Vector?
function M.GetPosition(path, point)
    point = point or 0;
    if M.GetPathPointCount(path) > point then
        --- @diagnostic disable-next-line: deprecated
        return GetPosition(path, point);
    end
    return nil;
end

--- Is this object a [PathName, index] array?
--- @param object any Object in question
--- @return boolean
function M.IsPathWithString(object)
    return type(object) == 'table' and object[1] and type(object[1]) == 'string' and object[2] and type(object[2]) == 'number';
end

--- @section Iterator Operations

--- Iterate the vectors along the path.
--- Return LUA style 1 based indexes for the path points.
--- @param path string Path name
--- @return fun(): (integer, Vector)
function M.IteratePath(path)
    local count = M.GetPathPointCount(path);
    local i = 0;
    local iterator = function()
        if i < count then
            local position = M.GetPosition(path, i);
            i = i + 1;
            return i, position;
        end
        return nil;
    end
    return iterator;
end

--- If GetPathPointCount is not available, provide an alternate implementation of IteratePath
--- @diagnostic disable-next-line: deprecated
if not _G.GetPathPointCount then
    -- [[START_IGNORE]]
    M.IteratePath = function(path)
        local i = 0;
        local last_position = nil;
        local iterator = function()
            -- Use the game provided GetPosition so we can watch for its side effects
            --- @diagnostic disable-next-line: deprecated
            local position = _G.GetPosition(path, i);

            if i == 0 and position.x == 0 and position.y == 0 and position.z == 0 then
                -- abort because the path isn't real
                return nil;
            end

            if last_position == position then
                -- abort because the path is repeating the last point, indicating the end
                return nil;
            end
            
            i = i + 1;
            last_position = position;
            return i, position;
        end
        return iterator;
    end
    -- [[END_IGNORE]]
end

--- @section Logging

--- Log the path points to the data store
--- @param path string Path name
--- @param level LogLevel? Log level
function M.LogPathToData(path, level)
    level = level or LOG_LEVEL_PRINT_ALL_PATHS;
    if logger.IsDataMode() and logger.DoLogLevel(level) then

        if not api.CurrentCall[#api.CurrentCall] then
            -- can't get path points this early and thus can't confirm paths exist or return their data
           
            -- load data from BZN
            LoadDataFromBzn();

            local path_data = path_short_term_cache[path];
            if path_data then
                local path_points = {}
                for _, point in ipairs(path_data.points) do
                    table.insert(path_points, string.format("%f,%f,%f", point.x, point.y, point.z));
                end
                logger.print(level, nil,
                    string.format("Path|%s|%d|%d|%s",
                        path,
                        M.GetPathType(path),
                        M.GetSpecialPathType(path),
                        table.concat(path_points, "|")));
            else
                paths_pending_log[path] = true;
            end
        else
            local path_points = {}
            for _, point in M.IteratePath(path) do
                table.insert(path_points, string.format("%f,%f,%f", point.x, point.y, point.z));
            end
            logger.print(level, nil,
                string.format("Path|%s|%d|%d|%s",
                    path,
                    M.GetPathType(path),
                    M.GetSpecialPathType(path),
                    table.concat(path_points, "|")));
        end
    end
end

--- @section Other

--- @section Core

--- @section Hooks

local function AutoLogAllPaths()
    if logger.IsDataMode() and logger.DoLogLevel(LOG_LEVEL_PRINT_ALL_PATHS) then
        for _, path_name in ipairs(GetPathNames()) do
            M.LogPathToData(path_name);
        end
    end
end

-- no priority here since these are just logging so we don't really care when they run
hook.Add("Start", "_paths_Start", function()
    AutoLogAllPaths();
end);
hook.Add("Load", "_paths_Load", function()
    AutoLogAllPaths();
end);
hook.Add("Update", "_paths_Update", function()
    if next(paths_pending_log) ~= nil then
        for path_name, _ in pairs(paths_pending_log) do
            M.LogPathToData(path_name);
        end
        paths_pending_log = {};
    end
end);

logger.print(logger.LogLevel.DEBUG, nil, "_paths Loaded");

return M;