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
--- local priority = config.get("hook_priority.DeleteObject.GameObject")
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

local function resolve_path(tbl, path)
    -- Resolve a period or colon delimited path into a nested table value
    local current = tbl
    for segment in path:gmatch("[^.:]+") do
        if type(current) ~= "table" then
            error("Invalid path: '" .. path .. "' (non-table value encountered at '" .. segment .. "')")
        end
        current = current[segment]
        if current == nil then
            error("Invalid path: '" .. path .. "' (key '" .. segment .. "' not found)")
        end
    end
    return current
end

local M_MT = {};
local locked = false;
local data = {};

--- @class _config
local M = {};

local readonly_mt = {
    __newindex = function(t, k, v)
        error("Attempt to modify read-only config table", 2)
    end,
    __metatable = false -- Prevent further changes to the metatable
}

local function make_readonly(tbl)
    if type(tbl) ~= "table" or getmetatable(tbl) == readonly_mt then return end
    setmetatable(tbl, readonly_mt)
    for _, v in pairs(tbl) do
        if type(v) == "table" then
            make_readonly(v)
        end
    end
end

M_MT.__index = function(dtable, key)
    if key == "locked" then
        return locked;
    end
    if key == "get" then
        --return M_MT.get;
        return rawget(dtable, key);
    end
    --if locked then
    --    error("Config table is locked. No further changes allowed.");
    --end
    return rawget(data, key);
  end
M_MT.__newindex = function(dtable, key, value)
    if locked then
        error("Cannot set key '"..key.."' after config table is locked.");
    end
    if key == "locked" then
        error("Cannot set 'locked' key directly.");
    end
    rawset(data, key, value);
end

--- Get a value from the config table using a period or colon delimited path.
--- @param path string The path to the value, e.g. "hook_priority.Update.StateMachine"
--- @return any value The value at the specified path
function M.get(path)
    -- Access a value using a period or colon delimited path
    local value = resolve_path(data, path)
    if value ~= nil and not locked then
        locked = true;
        make_readonly(data);
        logger.print(logger.LogLevel.DEBUG, nil, "Config table is now locked.")
        logger.print(logger.LogLevel.DEBUG, nil, table.show(data, "config"))
    end
    return value
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
--- Update                         .Network       =  9990
--- -----------------------------------------------------
--- Receive                        .GameObject    =  9999
--- ```
M.hook_priority = {
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
        --GameObject = 9999,
        ParamDB = 9900,
        Network = 9990,
    },
    Receive = {
        GameObject = 9999,
    }
}

--- Network Packet IDs
--- 
--- ```
--- api = "_"
--- ```
M.network_packet_id = {
    api = "_",
}

logger.print(logger.LogLevel.DEBUG, nil, "_config Loaded");

return M;