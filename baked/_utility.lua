--- BZ98R LUA Extended API Utility.
---
--- @module '_utility'
--- @author John "Nielk1" Klein

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_utility Loading");

--- @class WeightedItem
--- @field item any The item to be chosen.
--- @field chance number The weight of the item.

--- @class _utility
local M = {};
--local utility_module_meta = {};

--utility_meta.__index = function(table, key)
--    local retVal = rawget(table, key);
--    if retVal ~= nil then
--        return retVal; -- found in table
--    end
--    return rawget(utility_meta, key); -- move on to base (looking for functions)
--end

--- @section Enumerations

--- TeamSlotStrings
--- @enum TeamSlotString
M.TeamSlotString = {
    UNDEFINED = "UNDEFINED",
    PLAYER = "PLAYER",

    RECYCLER = "RECYCLER",
    FACTORY = "FACTORY",
    ARMORY = "ARMORY",
    CONSTRUCT = "CONSTRUCT",

    MIN_OFFENSE = "MIN_OFFENSE",
    MAX_OFFENSE = "MAX_OFFENSE",
    MIN_DEFENSE = "MIN_DEFENSE",
    MAX_DEFENSE = "MAX_DEFENSE",
    MIN_UTILITY = "MIN_UTILITY",
    MAX_UTILITY = "MAX_UTILITY",

    MIN_BEACON = "MIN_BEACON",
    MAX_BEACON = "MAX_BEACON",

    MIN_POWER = "MIN_POWER",
    MAX_POWER = "MAX_POWER",
    MIN_COMM = "MIN_COMM",
    MAX_COMM = "MAX_COMM",
    MIN_REPAIR = "MIN_REPAIR",
    MAX_REPAIR = "MAX_REPAIR",
    MIN_SUPPLY = "MIN_SUPPLY",
    MAX_SUPPLY = "MAX_SUPPLY",
    MIN_SILO = "MIN_SILO",
    MAX_SILO = "MAX_SILO",
    MIN_BARRACKS = "MIN_BARRACKS",
    MAX_BARRACKS = "MAX_BARRACKS",
    MIN_GUNTOWER = "MIN_GUNTOWER",
    MAX_GUNTOWER = "MAX_GUNTOWER",

    PORTAL = "PORTAL", -- {VERSION 2.2.315+}

    [-1] = "UNDEFINED",
    [0] = "PLAYER",

    [1] = "RECYCLER",
    [2] = "FACTORY",
    [3] = "ARMORY",
    [4] = "CONSTRUCT",

    [5] = "MIN_OFFENSE",
    [14] = "MAX_OFFENSE",
    [15] = "MIN_DEFENSE",
    [24] = "MAX_DEFENSE",
    [25] = "MIN_UTILITY",
    [34] = "MAX_UTILITY",

    [35] = "MIN_BEACON",
    [44] = "MAX_BEACON",

    [45] = "MIN_POWER",
    [54] = "MAX_POWER",
    [55] = "MIN_COMM",
    [59] = "MAX_COMM",
    [60] = "MIN_REPAIR",
    [64] = "MAX_REPAIR",
    [65] = "MIN_SUPPLY",
    [69] = "MAX_SUPPLY",
    [70] = "MIN_SILO",
    [74] = "MAX_SILO",
    [75] = "MIN_BARRACKS",
    [79] = "MAX_BARRACKS",
    [80] = "MIN_GUNTOWER",
    [89] = "MAX_GUNTOWER",

    [90] = "PORTAL", -- {VERSION 2.2.315+}
}

