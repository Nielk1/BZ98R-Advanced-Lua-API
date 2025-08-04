--- BZ98R LUA Extended API Utility.
---
--- @module '_utility'
--- @author John "Nielk1" Klein

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_utility Loading");

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

--- TeamSlotStrings
--- @enum TeamSlotString
M.TeamSlotString = {
    UNDEFINED = "UNDEFINED", -- UNDEFINED
    PLAYER = "PLAYER", -- PLAYER

    RECYCLER = "RECYCLER", -- RECYCLER
    FACTORY = "FACTORY", -- FACTORY
    ARMORY = "ARMORY", -- ARMORY
    CONSTRUCT = "CONSTRUCT", -- CONSTRUCT

    MIN_OFFENSE = "MIN_OFFENSE", -- MIN_OFFENSE
    MAX_OFFENSE = "MAX_OFFENSE", -- MAX_OFFENSE
    MIN_DEFENSE = "MIN_DEFENSE", -- MIN_DEFENSE
    MAX_DEFENSE = "MAX_DEFENSE", -- MAX_DEFENSE
    MIN_UTILITY = "MIN_UTILITY", -- MIN_UTILITY
    MAX_UTILITY = "MAX_UTILITY", -- MAX_UTILITY

    MIN_BEACON = "MIN_BEACON", -- MIN_BEACON
    MAX_BEACON = "MAX_BEACON", -- MAX_BEACON

    MIN_POWER = "MIN_POWER", -- MIN_POWER
    MAX_POWER = "MAX_POWER", -- MAX_POWER
    MIN_COMM = "MIN_COMM", -- MIN_COMM
    MAX_COMM = "MAX_COMM", -- MAX_COMM
    MIN_REPAIR = "MIN_REPAIR", -- MIN_REPAIR
    MAX_REPAIR = "MAX_REPAIR", -- MAX_REPAIR
    MIN_SUPPLY = "MIN_SUPPLY", -- MIN_SUPPLY
    MAX_SUPPLY = "MAX_SUPPLY", -- MAX_SUPPLY
    MIN_SILO = "MIN_SILO", -- MIN_SILO
    MAX_SILO = "MAX_SILO", -- MAX_SILO
    MIN_BARRACKS = "MIN_BARRACKS", -- MIN_BARRACKS
    MAX_BARRACKS = "MAX_BARRACKS", -- MAX_BARRACKS
    MIN_GUNTOWER = "MIN_GUNTOWER", -- MIN_GUNTOWER
    MAX_GUNTOWER = "MAX_GUNTOWER", -- MAX_GUNTOWER

    PORTAL = "PORTAL", -- PORTAL [2.2.315+]

    [-1] = "UNDEFINED", -- UNDEFINED
    [0] = "PLAYER", -- PLAYER

    [1] = "RECYCLER", -- RECYCLER
    [2] = "FACTORY", -- FACTORY
    [3] = "ARMORY", -- ARMORY
    [4] = "CONSTRUCT", -- CONSTRUCT

    [5] = "MIN_OFFENSE", -- MIN_OFFENSE
    [14] = "MAX_OFFENSE", -- MAX_OFFENSE
    [15] = "MIN_DEFENSE", -- MIN_DEFENSE
    [24] = "MAX_DEFENSE", -- MAX_DEFENSE
    [25] = "MIN_UTILITY", -- MIN_UTILITY
    [34] = "MAX_UTILITY", -- MAX_UTILITY

    [35] = "MIN_BEACON", -- MIN_BEACON
    [44] = "MAX_BEACON", -- MAX_BEACON

    [45] = "MIN_POWER", -- MIN_POWER
    [54] = "MAX_POWER", -- MAX_POWER
    [55] = "MIN_COMM", -- MIN_COMM
    [59] = "MAX_COMM", -- MAX_COMM
    [60] = "MIN_REPAIR", -- MIN_REPAIR
    [64] = "MAX_REPAIR", -- MAX_REPAIR
    [65] = "MIN_SUPPLY", -- MIN_SUPPLY
    [69] = "MAX_SUPPLY", -- MAX_SUPPLY
    [70] = "MIN_SILO", -- MIN_SILO
    [74] = "MAX_SILO", -- MAX_SILO
    [75] = "MIN_BARRACKS", -- MIN_BARRACKS
    [79] = "MAX_BARRACKS", -- MAX_BARRACKS
    [80] = "MIN_GUNTOWER", -- MIN_GUNTOWER
    [89] = "MAX_GUNTOWER", -- MAX_GUNTOWER

    [90] = "PORTAL", -- PORTAL [2.2.315+]
}

