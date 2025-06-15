--- BZ98R LUA Extended API Print Fix.
---
--- Hot-patches print to decorate output for finding in the mess of a log file.
---
--- @module '_printfix'
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

local oldPrint = print;
print = function(...)
    local args = {};
    for i, v in ipairs({...}) do
        args[i] = tostring(v); -- Convert each argument to a string
    end
    for s in table.concat(args, "\t"):gmatch("[^\r\n]+") do
        oldPrint("|LUA|PRINT|"..s.."|PRINT|LUA|");
    end
end

local oldError = error;
error = function(...)
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