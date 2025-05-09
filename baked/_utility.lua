--- BZ98R LUA Extended API Utility.
--- 
--- Crude custom type to make data not save/load exploiting the custom type system.
--- 
--- @module _utility
--- @author John "Nielk1" Klein
--- @alias utility
--- @usage local utility = require("_utility");
--- 
--- utility.Register(ObjectDef);

local debugprint = debugprint or function(...) end;

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
--- For example, `ClassLabels["PROD"]` returns `"producer"`, and `ClassLabels["producer"]` returns `"PROD"`.
--- @table ClassLabels
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

--- Convert human readable color names to BZ98R color labels.
--- @table ColorLabels
ColorLabels = {
    Black      = "BLACK",    -- BLACK:    <div style="background-color: #000000; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">BLACK</div>
    DarkGrey   = "DKGREY",   -- DKGREY:   <div style="background-color: #4C4C4C; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">DKGREY</div>
    Grey       = "GREY",     -- GREY:     <div style="background-color: #999999; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">GREY</div>
    White      = "WHITE",    -- WHITE:    <div style="background-color: #FFFFFF; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">WHITE</div>
    Blue       = "BLUE",     -- BLUE:     <div style="background-color: #007FFF; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">BLUE</div>
    DarkBlue   = "DKBLUE",   -- DKBLUE:   <div style="background-color: #004C99; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">DKBLUE</div>
    Green      = "GREEN",    -- GREEN:    <div style="background-color: #00FF00; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">GREEN</div>
    DarkGreen  = "DKGREEN",  -- DKGREEN:  <div style="background-color: #009900; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">DKGREEN</div>
    Yellow     = "YELLOW",   -- YELLOW:   <div style="background-color: #FFFF00; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">YELLOW</div>
    DarkYellow = "DKYELLOW", -- DKYELLOW: <div style="background-color: #999900; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">DKYELLOW</div>
    Red        = "RED",      -- RED:      <div style="background-color: #FF0000; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">RED</div>
    DarkRed    = "DKRED",    -- DKRED:    <div style="background-color: #990000; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">DKRED</div>
}

--- Convert BZ98R color labels to RGB color codes.
--- This probably isn't useful but it's here.
--- @table ColorCodes
local colorCodes = {
    BLACK    = 0x000000FF, -- 0x000000FF: <div style="background-color: #000000; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">BLACK</div>
    DKGREY   = 0x4C4C4CFF, -- 0x4C4C4CFF: <div style="background-color: #4C4C4C; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">DKGREY</div>
    GREY     = 0x999999FF, -- 0x999999FF: <div style="background-color: #999999; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">GREY</div>
    WHITE    = 0xFFFFFFFF, -- 0xFFFFFFFF: <div style="background-color: #FFFFFF; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">WHITE</div>
    BLUE     = 0x007FFFFF, -- 0x007FFFFF: <div style="background-color: #007FFF; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">BLUE</div>
    DKBLUE   = 0x004C99FF, -- 0x004C99FF: <div style="background-color: #004C99; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">DKBLUE</div>
    GREEN    = 0x00FF00FF, -- 0x00FF00FF: <div style="background-color: #00FF00; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">GREEN</div>
    DKGREEN  = 0x009900FF, -- 0x009900FF: <div style="background-color: #009900; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">DKGREEN</div>
    YELLOW   = 0xFFFF00FF, -- 0xFFFF00FF: <div style="background-color: #FFFF00; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">YELLOW</div>
    DKYELLOW = 0x999900FF, -- 0x999900FF: <div style="background-color: #999900; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">DKYELLOW</div>
    RED      = 0xFF0000FF, -- 0xFF0000FF: <div style="background-color: #FF0000; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">RED</div>
    DKRED    = 0x990000FF, -- 0x990000FF: <div style="background-color: #990000; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">DKRED</div>
    CYAN     = 0x00FFFFFF, -- 0x00FFFFFF: <div style="background-color: #00FFFF; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">CYAN</div>
    DKCYAN   = 0x009999FF, -- 0x009999FF: <div style="background-color: #009999; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;">DKCYAN</div>
}

-------------------------------------------------------------------------------
-- Type Check Functions
-------------------------------------------------------------------------------
-- @section

--- Is this object a function?
--- @param object Object in question
--- @treturn bool
function utility_module.isfunction(object)
    return (type(object) == "function");
end

--- Is this object a table?
--- @param object Object in question
--- @treturn bool
function utility_module.istable(object)
    return (type(object) == 'table');
end

--- Is this object a string?
--- @param object Object in question
--- @treturn bool
function utility_module.isstring(object)
    return (type(object) == "string");
end

--- Is this object a boolean?
--- @param object Object in question
--- @treturn bool
function utility_module.isboolean(object)
    return (type(object) == "boolean");
end

--- Is this object a number?
--- @param object Object in question
--- @treturn bool
function utility_module.isnumber(object)
    return (type(object) == "number");
end

--- Is this object an integer?
--- @param object Object in question
--- @treturn bool
function utility_module.isinteger(object)
    if not utility_module.isnumber(object) then return false end;
    return object == math.floor(object);
end

-------------------------------------------------------------------------------
-- Utility - Table Operations
-------------------------------------------------------------------------------
-- @section

function utility_module.shallowCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = v
    end
    return copy
end

-------------------------------------------------------------------------------
-- Utility - Iterator Operations
-------------------------------------------------------------------------------
-- @section

--- Convert an iterator to an array.
--- This function takes an iterator and converts it to an array. It handles both array-like and non-array-like iterators.
--- @param iterator The iterator to convert
--- @return An array containing the values from the iterator
function IteratorToArray(iterator)
    local array = {}
    for index, value in iterator do
        if type(index) == "number" and index > 0 and math.floor(index) == index then
            -- Use the index directly if it's a positive integer
            array[index] = value
        else
            -- Fallback to table.insert for non-array-like indexes
            table.insert(array, value)
        end
    end
    return array
end

-------------------------------------------------------------------------------
-- Utility - Core
-------------------------------------------------------------------------------
-- @section

--utility_module = setmetatable(utility_module, utility_module_meta);

debugprint("_utility Loaded");

return utility_module;