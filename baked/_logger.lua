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
--- @field intercept_print InterceptPrint
--- @field strip_colors boolean
--- @field suppress string[] -- Patterns to suppress in log messages
local settings = {
    level = M.LogLevel.NONE,
    format = M.LogFormat.RAW,
    intercept_print = M.InterceptPrint.NONE,
    strip_colors = false, -- Strip ANSI color codes, but only from dedicated logging function, print/error not touched
    suppress = {}, -- Patterns to suppress in log messages
};
M.settings = settings; --- @todo make this readonly (at least through this window)

--- @param odf ParameterDB
--- @param section string?
--- @param label string
--- @param default any?
--- @param boolVal any
--- @param enumTable table<string, integer>
--- @return any, boolean
--- @overload fun(odf: ParameterDB, section: string|nil, label: string, default: LogLevel, boolVal: LogLevel, enumTable: table<string, LogLevel>): LogLevel, boolean
local function GetODFEnum(odf, section, label, default, boolVal, enumTable)
    local value;
    --- @type boolean?
    local success;
    local value, success = GetODFString(odf, section, label);
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
        --- @diagnostic disable-next-line: cast-local-type
        value, success = GetODFInt(odf, section, label);
    end
    if not success then
        --- @diagnostic disable-next-line: cast-local-type
        value, success = GetODFBool(odf, section, label);
        if success then
            if value then
                --- @diagnostic disable-next-line: cast-local-type
                value = boolVal;
            else
                value = default;
            end
        end
    end
    return value, success;
end

--- @type ParameterDB?
local settingsFile = OpenODF("logger.cfg");
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

    settings.intercept_print = GetODFEnum(settingsFile, "Logging", "intercept_print", M.InterceptPrint.NONE, M.InterceptPrint.WRAPPED, M.InterceptPrint);
    if settings.intercept_print < M.InterceptPrint.NONE then
        settings.intercept_print = M.InterceptPrint.NONE;
    end
    if settings.intercept_print > M.InterceptPrint.LOGGER then
        settings.intercept_print = M.InterceptPrint.LOGGER;
    end

    settings.strip_colors = GetODFBool(settingsFile, "Logging", "strip_colors", false);

    -- loop untip GetODFString returns nil
    for i = 1, 100 do
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
    for i, v in ipairs({...}) do
        args[i] = tostring(v); -- Convert each argument to a string
    end
    for s in table.concat(args, "\t"):gmatch("[^\r\n]+") do
        oldPrint("|LUA|PRINT|"..s.."|PRINT|LUA|");
    end
end

local oldError = error;
local wrapError = function(...)
    local args = {};
    for i, v in ipairs({...}) do
        args[i] = tostring(v); -- Convert each argument to a string
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
    local contextWrap = context;
    if not contextWrap then
        local info = debug.getinfo(2, "Sl")
        local filename = info.short_src or "unknown"
        filename = filename:gsub('%[string "(.-)"%]', '%1')
        filename = filename:match("[^/\\]+$") or filename -- strip path
        local lineinfo = info.currentline and ("#" .. info.currentline) or ""
        contextWrap = filename .. lineinfo;
    end
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
    if settings.format == M.LogFormat.RAW then
        local args = {};
        for i, v in ipairs({...}) do
            args[i] = tostring(v); -- Convert each argument to a string
            if settings.strip_colors then
                args[i] = RemoveANSIColors(args[i]);
            end
        end
        for s in table.concat(args, "\t"):gmatch("[^\r\n]+") do
            oldPrint(contextWrap.."|"..LogLevelName[level].."|"..s);
        end
    elseif settings.format == M.LogFormat.WRAPPED then
        local args = {};
        for i, v in ipairs({...}) do
            args[i] = tostring(v); -- Convert each argument to a string
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
                    oldPrint("|LUA|ERROR|"..contextWrap.."|"..LogLevelName[level].."|"..s.."|ERROR|LUA|");
                end
                for s in ("Traceback:\n" .. traceback):gmatch("[^\r\n]+") do
                    oldPrint("|LUA|ERROR|"..contextWrap.."|"..LogLevelName[level].."|"..s.."|ERROR|LUA|");
                end
            else
                wrapPrint(contextWrap.."|"..LogLevelName[level].."|"..s);
            end
        end
    end
end

--- [[START_IGNORE]]

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

--- [[END_IGNORE]]

--logger.print(logger.LogLevel.DEBUG, nil, "_logger Loaded");

return M;
