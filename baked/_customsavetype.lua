--- BZ98R LUA Extended API CustomSaveType.
---
--- Crude custom type to make data not save/load exploiting the custom type system.
---
--- @module '_customsavetype'
--- @author John "Nielk1" Klein
--- ```lua
--- local customsavetype = require("_customsavetype");
--- 
--- customsavetype.Register(ObjectDef);
--- ```

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_customsavetype Loading");

--- @class _customsavetype
local M = {};
local M_MT = {};

--customsavetype_meta.__index = function(table, key)
--    local retVal = rawget(table, key);
--    if retVal ~= nil then
--        return retVal; -- found in table
--    end
--    return rawget(customsavetype_meta, key); -- move on to base (looking for functions)
--end

-- @todo make this actually not save anything at all
--customsavetype_meta.__type = "customsavetype";
--customsavetype_meta.__nosave = true;

--- @class CustomSavableType
--- @field __type string The type name of the custom savable type.
--- @field __nosave boolean? If true, the type will not be saved or loaded, a nil will be saved instead.
--- @field __noref boolean? If true, the type will not undergo checks for shared or looped references when saving.
--- @field Save fun(...: any) | nil
--- @field Load fun(): ... | nil
--- @field BulkSave fun(): ... | nil
--- @field BulkLoad fun(...: any) | nil

--- @type table<string, CustomSavableType>
M.CustomSavableTypes = {};

--- Register a custom savable type.
--- @param obj CustomSavableType
function M.Register(obj)
    if obj == nil or obj.__type == nil then error("Custom type malformed, no __type"); end
    local typeT = {};
    if obj.Save ~= nil then
        typeT.Save = obj.Save;
    --else
    --    typeT.Save = function() end
    end
    if obj.Load ~= nil then
        typeT.Load = obj.Load;
    --else
    --    typeT.Load = function() end
    end
    if obj.BulkSave ~= nil then
        typeT.BulkSave = obj.BulkSave;
    --else
    --    typeT.BulkSave = function() end
    end
    if obj.BulkLoad ~= nil then
        typeT.BulkLoad = obj.BulkLoad;
    --else
    --    typeT.BulkLoad = function() end
    end
    typeT.__type = obj.__type;
    M.CustomSavableTypes[obj.__type] = typeT;
end

M = setmetatable(M, M_MT);

--- #section MapData - Core

logger.print(logger.LogLevel.DEBUG, nil, "_customsavetype Loaded");

return M;