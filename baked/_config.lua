--- BZ98R LUA Extended API Configuration.
--- 
--- Constants used to configure the API's system.
--- Note that reading any non-table value other than "locked" will lock the config table.
--- 
--- Dependencies: @{_table_show}
--- @module _config
--- @author John "Nielk1" Klein
--- @usage local config = require("_config");
--
-- if not config.locked then
--     config.hook_priority.DeleteObject.GameObject = -99999;
-- end

local debugprint = debugprint or function(...) end;

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

local config_meta = {};
config_meta.locked = false;
config_meta.data = {};

local config = setmetatable({}, config_meta);

local dont_lock = true;

config_meta.__index = function(dtable, key)
    if key == "locked" then
        return config_meta.locked;
    end
    if key == "get" then
        return config_meta.get;
    end
    if config_meta.locked then
        error("Config table is locked. No further changes allowed.");
    end
    return rawget(config_meta.data, key);
  end
config_meta.__newindex = function(dtable, key, value)
    if config_meta.locked then
        error("Cannot set key '"..key.."' after config table is locked.");
    end
    if key == "locked" then
        error("Cannot set 'locked' key directly.");
    end
    rawset(config_meta.data, key, value);
end

--- Get a value from the config table using a period or colon delimited path.
--- @tparam string path The path to the value, e.g. "hook_priority.Update.StateMachine"
--- @return The value at the specified path
function config_meta.get(path)
    -- Access a value using a period or colon delimited path
    local value = resolve_path(config_meta.data, path)
    if value ~= nil and not config_meta.locked then
        config_meta.locked = true;
        debugprint("Config table is now locked.")
        debugprint(table.show(config_meta.data, "config"))
    end
    return value
end

--- Priority of hooks
--
-- <pre>
-- DeleteObject                   .GameObject   = -9999
-- DeleteObject                   .NavManager   =  4999
-- DeleteObject                   .Tracker      =  4999
-- ----------------------------------------------------
-- CreateObject                   .NavManager   =  4999
-- CreateObject                   .Tracker      =  4999
-- ----------------------------------------------------
-- Start                          .Tracker      =  4999
-- ----------------------------------------------------
-- Update                         .Tracker      =  4999
-- Update                         .NavManager   =  5999
-- Update                         .StateMachine =  8999
-- ----------------------------------------------------
-- GameObject_SwapObjectReferences.Tracker      =  8999
-- GameObject_SwapObjectReferences.GameObject   =  9999</pre>
-- @field config.hook_priority
-- @table config.hook_priority
config.hook_priority = {
    DeleteObject = {
        GameObject = -9999,
        NavManager = 4999,
        Tracker = 4999,
    },
    CreateObject = {
        NavManager = 4999,
        Tracker = 4999,
    },
    Start = {
        NavManager = 4999,
        Tracker = 4999,
    },
    Update = {
        Tracker = 4999,
        NavManager = 5999,
        StateMachine = 8999,
        --GameObject = 9999,
    },
    GameObject_SwapObjectReferences = {
        Tracker = 8999,
        GameObject = 9999,
    },
}

dont_lock = false;

-- enable reading lockdown

debugprint("_config Loaded");

return config;