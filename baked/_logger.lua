--- BZ98R LUA Extended API Debug.
---
--- System for handling debugging and logging.
---
--- @module '_logger'
--- @author John "Nielk1" Klein

-- Bash to show log messages in real time:
--[[
tail -F -n0 BZLogger.txt | grep --line-buffered -oP '\|LUA\|PRINT\|.*?\|PRINT\|LUA\||\|LUA\|ERROR\|.*?\|ERROR\|LUA\|' | awk '
/^\|LUA\|PRINT\|/ { sub(/^\|LUA\|PRINT\|/, ""); sub(/\|PRINT\|LUA\|$/, ""); print; system("") }
/^\|LUA\|ERROR\|/ { sub(/^\|LUA\|ERROR\|/, ""); sub(/\|ERROR\|LUA\|$/, ""); print "\033[31m" $0 "\033[0m"; system("") }
'
--]]

-- Bash to show log messages in real time and save to file BZLuaLog.txt:
--[[
tail -F -n +1 BZLogger.txt | grep --line-buffered -oP '\|LUA\|PRINT\|.*?\|PRINT\|LUA\||\|LUA\|ERROR\|.*?\|ERROR\|LUA\|' | awk '
/^\|LUA\|PRINT\|/ { sub(/^\|LUA\|PRINT\|/, ""); sub(/\|PRINT\|LUA\|$/, ""); print; system("") }
/^\|LUA\|ERROR\|/ { sub(/^\|LUA\|ERROR\|/, ""); sub(/\|ERROR\|LUA\|$/, ""); print "\033[31m" $0 "\033[0m"; system("") }
' | tee BZLuaLog.txt
--]]

-- Bash to extract log messages from existing log file to file BZLuaLog.txt:
--[[
cat BZLogger.txt | grep --line-buffered -oP '\|LUA\|PRINT\|.*?\|PRINT\|LUA\||\|LUA\|ERROR\|.*?\|ERROR\|LUA\|' | awk '
/^\|LUA\|PRINT\|/ { sub(/^\|LUA\|PRINT\|/, ""); sub(/\|PRINT\|LUA\|$/, ""); print; system("") }
/^\|LUA\|ERROR\|/ { sub(/^\|LUA\|ERROR\|/, ""); sub(/\|ERROR\|LUA\|$/, ""); print "\033[31m" $0 "\033[0m"; system("") }
' > BZLuaLog.txt
--]]

-- Powershell to show log messages in window in real time: (LuaLogWatch.ps1)
--[[
Get-Content -Path "BZLogger.txt" -Wait -Tail 0 -Encoding UTF8 | ForEach-Object {
    if ($_ -match '\|LUA\|PRINT\|(.*?)\|PRINT\|LUA\|') {
        $msg = $Matches[1]
        Write-Host $msg
    }
    elseif ($_ -match '\|LUA\|ERROR\|(.*?)\|ERROR\|LUA\|') {
        $msg = $Matches[1]
        Write-Host $msg -ForegroundColor Red
    }
}
--]]

local CONTEXT_PAD = 32; -- Padding for context in log messages
local TIME_FORMAT = "%12.3f"; -- Padding for time in log messages

--- @class _logger
local M = {};


--- Print Intercept Mode
--- @enum InterceptPrint
M.InterceptPrint = {
    NONE = 0,
    WRAPPED = 1,
    LOGGER = 2,
};

--- Log Levels
--- @enum LogLevel
M.LogLevel = {
    NONE  = 0, -- No logging
    ERROR = 1, -- Error messages, used for critical issues
    WARN  = 2, -- Warning messages, used for non-critical issues
    PRINT = 3, -- Normal print messages, used most often in intercept
    DEBUG = 4, -- Debug messages
    TRACE = 5, -- Trace messages
};

--- Log Structure
--- @enum LogStructure
M.LogStructure = {
    TEXT  = 0, -- Logs have text, best for human reading
    DATA = 1, -- Logs have data structures, best for automations
};

--- @type table<LogLevel, string>
local LogLevelName = {
    [M.LogLevel.NONE]  = "NONE ",
    [M.LogLevel.ERROR] = "ERROR",
    [M.LogLevel.WARN]  = "WARN ",
    [M.LogLevel.PRINT] = "PRINT",
    [M.LogLevel.DEBUG] = "DEBUG",
    [M.LogLevel.TRACE] = "TRACE",
}

--- Log Format
--- @enum LogFormat
M.LogFormat = {
    RAW = 0, -- Raw format
    WRAPPED = 1, -- Wrapped format
};

