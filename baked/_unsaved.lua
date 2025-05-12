--- BZ98R LUA Extended API Unsaved.
---
--- Crude custom type to make data not save/load exploiting the custom type system.
---
--- @module '_unsaved'
--- @author John "Nielk1" Klein
--- @usage local unsaved = require("_unsaved");
--- 
--- data.unsavable = unsaved(data.unsavable);

local debugprint = debugprint or function(...) end;

debugprint("_unsaved Loading");

local M = {};
local M_MT = {};

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
--- @function __call
--- Creates a new table or augments the passed in table marking it as unsaved.
--- @param table table The module table itself.
--- @param data table? Table to augment with unsaved data. If nil, a new table is created.
--- @return table
M_MT.__call = function(table, data)
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

M = setmetatable(M, M_MT);

debugprint("_unsaved Loaded");

return M;