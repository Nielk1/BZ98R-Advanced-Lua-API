--- BZCC LUA Extended API Utility.
-- 
-- Crude custom type to make data not save/load exploiting the custom type system.
-- 
-- @module _utility
-- @author John "Nielk1" Klein
-- @alias utility
-- @usage local utility = require("_utility");
-- 
-- utility.Register(ObjectDef);

local debugprint = debugprint or function() end;

debugprint("_utility Loading");

local utility_module = {};
--local utility_module_meta = {};

--utility_meta.__index = function(table, key)
--    local retVal = rawget(table, key);
--    if retVal ~= nil then
--        return retVal; -- found in table
--    end
--    return rawget(utility_meta, key); -- move on to base (looking for functions)
--end

-------------------------------------------------------------------------------
-- Enumerations
-------------------------------------------------------------------------------
-- @section

--- This is a table that converts between class labels and class signatures.
-- For example, `ClassLabels["PROD"]` returns `"producer"`, and `ClassLabels["producer"]` returns `"PROD"`.
-- @table ClassLabels
utility_module.ClassLabel = {
    ["PROD"] = "producer", -- producer
    ["HOVR"] = "hover", -- hover
    ["WEPN"] = "weapon", -- weapon
    ["GOBJ"] = "gameobject", -- gameobject
    ["ORDN"] = "ordnance", -- ordnance
    ["APC\0"] = "apc", -- apc
    ["APC"] = "apc", -- apc (compatability)
    ["ARMR"] = "armory", -- armory
    ["CNST"] = "constructionrig", -- constructionrig
    ["FACT"] = "factory", -- factory
    ["PLNT"] = "powerplant", -- powerplant
    ["RCYC"] = "recycler", -- recycler
    ["SCAV"] = "scavenger", -- scavenger
    ["SDRP"] = "dropoff", -- scrap dropoff
    ["SDEP"] = "supplydepot", -- supply depot
    ["TUG\0"] = "tug", -- tug
    ["TUG"] = "tug", -- tug (compatability)
    ["TTNK"] = "turrettank", -- turret tank
    ["ARTI"] = "artifact", -- artifact
    ["BARR"] = "barracks", -- barracks
    ["BLDG"] = "i76building", -- building
    ["COMM"] = "commtower", -- comm tower
    ["CRFT"] = "craft", -- craft
    ["WRCK"] = "daywrecker", -- daywrecker
    ["GEIZ"] = "geyser", -- geyser
    ["MLYR"] = "minelayer", -- minelayer
    ["PERS"] = "person", -- person
    ["PWUP"] = "powerup", -- powerup
    ["CPOD"] = "camerapod", -- camera pod
    ["AMMO"] = "ammopack", -- ammo pack
    ["RKIT"] = "repairkit", -- repair kit
    ["RDEP"] = "repairdepot", -- repair depot
    ["SAV\0"] = "sav", -- sav
    ["SAV"] = "sav", -- sav (compatability)
    ["SFLD"] = "scrapfield", -- scrap field
    ["SILO"] = "scrapsilo", -- scrap silo
    ["SHLD"] = "shieldtower", -- shield tower
    ["SPWN"] = "spawnpnt", -- spawn buoy
    ["TORP"] = "torpedo", -- torpedo
    ["WING"] = "wingman", -- wingman
    ["HWTZ"] = "howitzer", -- howitzer
    ["TURR"] = "turret", -- turret
    ["WALK"] = "walker", -- walker
    ["SCRP"] = "scrap", -- scrap

    ["producer"] = "PROD", -- producer
    ["hover"] = "HOVR", -- hover
    ["weapon"] = "WEPN", -- weapon
    ["gameobject"] = "GOBJ", -- gameobject
    ["ordnance"] = "ORDN", -- ordnance
    ["apc"] = "APC\0", -- apc
    ["armory"] = "ARMR", -- armory
    ["constructionrig"] = "CNST", -- construction rig
    ["factory"] = "FACT", -- factory
    ["powerplant"] = "PLNT", -- power plant
    ["recycler"] = "RCYC", -- recycler
    ["scavenger"] = "SCAV", -- scavenger
    ["dropoff"] = "SDRP", -- scrap dropoff
    ["supplydepot"] = "SDEP", -- supply depot
    ["tug"] = "TUG\0", -- tug
    ["turrettank"] = "TTNK", -- turret tank
    ["artifact"] = "ARTI", -- artifact
    ["barracks"] = "BARR", -- barracks
    ["i76building"] = "BLDG", -- building
    ["commtower"] = "COMM", -- comm tower
    ["craft"] = "CRFT", -- craft
    ["daywrecker"] = "WRCK", -- daywrecker
    ["geyser"] = "GEIZ", -- geyser
    ["minelayer"] = "MLYR", -- minelayer
    ["person"] = "PERS", -- person
    ["powerup"] = "PWUP", -- powerup
    ["camerapod"] = "CPOD", -- camera pod
    ["ammopack"] = "AMMO", -- ammo pack
    ["repairkit"] = "RKIT", -- repair kit
    ["repairdepot"] = "RDEP", -- repair depot
    ["sav"] = "SAV\0", -- sav
    ["scrapfield"] = "SFLD", -- scrap field
    ["scrapsilo"] = "SILO", -- scrap silo
    ["shieldtower"] = "SHLD", -- shield tower
    ["spawnpnt"] = "SPWN", -- spawn buoy
    ["torpedo"] = "TORP", -- torpedo
    ["wingman"] = "WING", -- wingman
    ["howitzer"] = "HWTZ", -- howitzer
    ["turret"] = "TURR", -- turret
    ["walker"] = "WALK", -- walker
    ["scrap"] = "SCRP", -- scrap
};

-------------------------------------------------------------------------------
-- Type Check Functions
-------------------------------------------------------------------------------
-- @section

--- Is this object a function?
-- @param object Object in question
-- @treturn bool
function utility_module.isfunction(object)
    return (type(object) == "function");
end

--- Is this object a table?
-- @param object Object in question
-- @treturn bool
function utility_module.istable(object)
    return (type(object) == 'table');
end

--- Is this object a string?
-- @param object Object in question
-- @treturn bool
function utility_module.isstring(object)
    return (type(object) == "string");
end

--- Is this object a boolean?
-- @param object Object in question
-- @treturn bool
function utility_module.isboolean(object)
    return (type(object) == "boolean");
end

--- Is this object a number?
-- @param object Object in question
-- @treturn bool
function utility_module.isnumber(object)
    return (type(object) == "number");
end

--- Is this object an integer?
-- @param object Object in question
-- @treturn bool
function utility_module.isinteger(object)
    if not utility_module.isnumber(object) then return false end;
    return object == math.floor(object);
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Utility - Table Operations
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

function utility_module.shallowCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = v
    end
    return copy
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Utility - Core
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

--utility_module = setmetatable(utility_module, utility_module_meta);

debugprint("_utility Loaded");

return utility_module;