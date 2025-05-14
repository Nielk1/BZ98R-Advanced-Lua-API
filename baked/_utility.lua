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

--- ClassLabels
--- @enum ClassLabel
M.ClassLabel = {
    ["PROD"]  = "producer",        -- producer
    ["HOVR"]  = "hover",           -- hover
    ["WEPN"]  = "weapon",          -- weapon
    ["GOBJ"]  = "gameobject",      -- gameobject
    ["ORDN"]  = "ordnance",        -- ordnance
    ["APC\0"] = "apc",             -- apc
    ["APC"]   = "apc",             -- apc <i>(compatability)</i>
    ["ARMR"]  = "armory",          -- armory
    ["CNST"]  = "constructionrig", -- constructionrig
    ["FACT"]  = "factory",         -- factory
    ["PLNT"]  = "powerplant",      -- powerplant
    ["RCYC"]  = "recycler",        -- recycler
    ["SCAV"]  = "scavenger",       -- scavenger
    ["SDRP"]  = "dropoff",         -- scrap dropoff
    ["SDEP"]  = "supplydepot",     -- supply depot
    ["TUG\0"] = "tug",             -- tug
    ["TUG"]   = "tug",             -- tug <i>(compatability)</i>
    ["TTNK"]  = "turrettank",      -- turret tank
    ["ARTI"]  = "artifact",        -- artifact
    ["BARR"]  = "barracks",        -- barracks
    ["BLDG"]  = "i76building",     -- building
    ["COMM"]  = "commtower",       -- comm tower
    ["CRFT"]  = "craft",           -- craft
    ["WRCK"]  = "daywrecker",      -- daywrecker
    ["GEIZ"]  = "geyser",          -- geyser
    ["MLYR"]  = "minelayer",       -- minelayer
    ["PERS"]  = "person",          -- person
    ["PWUP"]  = "powerup",         -- powerup
    ["CPOD"]  = "camerapod",       -- camera pod
    ["AMMO"]  = "ammopack",        -- ammo pack
    ["RKIT"]  = "repairkit",       -- repair kit
    ["RDEP"]  = "repairdepot",     -- repair depot
    ["SAV\0"] = "sav",             -- sav
    ["SAV"]   = "sav",             -- sav <i>(compatability)</i>
    ["SFLD"]  = "scrapfield",      -- scrap field
    ["SILO"]  = "scrapsilo",       -- scrap silo
    ["SHLD"]  = "shieldtower",     -- shield tower
    ["SPWN"]  = "spawnpnt",        -- spawn buoy
    ["TORP"]  = "torpedo",         -- torpedo
    ["WING"]  = "wingman",         -- wingman
    ["HWTZ"]  = "howitzer",        -- howitzer
    ["TURR"]  = "turret",          -- turret
    ["WALK"]  = "walker",          -- walker
    ["SCRP"]  = "scrap",           -- scrap
};

--- ClassSigs
--- @enum ClassSig
M.ClassSig = {
    ["producer"]        = "PROD",  -- PROD
    ["hover"]           = "HOVR",  -- HOVR
    ["weapon"]          = "WEPN",  -- WEPN
    ["gameobject"]      = "GOBJ",  -- GOBJ
    ["ordnance"]        = "ORDN",  -- ORDN
    ["apc"]             = "APC\0", -- APC\0
    ["armory"]          = "ARMR",  -- ARMR
    ["constructionrig"] = "CNST",  -- CNST
    ["factory"]         = "FACT",  -- FACT
    ["powerplant"]      = "PLNT",  -- PLNT
    ["recycler"]        = "RCYC",  -- RCYC
    ["scavenger"]       = "SCAV",  -- SCAV
    ["dropoff"]         = "SDRP",  -- SDRP
    ["supplydepot"]     = "SDEP",  -- SDEP
    ["tug"]             = "TUG\0", -- TUG\0
    ["turrettank"]      = "TTNK",  -- TTNK
    ["artifact"]        = "ARTI",  -- ARTI
    ["barracks"]        = "BARR",  -- BARR
    ["i76building"]     = "BLDG",  -- BLDG
    ["commtower"]       = "COMM",  -- COMM
    ["craft"]           = "CRFT",  -- CRFT
    ["daywrecker"]      = "WRCK",  -- WRCK
    ["geyser"]          = "GEIZ",  -- GEIZ
    ["minelayer"]       = "MLYR",  -- MLYR
    ["person"]          = "PERS",  -- PERS
    ["powerup"]         = "PWUP",  -- PWUP
    ["camerapod"]       = "CPOD",  -- CPOD
    ["ammopack"]        = "AMMO",  -- AMMO
    ["repairkit"]       = "RKIT",  -- RKIT
    ["repairdepot"]     = "RDEP",  -- RDEP
    ["sav"]             = "SAV\0", -- SAV\0
    ["scrapfield"]      = "SFLD",  -- SFLD
    ["scrapsilo"]       = "SILO",  -- SILO
    ["shieldtower"]     = "SHLD",  -- SHLD
    ["spawnpnt"]        = "SPWN",  -- SPWN
    ["torpedo"]         = "TORP",  -- TORP
    ["wingman"]         = "WING",  -- WING
    ["howitzer"]        = "HWTZ",  -- HWTZ
    ["turret"]          = "TURR",  -- TURR
    ["walker"]          = "WALK",  -- WALK
    ["scrap"]           = "SCRP",  -- SCRP
};

