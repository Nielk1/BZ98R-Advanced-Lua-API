--- BZ98R LUA Extended API Configuration.
---
--- Constants used to configure the API's system.
--- Note that reading any non-table value other than "locked" will lock the config table.
---
--- @module '_config'
--- @author John "Nielk1" Klein
--- ```lua
--- local config = require("_config")
---
--- if not config.locked then
---     -- this code runs
---     config.hook_priority.DeleteObject.GameObject = -99999
--- end
--- 
--- -- this code works
--- config.hook_priority.DeleteObject.GameObject = -99999
--- 
--- -- read a value for configuration use, auto-locks all values
--- local priority = config.lock().hook_priority.DeleteObject.GameObject
---
--- if not config.locked then
---     -- this code doesn't run
---     config.hook_priority.DeleteObject.GameObject = -99999
--- end
--- 
--- -- this code errors
--- config.hook_priority.DeleteObject.GameObject = -99999
--- ```

local logger = require("_logger");

require("_table_show")

logger.print(logger.LogLevel.DEBUG, nil, "_config Loading");

local locked = false;

--- @class Config
local data = {};

--- @class _config : Config
--- @field locked boolean
local M = {};

local readonly_mt = {
    __index = function(t, k) return rawget(t, k); end,
    __newindex = function() error("Config is locked"); end,
    __metatable = false;
}

local function make_readonly(tbl)
    if type(tbl) ~= "table" or getmetatable(tbl) == readonly_mt then return; end
    setmetatable(tbl, readonly_mt);
    for _, v in pairs(tbl) do
        if type(v) == "table" then
            make_readonly(v);
        end
    end
end

local M_MT = {}
M_MT.__index = function(_, k)
    if k == "lock" then
        return M_MT.lock;
    end
    if k == "locked" then
        return locked;
    end
    return data[k];
end
M_MT.__newindex = function(_, k, v)
    if locked then
        error("Config is locked");
    end
    data[k] = v;
end

--- Lock the config
--- @return Config
function M.lock(self)
    if not locked then
        locked = true;
        make_readonly(data);
        logger.print(logger.LogLevel.DEBUG, nil, "Config table is now locked.")
        logger.print(logger.LogLevel.DEBUG, nil, table.show(data, "config"))
    end
    return data;
end

-- set metatable after building functions
M = setmetatable(M, M_MT);

--- Priority of hooks
---
--- ```
--- DeleteObject                   .GameObject    = -9999
--- DeleteObject                   .Producer      =  4999
--- DeleteObject                   .NavManager    =  4999
--- DeleteObject                   .Tracker       =  4999
--- DeleteObject                   .Patrol        =  4999
--- -----------------------------------------------------
--- CreateObject                   .FixPowerupAi2 =  3999
--- CreateObject                   .Producer      =  4999
--- CreateObject                   .NavManager    =  4999
--- CreateObject                   .Tracker       =  4999
--- -----------------------------------------------------
--- Start                          .Tracker       =  4999
--- Start                          .Producer      =  4999
--- Start                          .GameObject    =  9999
--- -----------------------------------------------------
--- Update                         .FixPowerupAi2 =  3999
--- Update                         .Producer      =  4999
--- Update                         .Patrol        =  4999
--- Update                         .Tracker       =  4999
--- Update                         .NavManager    =  5999
--- Update                         .Camera        =  8989
--- Update                         .StateMachine  =  8998
--- Update                         .WaveSpawner   =  8999
--- Update                         .ParamDB       =  9900
--- Update                         .Network       =  9999
--- -----------------------------------------------------
--- CreatePlayer                   .Network       =  9999
--- -----------------------------------------------------
--- AddPlayer                      .Network       =  9999
--- -----------------------------------------------------
--- RemovePlayer                   .Network       =  9999
--- -----------------------------------------------------
--- Receive                        .GameObject    =  9999
--- ```
--- @type table<string, table<string, number>>
data.hook_priority = {
    DeleteObject = {
        GameObject = -9999,
        Producer = 4999,
        NavManager = 4999,
        Tracker = 4999,
        Patrol = 4999,
    },
    CreateObject = {
        FixPowerupAi2 = 3999,
        Producer = 4999,
        NavManager = 4999,
        Tracker = 4999,
    },
    Start = {
        --NavManager = 4999,
        Tracker = 4999,
        Producer = 4999,
        GameObject = 9999,
    },
    Update = {
        FixPowerupAi2 = 3999,
        Producer = 4999,
        Patrol = 4999,
        Tracker = 4999,
        NavManager = 5999,
        Camera = 8989,
        StateMachine = 8998,
        WaveSpawner = 8999,
        ParamDB = 9900,
        --GameObject = 9998,
        Network = 9999,
    },
    Receive = {
        GameObject = 9999,
        Network = 9999,
    },
    CreatePlayer = {
        Network = 9999,
    },
    AddPlayer = {
        Network = 9999,
    },
    RemovePlayer = {
        Network = 9999,
    },
}

--- Network Packet IDs
--- @type table<string, string>
data.network_packet_id = {
    api = "_",
}


logger.print(logger.LogLevel.DEBUG, nil, "_config Loaded");

return M;