--- TeamSlotIntegers
--- @enum TeamSlotIntegerEnum
M.TeamSlotInteger = {
    UNDEFINED = -1, -- invalid, -1
    PLAYER = 0, -- 0

    RECYCLER = 1, -- 1
    FACTORY = 2, -- 2
    ARMORY = 3, -- 3
    CONSTRUCT = 4, -- 4

    MIN_OFFENSE = 5, -- 5
    MAX_OFFENSE = 14, -- 14
    MIN_DEFENSE = 15, -- 15
    MAX_DEFENSE = 24, -- 24
    MIN_UTILITY = 25, -- 25
    MAX_UTILITY = 34, -- 34

    MIN_BEACON = 35, -- 35
    MAX_BEACON = 44, -- 44

    MIN_POWER = 45, -- 45
    MAX_POWER = 54, -- 54
    MIN_COMM = 55, -- 55
    MAX_COMM = 59, -- 59
    MIN_REPAIR = 60, -- 60
    MAX_REPAIR = 64, -- 64
    MIN_SUPPLY = 65, -- 65
    MAX_SUPPLY = 69, -- 69
    MIN_SILO = 70, -- 70
    MAX_SILO = 74, -- 74
    MIN_BARRACKS = 75, -- 75
    MAX_BARRACKS = 79, -- 79
    MIN_GUNTOWER = 80, -- 80
    MAX_GUNTOWER = 89, -- 89

    PORTAL = 90, -- 90 [2.2.315+]

    [-1] = -1, -- invalid, -1
    [0] = 0, -- 0

    [1] = 1, -- 1
    [2] = 2, -- 2
    [3] = 3, -- 3
    [4] = 4, -- 4

    [5] = 5, -- 5
    [14] = 14, -- 14
    [15] = 15, -- 15
    [24] = 24, -- 24
    [25] = 25, -- 25
    [34] = 34, -- 34

    [35] = 35, -- 35
    [44] = 44, -- 44

    [45] = 45, -- 45
    [54] = 54, -- 54
    [55] = 55, -- 55
    [59] = 59, -- 59
    [60] = 60, -- 60
    [64] = 64, -- 64
    [65] = 65, -- 65
    [69] = 69, -- 69
    [70] = 70, -- 70
    [74] = 74, -- 74
    [75] = 75, -- 75
    [79] = 79, -- 79
    [80] = 80, -- 80
    [89] = 89, -- 89

    [90] = 90, -- 90 [2.2.315+]
}

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
    ["PORT"]  = "portal",          -- portal

    ["producer"]        = "producer",        -- producer
    ["hover"]           = "hover",           -- hover
    ["weapon"]          = "weapon",          -- weapon
    ["gameobject"]      = "gameobject",      -- gameobject
    ["ordnance"]        = "ordnance",        -- ordnance
    ["apc"]             = "apc",             -- apc
    ["armory"]          = "armory",          -- armory
    ["constructionrig"] = "constructionrig", -- constructionrig
    ["factory"]         = "factory",         -- factory
    ["powerplant"]      = "powerplant",      -- powerplant
    ["recycler"]        = "recycler",        -- recycler
    ["scavenger"]       = "scavenger",       -- scavenger
    ["dropoff"]         = "dropoff",         -- scrap dropoff
    ["supplydepot"]     = "supplydepot",     -- supply depot
    ["tug"]             = "tug",             -- tug
    ["turrettank"]      = "turrettank",      -- turret tank
    ["artifact"]        = "artifact",        -- artifact
    ["barracks"]        = "barracks",        -- barracks
    ["i76building"]     = "i76building",     -- building
    ["commtower"]       = "commtower",       -- comm tower
    ["craft"]           = "craft",           -- craft
    ["daywrecker"]      = "daywrecker",      -- daywrecker
    ["geyser"]          = "geyser",          -- geyser
    ["minelayer"]       = "minelayer",       -- minelayer
    ["person"]          = "person",          -- person
    ["powerup"]         = "powerup",         -- powerup
    ["camerapod"]       = "camerapod",       -- camera pod
    ["ammopack"]        = "ammopack",        -- ammo pack
    ["repairkit"]       = "repairkit",       -- repair kit
    ["repairdepot"]     = "repairdepot",     -- repair depot
    ["sav"]             = "sav",             -- sav
    ["scrapfield"]      = "scrapfield",      -- scrap field
    ["scrapsilo"]       = "scrapsilo",       -- scrap silo
    ["shieldtower"]     = "shieldtower",     -- shield tower
    ["spawnpnt"]        = "spawnpnt",        -- spawn buoy
    ["torpedo"]         = "torpedo",         -- torpedo
    ["wingman"]         = "wingman",         -- wingman
    ["howitzer"]        = "howitzer",        -- howitzer
    ["turret"]          = "turret",          -- turret
    ["walker"]          = "walker",          -- walker
    ["scrap"]           = "scrap",           -- scrap
    ["portal"]          = "portal",          -- portal
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
    ["portal"]          = "PORT",  -- PORT

    ["PROD"]  = "PROD",  -- PROD
    ["HOVR"]  = "HOVR",  -- HOVR
    ["WEPN"]  = "WEPN",  -- WEPN
    ["GOBJ"]  = "GOBJ",  -- GOBJ
    ["ORDN"]  = "ORDN",  -- ORDN
    ["APC"]   = "APC\0", -- APC\0
    ["APC\0"] = "APC\0", -- APC\0
    ["ARMR"]  = "ARMR",  -- ARMR
    ["CNST"]  = "CNST",  -- CNST
    ["FACT"]  = "FACT",  -- FACT
    ["PLNT"]  = "PLNT",  -- PLNT
    ["RCYC"]  = "RCYC",  -- RCYC
    ["SCAV"]  = "SCAV",  -- SCAV
    ["SDRP"]  = "SDRP",  -- SDRP
    ["SDEP"]  = "SDEP",  -- SDEP
    ["TUG"]   = "TUG\0", -- TUG\0
    ["TUG\0"] = "TUG\0", -- TUG\0
    ["TTNK"]  = "TTNK",  -- TTNK
    ["ARTI"]  = "ARTI",  -- ARTI
    ["BARR"]  = "BARR",  -- BARR
    ["BLDG"]  = "BLDG",  -- BLDG
    ["COMM"]  = "COMM",  -- COMM
    ["CRFT"]  = "CRFT",  -- CRFT
    ["WRCK"]  = "WRCK",  -- WRCK
    ["GEIZ"]  = "GEIZ",  -- GEIZ
    ["MLYR"]  = "MLYR",  -- MLYR
    ["PERS"]  = "PERS",  -- PERS
    ["PWUP"]  = "PWUP",  -- PWUP
    ["CPOD"]  = "CPOD",  -- CPOD
    ["AMMO"]  = "AMMO",  -- AMMO
    ["RKIT"]  = "RKIT",  -- RKIT
    ["RDEP"]  = "RDEP",  -- RDEP
    ["SAV"]   = "SAV\0", -- SAV\0
    ["SAV\0"] = "SAV\0", -- SAV\0
    ["SFLD"]  = "SFLD",  -- SFLD
    ["SILO"]  = "SILO",  -- SILO
    ["SHLD"]  = "SHLD",  -- SHLD
    ["SPWN"]  = "SPWN",  -- SPWN
    ["TORP"]  = "TORP",  -- TORP
    ["WING"]  = "WING",  -- WING
    ["HWTZ"]  = "HWTZ",  -- HWTZ
    ["TURR"]  = "TURR",  -- TURR
    ["WALK"]  = "WALK",  -- WALK
    ["SCRP"]  = "SCRP",  -- SCRP
    ["PORT"]  = "PORT",  -- PORT
    
    PRODUCER        = 'PROD',
    HOVER           = 'HOVR',
    POWERUP_WEAPON  = 'WEPN',
    GAMEOBJECT      = 'GOBJ',
    ORDNANCE        = 'ORDN',
    --APC             = 'APC\0',
    ARMORY          = 'ARMR',
    CONSTRUCTIONRIG = 'CNST',
    FACTORY         = 'FACT',
    POWERPLANT      = 'PLNT',
    RECYCLER        = 'RCYC',
    SCAVENGER       = 'SCAV',
    SCRAPDROPOFF    = 'SDRP',
    SUPPLYDEPOT     = 'SDEP',
    --TUG             = 'TUG\0',
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
    --SAV             = 'SAV\0',
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