--- @class DebugSettings
--- @field level LogLevel
--- @field format LogFormat
--- @field structure LogStructure -- Only used by log callers to know what to send
--- @field intercept_print InterceptPrint
--- @field strip_colors boolean
--- @field suppress string[] -- Patterns to suppress in log messages
local settings = {
    level = M.LogLevel.NONE,
    format = M.LogFormat.RAW,
    structure = M.LogStructure.TEXT,
    intercept_print = M.InterceptPrint.NONE,
    strip_colors = false, -- Strip ANSI color codes, but only from dedicated logging function, print/error not touched
    suppress = {}, -- Patterns to suppress in log messages
};
M.settings = settings; --- @todo make this readonly (at least through this window)

--- We can't use the nice fancy paramdb functions here since we want to load first so paramdb can log with us
--- @param odf ParameterDB ODF file name
--- @param section string? Section name
--- @param key string Key name
--- @param default integer? Default value if the key is not found or is a boolean false
--- @param boolVal integer? Value to return if the key is found and is a boolean true
--- @param enumTable table<string, integer>|table<string, LogLevel> Lookup table to convert enum value, a failed lookup will be considered a failure
--- @return integer, boolean
local function GetODFEnum(odf, section, key, default, boolVal, enumTable)
    --- @type integer?
    local value;
    --- @type boolean?
    local success;
    --- @diagnostic disable-next-line: deprecated
    local value, success = GetODFString(odf, section, key);
    if success then
        --- @cast value string
        if enumTable[value] then
            --- @diagnostic disable-next-line: cast-local-type
            value = enumTable[value];
        else
            success = false;
        end
    end
    if not success then
        --- @diagnostic disable-next-line: cast-local-type, deprecated
        value, success = GetODFInt(odf, section, key);
    end
    if not success then
        --- @diagnostic disable-next-line: cast-local-type, deprecated
        value, success = GetODFBool(odf, section, key);
        if success then
            if value then
                --- @diagnostic disable-next-line: cast-local-type
                value = boolVal;
            else
                --- @diagnostic disable-next-line: cast-local-type
                value = default;
            end
        end
    end
    --- @diagnostic disable-next-line: cast-type-mismatch
    --- @cast value integer
    return value, success;
end

--- @type ParameterDB?
--- @diagnostic disable-next-line: deprecated
local settingsFile = OpenODF("_api.cfg");
if settingsFile then
    settings.level = GetODFEnum(settingsFile, "Logging", "level", M.LogLevel.NONE, M.LogLevel.DEBUG, M.LogLevel);
    if settings.level < M.LogLevel.NONE then
        settings.level = M.LogLevel.NONE;
    end
    if settings.level > M.LogLevel.TRACE then
        settings.level = M.LogLevel.TRACE;
    end

    settings.format = GetODFEnum(settingsFile, "Logging", "format", M.LogFormat.RAW, M.LogFormat.WRAPPED, M.LogFormat);
    if settings.format < M.LogFormat.RAW then
        settings.format = M.LogFormat.RAW;
    end
    if settings.format > M.LogFormat.WRAPPED then
        settings.format = M.LogFormat.WRAPPED;
    end

    settings.structure = GetODFEnum(settingsFile, "Logging", "structure", M.LogStructure.TEXT, M.LogStructure.DATA, M.LogStructure);
    if settings.structure < M.LogStructure.TEXT then
        settings.structure = M.LogStructure.TEXT;
    end
    if settings.structure > M.LogStructure.DATA then
        settings.structure = M.LogStructure.DATA;
    end

    settings.intercept_print = GetODFEnum(settingsFile, "Logging", "intercept_print", M.InterceptPrint.NONE, M.InterceptPrint.WRAPPED, M.InterceptPrint);
    if settings.intercept_print < M.InterceptPrint.NONE then
        settings.intercept_print = M.InterceptPrint.NONE;
    end
    if settings.intercept_print > M.InterceptPrint.LOGGER then
        settings.intercept_print = M.InterceptPrint.LOGGER;
    end

    --- @diagnostic disable-next-line: deprecated
    settings.strip_colors = GetODFBool(settingsFile, "Logging", "strip_colors", false);

    -- loop until GetODFString returns nil
    for i = 1, 1000 do
        --- @diagnostic disable-next-line: deprecated
        local pattern, success = GetODFString(settingsFile, "Logging", "suppress"..tostring(i));
        if not success or not pattern then
            break;
        end
        table.insert(settings.suppress, pattern);
    end

    settingsFile = nil;
end

