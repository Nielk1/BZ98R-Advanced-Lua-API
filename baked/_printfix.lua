--- BZ98R LUA Extended API Print Fix.
-- 
-- Hot-patches print to decorate output for finding in the mess of a log file.
-- 
-- @module _printfix
-- @author John "Nielk1" Klein

-- tail -F -n0 BZLogger.txt | grep -oP '(?<=\|LUA\|PRINT\|).*?(?=\|PRINT\|LUA\|)|(?<=\|LUA\|ERROR\|).*?(?=\|ERROR\|LUA\|)'

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
error = function(a1, ...)
    if isstring(a1) then
        oldError("|LUA|ERROR|"..a.."|ERROR|LUA|");
    else
        oldError(a1, ...);
    end
end