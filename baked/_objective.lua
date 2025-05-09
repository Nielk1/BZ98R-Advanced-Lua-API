--- BZ98R LUA Extended API Objective Manager.
---
--- Note that this module cannot manage manually created objectives.
---
--- Dependencies: @{_hook}
--- @module _objective
--- @author John "Nielk1" Klein
--- @alias _objective
--- @usage local objective = require("_objective");
--- 
--- @todo write example usage

local debugprint = debugprint or function(...) end;

debugprint("_objective Loading");

local hook = require("_hook");

local _objective = {};

local allObjectives = {};
local nextId = 1;

local cmpObj = function(a, b)
    return a.position < b.position;
end

local reorderObjectives = function()
    --- @diagnostic disable: deprecated
    ClearObjectives();
    --- @diagnostic enable: deprecated

    local stable = {};
    for i, v in pairs(allObjectives) do
        table.insert(stable, v);
    end
    table.sort(stable, cmpObj);
    for i, v in ipairs(stable) do
        --- @diagnostic disable: deprecated
        AddObjective(v.name, v.color, v.duration, v.text);
        --- @diagnostic enable: deprecated
    end
end

--- Updates the objective message with the given name. If no objective exists with that name, it does nothing.
--- @param name string Unique name for objective, usually a filename ending with otf from which data is loaded
--- @param color? string Default to WHITE. See @{_utility.ColorLabels};
--- @param duration? number defaults to 8 seconds
--- @param text? string Override text from the target objective file. [2.0+]
--- @param position? number Sort position of the objective. Defaults to the next available ID.
--- @param persistant? bool If true, the objective will not be removed when the objectives are cleared. Defaults to false.
function _objective.UpdateObjective(name, color, duration, text, position, persistant)
    if allObjectives[name] then
        local o = allObjectives[name];
        allObjectives[name] = {
            name = o.name,
            color = color, -- will change to white if nil as per engine rules
            duration = duration, -- will show for 8 if nil as per engine rules
            text = text ~= nil and text or o.text,
            position = position ~= nil and position or o.position,
            persistant = persistant ~= nil and persistant or o.persistant
        }
        UpdateObjective(name, color, duration, text);
        reorderObjectives();
    end
end

--- Clear all objectives except for persistant ones.
function _objective.ClearObjectives()
    nextId = 1;
    local p = {};
    for i, v in pairs(allObjectives) do
        if v.persistant then
            table.insert(p, v);
        end
    end
    allObjectives = p;
    reorderObjectives();
end

--- Adds an objective message with the given name and properties.
--- @param name string Unique name for objective, usually a filename ending with otf from which data is loaded
--- @param color? string Default to WHITE. See @{_utility.ColorLabels};
--- @param duration? number defaults to 8 seconds
--- @param text? string Override text from the target objective file. [2.0+]
--- @param position? number Sort position of the objective. Defaults to the next available ID.
--- @param persistant? bool If true, the objective will not be removed when the objectives are cleared. Defaults to false.
function _objective.AddObjective(name, color, duration, text, position, persistant)
    --Resort all objectives
    if not allObjectives[name] then
        allObjectives[name] = {
            name = name,
            color = color,
            duration = duration,
            position = position ~= nil and position or nextId,
            text = text,
            persistant = persistant
        };
        nextId = nextId + 1;
        reorderObjectives();
    end
end

--- Removes the objective message with the given file name. Messages after the removed message will be moved up to fill the vacancy. If no objective exists with that file name, it does nothing.
--- @param name string
function _objective.RemoveObjective(name)
    allObjectives[name] = nil;
    RemoveObjective(name);
end

--- Set the objective position of the given name. If no objective exists with that name, it does nothing.
--- @param name string Unique name for objective, usually a filename ending with otf from which data is loaded
--- @param position number Sort position of the objective.
function _objective.SetObjectivePosition(name, position)
    if allObjectives[name] then
        allObjectives[name].position = position;
        reorderObjectives();
    end
end

--- Get the objective position of the given name. If no objective exists with that name, it does nothing.
--- @param name string Unique name for objective, usually a filename ending with otf from which data is loaded
--- @treturn number position Sort position of the objective.
function _objective.GetObjectivePosition(name)
    if allObjectives[name] then
        return allObjectives[name].position;
    end
end

--- Replaces the objective message with the given name. If no objective exists with that name, it does nothing.
--- @param oldname string Unique name for objective, usually a filename ending with otf from which data is loaded
--- @param name string Unique name for objective, usually a filename ending with otf from which data is loaded
--- @param color? string Default to WHITE. See @{_utility.ColorLabels};
--- @param duration? number defaults to 8 seconds
--- @param text? string Override text from the target objective file. [2.0+]
--- @param position? number Sort position of the objective. Defaults to the removed objective's position or next available ID.
--- @param persistant? bool If true, the objective will not be removed when the objectives are cleared. Defaults to false.
function _objective.ReplaceObjective(oldname, name, color, duration, text, position, persistant)
    local obj = allObjectives[name];
    _objective.RemoveObjective(oldname);
    if obj then
        _objective.UpdateObjective(name, color, duration, text, obj.position, persistant); -- update if it exists or do nothing
        _objective.AddObjective(name, color, duration, text, obj.position, persistant); -- add if it doesn't exist
    else
        _objective.AddObjective(name, color, duration, text, position, persistant);
    end
end




-------------------------------------------------------------------------------
-- Objective - Core
-------------------------------------------------------------------------------
-- @section

hook.AddSaveLoad("_objective", function()
    return allObjectives, nextId;
end,
function(_allObjectives, _nextId)
    allObjectives = _allObjectives;
    nextId = _nextId;
end);

debugprint("_objective Loaded");

return _objective;