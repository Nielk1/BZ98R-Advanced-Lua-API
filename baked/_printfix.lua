--- BZ98R LUA Extended API Print Fix.
---
--- Hot-patches print to decorate output for finding in the mess of a log file.
---
--- @module '_printfix'
--- @author John "Nielk1" Klein

--[[
tail -F -n0 BZLogger.txt | grep --line-buffered -oP '\|LUA\|PRINT\|.*?\|PRINT\|LUA\||\|LUA\|ERROR\|.*?\|ERROR\|LUA\|' | awk '
/^\|LUA\|PRINT\|/ { sub(/^\|LUA\|PRINT\|/, ""); sub(/\|PRINT\|LUA\|$/, ""); print; system("") }
/^\|LUA\|ERROR\|/ { sub(/^\|LUA\|ERROR\|/, ""); sub(/\|ERROR\|LUA\|$/, ""); print "\033[31m" $0 "\033[0m"; system("") }
'
--]]

--[[
tail -F -n +1 BZLogger.txt | grep --line-buffered -oP '\|LUA\|PRINT\|.*?\|PRINT\|LUA\||\|LUA\|ERROR\|.*?\|ERROR\|LUA\|' | awk '
/^\|LUA\|PRINT\|/ { sub(/^\|LUA\|PRINT\|/, ""); sub(/\|PRINT\|LUA\|$/, ""); print; system("") }
/^\|LUA\|ERROR\|/ { sub(/^\|LUA\|ERROR\|/, ""); sub(/\|ERROR\|LUA\|$/, ""); print "\033[31m" $0 "\033[0m"; system("") }
' | tee BZLuaLog.txt
--]]

--[[
cat BZLogger.txt | grep --line-buffered -oP '\|LUA\|PRINT\|.*?\|PRINT\|LUA\||\|LUA\|ERROR\|.*?\|ERROR\|LUA\|' | awk '
/^\|LUA\|PRINT\|/ { sub(/^\|LUA\|PRINT\|/, ""); sub(/\|PRINT\|LUA\|$/, ""); print; system("") }
/^\|LUA\|ERROR\|/ { sub(/^\|LUA\|ERROR\|/, ""); sub(/\|ERROR\|LUA\|$/, ""); print "\033[31m" $0 "\033[0m"; system("") }
' > BZLuaLog.txt
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