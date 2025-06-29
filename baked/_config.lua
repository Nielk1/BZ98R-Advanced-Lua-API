--- BZ98R LUA Extended API Configuration.
---
--- Constants used to configure the API's system.
--- Note that reading any non-table value other than "locked" will lock the config table.
---
--- @module '_config'
--- @author John "Nielk1" Klein
--- @usage local config = require("_config");
--
-- if not config.locked then
--     config.hook_priority.DeleteObject.GameObject = -99999;
-- end

--- @diagnostic disable: undefined-global
local debugprint = debugprint or function(...) end;
--- @diagnostic enable: undefined-global

require("_table_show")

debugprint("_config Loading");

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
M_MT.locked = false;
M_MT.data = {};

local M = setmetatable({}, M_MT);

local dont_lock = true;

M_MT.__index = function(dtable, key)
    if key == "locked" then
        return M_MT.locked;
    end
    if key == "get" then
        return M_MT.get;
    end
    if M_MT.locked then
        error("Config table is locked. No further changes allowed.");
    end
    return rawget(M_MT.data, key);
  end
M_MT.__newindex = function(dtable, key, value)
    if M_MT.locked then
        error("Cannot set key '"..key.."' after config table is locked.");
    end
    if key == "locked" then
        error("Cannot set 'locked' key directly.");
    end
    rawset(M_MT.data, key, value);
end

--- Get a value from the config table using a period or colon delimited path.
--- @param path string The path to the value, e.g. "hook_priority.Update.StateMachine"
--- @return any The value at the specified path
--- @function get
function M_MT.get(path)
    -- Access a value using a period or colon delimited path
    local value = resolve_path(M_MT.data, path)
    if value ~= nil and not M_MT.locked then
        M_MT.locked = true;
        debugprint("Config table is now locked.")
        debugprint(table.show(M_MT.data, "config"))
    end
    return value
end

--- Priority of hooks
---
--- <pre>
--- DeleteObject                   .GameObject   = -9999
--- DeleteObject                   .Producer     =  4999
--- DeleteObject                   .NavManager   =  4999
--- DeleteObject                   .Tracker      =  4999
--- DeleteObject                   .Patrol       =  4999
--- ----------------------------------------------------
--- CreateObject                   .Producer     =  4999
--- CreateObject                   .NavManager   =  4999
--- CreateObject                   .Tracker      =  4999
--- ----------------------------------------------------
--- Start                          .Tracker     =  4999
--- Start                          .Producer     =  4999
--- Start                          .GameObject   =  9999
--- ----------------------------------------------------
--- Update                         .Producer     =  4999
--- Update                         .Patrol       =  4999
--- Update                         .Tracker      =  4999
--- Update                         .NavManager   =  5999
--- Update                         .Camera       =  8989
--- Update                         .StateMachine =  8999</pre>
M.hook_priority = {
    DeleteObject = {
        GameObject = -9999,
        Producer = 4999,
        NavManager = 4999,
        Tracker = 4999,
        Patrol = 4999,
    },
    CreateObject = {
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
        Producer = 4999,
        Patrol = 4999,
        Tracker = 4999,
        NavManager = 5999,
        Camera = 8989,
        StateMachine = 8999,
        --GameObject = 9999,
    },
}

dont_lock = false;

-- enable reading lockdown

debugprint("_config Loaded");

return M;