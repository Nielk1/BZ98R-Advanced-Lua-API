--- BZ98R LUA Extended API Require Fix.
---
--- Repairs lua loader to look in mod paths for DLL or LUA modules with names longer than 15 characters.
---
--- @module '_requirefix'
--- @author John "Nielk1" Klein
--- ```lua
--- require("_requirefix").addmod("12345").addmod("67890");
--- ```
--- ```lua
--- require("_requirefix").addmod("12345");
--- require("_requirefix").addmod("67890");
--- ```

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_requirefix Loading");

local modPaths = {};
local modPathSet = {};

--- @class _requirefix
local moduleTable = {};
--local modFileExistCache = {};

--- Abuses the loadfile function to check if a file exists.
--[[local function FileExists(filename)
    local cached = modFileExistCache[filename];
    if cached ~= nil then
        return cached; -- Return the cached result
    end
    local file, err = loadfile(filename)
    if file then
        modFileExistCache[filename] = true; -- Cache the result
        return true -- File exists and is a valid Lua file
    elseif err then
        if err:match("cannot open") then
            modFileExistCache[filename] = false; -- Cache the result
            return false -- File does not exist
        else
            modFileExistCache[filename] = true; -- Cache the result
            return true -- File does not exist
        end
    else
        modFileExistCache[filename] = false; -- Cache the result
        return false -- File exists but contains invalid Lua code
    end
end]]

table.insert(package.loaders, 2, function(modulename) -- TODO is priority 2 too high?
    local errmsg = "";
    for _, k in ipairs(modPaths) do
        local relativePaths = {"addon/"..k.."/", "../../workshop/content/301650/"..k.."/", "mods/"..k.."/", "packaged_mods/"..k.."/"};
        for _, relativePath in ipairs(relativePaths) do
            local lfile = relativePath..modulename.. ".lua";
            --if FileExists(relativePath .. k .. ".ini") then -- does this look like a mod folder?
                local lfunc = loadfile(lfile)
                if (lfunc) then
                    return lfunc;
                else
                    errmsg = errmsg.."\n\tno mod asset '"..lfile.."'";
                end
            --end
        end
    end
    for _, k in ipairs(modPaths) do
        local relativePaths = {"addon/"..k.."/", "../../workshop/content/301650/"..k.."/", "mods/"..k.."/"};
        for _, relativePath in ipairs(relativePaths) do
            local cfile = relativePath..modulename.. ".dll";
            --if FileExists(relativePath .. k .. ".ini") then -- does this look like a mod folder?
                --print("Trying to load C module '"..cfile.."'");
                local cfunc = package.loadlib(cfile, "luaopen_"..modulename)
                if (cfunc) then
                    logger.print(logger.LogLevel.DEBUG, nil, modulename.." Loaded (C)");
                    return cfunc;
                else
                    errmsg = errmsg.."\n\tno mod asset '"..cfile.."'";
                end
            --end
        end
    end
    return errmsg;
end);

--- Add a workshop mod folder to the search paths
--- @param mod_id string The ID of the mod to add
--- @return _requirefix self Module self reference to allow chaining
function moduleTable.addmod(mod_id)
    logger.print(logger.LogLevel.DEBUG, nil, "Add module require path '"..mod_id.."'");
	if not modPathSet[mod_id] then
		table.insert(modPaths, mod_id);
		modPathSet[mod_id] = true;
	end
    return moduleTable; -- chaining
end;

logger.print(logger.LogLevel.DEBUG, nil, "Processing _api.cfg");
--- @type ParameterDB?
--- @diagnostic disable-next-line: deprecated
local settingsFile = OpenODF("_api.cfg");
if settingsFile then
    -- loop until GetODFString returns nil
    for i = 1, 1000 do
        --- @diagnostic disable-next-line: deprecated
        local mod, success = GetODFString(settingsFile, "RequireFix", "include"..tostring(i));
        if not success or not mod then
            break;
        end
        moduleTable.addmod(mod);
    end
    settingsFile = nil;
end
logger.print(logger.LogLevel.DEBUG, nil, "Processed _api.cfg");

logger.print(logger.LogLevel.DEBUG, nil, "_requirefix Loaded");

return moduleTable;