--- TeamSlotIntegers
--- @enum TeamSlotIntegerEnum
M.TeamSlotInteger = {
    UNDEFINED = -1, -- invalid
    PLAYER = 0,

    RECYCLER = 1,
    FACTORY = 2,
    ARMORY = 3,
    CONSTRUCT = 4,

    MIN_OFFENSE = 5,
    MAX_OFFENSE = 14,
    MIN_DEFENSE = 15,
    MAX_DEFENSE = 24,
    MIN_UTILITY = 25,
    MAX_UTILITY = 34,

    MIN_BEACON = 35,
    MAX_BEACON = 44,

    MIN_POWER = 45,
    MAX_POWER = 54,
    MIN_COMM = 55,
    MAX_COMM = 59,
    MIN_REPAIR = 60,
    MAX_REPAIR = 64,
    MIN_SUPPLY = 65,
    MAX_SUPPLY = 69,
    MIN_SILO = 70,
    MAX_SILO = 74,
    MIN_BARRACKS = 75,
    MAX_BARRACKS = 79,
    MIN_GUNTOWER = 80,
    MAX_GUNTOWER = 89,

    PORTAL = 90, -- {VERSION 2.2.315+}

    [-1] = -1, -- invalid
    [0] = 0,

    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 4,

    [5] = 5,
    [14] = 14,
    [15] = 15,
    [24] = 24,
    [25] = 25,
    [34] = 34,

    [35] = 35,
    [44] = 44,

    [45] = 45,
    [54] = 54,
    [55] = 55,
    [59] = 59,
    [60] = 60,
    [64] = 64,
    [65] = 65,
    [69] = 69,
    [70] = 70,
    [74] = 74,
    [75] = 75,
    [79] = 79,
    [80] = 80,
    [89] = 89,

    [90] = 90, -- {VERSION 2.2.315+}
}

--- ClassLabels
--- @enum ClassLabel
M.ClassLabel = {
    ["PROD"]  = "producer",
    ["HOVR"]  = "hover",
    ["WEPN"]  = "weapon",
    ["GOBJ"]  = "gameobject",
    ["ORDN"]  = "ordnance",
    ["APC\0"] = "apc",
    ["APC"]   = "apc", -- *compatability*
    ["ARMR"]  = "armory",
    ["CNST"]  = "constructionrig",
    ["FACT"]  = "factory",
    ["PLNT"]  = "powerplant",
    ["RCYC"]  = "recycler",
    ["SCAV"]  = "scavenger",
    ["SDRP"]  = "dropoff",
    ["SDEP"]  = "supplydepot",
    ["TUG\0"] = "tug",
    ["TUG"]   = "tug", -- *compatability*
    ["TTNK"]  = "turrettank",
    ["ARTI"]  = "artifact",
    ["BARR"]  = "barracks",
    ["BLDG"]  = "i76building",
    ["COMM"]  = "commtower",
    ["CRFT"]  = "craft",
    ["WRCK"]  = "daywrecker",
    ["GEIZ"]  = "geyser",
    ["MLYR"]  = "minelayer",
    ["PERS"]  = "person",
    ["PWUP"]  = "powerup",
    ["CPOD"]  = "camerapod",
    ["AMMO"]  = "ammopack",
    ["RKIT"]  = "repairkit",
    ["RDEP"]  = "repairdepot",
    ["SAV\0"] = "sav",
    ["SAV"]   = "sav", -- *compatability*
    ["SFLD"]  = "scrapfield",
    ["SILO"]  = "scrapsilo",
    ["SHLD"]  = "shieldtower",
    ["SPWN"]  = "spawnpnt",
    ["TORP"]  = "torpedo",
    ["WING"]  = "wingman",
    ["HWTZ"]  = "howitzer",
    ["TURR"]  = "turret",
    ["WALK"]  = "walker",
    ["SCRP"]  = "scrap",
    ["PORT"]  = "portal",

    ["producer"]        = "producer",
    ["hover"]           = "hover",
    ["weapon"]          = "weapon",
    ["gameobject"]      = "gameobject",
    ["ordnance"]        = "ordnance",
    ["apc"]             = "apc",
    ["armory"]          = "armory",
    ["constructionrig"] = "constructionrig",
    ["factory"]         = "factory",
    ["powerplant"]      = "powerplant",
    ["recycler"]        = "recycler",
    ["scavenger"]       = "scavenger",
    ["dropoff"]         = "dropoff",
    ["supplydepot"]     = "supplydepot",
    ["tug"]             = "tug",
    ["turrettank"]      = "turrettank",
    ["artifact"]        = "artifact",
    ["barracks"]        = "barracks",
    ["i76building"]     = "i76building",
    ["commtower"]       = "commtower",
    ["craft"]           = "craft",
    ["daywrecker"]      = "daywrecker",
    ["geyser"]          = "geyser",
    ["minelayer"]       = "minelayer",
    ["person"]          = "person",
    ["powerup"]         = "powerup",
    ["camerapod"]       = "camerapod",
    ["ammopack"]        = "ammopack",
    ["repairkit"]       = "repairkit",
    ["repairdepot"]     = "repairdepot",
    ["sav"]             = "sav",
    ["scrapfield"]      = "scrapfield",
    ["scrapsilo"]       = "scrapsilo",
    ["shieldtower"]     = "shieldtower",
    ["spawnpnt"]        = "spawnpnt",
    ["torpedo"]         = "torpedo",
    ["wingman"]         = "wingman",
    ["howitzer"]        = "howitzer",
    ["turret"]          = "turret",
    ["walker"]          = "walker",
    ["scrap"]           = "scrap",
    ["portal"]          = "portal",
};