--- Get the ClassLabel string for any ClassSig or ClassLabel.
--- This will attempt to infer from the input what the desired ClassLabel is.
--- Note that some of the raw mapping tables have some illegal input mappings so these functions are the optimal converter to use.
--- @param input ClassSig|ClassLabel|string The class label or class signature.
--- @return ClassLabel? classLabel The class label.
function M.GetClassLabel(input)
    if input == nil then return nil; end

    -- test input in ClassSig to ClassLabel map
    -- note this includes some illegal mangled ClassSigs as keys
    local value = M.ClassLabel[input:upper()];
    if value ~= nil then
        return value;
    end

    -- test input as key in ClassSig key list
    -- this only has valid ClassLabels as keys
    input = input:lower();
    if M.ClassSig[input] ~= nil then
        -- input was a ClassLabel, not a ClassSig
        return input;
    end

    return nil;
end

--- Get the ClassSig string for any ClassLabel or ClassSig.
--- This will attempt to infer from the input what the desired ClassSig is.
--- Note that some of the raw mapping tables have some illegal input mappings so these functions are the optimal converter to use.
--- @param input ClassLabel|ClassSig|string The class label or class signature.
--- @return ClassSig? classSig The class signature.
function M.GetClassSig(input)
    if input == nil then return nil; end

    -- test input in ClassLabel to ClassSig map
    -- this only has valid ClassLabel as keys
    local value = M.ClassSig[input:lower()];
    if value ~= nil then
        return value;
    end

    -- test input as key in ClassSig to ClassLabel map
    -- note this includes some illegal mangled ClassSigs as keys
    input = input:upper();
    if M.ClassLabel[input] ~= nil then
        -- output is a class sig so input was ClassLabel, though it may be mangled
        -- we will ping-pong it to ensure it's not mangled
        return M.ClassSig[M.ClassLabel[input]];
    end

    return nil;
end

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
    return mt and mt.__type == "BZHandle"
end

--- Is this object a Vector?
--- @param object any Object in question
--- @return boolean
function M.isVector(object)
    if type(object) ~= "userdata" then
        return false
    end
    local mt = getmetatable(object)
    return mt and mt.__type == "VECTOR_3D"
end

--- Is this object a Matrix?
--- @param object any Object in question
--- @return boolean
function M.isMatrix(object)
    if type(object) ~= "userdata" then
        return false
    end
    local mt = getmetatable(object)
    return mt and mt.__type == "MAT_3D"
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
-- Utility - Other
-------------------------------------------------------------------------------
-- @section

local version_pattern = "^(%d+)(%.(%d+)(%.(%d+)(%.(%d+)((%a)(%d+)?)?)?)?)?$";

--- Compare two version strings.
--- This function compares two version strings in the format `d`, `d.d`, `d.d.d`, `d.d.d.d`, `d.d.d.da`, and `d.d.d.dad` where d is a digit and a is an alphanumeric character.
--- It returns -1 if version1 is less than version2, 1 if version1 is greater than version2, and 0 if they are equal.
--- @param version1 string The first version string
--- @param version2 string The second version string
--- @return number -1, 0, or 1 depending on the comparison result
function M.CompareVersion(version1, version2)
    local g1_01, g1_02, g1_03, g1_04, g1_05, g1_06, g1_07, g1_08, g1_09, g1_10 = version1:match(version_pattern)
    local g2_01, g2_02, g2_03, g2_04, g2_05, g2_06, g2_07, g2_08, g2_09, g2_10 = version2:match(version_pattern)

    local captures = {
        {'d', g1_01, g2_01}, -- (d).d.d.dad
        {' ', g1_02, g2_02}, -- d(.d.d.dad)
        {'d', g1_03, g2_03}, -- d.(d).d.dad
        {' ', g1_04, g2_04}, -- d.d(.d.dad)
        {'d', g1_05, g2_05}, -- d.d.(d).dad
        {' ', g1_06, g2_06}, -- d.d.d(.dad)
        {'d', g1_07, g2_07}, -- d.d.d.(d)ad
        {' ', g1_08, g2_08}, -- d.d.d.d(ad)
        {'a', g1_09, g2_09}, -- d.d.d.d(a)d
        {'d', g1_10, g2_10}, -- d.d.d.da(d)
    }

    for i = 1, #captures do
        local type = captures[i][1];
        if type == 'd' then
            local v1 = tonumber(captures[i][2] or -1); -- version1 value
            local v2 = tonumber(captures[i][3] or -1); -- version2 value
            if v1 < v2 then return -1 end
            if v1 > v2 then return 1 end
        end
        if type == 'a' then
            local v1 = captures[i][2] or ""; -- version1 value
            local v2 = captures[i][3] or ""; -- version2 value
            if v1 < v2 then return -1 end
            if v1 > v2 then return 1 end
        end
    end
    return 0
end

-------------------------------------------------------------------------------
-- Utility - Core
-------------------------------------------------------------------------------
-- @section

--utility_module = setmetatable(utility_module, utility_module_meta);

debugprint("_utility Loaded");

return M;