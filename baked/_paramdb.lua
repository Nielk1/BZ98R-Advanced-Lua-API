--- BZ98R LUA Extended API ODF Handler.
---
--- Tracks objects by class and odf.
---
--- @module '_paramdb'
--- @author John "Nielk1" Klein

local MAX_PARAMDB_CACHE_AGE = 300; -- seconds max age of cache items before purging
local PURGE_PARAMDB_CHECK_INTERVAL = 60; -- seconds interval to check for old cache items

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_paramdb Loading");

--- @class _paramdb
local M = {};

local utility = require("_utility");
local config = require("_config");
local hook = require("_hook");

--- @class ParameterDBCacheItem
--- @field db ParameterDB
--- @field timestamp number Time of last access

--- Cache of opened odfs
--- @type table<string, ParameterDBCacheItem>
local OpenOdfs = {};

--- Cache of parameter values
--- @type table<string, table<string, table<string, any>>>
local DataCache = {};

local game_time = 0;
local time_next_purge = 60;

--- Open an ODF and return the ParameterDB handle.
--- Caches the ODF handle for reuse, purging old entries periodically.
--- @param odf string ODF file name
--- @return ParameterDB db
function M.OpenODF(odf)
    if not utility.isstring(odf) then error("Parameter odf must be a string."); end
    odf = odf:lower();

    local found = OpenOdfs[odf];
    if found then
        found.timestamp = game_time;
        return found.db;
    end

    --- @diagnostic disable-next-line: deprecated
    local odfHandle = OpenODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    OpenOdfs[odf] = { db = odfHandle, timestamp = game_time };

    return odfHandle;
end

--- @param odf string ODF file name
--- @return boolean is_gameobject
function M.IsGameObject(odf)
    local sig = M.GetClassSig(odf);
    return sig ~= nil;
end

--- @param odf string ODF file name
--- @return ClassLabel? classlabel
function M.GetClassLabel(odf)
    if not utility.isstring(odf) then error("Parameter odf must be a string."); end
    odf = odf:lower();

    local odfHandle = M.OpenODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    if DataCache[odf] and DataCache[odf]["gameobjectclass"] and DataCache[odf]["gameobjectclass"]["classlabel"] then
        return DataCache[odf]["gameobjectclass"]["classlabel"];
    end

    --- @diagnostic disable-next-line: deprecated
    local classLabel = GetODFString(odfHandle, "GameObjectClass", "classLabel");
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf]["gameobjectclass"] = DataCache[odf]["gameobjectclass"] or {};
    DataCache[odf]["gameobjectclass"]["classlabel"] = classLabel;
    return classLabel;
end

--- @param odf string ODF file name
--- @return ClassSig? classlabel
function M.GetClassSig(odf)
    local classLabel = M.GetClassLabel(odf);
    local classSig = utility.GetClassSig(classLabel);
    return classSig;
end

--- @param odf string ODF file name
--- @return integer scrap cost
function M.GetScrapCost(odf)
    if not utility.isstring(odf) then error("Parameter odf must be a string."); end
    odf = odf:lower();

    if DataCache[odf] and DataCache[odf]["gameobjectclass"] and DataCache[odf]["gameobjectclass"]["scrapcost"] then
        return DataCache[odf]["gameobjectclass"]["scrapcost"];
    end
    
    local odfHandle = M.OpenODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end
    local sig = M.GetClassSig(odf)
    if sig == nil then error("GetClassSig() returned nil."); end

    local scrap = 2147483647; -- GameObject default
    
    if sig == utility.ClassSig.person then
        scrap = 0;
    end

    --- @diagnostic disable-next-line: deprecated
    scrap = GetODFInt(odfHandle, "GameObjectClass", "scrapCost", scrap);
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf]["gameobjectclass"] = DataCache[odf]["gameobjectclass"] or {};
    DataCache[odf]["gameobjectclass"]["scrapcost"] = scrap;
    return scrap;
end

--- @param odf string ODF file name
--- @return integer pilot cost
function M.GetPilotCost(odf)
    if not utility.isstring(odf) then error("Parameter odf must be a string."); end
    odf = odf:lower();

    if DataCache[odf] and DataCache[odf]["gameobjectclass"] and DataCache[odf]["gameobjectclass"]["pilotcost"] then
        return DataCache[odf]["gameobjectclass"]["pilotcost"];
    end

    local odfHandle = M.OpenODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end
    local sig = M.GetClassSig(odf)
    if sig == nil then error("GetClassSig() returned nil."); end

    local pilot = 0; -- GameObject default

    if sig == utility.ClassSig.craft then
        pilot = 1;
    elseif sig == utility.ClassSig.person then
        pilot = 1;
    elseif sig == utility.ClassSig.producer then
        pilot = 0;
    elseif sig == utility.ClassSig.sav then
        pilot = 0;
    elseif sig == utility.ClassSig.torpedo then
        pilot = 0;
    elseif sig == utility.ClassSig.turret then
        pilot = 0;
    end

    --- @diagnostic disable-next-line: deprecated
    pilot = GetODFInt(odfHandle, "GameObjectClass", "pilotCost", pilot);
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf]["gameobjectclass"] = DataCache[odf]["gameobjectclass"] or {};
    DataCache[odf]["gameobjectclass"]["pilotcost"] = pilot;
    return pilot;
end