--- ClassSigs
--- @enum ClassSig
M.ClassSig = {
    ["producer"]        = "PROD",
    ["hover"]           = "HOVR",
    ["weapon"]          = "WEPN",
    ["gameobject"]      = "GOBJ",
    ["ordnance"]        = "ORDN",
    ["apc"]             = "APC\0",
    ["armory"]          = "ARMR",
    ["constructionrig"] = "CNST",
    ["factory"]         = "FACT",
    ["powerplant"]      = "PLNT",
    ["recycler"]        = "RCYC",
    ["scavenger"]       = "SCAV",
    ["dropoff"]         = "SDRP",
    ["supplydepot"]     = "SDEP",
    ["tug"]             = "TUG\0",
    ["turrettank"]      = "TTNK",
    ["artifact"]        = "ARTI",
    ["barracks"]        = "BARR",
    ["i76building"]     = "BLDG",
    ["commtower"]       = "COMM",
    ["craft"]           = "CRFT",
    ["daywrecker"]      = "WRCK",
    ["geyser"]          = "GEIZ",
    ["minelayer"]       = "MLYR",
    ["person"]          = "PERS",
    ["powerup"]         = "PWUP",
    ["camerapod"]       = "CPOD",
    ["ammopack"]        = "AMMO",
    ["repairkit"]       = "RKIT",
    ["repairdepot"]     = "RDEP",
    ["sav"]             = "SAV\0",
    ["scrapfield"]      = "SFLD",
    ["scrapsilo"]       = "SILO",
    ["shieldtower"]     = "SHLD",
    ["spawnpnt"]        = "SPWN",
    ["torpedo"]         = "TORP",
    ["wingman"]         = "WING",
    ["howitzer"]        = "HWTZ",
    ["turret"]          = "TURR",
    ["walker"]          = "WALK",
    ["scrap"]           = "SCRP",
    ["portal"]          = "PORT",

    ["PROD"]  = "PROD",
    ["HOVR"]  = "HOVR",
    ["WEPN"]  = "WEPN",
    ["GOBJ"]  = "GOBJ",
    ["ORDN"]  = "ORDN",
    ["APC"]   = "APC\0",
    ["APC\0"] = "APC\0",
    ["ARMR"]  = "ARMR",
    ["CNST"]  = "CNST",
    ["FACT"]  = "FACT",
    ["PLNT"]  = "PLNT",
    ["RCYC"]  = "RCYC",
    ["SCAV"]  = "SCAV",
    ["SDRP"]  = "SDRP",
    ["SDEP"]  = "SDEP",
    ["TUG"]   = "TUG\0",
    ["TUG\0"] = "TUG\0",
    ["TTNK"]  = "TTNK",
    ["ARTI"]  = "ARTI",
    ["BARR"]  = "BARR",
    ["BLDG"]  = "BLDG",
    ["COMM"]  = "COMM",
    ["CRFT"]  = "CRFT",
    ["WRCK"]  = "WRCK",
    ["GEIZ"]  = "GEIZ",
    ["MLYR"]  = "MLYR",
    ["PERS"]  = "PERS",
    ["PWUP"]  = "PWUP",
    ["CPOD"]  = "CPOD",
    ["AMMO"]  = "AMMO",
    ["RKIT"]  = "RKIT",
    ["RDEP"]  = "RDEP",
    ["SAV"]   = "SAV\0",
    ["SAV\0"] = "SAV\0",
    ["SFLD"]  = "SFLD",
    ["SILO"]  = "SILO",
    ["SHLD"]  = "SHLD",
    ["SPWN"]  = "SPWN",
    ["TORP"]  = "TORP",
    ["WING"]  = "WING",
    ["HWTZ"]  = "HWTZ",
    ["TURR"]  = "TURR",
    ["WALK"]  = "WALK",
    ["SCRP"]  = "SCRP",
    ["PORT"]  = "PORT",

    PRODUCER        = 'PROD',
    HOVER           = 'HOVR',
    POWERUP_WEAPON  = 'WEPN',
    GAMEOBJECT      = 'GOBJ',
    ORDNANCE        = 'ORDN',
    -- [[START_IGNORE]]
    --APC             = 'APC\0',
    -- [[END_IGNORE]]
    ARMORY          = 'ARMR',
    CONSTRUCTIONRIG = 'CNST',
    FACTORY         = 'FACT',
    POWERPLANT      = 'PLNT',
    RECYCLER        = 'RCYC',
    SCAVENGER       = 'SCAV',
    SCRAPDROPOFF    = 'SDRP',
    SUPPLYDEPOT     = 'SDEP',
    -- [[START_IGNORE]]
    --TUG             = 'TUG\0',
    -- [[END_IGNORE]]
    TURRETTANK      = 'TTNK',
    ARTIFACT        = 'ARTI',
    BARRACKS        = 'BARR',
    BUILDING        = 'BLDG',
    COMMTOWER       = 'COMM',
    CRAFT           = 'CRFT',
    DAYWRECKER      = 'WRCK',
    GEIZER          = 'GEIZ',
    MINELAYER       = 'MLYR',
    PERSON          = 'PERS',
    POWERUP         = 'PWUP',
    POWERUP_CAMERA  = 'CPOD',
    POWERUP_RELOAD  = 'AMMO',
    POWERUP_REPAIR  = 'RKIT',
    REPAIRDEPOT     = 'RDEP',
    -- [[START_IGNORE]]
    --SAV             = 'SAV\0',
    -- [[END_IGNORE]]
    SCRAPFIELD      = 'SFLD',
    SCRAPSILO       = 'SILO',
    SHIELDTOWER     = 'SHLD',
    SPAWNBUOY       = 'SPWN',
    TORPEDO         = 'TORP',
    WINGMAN         = 'WING',
    HOWITZER        = 'HWTZ',
    TURRET          = 'TURR',
    WALKER          = 'WALK',
    SCRAP           = 'SCRP',
    PORTAL          = 'PORT',
};

