--- BZCC LUA Extended API CustomSaveType.
-- 
-- Crude custom type to make data not save/load exploiting the custom type system.
-- 
-- @module _customsavetype
-- @author John "Nielk1" Klein
-- @alias customsavetype
-- @usage local customsavetype = require("_customsavetype");
-- 
-- customsavetype.Register(ObjectDef);

local debugprint = debugprint or function() end;

debugprint("_customsavetype Loading");

local customsavetype_module = {};
local customsavetype_module_meta = {};

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

customsavetype_module.CustomSavableTypes = {};

function customsavetype_module.Register(obj)
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
    if obj.PostLoad ~= nil then
        typeT.PostLoad = obj.PostLoad;
    --else
    --    typeT.PostLoad = function() end
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
    if obj.BulkPostLoad ~= nil then
        typeT.BulkPostLoad = obj.BulkPostLoad;
    --else
    --    typeT.BulkPostLoad = function() end
    end
    typeT.TypeName = obj.__type;
    customsavetype_module.CustomSavableTypes[obj.__type] = typeT;
end

customsavetype_module = setmetatable(customsavetype_module, customsavetype_module_meta);

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MapData - Core
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

debugprint("_customsavetype Loaded");

return customsavetype_module;