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
--- @type table<string, table<string, table<string, {[1]: any, [2]: boolean}>>>
local DataCache = {};

local game_time = 0;
local time_next_purge = 60;

--- Open an ODF and return the ParameterDB handle.
--- Caches the ODF handle for reuse, purging old entries periodically.
--- @param odf string ODF file name
--- @return ParameterDB db
local function OpenAndCacheODF(odf)
    if not utility.IsString(odf) then error("Parameter odf must be a string."); end
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
--- @return boolean success
function M.GetClassLabel(odf)
    if not utility.IsString(odf) then error("Parameter odf must be a string."); end
    odf = odf:lower();

    local odfHandle = OpenAndCacheODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    if DataCache[odf] and DataCache[odf]["gameobjectclass"] and DataCache[odf]["gameobjectclass"]["classlabel"] then
        return DataCache[odf]["gameobjectclass"]["classlabel"][1], DataCache[odf]["gameobjectclass"]["classlabel"][2];
    end

    --- @diagnostic disable-next-line: deprecated
    local classLabel, success = GetODFString(odfHandle, "GameObjectClass", "classLabel");
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf]["gameobjectclass"] = DataCache[odf]["gameobjectclass"] or {};
    DataCache[odf]["gameobjectclass"]["classlabel"] = { classLabel, success };
    return classLabel, success;
end

--- @param odf string ODF file name
--- @return ClassSig? classlabel
--- @return boolean success
function M.GetClassSig(odf)
    local classLabel, success = M.GetClassLabel(odf);
    if not success then return nil, false; end
    local classSig = utility.GetClassSig(classLabel);
    return classSig, success;
end

--- @param odf string ODF file name
--- @return integer scrap cost
--- @return boolean success
function M.GetScrapCost(odf)
    if not utility.IsString(odf) then error("Parameter odf must be a string."); end
    odf = odf:lower();

    if DataCache[odf] and DataCache[odf]["gameobjectclass"] and DataCache[odf]["gameobjectclass"]["scrapcost"] then
        return DataCache[odf]["gameobjectclass"]["scrapcost"][1], DataCache[odf]["gameobjectclass"]["scrapcost"][2];
    end
    
    local odfHandle = OpenAndCacheODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end
    local sig = M.GetClassSig(odf)
    if sig == nil then error("GetClassSig() returned nil."); end

    local scrap = 2147483647; -- GameObject default
    
    if sig == utility.ClassSig.person then
        scrap = 0;
    end

    local success = false;
    --- @diagnostic disable-next-line: deprecated
    scrap, success = GetODFInt(odfHandle, "GameObjectClass", "scrapCost", scrap);
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf]["gameobjectclass"] = DataCache[odf]["gameobjectclass"] or {};
    DataCache[odf]["gameobjectclass"]["scrapcost"] = { scrap, success };
    return scrap, success;
end

--- @param odf string ODF file name
--- @return integer pilot cost
--- @return boolean success
function M.GetPilotCost(odf)
    if not utility.IsString(odf) then error("Parameter odf must be a string."); end
    odf = odf:lower();

    if DataCache[odf] and DataCache[odf]["gameobjectclass"] and DataCache[odf]["gameobjectclass"]["pilotcost"] then
        return DataCache[odf]["gameobjectclass"]["pilotcost"][1], DataCache[odf]["gameobjectclass"]["pilotcost"][2];
    end

    local odfHandle = OpenAndCacheODF(odf);
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

    local success = false;
    --- @diagnostic disable-next-line: deprecated
    pilot, success = GetODFInt(odfHandle, "GameObjectClass", "pilotCost", pilot);
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf]["gameobjectclass"] = DataCache[odf]["gameobjectclass"] or {};
    DataCache[odf]["gameobjectclass"]["pilotcost"] = { pilot, success };
    return pilot, success;
end