--- TeamSlotRange
--- @alias TeamSlotRange { [1]: TeamSlotInteger, [2]: TeamSlotInteger }

--- TeamSlotRanges
--- @type table<ClassLabel|ClassSig, TeamSlotRange>
M.TeamSlotRanges = {
    ["producer"]        = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["PROD"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["hover"]           = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["HOVR"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["weapon"]          = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["WEPN"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["gameobject"]      = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["GOBJ"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["ordnance"]        = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["ORDN"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["apc"]             = { TeamSlot.MIN_OFFENSE, TeamSlot.MAX_OFFENSE },
    ["APC\0"]           = { TeamSlot.MIN_OFFENSE, TeamSlot.MAX_OFFENSE },
    ["APC"]             = { TeamSlot.MIN_OFFENSE, TeamSlot.MAX_OFFENSE },

    ["armory"]          = { TeamSlot.ARMORY, TeamSlot.ARMORY },
    ["ARMR"]            = { TeamSlot.ARMORY, TeamSlot.ARMORY },

    ["constructionrig"] = { TeamSlot.CONSTRUCT, TeamSlot.CONSTRUCT },
    ["CNST"]            = { TeamSlot.CONSTRUCT, TeamSlot.CONSTRUCT },

    ["factory"]         = { TeamSlot.FACTORY, TeamSlot.FACTORY },
    ["FACT"]            = { TeamSlot.FACTORY, TeamSlot.FACTORY },

    ["powerplant"]      = { TeamSlot.MIN_POWER, TeamSlot.MAX_POWER },
    ["PLNT"]            = { TeamSlot.MIN_POWER, TeamSlot.MAX_POWER },

    ["recycler"]        = { TeamSlot.RECYCLER, TeamSlot.RECYCLER },
    ["RCYC"]            = { TeamSlot.RECYCLER, TeamSlot.RECYCLER },

    ["scavenger"]       = { TeamSlot.MIN_UTILITY, TeamSlot.MAX_UTILITY },
    ["SCAV"]            = { TeamSlot.MIN_UTILITY, TeamSlot.MAX_UTILITY },

    ["dropoff"]         = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["SDRP"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["supplydepot"]     = { TeamSlot.MIN_SUPPLY, TeamSlot.MAX_SUPPLY },
    ["SDEP"]            = { TeamSlot.MIN_SUPPLY, TeamSlot.MAX_SUPPLY },

    ["tug"]             = { TeamSlot.MIN_UTILITY, TeamSlot.MAX_UTILITY },
    ["TUG\0"]           = { TeamSlot.MIN_UTILITY, TeamSlot.MAX_UTILITY },
    ["TUG"]             = { TeamSlot.MIN_UTILITY, TeamSlot.MAX_UTILITY },

    ["turrettank"]      = { TeamSlot.MIN_DEFENSE, TeamSlot.MAX_DEFENSE },
    ["TTNK"]            = { TeamSlot.MIN_DEFENSE, TeamSlot.MAX_DEFENSE },

    ["artifact"]        = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["ARTI"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["barracks"]        = { TeamSlot.MIN_BARRACKS, TeamSlot.MAX_BARRACKS },
    ["BARR"]            = { TeamSlot.MIN_BARRACKS, TeamSlot.MAX_BARRACKS },

    ["i76building"]     = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["BLDG"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["commtower"]       = { TeamSlot.MIN_COMM, TeamSlot.MAX_COMM },
    ["COMM"]            = { TeamSlot.MIN_COMM, TeamSlot.MAX_COMM },

    ["craft"]           = { TeamSlot.MIN_OFFENSE, TeamSlot.MAX_OFFENSE },
    ["CRFT"]            = { TeamSlot.MIN_OFFENSE, TeamSlot.MAX_OFFENSE },

    ["daywrecker"]      = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["WRCK"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["geyser"]          = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["GEIZ"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["minelayer"]       = { TeamSlot.MIN_DEFENSE, TeamSlot.MAX_DEFENSE },
    ["MLYR"]            = { TeamSlot.MIN_DEFENSE, TeamSlot.MAX_DEFENSE },

    ["person"]          = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["PERS"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["powerup"]         = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["PWUP"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["camerapod"]       = { TeamSlot.MIN_BEACON, TeamSlot.MAX_BEACON },
    ["CPOD"]            = { TeamSlot.MIN_BEACON, TeamSlot.MAX_BEACON },

    ["ammopack"]        = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["AMMO"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["repairkit"]       = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["RKIT"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["repairdepot"]     = { TeamSlot.MIN_REPAIR, TeamSlot.MAX_REPAIR },
    ["RDEP"]            = { TeamSlot.MIN_REPAIR, TeamSlot.MAX_REPAIR },

    ["sav"]             = { TeamSlot.MIN_OFFENSE, TeamSlot.MAX_OFFENSE },
    ["SAV\0"]           = { TeamSlot.MIN_OFFENSE, TeamSlot.MAX_OFFENSE },
    ["SAV"]             = { TeamSlot.MIN_OFFENSE, TeamSlot.MAX_OFFENSE },

    ["scrapfield"]      = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["SFLD"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["scrapsilo"]       = { TeamSlot.MIN_SILO, TeamSlot.MAX_SILO },
    ["SILO"]            = { TeamSlot.MIN_SILO, TeamSlot.MAX_SILO },

    ["shieldtower"]     = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["SHLD"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["spawnpnt"]        = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["SPWN"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["torpedo"]         = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["TORP"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["wingman"]         = { TeamSlot.MIN_OFFENSE, TeamSlot.MAX_OFFENSE },
    ["WING"]            = { TeamSlot.MIN_OFFENSE, TeamSlot.MAX_OFFENSE },

    ["howitzer"]        = { TeamSlot.MIN_DEFENSE, TeamSlot.MAX_DEFENSE },
    ["HWTZ"]            = { TeamSlot.MIN_DEFENSE, TeamSlot.MAX_DEFENSE },

    ["turret"]          = { TeamSlot.MIN_GUNTOWER, TeamSlot.MAX_GUNTOWER },
    ["TURR"]            = { TeamSlot.MIN_GUNTOWER, TeamSlot.MAX_GUNTOWER },

    ["walker"]          = { TeamSlot.MIN_OFFENSE, TeamSlot.MAX_OFFENSE },
    ["WALK"]            = { TeamSlot.MIN_OFFENSE, TeamSlot.MAX_OFFENSE },

    ["scrap"]           = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },
    ["SCRP"]            = { TeamSlot.UNDEFINED, TeamSlot.UNDEFINED },

    ["portal"]          = { TeamSlot.PORTAL, TeamSlot.PORTAL },
    ["PORT"]            = { TeamSlot.PORTAL, TeamSlot.PORTAL },
};

--- Get the ClassLabel string for any ClassSig or ClassLabel.
--- @param input ClassSig|ClassLabel|string The class label or class signature.
--- @return ClassLabel? classLabel The class label.
function M.GetClassLabel(input)
    if input == nil then return nil; end

    local value = M.ClassLabel[input:upper()];
    if value ~= nil then
        return value;
    end

    local value = M.ClassLabel[input:lower()];
    if value ~= nil then
        return value;
    end

    return nil;
end

--- Get the ClassSig string for any ClassLabel or ClassSig.
--- @param input ClassLabel|ClassSig|string The class label or class signature.
--- @return ClassSig? classSig The class signature.
function M.GetClassSig(input)
    if input == nil then return nil; end

    local value = M.ClassSig[input:lower()];
    if value ~= nil then
        return value;
    end

    local value = M.ClassSig[input:upper()];
    if value ~= nil then
        return value;
    end

    return nil;
end

--- @section Type Check Functions

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

--- @section Utility - Table Operations

function M.shallowCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = v
    end
    return copy
end

--- @section Utility - Array Operations

--- Chooses a random item from a list of items.
--- @param ... any The items to choose from.
--- @return any item The chosen item.
function M.ChooseOne(...)
    local items = {...};
    if #items == 0 then
        error("ChooseOne requires at least one item");
    end
    local random_index = math.random(#items);
    return items[random_index];
end

--- Chooses a random item from a list of weighted items.
--- @param ... WeightedItem The items to choose from.
--- @return any|WeightedItem item The chosen item.
function M.ChooseOneWeighted(...)
    local items = {...};
    if #items == 0 then
        error("ChooseOneWeighted requires at least one item");
    end
    local total_probability = 0;
    for _, v in pairs(items) do
        total_probability = total_probability + (v.chance or 1);
    end
    local random_index = math.random() * total_probability;
    local running_weight = 0;
    for _, v in ipairs(items) do
        local chance = (v.chance or 1);
        if (chance + running_weight) > random_index then
            return v.item or v;
        end
        running_weight = running_weight + chance;
    end
    return items[1].item or items[1];
end

--- @section Utility - Iterator Operations

--- Convert an iterator to an array or table.
--- If the iterator returns only values, returns an array.
--- If the iterator returns key-value pairs, returns a table.
--- @param iterator (fun(): any?)|(fun(): (any, any?)) The iterator to convert
--- @return table result The resulting array or table
function M.IteratorToArray(iterator)
    if type(iterator) ~= "function" then
        error("IteratorToArray expects a function as the iterator", 2)
    end

    local result = {}
    local i = 1
    while true do
        local a, b = iterator()
        if a == nil and b == nil then break end
        if b == nil then
            -- Value-only iterator: treat as array
            result[i] = a
            i = i + 1
        else
            -- Key-value iterator: treat as table
            result[a] = b
        end
    end
    return result
end

--- @section Utility - Other


--- @section Utility - Core

--utility_module = setmetatable(utility_module, utility_module_meta);

logger.print(logger.LogLevel.DEBUG, nil, "_utility Loaded");

return M;