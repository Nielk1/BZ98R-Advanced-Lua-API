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

--utility_module = setmetatable(utility_module, utility_module_meta);

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MapData - Core
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

debugprint("_utility Loaded");

return utility_module;