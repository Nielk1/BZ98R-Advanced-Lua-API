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

--- Custom Savable Type definition.  This allows for complex structures to be saved and loaded and preserve their function metatable assignment.
--- If a custom type is registered, it will be used instead of the default serialization methods.
--- {(i)Saving / Loading(i) Type Save/Load always run first, before any other save/load/postload hooks.
--- This is needed to ensure the type instances that appear in later save/load calls will work properly.
--- If a "TypePostLoad" is needed use a standard SaveLoad hook.}
--- @class CustomSavableType
--- @field __type string The type name of the custom savable type.
--- @field __nosave boolean? If true, the type will not be saved or loaded, a nil will be saved instead.
--- @field __noref boolean? If true, the type will not undergo checks for shared or looped references when saving.
--- @field __base CustomSavableType? The base type to inherit from, if any.
--- @field Save fun(self: CustomSavableType):... Called when saving an instance of this type. Return value is saved.
--- @field Load fun(...: any?) Called when loading an instance of this type. Data is the value returned from Save.
--- @field TypeSave fun():... Called on the type itself before any other data is saved.
--- @field TypeLoad fun(...: any?) Called on the type itself, before any other data is loaded.

--- @type table<string, CustomSavableType>
M.CustomSavableTypes = {};

--- Creates a new table or augments the passed in table marking it as unsaved.
--- @param data table? Table to augment with unsaved data. If nil, a new table is created.
--- @return table
function M.NoSave(data)
    if data == nil then
        data = {};
    end
    data.__nosave = true; -- mark it as unsaved, don't even bother with metatables
    return data;
end

--- Register a custom savable type.
--- @param obj CustomSavableType
function M.Register(obj)
    if obj == nil or obj.__type == nil then error("Custom type malformed, no __type"); end
    M.CustomSavableTypes[obj.__type] = obj;
end

--- Does this custom savable type implement the given type?
--- @param obj CustomSavableType
--- @param name string
--- @return boolean
function M.Implements(obj, name)
    local type_ = obj;
    while (type_ ~= nil) do
        if type(type_) ~= "table" then
            return false; -- not a table, cannot be a custom savable type
        end
        if type_.__type == name then
            return true;
        end
        type_ = type_.__base
    end
    return false;
end

--- Extract the custom savable type if implemented
--- For example, if you're using something that might be a child of
--- a GameObject, and you need the GameObject to use as a memory key,
--- use this function to extract it.
--- @param obj CustomSavableType
--- @param name string
--- @return any?
function M.Extract(obj, name)
    local type_ = obj;
    while(type_ ~= nil) do
        if type(type_) ~= "table" then
            return nil; -- not a table, cannot be a custom savable type
        end
        if type_.__type == name then
            return type_;
        end
        type_ = type_.__base
    end
    return nil;
end

M = setmetatable(M, M_MT);

--- @section MapData - Core

logger.print(logger.LogLevel.DEBUG, nil, "_customsavetype Loaded");

return M;