--- @todo This might not need to exist since it doesn't have special class code
--- @param odf string ODF file name
--- @return number time
--- @return boolean success
function M.GetBuildTime(odf)
    if not utility.IsString(odf) then error("Parameter odf must be a string."); end
    odf = odf:lower();

    if DataCache[odf] and DataCache[odf]["gameobjectclass"] and DataCache[odf]["gameobjectclass"]["buildtime"] then
        return DataCache[odf]["gameobjectclass"]["buildtime"][1], DataCache[odf]["gameobjectclass"]["buildtime"][2];
    end

    local odfHandle = OpenAndCacheODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    --- @diagnostic disable-next-line: deprecated
    local buildTime, success = GetODFFloat(odfHandle, "GameObjectClass", "buildTime", 5.0);
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf]["gameobjectclass"] = DataCache[odf]["gameobjectclass"] or {};
    DataCache[odf]["gameobjectclass"]["buildtime"] = { buildTime, success };
    return buildTime, success;
end

--- Get a general string without handling of class defaults.
--- @param odf string ODF file name
--- @param section string? Section name
--- @param key string Key name
--- @param default string? Default value if the key is not found
--- @return string value
--- @return boolean success
function M.GetValueString(odf, section, key, default)
    if not utility.IsString(odf) then error("Parameter odf must be a string."); end
    if section ~= nil and not utility.IsString(section) then error("Parameter section must be a string or nil."); end
    if not utility.IsString(key) then error("Parameter key must be a string."); end
    odf = odf:lower();
    section = section and section:lower();
    key = key:lower();

    if DataCache[odf] and DataCache[odf][section or ""] and DataCache[odf][section or ""][key] then
        return DataCache[odf][section or ""][key][1], DataCache[odf][section or ""][key][2];
    end

    local odfHandle = OpenAndCacheODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    --- @diagnostic disable-next-line: deprecated
    local valueString, success = GetODFString(odfHandle, section, key, default);
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf][section or ""] = DataCache[odf][section or ""] or {};
    DataCache[odf][section or ""][key] = { valueString, success };
    return valueString, success;
end

--- Get a general integer without handling of class defaults.
--- @param odf string ODF file name
--- @param section string? Section name
--- @param key string Key name
--- @param default integer? Default value if the key is not found
--- @return integer value
--- @return boolean success
function M.GetValueInt(odf, section, key, default)
    if not utility.IsString(odf) then error("Parameter odf must be a string."); end
    if section ~= nil and not utility.IsString(section) then error("Parameter section must be a string or nil."); end
    if not utility.IsString(key) then error("Parameter key must be a string."); end
    odf = odf:lower();
    section = section and section:lower();
    key = key:lower();

    if DataCache[odf] and DataCache[odf][section or ""] and DataCache[odf][section or ""][key] then
        return DataCache[odf][section or ""][key][1], DataCache[odf][section or ""][key][2];
    end

    local odfHandle = OpenAndCacheODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    --- @diagnostic disable-next-line: deprecated
    local valueString, success = GetODFInt(odfHandle, section, key, default);
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf][section or ""] = DataCache[odf][section or ""] or {};
    DataCache[odf][section or ""][key] = { valueString, success };
    return valueString, success;
end

--- Get a general float without handling of class defaults.
--- @param odf string ODF file name
--- @param section string? Section name
--- @param key string Key name
--- @param default number? Default value if the key is not found
--- @return number value
--- @return boolean success
function M.GetValueFloat(odf, section, key, default)
    if not utility.IsString(odf) then error("Parameter odf must be a string."); end
    if section ~= nil and not utility.IsString(section) then error("Parameter section must be a string or nil."); end
    if not utility.IsString(key) then error("Parameter key must be a string."); end
    odf = odf:lower();
    section = section and section:lower();
    key = key:lower();

    if DataCache[odf] and DataCache[odf][section or ""] and DataCache[odf][section or ""][key] then
        return DataCache[odf][section or ""][key][1], DataCache[odf][section or ""][key][2];
    end

    local odfHandle = OpenAndCacheODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    --- @diagnostic disable-next-line: deprecated
    local valueString, success = GetODFFloat(odfHandle, section, key, default);
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf][section or ""] = DataCache[odf][section or ""] or {};
    DataCache[odf][section or ""][key] = { valueString, success };
    return valueString, success;
end