--- @todo This might not need to exist since it doesn't have special class code
--- @param odf string ODF file name
--- @return number time
function M.GetBuildTime(odf)
    if not utility.isstring(odf) then error("Parameter odf must be a string."); end
    odf = odf:lower();

    if DataCache[odf] and DataCache[odf]["gameobjectclass"] and DataCache[odf]["gameobjectclass"]["buildtime"] then
        return DataCache[odf]["gameobjectclass"]["buildtime"];
    end

    local odfHandle = M.OpenODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    --- @diagnostic disable-next-line: deprecated
    local buildTime = GetODFFloat(odfHandle, "GameObjectClass", "buildTime", 5.0);
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf]["gameobjectclass"] = DataCache[odf]["gameobjectclass"] or {};
    DataCache[odf]["gameobjectclass"]["buildtime"] = buildTime;
    return buildTime;
end

--- Get a general string without handling of class defaults.
--- @param odf string ODF file name
--- @param section string? Section name
--- @param key string Key name
--- @param default string? Default value if the key is not found
--- @return string value
function M.GetValueString(odf, section, key, default)
    if not utility.isstring(odf) then error("Parameter odf must be a string."); end
    if section ~= nil and not utility.isstring(section) then error("Parameter section must be a string or nil."); end
    if not utility.isstring(key) then error("Parameter key must be a string."); end
    odf = odf:lower();
    section = section and section:lower();
    key = key:lower();

    if DataCache[odf] and DataCache[odf][section or ""] and DataCache[odf][section or ""][key] then
        return DataCache[odf][section or ""][key];
    end

    local odfHandle = M.OpenODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    --- @diagnostic disable-next-line: deprecated
    local valueString = GetODFString(odfHandle, section, key, default);
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf][section or ""] = DataCache[odf][section or ""] or {};
    DataCache[odf][section or ""][key] = valueString;
    return valueString;
end

--- Get a general integer without handling of class defaults.
--- @param odf string ODF file name
--- @param section string? Section name
--- @param key string Key name
--- @param default integer? Default value if the key is not found
--- @return integer value
function M.GetValueInt(odf, section, key, default)
    if not utility.isstring(odf) then error("Parameter odf must be a string."); end
    if section ~= nil and not utility.isstring(section) then error("Parameter section must be a string or nil."); end
    if not utility.isstring(key) then error("Parameter key must be a string."); end
    odf = odf:lower();
    section = section and section:lower();
    key = key:lower();

    if DataCache[odf] and DataCache[odf][section or ""] and DataCache[odf][section or ""][key] then
        return DataCache[odf][section or ""][key];
    end

    local odfHandle = M.OpenODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    --- @diagnostic disable-next-line: deprecated
    local valueString = GetODFInt(odfHandle, section, key, default);
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf][section or ""] = DataCache[odf][section or ""] or {};
    DataCache[odf][section or ""][key] = valueString;
    return valueString;
end

--- Get a general float without handling of class defaults.
--- @param odf string ODF file name
--- @param section string? Section name
--- @param key string Key name
--- @param default number? Default value if the key is not found
--- @return number value
function M.GetValueFloat(odf, section, key, default)
    if not utility.isstring(odf) then error("Parameter odf must be a string."); end
    if section ~= nil and not utility.isstring(section) then error("Parameter section must be a string or nil."); end
    if not utility.isstring(key) then error("Parameter key must be a string."); end
    odf = odf:lower();
    section = section and section:lower();
    key = key:lower();

    if DataCache[odf] and DataCache[odf][section or ""] and DataCache[odf][section or ""][key] then
        return DataCache[odf][section or ""][key];
    end

    local odfHandle = M.OpenODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    --- @diagnostic disable-next-line: deprecated
    local valueString = GetODFFloat(odfHandle, section, key, default);
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf][section or ""] = DataCache[odf][section or ""] or {};
    DataCache[odf][section or ""][key] = valueString;
    return valueString;
end

--- Get a general boolean without handling of class defaults.
--- @param odf string ODF file name
--- @param section string? Section name
--- @param key string Key name
--- @param default boolean? Default value if the key is not found
--- @return boolean value
function M.GetValueBool(odf, section, key, default)
    if not utility.isstring(odf) then error("Parameter odf must be a string."); end
    if section ~= nil and not utility.isstring(section) then error("Parameter section must be a string or nil."); end
    if not utility.isstring(key) then error("Parameter key must be a string."); end
    odf = odf:lower();
    section = section and section:lower();
    key = key:lower();

    if DataCache[odf] and DataCache[odf][section or ""] and DataCache[odf][section or ""][key] then
        return DataCache[odf][section or ""][key];
    end

    local odfHandle = M.OpenODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    --- @diagnostic disable-next-line: deprecated
    local valueString = GetODFBool(odfHandle, section, key, default);
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf][section or ""] = DataCache[odf][section or ""] or {};
    DataCache[odf][section or ""][key] = valueString;
    return valueString;
end

hook.Add("Update", "_paramdb_Update", function(dtime, ttime)
    game_time = ttime;

    if game_time >= time_next_purge then
        local to_remove = {};
        for odf, item in pairs(OpenOdfs) do
            if (game_time - item.timestamp) > MAX_PARAMDB_CACHE_AGE then
                table.insert(to_remove, odf);
            end
        end
        for _, odf in ipairs(to_remove) do
            logger.print(logger.LogLevel.DEBUG, nil, "Purging ODF from cache: "..odf);
            OpenOdfs[odf] = nil;
        end
        time_next_purge = game_time + PURGE_PARAMDB_CHECK_INTERVAL;
    end
end, config.get("hook_priority.Update.ParamDB"));

hook.AddSaveLoad("_paramdb", function()
    return game_time, time_next_purge
end, function(saved_game_time, saved_time_next_purge)
    game_time = saved_game_time or 0;
    time_next_purge = saved_time_next_purge or PURGE_PARAMDB_CHECK_INTERVAL;
    OpenOdfs = {};
end);

logger.print(logger.LogLevel.DEBUG, nil, "_paramdb Loaded");

return M;