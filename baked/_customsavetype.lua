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
local utility = require("_utility");

logger.print(logger.LogLevel.DEBUG, nil, "_customsavetype Loading");

--- @class _customsavetype
local M = {};
--local M_MT = {};

--- Cache data for faster lookups, stored as a NoSave table.
--- @todo Consider logic to clear garbage data from this cache as it could build up a lot of "does not exist" entries.
--- @class CustomSavableTypeCache
--- @field __ancestors_set table<string, boolean>? Memoized set of ancestor type names for optimization.
--- @field __ancestors_map table<string, CustomSavableType>? Memoized map of ancestor type names to their definitions for optimization.
--- @field __implements table<string, boolean>? Memoized set of implemented type names for optimization.
--- @field __cast table<string, boolean>? Memoized set of cast type names for optimization.

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
--- @field __children table<string, CustomSavableType>? A list of child types inherited from to facilitate "casting".
--- @field __cache CustomSavableTypeCache
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

function M.IsCustomSavableType(obj)
    return obj ~= nil and type(obj) == "table" and obj.__type ~= nil;
end

--- Does this custom savable type implement the given type?
--- If you intend to cast use the Cast function instead and check for a nil response.
--- If you intend to test multiple use the Ancestors function to save time by pre-fetching ancestor instances.
--- @param obj CustomSavableType
--- @param name string
--- @param check_children boolean? If true, also check __children for the type.
--- @return boolean
function M.Implements(obj, name, check_children)
    if not M.IsCustomSavableType(obj) then error("Invalid CustomSavableType"); end

    if obj.__cache == nil then
        obj.__cache = M.NoSave();
    end
    if obj.__cache.__implements == nil then
        obj.__cache.__implements = {};
    end
    local cache_key = (check_children and "1" or "0") .. name
    local cached_result = obj.__cache.__implements[cache_key]
    if cached_result ~= nil then
        return cached_result;
    end

    if check_children then
        -- special case where we check other cache since we can go any direction
        if obj.__cache.__ancestors_set then
            return obj.__cache.__ancestors_set[name] == true;
        end
    end

    local checked = {};
    local function check(type_)
        if type_ == nil or type(type_) ~= "table" or checked[type_] then
            return false; -- not a table, cannot be a custom savable type
        end
        checked[type_] = true;
        if type_.__type == name then
            return true;
        end
        if check(type_.__base) then
            return true;
        end
        if check_children and type_.__children then
            for _, child in pairs(type_.__children) do
                if check(child) then
                    return true;
                end
            end
        end
        return false;
    end
    local r = check(obj);
    obj.__cache.__implements[cache_key] = r;
    return r;
end

--- Extract the custom savable type if implemented.
--- This is not a "cast" on the conventional sense but instead
--- a search of boxed ancestors. For example, if you're using
--- something that might be a child of a GameObject, and you
--- need the GameObject to use as a memory key, use this
--- function to extract it. Use the `Parent` function to get
--- the highest level of parent to utilize the expected functions.
--- @param obj CustomSavableType
--- @param name string
--- @param check_children boolean? If true, also check __children for the type.
--- @return any?
function M.Cast(obj, name, check_children)
    if not M.IsCustomSavableType(obj) then error("Invalid CustomSavableType"); end

    if obj.__cache == nil then
        obj.__cache = M.NoSave();
    end
    if obj.__cache.__implements == nil then
        obj.__cache.__implements = {};
    end
    if obj.__cache.__cast == nil then
        obj.__cache.__cast = {};
    end
    local cache_key = (check_children and "1" or "0") .. name
    local cached_result = obj.__cache.__cast[cache_key]
    if cached_result ~= nil then
        return cached_result;
    end
    -- if we have an ancestors map and we know we implement it, check there
    if obj.__cache.__ancestors_map and obj.__cache.__implements[cache_key] then
        cached_result = obj.__cache.__ancestors_map[name]
        if cached_result ~= nil then
            return cached_result;
        end
    end

    local checked = {};
    local function extract_inner(type_)
        if type_ == nil or type(type_) ~= "table" or checked[type_] then
            return nil; -- searched before or not a table and thus cannot be a custom savable type
        end
        checked[type_] = true

        -- check self
        if type_.__type == name then
            return type_;
        end

        -- check __base
        local base_result = extract_inner(type_.__base)
        if base_result then return base_result end

        -- check __children
        if check_children and type_.__children then
            for _, child in pairs(type_.__children) do
                local child_result = extract_inner(child)
                if child_result then return child_result end
            end
        end

        return nil;
    end
    local r = extract_inner(obj);
    obj.__cache.__cast[cache_key] = r;
    obj.__cache.__implements[cache_key] = r ~= nil;
    return r;
end

--- Find all types that can be Casted to from this object.
--- Traverses both __base and __children recursively.
--- @param obj CustomSavableType
--- @return table<string, boolean> Names Set of type names
--- @return table<string, CustomSavableType> Instances Type instances keyed by type name
function M.Ancestors(obj)
    if not M.IsCustomSavableType(obj) then error("Invalid CustomSavableType"); end

    if obj.__cache == nil then
        obj.__cache = M.NoSave();
    end
    if obj.__cache.__ancestors_set and obj.__cache.__ancestors_map then
        return obj.__cache.__ancestors_set, obj.__cache.__ancestors_map
    end

    local checked = {}
    local name_set = {}
    local name_map = {}

    local function collect(type_)
        if type_ == nil or type(type_) ~= "table" or checked[type_] then
            return;
        end
        checked[type_] = true;

        if type_.__type then
            name_set[type_.__type] = true;
            name_map[type_.__type] = type_;
        end

        -- Traverse __base
        if type_.__base then
            collect(type_.__base);
        end

        -- Traverse __children
        if type_.__children then
            for _, child in pairs(type_.__children) do
                collect(child);
            end
        end
    end

    collect(obj);
    if obj.__cache == nil then
        obj.__cache = M.NoSave();
    end
    obj.__cache.__ancestors_set = name_set
    obj.__cache.__ancestors_map = name_map
    return name_set, name_map
end

--- Extends a type by setting its __base and/or adding to __children.
--- @param obj CustomSavableType The object to extend (child)
--- @param base CustomSavableType The parent to extend from
--- @return CustomSavableType The extended object
function M.Extend(obj, base)
    if not M.IsCustomSavableType(obj) then error("obj Invalid CustomSavableType"); end
    if not M.IsCustomSavableType(base) then error("base Invalid CustomSavableType"); end

    -- Invalidate memoization
    M.ClearCache(obj);

    -- set base of new object
    obj.__base = base;

    -- add to parent's children
    if base.__children == nil then
        base.__children = {};
    end
    if not base.__children[obj.__type] then
        base.__children[obj.__type] = obj;
    end
    return obj;
end

--- Clears the cache for a CustomSavableType.
--- @param obj CustomSavableType
function M.ClearCache(obj)
    if not M.IsCustomSavableType(obj) then error("Invalid CustomSavableType"); end
    --if obj.__cache then
    --    for k in pairs(obj.__cache) do
    --        obj.__cache[k] = nil
    --    end
    --end
    obj.__cache = M.NoSave();
end

--M = setmetatable(M, M_MT);

--- @section MapData - Core

logger.print(logger.LogLevel.DEBUG, nil, "_customsavetype Loaded");

return M;