--- TeamSlotRanges
--- @enum TeamSlotRange
--- @todo _fix uses this module, but _fix sets portal, so this needs some reorganization
M.TeamSlotRange = {
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
--- Sparse numeric indices will result in `nil` values in the array.
--- Duplicate numeric indices will overwrite previous values.
--- An empty iterator will return an empty array.
--- @param iterator function The iterator to convert
--- @return any[] array An array containing the values from the iterator
function M.IteratorToArray(iterator)
    if type(iterator) ~= "function" then
        error("IteratorToArray expects a function as the iterator", 2)
    end

    local array = {}
    local appendIndex = #array + 1
    for index, value in iterator do
        if type(index) == "number" and index > 0 and math.floor(index) == index then
            -- Use the index directly if it's a positive integer
            array[index] = value
        else
            -- Append to the array for non-array-like indexes
            array[appendIndex] = value
            appendIndex = appendIndex + 1
        end
    end
    return array
end

-------------------------------------------------------------------------------
-- Utility - Other
-------------------------------------------------------------------------------
-- @section


-------------------------------------------------------------------------------
-- Utility - Core
-------------------------------------------------------------------------------
-- @section

--utility_module = setmetatable(utility_module, utility_module_meta);

logger.print(logger.LogLevel.DEBUG, nil, "_utility Loaded");

return M;