--- Get a general boolean without handling of class defaults.
--- @param odf string ODF file name
--- @param section string? Section name
--- @param key string Key name
--- @param default boolean? Default value if the key is not found
--- @return boolean value
--- @return boolean success
function M.GetValueBool(odf, section, key, default)
    if not utility.IsString(odf) then error("Parameter odf must be a string."); end
    if section ~= nil and not utility.IsString(section) then error("Parameter section must be a string or nil."); end
    if not utility.IsString(key) then error("Parameter key must be a string."); end
    odf = odf:lower();
    section = section and section:lower();
    key = key:lower();

    if DataCache[odf] and DataCache[odf][section or ""] and DataCache[odf][section or ""][key] then
        return DataCache[odf][section or ""][key][1], DataCache[odf][section or ""][key][2];
    end

    local odfHandle = OpenAndCacheODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    --- @diagnostic disable-next-line: deprecated
    local valueString, success = GetODFBool(odfHandle, section, key, default);
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf][section or ""] = DataCache[odf][section or ""] or {};
    DataCache[odf][section or ""][key] = { valueString, success };
    return valueString, success;
end

--- @param odf string ODF file name
--- @param section string? Section name
--- @param key string Key name
--- @param default integer? Default value if the key is not found or is a boolean false
--- @param boolVal integer? Value to return if the key is found and is a boolean true
--- @param enumTable table<string, integer> Lookup table to convert enum value, a failed lookup will be considered a failure
--- @return integer, boolean
function M.GetValueIntegerEnum(odf, section, key, default, boolVal, enumTable)
    if not utility.IsString(odf) then error("Parameter odf must be a string."); end
    if section ~= nil and not utility.IsString(section) then error("Parameter section must be a string or nil."); end
    if not utility.IsString(key) then error("Parameter key must be a string."); end
    if enumTable == nil or type(enumTable) ~= "table" then error("Parameter enumTable must be a table."); end
    odf = odf:lower();
    section = section and section:lower();
    key = key:lower();

    if DataCache[odf] and DataCache[odf][section or ""] and DataCache[odf][section or ""][key] then
        return DataCache[odf][section or ""][key][1], DataCache[odf][section or ""][key][2];
    end

    local odfHandle = OpenAndCacheODF(odf);
    if odfHandle == nil then error("OpenODF() returned nil."); end

    --- @type integer?
    local value;
    --- @type boolean?
    local success;
    --- @diagnostic disable-next-line: deprecated
    local value, success = GetODFString(odfHandle, section, key);
    if success then
        --- @diagnostic disable-next-line: cast-type-mismatch
        --- @cast value string?
        if enumTable[value] then
            --- @diagnostic disable-next-line: cast-local-type
            value = enumTable[value];
        else
            success = false;
        end
    end
    if not success then
        --- @diagnostic disable-next-line: cast-type-mismatch
        --- @cast value integer?
        --- @diagnostic disable-next-line: cast-local-type, deprecated
        value, success = GetODFInt(odfHandle, section, key);
    end
    if not success then
        --- @diagnostic disable-next-line: cast-type-mismatch
        --- @cast value boolean?
        --- @diagnostic disable-next-line: cast-local-type, deprecated
        value, success = GetODFBool(odfHandle, section, key);
        if success then
            if value then
                --- @diagnostic disable-next-line: cast-type-mismatch
                --- @cast value integer?
                --- @diagnostic disable-next-line: cast-local-type
                value = boolVal;
            else
                --- @diagnostic disable-next-line: cast-type-mismatch
                --- @cast value integer?
                --- @diagnostic disable-next-line: cast-local-type
                value = default;
            end
        end
    end
    --- @diagnostic disable-next-line: cast-type-mismatch
    --- @cast value integer
   
    DataCache[odf] = DataCache[odf] or {};
    DataCache[odf][section or ""] = DataCache[odf][section or ""] or {};
    DataCache[odf][section or ""][key] = { value, success };
    return value, success;
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
end, config.lock().hook_priority.Update.ParamDB);

hook.AddSaveLoad("_paramdb", function()
    return game_time, time_next_purge
end, function(saved_game_time, saved_time_next_purge)
    game_time = saved_game_time or 0;
    time_next_purge = saved_time_next_purge or PURGE_PARAMDB_CHECK_INTERVAL;
    OpenOdfs = {};
end);

logger.print(logger.LogLevel.DEBUG, nil, "_paramdb Loaded");

return M;