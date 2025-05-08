--- BZCC LUA Extended API Unsaved.
-- 
-- Crude custom type to make data not save/load exploiting the custom type system.
-- 
-- @module _unsaved
-- @author John "Nielk1" Klein
-- @alias unsaved
-- @usage local unsaved = require("_unsaved");
-- 
-- data.unsavable = unsaved(data.unsavable);

local debugprint = debugprint or function(...) end;

debugprint("_unsaved Loading");

local unsaved_module = {};
local unsaved_module_meta = {};

--local unsaved_meta = {};

--unsaved_meta.__index = function(table, key)
--    local retVal = rawget(table, key);
--    if retVal ~= nil then
--        return retVal; -- found in table
--    end
--    return rawget(unsaved_meta, key); -- move on to base (looking for functions)
--end

-- @todo make this actually not save anything at all
--unsaved_meta.__type = "Unsaved";
--unsaved_meta.__nosave = true;

--- __call
-- @function __call
-- Creates a new table or augments the passed in table marking it as unsaved.
-- @tparam table table The module table itself.
-- @tparam table data Table to augment with unsaved data. If nil, a new table is created.
-- @treturn table The unsavable table.
unsaved_module_meta.__call = function(table, data)
    --if data ~= nil then
    --    return setmetatable(data, unsaved_meta);
    --end
    --return setmetatable({}, unsaved_meta);
    if data == nil then
        data = {};
    end
    data.__nosave = true; -- mark it as unsaved, don't even bother with metatables
    return data;
end

unsaved_module = setmetatable(unsaved_module, unsaved_module_meta);

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MapData - Core
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

debugprint("_unsaved Loaded");

return unsaved_module;