--- BZ98R LUA Extended API Utility.
---
--- Crude custom type to make data not save/load exploiting the custom type system.
---
--- @module '_utility'
--- @author John "Nielk1" Klein
--- @usage local utility = require("_utility");
--- 
--- utility.Register(ObjectDef);

local debugprint = debugprint or function(...) end;

debugprint("_utility Loading");

local M = {};
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
--- @enum ClassLabels
M.ClassLabel = {
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
--- @enum ColorLabels
M.ColorLabels = {
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
--- @enum ColorCodes
M.colorCodes = {
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

--- RAVE GUN! color cycle.
--- Each color is represented as a hexadecimal number: 0xRRGGBB.
--- @enum RAVE_COLOR
M.RAVE_COLOR = {
    [1] = 0xFF0000FF, -- 1: <div style="background-color: #FF0000; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [2] = 0xFF3300FF, -- 2: <div style="background-color: #FF3300; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [3] = 0xFF6600FF, -- 3: <div style="background-color: #FF6600; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [4] = 0xFF9900FF, -- 4: <div style="background-color: #FF9900; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>

    [5] = 0xFFCC00FF, -- 5: <div style="background-color: #FFCC00; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [6] = 0xFFFF00FF, -- 6: <div style="background-color: #FFFF00; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [7] = 0xCCFF00FF, -- 7: <div style="background-color: #CCFF00; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [8] = 0x99FF00FF, -- 8: <div style="background-color: #99FF00; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>

    [9] = 0x66FF00FF, -- 9: <div style="background-color: #66FF00; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [10] = 0x33FF00FF, -- 10: <div style="background-color: #33FF00; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [11] = 0x00FF00FF, -- 11: <div style="background-color: #00FF00; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [12] = 0x00FF33FF, -- 12: <div style="background-color: #00FF33; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>

    [13] = 0x00FF66FF, -- 13: <div style="background-color: #00FF66; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [14] = 0x00FF99FF, -- 14: <div style="background-color: #00FF99; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [15] = 0x00FFCCFF, -- 15: <div style="background-color: #00FFCC; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [16] = 0x00FFFFFF, -- 16: <div style="background-color: #00FFFF; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>

    [17] = 0x00CCFFFF, -- 17: <div style="background-color: #00CCFF; color: #000; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [18] = 0x0099FFFF, -- 18: <div style="background-color: #0099FF; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [19] = 0x0066FFFF, -- 19: <div style="background-color: #0066FF; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [20] = 0x0033FFFF, -- 20: <div style="background-color: #0033FF; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>

    [21] = 0x0000FFFF, -- 21: <div style="background-color: #0000FF; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [22] = 0x3300FFFF, -- 22: <div style="background-color: #3300FF; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [23] = 0x6600FFFF, -- 23: <div style="background-color: #6600FF; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [24] = 0x9900FFFF, -- 24: <div style="background-color: #9900FF; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>

    [25] = 0xCC00FFFF, -- 25: <div style="background-color: #CC00FF; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [26] = 0xFF00FFFF, -- 26: <div style="background-color: #FF00FF; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [27] = 0xFF00CCFF, -- 27: <div style="background-color: #FF00CC; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [28] = 0xFF0099FF, -- 28: <div style="background-color: #FF0099; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>

    [29] = 0xFF0066FF, -- 29: <div style="background-color: #FF0066; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
    [30] = 0xFF0033FF, -- 30: <div style="background-color: #FF0033; color: #FFF; text-align: center; display: inline-block; margin-left: 4px; width: 100px; height: calc(1em + 2px); border: 1px solid black;"></div>
}

-------------------------------------------------------------------------------
-- Type Check Functions
-------------------------------------------------------------------------------
-- @section

--- Is this object a function?
--- @param object any Object in question
--- @return boolean
function M.isfunction(object)
    return (type(object) == "function");
end

--- Is this object a table?
--- @param object any Object in question
--- @return boolean
function M.istable(object)
    return (type(object) == 'table');
end

--- Is this object a string?
--- @param object any Object in question
--- @return boolean
function M.isstring(object)
    return (type(object) == "string");
end

--- Is this object a boolean?
--- @param object any Object in question
--- @return boolean
function M.isboolean(object)
    return (type(object) == "boolean");
end

--- Is this object a number?
--- @param object any Object in question
--- @return boolean
function M.isnumber(object)
    return (type(object) == "number");
end

--- Is this object an integer?
--- @param object any Object in question
--- @return boolean
function M.isinteger(object)
    if not M.isnumber(object) then return false end;
    return object == math.floor(object);
end

--- Is this object a Handle?
--- @param object any Object in question
--- @return boolean
function M.isHandle(object)
    if type(object) ~= "userdata" then
        return false
    end
    local mt = getmetatable(object)
    return mt and mt.__name == "BZHandle"
end

--- Is this object a Vector?
--- @param object any Object in question
--- @return boolean
function M.isVector(object)
    if type(object) ~= "userdata" then
        return false
    end
    local mt = getmetatable(object)
    return mt and mt.__name == "VECTOR_3D"
end

--- Is this object a Matrix?
--- @param object any Object in question
--- @return boolean
function M.isMatrix(object)
    if type(object) ~= "userdata" then
        return false
    end
    local mt = getmetatable(object)
    return mt and mt.__name == "MAT_3D"
end

-------------------------------------------------------------------------------
-- Utility - Table Operations
-------------------------------------------------------------------------------
-- @section

function M.shallowCopy(original)
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
--- @param iterator function The iterator to convert
--- @return any[] array An array containing the values from the iterator
function M.IteratorToArray(iterator)
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

return M;