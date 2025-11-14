--- BZ98R LUA Extended API Object Logger.
---
--- Logger Extension: Objects
---
--- @module '_object_logger'
--- @author John "Nielk1" Klein


local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_object_logger Loading");

--local config = require("_config");
local hook = require("_hook");
local gameobject = require("_gameobject");
local customsavetypes = require("_customsavetype");

--- @class _object_logger
local M = {}

--- Debug print timer
local next_dump = math.huge;

local TrackedObjects = {};
local EmitRemovals = {};

local function LogObject(obj)
    local whitelist = {
        { "id" },
        { "__type" },
        { "addonData", "__object_logger", "*" }
    };

    -- update our state data
    if not obj.__object_logger then
        obj.__object_logger = customsavetypes.NoSave();
    end
    obj.__object_logger.position = obj:GetPosition();

    logger.data(logger.LogLevel.DEBUG, nil, "GameObject", obj, whitelist);
end

function M.AddObject(obj)
    if obj ~= nil and gameobject.IsGameObject(obj) then
        TrackedObjects[obj] = (TrackedObjects[obj] or 0) + 1;
        LogObject(obj);
    end
end

function M.RemoveObject(obj)
    if obj ~= nil and gameobject.IsGameObject(obj) then
        local count = TrackedObjects[obj];
        if count ~= nil then
            if count <= 1 then
                TrackedObjects[obj] = nil;
                EmitRemovals[obj] = true;
            else
                TrackedObjects[obj] = count - 1;
            end
        end
    end
end

hook.Add("Update", "_object_logger:Update", function(dtime, ttime)

    -- data logging
    if logger.IsDataMode() and logger.DoLogLevel(logger.LogLevel.DEBUG) then

        -- emit pending removals
        if next(EmitRemovals) ~= nil then
            local removals = {};
            for obj, _ in pairs(EmitRemovals) do
                table.insert(removals, obj:GetSeqNo() );
            end
            logger.print(logger.LogLevel.DEBUG, nil, "Removed|", table.concat(removals, '|'));
            EmitRemovals = {};
        end
        
        if ttime > next_dump then
            next_dump = ttime + 1;
            for obj, _ in pairs(TrackedObjects) do
                LogObject(obj);
            end
        end
    end
end);

hook.Add("RemoveObject", "_object_logger:RemoveObject", function(obj)
    if logger.IsDataMode() and logger.DoLogLevel(logger.LogLevel.DEBUG) then
        EmitRemovals[obj] = true;
        TrackedObjects[obj] = nil;
    end
end);

logger.print(logger.LogLevel.DEBUG, nil, "_object_logger Loaded");

return M;