-- preserve old functions since we need these
local oldPrint = print;
local wrapPrint = function(...)
    local args = {};
    for i = 1, select("#", ...) do
        args[i] = tostring(select(i, ...)); -- Convert each argument to a string
    end
    for s in table.concat(args, "\t"):gmatch("[^\r\n]+") do
        oldPrint("|LUA|PRINT|"..s.."|PRINT|LUA|");
    end
end

local oldError = error;
local wrapError = function(...)
    local args = {};
    for i = 1, select("#", ...) do
        args[i] = tostring(select(i, ...)); -- Convert each argument to a string
    end

    -- Capture the stack trace at the appropriate level
    --- @diagnostic disable-next-line: undefined-global
    local traceback = debug.traceback("", (level or 2))

    for s in table.concat(args, "\t"):gmatch("[^\r\n]+") do
        oldPrint("|LUA|ERROR|"..s.."|ERROR|LUA|");
    end
    for s in ("Traceback:\n" .. traceback):gmatch("[^\r\n]+") do
        oldPrint("|LUA|ERROR|"..s.."|ERROR|LUA|");
    end

    oldError(...);
end

--logger.print(logger.LogLevel.DEBUG, nil, "_logger Loading");

local function RemoveANSIColors(str)
    -- Lua 5.1 does not support \x1b, use \27 and escape [
    return str:gsub("\27%[[%d;]*m", "")
end

--- Print log line
--- Ignores wrapping setting for normal print.
--- Will strip colors if not supported.
--- @param level LogLevel|integer
--- @param context string?
--- @param ... any
function M.print(level, context, ...)
    if level > settings.level then
        return;
    end

    if not context then
        local info = debug.getinfo(2, "Sl")
        local filename = info.short_src or "unknown"
        filename = filename:gsub('%[string "(.-)"%]', '%1')
        filename = filename:match("[^/\\]+$") or filename -- strip path
        local lineinfo = info.currentline and ("#" .. info.currentline) or ""
        context = filename .. lineinfo;
    end

    local contextWrap = context;
    if level ~= M.LogLevel.ERROR then
        -- supressed logging by context, except for errors
        for _, pattern in ipairs(settings.suppress) do
            if contextWrap:match(pattern) then
                return; -- Suppress this message
            end
        end
    end
    if #contextWrap < CONTEXT_PAD then
        contextWrap = contextWrap .. string.rep(" ", CONTEXT_PAD - #contextWrap)
    end

    local ttime = GetTime();
    local timeWrap = string.format(TIME_FORMAT, ttime);

    if settings.format == M.LogFormat.RAW then
        local args = {};
        for i = 1, select('#', ...) do
            args[i] = tostring(select(i, ...)); -- Convert each argument to a string
            if settings.strip_colors then
                args[i] = RemoveANSIColors(args[i]);
            end
        end
        for s in table.concat(args, "\t"):gmatch("[^\r\n]+") do
            oldPrint(timeWrap.."|"..contextWrap.."|"..LogLevelName[level].."|"..s);
        end
    elseif settings.format == M.LogFormat.WRAPPED then
        local args = {};
        for i = 1, select('#', ...) do
            args[i] = tostring(select(i, ...)); -- Convert each argument to a string
            if settings.strip_colors then
                args[i] = RemoveANSIColors(args[i]);
            end
        end
        for s in table.concat(args, "\t"):gmatch("[^\r\n]+") do
            if level == M.LogLevel.ERROR then
                -- Capture the stack trace at the appropriate level
                --- @diagnostic disable-next-line: undefined-global
                local traceback = debug.traceback("", (level or 2))

                for s in table.concat(args, "\t"):gmatch("[^\r\n]+") do
                    oldPrint("|LUA|ERROR|"..timeWrap.."|"..contextWrap.."|"..LogLevelName[level].."|"..s.."|ERROR|LUA|");
                end
                for s in ("Traceback:\n" .. traceback):gmatch("[^\r\n]+") do
                    oldPrint("|LUA|ERROR|"..timeWrap.."|"..contextWrap.."|"..LogLevelName[level].."|"..s.."|ERROR|LUA|");
                end
            else
                wrapPrint(timeWrap.."|"..contextWrap.."|"..LogLevelName[level].."|"..s);
            end
        end
    end
end

--- Encode data for  serialization
---@param obj any
---@return string value serialized value
---@return string type
local function encode_data(obj)
    -- Minimal JSON encoder for numbers, strings, booleans, nil, and tables with string keys
    local t = type(obj)
    if t == "number" or t == "boolean" then
        return tostring(obj), t
    elseif t == "string" then
        return string.format("%q", obj), t
    elseif t == "table" then
        if obj.__type == "nil" then
            return "nil", "nil"
        else
            local array_portion = 0;
            local items = {}
            for i, v in ipairs(obj) do
                if v == nil then
                    array_portion = i
                    break
                end
                local r = encode_data(v)
                table.insert(items, r)
            end
            for k, v in pairs(obj) do
                if type(k) == "number" and k > 0 and k <= array_portion then
                    -- already handled in array portion
                else
                    local r = encode_data(v)
                    if type(k) == "string" and string.match(k, "^[A-Za-z_][A-Za-z0-9_]*$") then
                        table.insert(items, string.format("%s=%s", k, r))
                    else
                        table.insert(items, string.format("[%q]=%s", tostring(k), r))
                    end
                end
            end
            return "{" .. table.concat(items, ",") .. "}", t
        end
    elseif t == "nil" then -- probably can't happen
        return "nil", t
    elseif t == "userdata" then
        local mt = getmetatable(obj)
        if mt then
            if mt.__type == "BZHandle" then
                --return string.format("0x%s", tostring(obj):sub(-8)), mt.__type
                return string.format("H%d", tonumber(tostring(obj):sub(-5), 16)), mt.__type
            elseif mt.__type == "VECTOR_3D" then
                return string.format("{x=%d,y=%d,z=%d}", obj.x, obj.y, obj.z), mt.__type
            elseif mt.__type == "MAT_3D" then
                return string.format("{right_x=%d,right_y=%d,right_z=%d,up_x=%d,up_y=%d,up_z=%d,front_x=%d,front_y=%d,front_z=%d,pos_x=%d,pos_y=%d,pos_z=%d}",
                    obj.right_x, obj.right_y, obj.right_z,
                    obj.up_x, obj.up_y, obj.up_z,
                    obj.front_x, obj.front_y, obj.front_z,
                    obj.pos_x, obj.pos_y, obj.pos_z), mt.__type
            else
                error("Unsupported userdata type: " .. tostring(mt.__type))
            end
        else
            error("Unsupported type: " .. t)
        end
    else
        error("Unsupported type: " .. t)
    end
end

--- Print multiple log lines of data
--- @param level LogLevel|integer
--- @param context string?
--- @param name string
--- @param data any
--- @param whitelist (string|integer)[]? -- List of allowed key paths (each path is a table of keys)
function M.data(level, context, name, data, whitelist)

    if not context then
        local info = debug.getinfo(2, "Sl")
        local filename = info.short_src or "unknown"
        filename = filename:gsub('%[string "(.-)"%]', '%1')
        filename = filename:match("[^/\\]+$") or filename -- strip path
        local lineinfo = info.currentline and ("#" .. info.currentline) or ""
        context = filename .. lineinfo;
    end

    local seen = {}
    local tables = {}
    local order = {}

    local function get_id(tbl)
        -- Use the table's memory address as its unique ID
        local addr = tostring(tbl):sub(-8)
        if not seen[addr] then
            seen[addr] = addr
        end
        return addr
    end

    --local function is_string_key_table(tbl)
    --    for k, _ in pairs(tbl) do
    --        if type(k) ~= "string" then return false end
    --    end
    --    return true
    --end

    local function is_array(tbl)
        local n = 0
        for k, _ in pairs(tbl) do
            if type(k) ~= "number" then return false end
            n = n + 1
        end
        return n == #tbl
    end

    local function has_non_string_key(tbl)
        for k, _ in pairs(tbl) do
            if type(k) ~= "string" then return true end
        end
        return false
    end

    local function path_allowed(path, allow_more)
        if not whitelist then return true end
        for idx, allowed in ipairs(whitelist) do
            local match = true
            --for i = 1, #path do
            --    if allowed[i] ~= path[i] then
            --        match = false
            --        break
            --    end
            --end
            for i = 1, math.min(#path, #allowed) do
                if allowed[i] ~= path[i] then
                    match = false
                    break
                end
            end
            if match and #path == #allowed then
                return true
            end
            if match and idx == #allowed and allow_more then
                return true
            end
        end
        return false
    end

    local function serialize(tbl, path)
        path = path or {}
        local id = get_id(tbl)
        if tables[id] then
            return {["$ref"] = id}
        end
        local out
        local __type = tbl.__type;
        if not __type and is_array(tbl) then
            -- Array: encode as JSON array
            out = {}
            tables[id] = out
            table.insert(order, id)
            for i = 1, #tbl do
                local v = tbl[i]
                local new_path = {table.unpack(path)}
                table.insert(new_path, i)
                local allow = path_allowed(new_path, type(v) == "table")
                if allow then
                    if type(v) == "table" then
                        local val_ref_id = get_id(v)
                        out[i] = {["$ref"] = val_ref_id}
                        serialize(v, new_path)
                    else
                        out[i] = v
                    end
                else
                    out["$partial"] = true
                end
            end
        elseif has_non_string_key(tbl) then
            -- Not array, has non-string keys: use $entries
            out = {}
            tables[id] = out
            table.insert(order, id)
            out["__type"] = __type
            out["$entries"] = {}
            for k, v in pairs(tbl) do
                local new_path = {table.unpack(path)}
                table.insert(new_path, k)
                local allow = path_allowed(new_path, type(v) == "table")
                if allow then
                    local key_serialized = type(k) == "table" and {["$ref"] = get_id(k)} or k
                    if type(k) == "table" then serialize(k, new_path) end
                    local value_serialized = type(v) == "table" and {["$ref"] = get_id(v)} or v
                    if type(v) == "table" then serialize(v, new_path) end
                    local tmpTable = {key = key_serialized, value = value_serialized}
                    table.insert(out["$entries"], tmpTable)
                else
                    out["$partial"] = true
                end
            end
        else
            -- Only string keys: encode as JSON object
            out = {}
            tables[id] = out
            table.insert(order, id)
            out["__type"] = __type
            for k, v in pairs(tbl) do
                local new_path = {table.unpack(path)}
                table.insert(new_path, k)
                local allow = path_allowed(new_path, type(v) == "table")
                if type(v) == "table" then
                    if allow then
                        local val_ref_id = get_id(v)
                        out[k] = {["$ref"] = val_ref_id}
                        serialize(v, new_path)
                    else
                        out["$partial"] = true
                    end
                else
                    if allow then
                        out[k] = v
                    else
                        out["$partial"] = true
                    end
                end
            end

            -- After normal serialization, ensure nils for whitelisted paths
            if whitelist then
                for _, allowed in ipairs(whitelist) do
                    if #allowed == #path + 1 then
                        local key = allowed[#allowed]
                        local match = true
                        for i = 1, #path do
                            if allowed[i] ~= path[i] then
                                match = false
                                break
                            end
                        end
                        if match and out[key] == nil then
                            out[key] = { __type = "nil" }
                        end
                    end
                end
            end
        end
        return out
    end

    -- Start serialization
    serialize(data, {})

    -- Output lines
    --if #order == 1 then
    --    local id = order[1]
    --    local t = tables[id]
    --    local encoded_str, type = encode_data(t)
    --    M.print(level, context, "ONE|" .. name .. "|" .. type .. "|" .. encoded_str)
    --else
        M.print(level, context, "START|" .. name)
        -- Iterate in arbitrary order since table addresses are not sequential
        for i = #order, 1, -1 do
            local id = order[i]
            local t = tables[id]
            local encoded_str, type = encode_data(t)
            M.print(level, context, type .. "|" .. id .. "|" .. encoded_str)
        end
        M.print(level, context, "END|" .. name)
    --end
end

-- [[START_IGNORE]]

-- Replace original print function with wrapped ones
if settings.intercept_print == M.InterceptPrint.WRAPPED then
    print = wrapPrint;
    error = wrapError;
elseif settings.intercept_print == M.InterceptPrint.LOGGER then
    print = function(...)
        local info = debug.getinfo(2, "Sl")
        local filename = info.short_src or "unknown"
        filename = filename:gsub('%[string "(.-)"%]', '%1')
        filename = filename:match("[^/\\]+$") or filename -- strip path
        local lineinfo = info.currentline and ("#" .. info.currentline) or ""
        M.print(M.LogLevel.PRINT, filename .. lineinfo, ...);
    end
    error = function(...)
        local info = debug.getinfo(2, "Sl")
        local filename = info.short_src or "unknown"
        filename = filename:gsub('%[string "(.-)"%]', '%1')
        filename = filename:match("[^/\\]+$") or filename -- strip path
        local lineinfo = info.currentline and ("#" .. info.currentline) or ""
        M.print(M.LogLevel.ERROR, filename .. lineinfo, ...);
    end
end

-- [[END_IGNORE]]

--- Check if the logger is in data mode.
--- @return boolean
function M.IsDataMode()
    return M.settings.structure == M.LogStructure.DATA;
end

--- Check if the logger should log a message at the given level.
--- @param level any
--- @return boolean
function M.DoLogLevel(level)
    return level <= M.settings.level;
end

--logger.print(logger.LogLevel.DEBUG, nil, "_logger Loaded");

return M;
