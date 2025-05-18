--- BZ98R LUA Extended API GameObject.
---
--- GameObject wrapper functions.
---
--- @module '_gameobject'
--- @author John "Nielk1" Klein

--- @diagnostic disable: undefined-global
local debugprint = debugprint or function(...) end;
--- @diagnostic enable: undefined-global

debugprint("_gameobject Loading");

require("_fix");
local utility = require("_utility");
local config = require("_config");
local hook = require("_hook");
local unsaved = require("_unsaved");
local customsavetype = require("_customsavetype");

local M = {};

--- Is this object an instance of GameObject?
--- @param object any Object in question
--- @return boolean
function M.isgameobject(object)
    return (type(object) == "table" and object.__type == "GameObject");
end

local GameObjectWeakList_MT = {};
GameObjectWeakList_MT.__mode = "v";
local GameObjectWeakList = setmetatable({}, GameObjectWeakList_MT);
local GameObjectAltered = {}; -- used to strong-reference hold objects with custom data until they are removed from game world
--local GameObjectDead = {}; -- used to hold dead objects till next update for cleanup

--- GameObject
--- An object containing all functions and data related to a game object.
--- @class GameObject : CustomSavableType
--- @field id Handle Handle used by BZ98R
--- @field addonData table Extended data saved into the object
--- @field cache_memo table Unsaved data used for housekeeping that is regenerated at load
GameObject = {}; -- the table representing the class, which will double as the metatable for the instances
--GameObject.__index = GameObject; -- failed table lookups on the instances should fallback to the class table, to get methods
function GameObject.__index(dtable, key)
    local retVal = rawget(dtable, key);
    if retVal ~= nil then return retVal; end
    local addonData = rawget(dtable, "addonData");
    if addonData ~= nil then
        retVal = rawget(rawget(dtable, "addonData"), key);
        if retVal ~= nil then return retVal; end
    end
    return rawget(GameObject, key); -- if you fail to get it from the subdata, move on to base (looking for functions)
end
function GameObject.__newindex(dtable, key, value)
    if key == "addonData" then
        rawset(dtable, "addonData", value);
        local objectId = dtable:GetHandle();--string.sub(tostring(table:GetHandle()),4);
        GameObjectAltered[objectId] = dtable;
    elseif key ~= "id" and key ~= "addonData" then
        local addonData = rawget(dtable, "addonData");
        if addonData == nil then
            rawset(dtable, "addonData", {});
            addonData = rawget(dtable, "addonData");
        end
        rawset(addonData, key, value);
        local objectId = dtable:GetHandle();--string.sub(tostring(table:GetHandle()),4);
        GameObjectAltered[objectId] = dtable;
        -- @todo consider removing object from GameObjectAltered if addonData is empty
    else
        rawset(dtable, key, value);
    end
end
GameObject.__type = "GameObject";
GameObject.__noref = true;

-------------------------------------------------------------------------------
-- Core
-------------------------------------------------------------------------------
-- @section

--- Create new GameObject Intance.
--- @param handle Handle Handle from BZ98R
--- @return GameObject?
function M.FromHandle(handle)
    local objectId = handle;--string.sub(tostring(handle),4);
    if GameObjectWeakList[objectId] ~= nil then
        return GameObjectWeakList[objectId];
    end
    local self = setmetatable({}, GameObject);
    self.id = handle;
    GameObjectWeakList[objectId] = self;
    return self;
end

--- Get Handle used by BZ98R.
--- @param self GameObject GameObject instance
--- @return Handle
function GameObject.GetHandle(self)
    return self.id;
end

--- Save event function.
--- INTERNAL USE.
--- @param self GameObject GameObject instance
--- @return ...
--- @package
function GameObject.Save(self)
    return self.id;
end

--- Load event function.
--- INTERNAL USE.
--- @param id any Handle
--- @package
function GameObject.Load(id)
    return M.FromHandle(id);
end

--- BulkSave event function.
--- INTERNAL USE.
--- @return ...
--- @package
function GameObject.BulkSave()
    -- store all the custom data we have for GameObjects by their handle keys
    local returnData = {};
    for k,v in pairs(GameObjectWeakList) do
        if v.addonData ~= nil and next(v.addonData) ~= nil then
            returnData[k] = v.addonData;
        end
    end
    
    -- store a list of handles that have already died (in theory this should always be empty but it might happen before Update can clean this)
    --local returnDataDead = {};
    --for k,v in pairs(GameObjectDead) do
    --    --table.insert(returnDataDead, v:GetHandle());
    --    table.insert(returnDataDead, k);
    --end
    --return returnData,returnDataDead;
    return returnData;
end

--- BulkLoad event function.
--- INTERNAL USE.
--- @param data any Object data
--- @package
function GameObject.BulkLoad(data)
-- Xparam dataDead Dead object data
--function GameObject.BulkLoad(data,dataDead)
    local _ObjectiveObjects = {};

    --- @diagnostic disable-next-line: deprecated
    if not utility.isfunction(IsObjectiveOn) then
            local lastObject = nil;
            --- @diagnostic disable-next-line: deprecated
            for h in ObjectiveObjects() do
                if lastObject == h then
                    break; -- break out of inf loop issue
                end
            _ObjectiveObjects[h] = true;
                debugprint("BulkLoad GameObject ObjectiveObjects: "..tostring(h));
                lastObject = h;
            end
    end

    for k,v in pairs(data) do
        local newGameObject = M.FromHandle(k);
        newGameObject.addonData = v;

        -- IsObjectiveOn Memo
        local objectiveData = _ObjectiveObjects[k];
        if objectiveData ~= nil then
            newGameObject.cache_memo = unsaved({ IsObjectiveOn = true });
            _ObjectiveObjects[k] = nil; -- does this speed things up or slow them down?
        end
    end
    --for k,v in pairs(dataDead) do
    --    local newGameObject = _gameobject.FromHandle(v); -- this will be either a new GameObject or an existing one from the above addon data filling loop
    --    GameObjectDead[v] = newGameObject;
    --end
end

-------------------------------------------------------------------------------
-- Object Creation / Destruction
-------------------------------------------------------------------------------
-- @section

--- Build Object.
--- @param odf string Object Definition File (without ".odf")
--- @param team TeamNum Team number for the object, 0 to 15
--- @param pos Vector|Matrix|GameObject|Handle|string Vector, Matrix, GameObject, or pathpoint by name
--- @param point? integer index
--- @return GameObject? object Newly built GameObject
function M.BuildGameObject(odf, team, pos, point)
    local handle = nil;
    if M.isgameobject(pos) then
        --- @cast pos GameObject
        --- @diagnostic disable-next-line: deprecated
        handle = BuildObject(odf, team, pos:GetHandle());
    elseif pos ~= nil then
        --- @cast pos Vector|Matrix|Handle|string
        --- @diagnostic disable-next-line: deprecated
        handle = BuildObject(odf, team, pos, point);
    else
        error("Parameter pos must be Vector, Matrix, GameObject, or path name.");
    end
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Remove GameObject from world.
--- @param self GameObject GameObject instance
function GameObject.RemoveObject(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    RemoveObject(self:GetHandle());
end

--- Get GameObject by Label.
--- @param key any Label
--- @return GameObject? object GameObject with Label or nil if none found
function M.GetGameObject(key)
    --- @diagnostic disable-next-line: deprecated
    local handle = GetHandle(key);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Get the game object in the specified team slot.
--- @param slot TeamSlotInteger Slot number, see TeamSlot
--- @see ScriptUtils.TeamSlot
--- @param team? TeamNum Team number, 0 to 15
function M.GetTeamSlot(slot, team)
    if not utility.isnumber(slot) then error("Parameter slot must be a number") end
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number") end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetTeamSlot(slot, team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Get Player GameObject of team.
--- @param team? TeamNum Team number of player
--- @return GameObject? player GameObject of player or nil
function M.GetPlayerGameObject(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    --- @diagnostic disable-next-line: deprecated
    local handle = GetPlayerHandle(team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Get Recycler GameObject of team.
--- @param team? TeamNum Team number of player
--- @return GameObject? recycler GameObject of recycler or nil
function M.GetRecyclerGameObject(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    --- @diagnostic disable-next-line: deprecated
    local handle = GetRecyclerHandle(team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Get Factory GameObject of team.
--- @param team? TeamNum Team number of player
--- @return GameObject? factory GameObject of factory or nil
function M.GetFactoryGameObject(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    --- @diagnostic disable-next-line: deprecated
    local handle = GetFactoryHandle(team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Get Armory GameObject of team.
--- @param team? TeamNum Team number of player
--- @return GameObject? armory of armory or nil
function M.GetArmoryGameObject(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    --- @diagnostic disable-next-line: deprecated
    local handle = GetArmoryHandle(team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Get Factory GameObject of team.
--- @param team? TeamNum Team number of player
--- @return GameObject? constructor of constructor or nil
function M.GetConstructorGameObject(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    --- @diagnostic disable-next-line: deprecated
    local handle = GetConstructorHandle(team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

-------------------------------------------------------------------------------
-- Deploy
-------------------------------------------------------------------------------
-- @section
-- These functions control deployable craft (such as Turret Tanks or Producer units).

--- Returns true if the game object is a deployed craft. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @return boolean
--- @function IsDeployed
function GameObject.IsDeployed(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsDeployed(self:GetHandle());
end

--- Tells the game object to deploy.
--- @param self GameObject GameObject instance
--- @function Deploy
function GameObject.Deploy(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    Deploy(self:GetHandle());
end

-------------------------------------------------------------------------------
-- Unit Commands
-------------------------------------------------------------------------------
-- @section
-- These functions send commands to units or query their command state.

--- Returns true if the game object can be commanded. Returns false otherwise.
--- @param self GameObject
--- @return boolean
function GameObject.CanCommand(self)
    if not M.isgameobject(self) then error("Parameter me must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return CanCommand(self:GetHandle());
end

--- Returns true if the game object is a producer that can build at the moment. Returns false otherwise.
--- The concept here is that the builder either A: Does not need to deploy or B: Does need to deploy but is deployed.
--- @param self GameObject
--- @return boolean
function GameObject.CanBuild(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return CanBuild(self:GetHandle());
end

--- Returns true if the game object is a producer and currently busy. Returns false otherwise.
--- An undeployed builder that needs to deploy will always indicate false.
--- A deployed (if needed) producer with a buildClass set is considered busy. The buildClass may be cleared after the CreateObject call.
--- @param self GameObject
--- @return boolean
function GameObject.IsBusy(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsBusy(self:GetHandle());
end

--- Returns the current command for the game object. Looking up the command number in the AiCommand table will convert it to a string. Looking up the command string in the AiCommand table will convert it back to a number.
--- @param self GameObject
--- @return AiCommand
function GameObject.GetCurrentCommand(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetCurrentCommand(self:GetHandle());
end

--- Returns the target of the current command for the game object. Returns nil if it has none.
--- @param self GameObject
--- @return GameObject?
function GameObject.GetCurrentWho(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetCurrentWho(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Gets the independence of a unit.
--- @param self GameObject
--- @return integer
function GameObject.GetIndependence(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetIndependence(self:GetHandle());
end

--- Sets the independence of a unit. 1 (the default) lets the unit take initiative (e.g. attack nearby enemies), while 0 prevents that.
--- @param self GameObject
--- @param independence integer
function GameObject.SetIndependence(self, independence)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(independence) then error("Parameter independence must be a number") end
    --- @diagnostic disable-next-line: deprecated
    SetIndependence(self:GetHandle(), independence);
end

--- Commands the unit using the given parameters. Be careful with this since not all commands work with all units and some have strict requirements on their parameters.
--- "Command" is the command to issue, normally chosen from the global AiCommand table (e.g. AiCommand.GO).
--- "Priority" is the command priority; a value of 0 leaves the unit commandable by the player while the default value of 1 makes it uncommandable.
--- "Who" is an optional target game object.
--- "Where" is an optional destination, and can be a matrix (transform), a vector (position), or a string (path name).
--- "When" is an optional absolute time value only used by command AiCommand.STAGE.
--- "Param" is an optional odf name only used by command AiCommand.BUILD.
--- @param self GameObject
--- @param command integer
--- @param priority? integer
--- @param who? GameObject|Handle
--- @param where Matrix|Vector|string?
--- @param when? number
--- @param param? string
function GameObject.SetCommand(self, command, priority, who, where, when, param)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(command) then error("Parameter command must be a number") end
    if priority ~= nil and not utility.isnumber(priority) then error("Parameter priority must be a number") end
    if who ~= nil and not (M.isgameobject(who) or utility.isstring(who)) then error("Parameter who must be GameObject or string") end
    if where ~= nil and not (utility.ismatrix(where) or utility.isvector(where) or utility.isstring(where)) then error("Parameter where must be Matrix, Vector, or string") end
    if when ~= nil and not utility.isnumber(when) then error("Parameter when must be a number") end
    if param ~= nil and not utility.isstring(param) then error("Parameter param must be a string") end

    if who ~= nil and M.isgameobject(who) then
        --- @cast who GameObject
        --- @diagnostic disable-next-line: deprecated
        SetCommand(self:GetHandle(), command, priority, who:GetHandle(), where, when, param);
        return;
    end
    --- @cast who Handle?
    --- @diagnostic disable-next-line: deprecated
    SetCommand(self:GetHandle(), command, priority, who, where, when, param);
end













--- Order GameObject to Attack target GameObject.
--- @param self GameObject GameObject instance
--- @param target GameObject|Handle Target GameObject
--- @param priority? integer Order priority, >0 removes user control
function GameObject.Attack(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        Attack(self:GetHandle(), target:GetHandle(), priority);
    elseif target ~= nil then
        --- @cast target Handle
        --- @diagnostic disable-next-line: deprecated
        Attack(self:GetHandle(), target, priority);
    else
        error("Parameter target must be Vector, Matrix, GameObject, Handle, or path name.");
    end
end

--- Order GameObject to Goto target Vector, Matrix, GameObject, or Path.
--- @function GameObject.Goto
--- @param self GameObject GameObject instance
--- @param target Vector|Matrix|GameObject|Handle|string Target Path name
--- @param priority? integer Order priority, >0 removes user control
function GameObject.Goto(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        Goto(self:GetHandle(), target:GetHandle(), priority);
    elseif target ~= nil then
        --- @cast target Vector|Matrix|Handle|string
        --- @diagnostic disable-next-line: deprecated
        Goto(self:GetHandle(), target, priority);
    else
        error("Parameter target must be Vector, Matrix, GameObject, Handle, or path name.");
    end
end

--- Order GameObject to Mine target Path.
--- @param self GameObject GameObject instance
--- @param target Vector|Matrix|string Target Vector, Matrix, or Path name
--- @param priority? integer Order priority, >0 removes user control
function GameObject.Mine(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if target ~= nil then
        --- @diagnostic disable-next-line: deprecated
        Mine(self:GetHandle(), target, priority);
    else
        error("Parameter target must be Vector, Matrix, GameObject, Handle, or path name.");
    end
end

--- Order GameObject to Follow target GameObject.
--- @param self GameObject GameObject instance
--- @param target GameObject|Handle Target GameObject instance
--- @param priority? integer Order priority, >0 removes user control
function GameObject.Follow(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        Follow(self:GetHandle(), target:GetHandle(), priority);
    elseif target ~= nil then
        --- @cast target Handle
        --- @diagnostic disable-next-line: deprecated
        Follow(self:GetHandle(), target, priority);
    else
        error("Parameter target must be GameObject instance or Handle.");
    end
end

--- Is the GameObject following the target GameObject?
--- @param self GameObject GameObject instance
--- @param target GameObject|Handle Target GameObject instance
--- @return boolean following true if following, false otherwise
function GameObject.IsFollowing(self, target)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        return IsFollowing(self:GetHandle(), target:GetHandle());
    elseif target ~= nil then
        --- @cast target Handle
        --- @diagnostic disable-next-line: deprecated
        return IsFollowing(self:GetHandle(), target);
    else
        error("Parameter target must be GameObject instance or Handle.");
    end
end

--- Order GameObject to Defend area.
--- @param self GameObject GameObject instance
--- @param priority? integer Order priority, >0 removes user control
function GameObject.Defend(self, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    Defend(self:GetHandle(), priority);
end

--- Order GameObject to Defend2 target GameObject.
--- @param self GameObject GameObject instance
--- @param target GameObject|Handle Target GameObject instance
--- @param priority? integer Order priority, >0 removes user control
function GameObject.Defend2(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        Defend2(self:GetHandle(), target:GetHandle(), priority);
    elseif target ~= nil then
        --- @cast target Handle
        --- @diagnostic disable-next-line: deprecated
        Defend2(self:GetHandle(), target, priority);
    else
        error("Parameter target must be GameObject instance or Handle.");
    end
end

--- Order GameObject to Stop.
--- @param self GameObject GameObject instance
--- @param priority? integer Order priority, >0 removes user control
function GameObject.Stop(self, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    Stop(self:GetHandle(), priority);
end

--- Order GameObject to Patrol target path.
--- @param self GameObject GameObject instance
--- @param target string Target Path name
--- @param priority? integer Order priority, >0 removes user control
function GameObject.Patrol(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(target) then error("Parameter target must be a string") end
    --- @diagnostic disable-next-line: deprecated
    Patrol(self:GetHandle(), target, priority);
end

--- Order GameObject to Retreat.
--- @param self GameObject GameObject instance
--- @param target GameObject|Handle|string Target GameObject or Path name
--- @param priority? integer Order priority, >0 removes user control
function GameObject.Retreat(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        Retreat(self:GetHandle(), target:GetHandle(), priority);
    elseif target ~= nil then
        --- @cast target Handle|string
        --- @diagnostic disable-next-line: deprecated
        Retreat(self:GetHandle(), target, priority)
    else
        error("Parameter target must be GameObject, Handle, or path name.");
    end
end

--- Order GameObject to GetIn target GameObject.
--- @param self GameObject GameObject instance
--- @param target GameObject|Handle Target GameObject
--- @param priority? integer Order priority, >0 removes user control
function GameObject.GetIn(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        GetIn(self:GetHandle(), target:GetHandle(), priority);
    elseif target ~= nil then
        --- @cast target Handle
        --- @diagnostic disable-next-line: deprecated
        GetIn(self:GetHandle(), target, priority)
    else
        error("Parameter target must be GameObject or Handle.");
    end
end

--- Order GameObject to Pickup target GameObject.
--- @param self GameObject GameObject instance
--- @param target GameObject|Handle Target GameObject
--- @param priority? integer Order priority, >0 removes user control
function GameObject.Pickup(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        Pickup(self:GetHandle(), target:GetHandle(), priority);
    elseif target ~= nil then
        --- @cast target Handle
        --- @diagnostic disable-next-line: deprecated
        Pickup(self:GetHandle(), target, priority)
    else
        error("Parameter target must be GameObject or Handle.");
    end
end

--- Order GameObject to Pickup target path name.
--- @param self GameObject GameObject instance
--- @param target Vector|Matrix|string Target vector, matrix, or path name
--- @param priority? integer Order priority, >0 removes user control
function GameObject.Dropoff(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if target ~= nil then
        --- @diagnostic disable-next-line: deprecated
        Dropoff(self:GetHandle(), target, priority)
    else
        error("Parameter target must be Vector, Matrix, or path name.");
    end
end

--- Order GameObject to Build target config.
--- Oddly this function does not include a location for the action, might want to use the far more powerful orders system.
--- @param self GameObject GameObject instance
--- @param odf string Object Definition
--- @param priority? integer Order priority, >0 removes user control
function GameObject.Build(self, odf, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(odf) then error("Parameter odf must be a string") end
    --- @diagnostic disable-next-line: deprecated
    Build(self:GetHandle(), odf, priority)
end

--- Order GameObject to BuildAt target GameObject.
--- @param self GameObject GameObject instance
--- @param odf string Object Definition
--- @param target Vector|Matrix|GameObject|Handle|string Target GameObject instance, vector, matrix, or path name
--- @param priority? integer Order priority, >0 removes user control
function GameObject.BuildAt(self, odf, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        BuildAt(self:GetHandle(), odf, target:GetHandle(), priority);
    elseif target ~= nil then
        --- @cast target Vector|Matrix|Handle|string
        --- @diagnostic disable-next-line: deprecated
        BuildAt(self:GetHandle(), odf, target, priority)
    else
        error("Parameter target must be GameObject, Handle, Vector, Matrix, or path name.");
    end
end

--- Order GameObject to Formation follow target GameObject.
--- @param self GameObject GameObject instance
--- @param target GameObject|Handle Target GameObject instance
--- @param priority? integer Order priority, >0 removes user control
function GameObject.Formation(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        Formation(self:GetHandle(), target:GetHandle(), priority);
    elseif target ~= nil then
        --- @cast target Handle
        --- @diagnostic disable-next-line: deprecated
        Formation(self:GetHandle(), target, priority);
    else
        error("Parameter target must be GameObject or Handle.");
    end
end

--- Order GameObject to Hunt area.
--- @param self GameObject GameObject instance
--- @param priority? integer Order priority, >0 removes user control
function GameObject.Hunt(self, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    Hunt(self:GetHandle(), priority);
end

-------------------------------------------------------------------------------
-- Position & Velocity
-------------------------------------------------------------------------------
-- @section

--- Get object's position vector.
--- @param self GameObject GameObject instance
--- @return Vector?
function GameObject.GetPosition(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetPosition(self:GetHandle());
end

--- Get front vector.
--- @param self GameObject GameObject instance
--- @return Vector?
function GameObject.GetFront(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetFront(self:GetHandle());
end

--- Set the position of the GameObject.
--- @param self GameObject GameObject instance
--- @param position Vector|Matrix|string Vector position, Matrix position, or path name
--- @param point? integer Index of the path point in the path (optional)
function GameObject.SetPosition(self, position, point)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if position ~= nil then
        --- @diagnostic disable-next-line: deprecated
        SetPosition(self:GetHandle(), position, point);
    else
        error("Parameter position must be Vector, Matrix, or path name.");
    end
end

--- Get object's tranform matrix.
--- @param self GameObject GameObject instance
--- @return Matrix?
function GameObject.GetTransform(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetTransform(self:GetHandle());
end

--- Set the tranform matrix of the GameObject.
--- @param self GameObject GameObject instance
--- @param transform Matrix transform matrix
function GameObject.SetTransform(self, transform)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isMatrix(transform) then error("Parameter transform must be a Matrix") end
    --- @diagnostic disable-next-line: deprecated
    SetTransform(self:GetHandle(), transform);
end

--- Get object's velocity vector.
--- @param self GameObject GameObject instance
--- @return Vector Vector (0,0,0) if the handle is invalid or isn't movable.
function GameObject.GetVelocity(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetVelocity(self:GetHandle());
end

--- Set the velocity of the GameObject.
--- @param self GameObject GameObject instance
--- @param velocity Vector Vector velocity
function GameObject.SetVelocity(self, velocity)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isVector(velocity) then error("Parameter velocity must be a Vector") end
    --- @diagnostic disable-next-line: deprecated
    SetVelocity(self:GetHandle(), velocity);
end

--- Get object's omega.
--- @param self GameObject GameObject instance
--- @return Vector Vector (0,0,0) if the handle is invalid or isn't movable.
function GameObject.GetOmega(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetOmega(self:GetHandle());
end

--- Set the omega of the GameObject.
--- @param self GameObject GameObject instance
--- @param omega any
function GameObject.SetOmega(self, omega)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isVector(omega) then error("Parameter omega must be a Vector") end
    --- @diagnostic disable-next-line: deprecated
    SetOmega(self:GetHandle(), omega);
end

-------------------------------------------------------------------------------
-- Condition Checks
-------------------------------------------------------------------------------
-- @section

--- Does the GameObject exist in the world?
--- Returns true if the game object exists. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject.IsValid(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsValid(self:GetHandle());
end

--- Is the GameObject alive and is still pilot controlled?
--- Returns true if the game object exists and (if the object is a vehicle) controlled. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject.IsAlive(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsAlive(self:GetHandle());
end

--- Is the GameObject alive and piloted?
--- Returns true if the game object exists and (if the object is a vehicle) controlled and piloted. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject.IsAliveAndPilot(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsAliveAndPilot(self:GetHandle());
end

--- Returns true if it's a Craft.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject.IsCraft(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsCraft(self:GetHandle());
end

--- Returns true if it's a Building.
--- Does not include guntowers.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject.IsBuilding(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsBuilding(self:GetHandle());
end

--- Returns true if it's a person.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject.IsPerson(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsPerson(self:GetHandle());
end

-------------------------------------------------------------------------------
-- Tug Cargo
-------------------------------------------------------------------------------
-- @section
-- These functions query Tug and Cargo.

--- Returns true if the GameObject is a tug carrying cargo.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject.HasCargo(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return HasCargo(self:GetHandle());
end

--- Returns the GameObject of the cargo if the GameObject is a tug carrying cargo. Returns nil otherwise.
--- @param self GameObject GameObject instance
--- @return GameObject? GameObject of the GameObject carried by the GameObject, or nil
function GameObject.GetCargo(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetCargo(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Returns the GameObject of the tug carrying the object. Returns nil if not carried.
--- @param self GameObject GameObject instance
--- @return GameObject? GameObject of the tug carrying the GameObject, or nil
function GameObject.GetTug(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetTug(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

-------------------------------------------------------------------------------
-- Pilot Actions
-------------------------------------------------------------------------------
-- @section
-- These functions control the pilot of a vehicle.

--- Commands the vehicle's pilot to eject.
--- @param self GameObject
function GameObject.EjectPilot(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    EjectPilot(self:GetHandle());
end

--- Commands the vehicle's pilot to hop out.
--- @param self GameObject
function GameObject.HopOut(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    HopOut(self:GetHandle());
end

--- Kills the vehicle's pilot as if sniped.
--- @param self GameObject
function GameObject.KillPilot(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    KillPilot(self:GetHandle());
end

--- Removes the vehicle's pilot cleanly.
--- @param self GameObject
function GameObject.RemovePilot(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    RemovePilot(self:GetHandle());
end

--- Returns the vehicle that the pilot GameObject most recently hopped out of.
--- @param self GameObject GameObject instance
--- @return GameObject? GameObject of the vehicle that the pilot most recently hopped out of, or nil
function GameObject.HoppedOutOf(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = HoppedOutOf(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

-------------------------------------------------------------------------------
-- Weapon
-------------------------------------------------------------------------------
-- @section
-- These functions access unit weapons and damage.

--- Sets what weapons the unit's AI process will use.
--- To calculate the mask value, add up the values of the weapon hardpoint slots you want to enable.
--- weaponHard1: 1 weaponHard2: 2 weaponHard3: 4 weaponHard4: 8 weaponHard5: 16
--- @param self GameObject GameObject instance
--- @param mask integer
function GameObject.SetWeaponMask(self, mask)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(mask) then error("Parameter mask must be number."); end
    --- @diagnostic disable-next-line: deprecated
    SetWeaponMask(self:GetHandle(), mask);
end

--- Gives the game object the named weapon in the given slot. If no slot is given, it chooses a slot based on hardpoint type and weapon priority like a weapon powerup would. If the weapon name is empty, nil, or blank and a slot is given, it removes the weapon in that slot.
--- Returns true if it succeeded. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @param weaponname? string
--- @param slot? integer
function GameObject.GiveWeapon(self, weaponname, slot)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if weaponname ~= nil and not utility.isstring(weaponname) then error("Parameter weaponname must be a string or nil.") end
    if slot ~= nil and not utility.isnumber(slot) then error("Parameter slot must be a number or nil.") end
    --- @diagnostic disable-next-line: deprecated
    return GiveWeapon(self:GetHandle(), weaponname, slot);
end

--- Returns the odf name of the weapon in the given slot on the game object. Returns nil if the game object does not exist or the slot is empty.
--- For example, an "avtank" game object would return "gatstab" for index 0 and "gminigun" for index 1.
--- @param self GameObject GameObject instance
--- @param slot integer
--- @return string
function GameObject.GetWeaponClass(self, slot)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(slot) then error("Parameter slot must be number.") end
    --- @diagnostic disable-next-line: deprecated
    return GetWeaponClass(self:GetHandle(), slot);
end

--- Tells the game object to fire at the given target.
--- @param self GameObject GameObject instance
--- @param target GameObject|Handle
function GameObject.FireAt(self, target)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        FireAt(self:GetHandle(), target:GetHandle());
    elseif target ~= nil then
        --- @cast target Handle
        --- @diagnostic disable-next-line: deprecated
        FireAt(self:GetHandle(), target);
    else
        error("Parameter target must be GameObject or Handle.");
    end
end

--- Applies damage to the game object.
--- @param self GameObject GameObject instance
--- @param amount number damage amount
function GameObject.Damage(self, amount)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amount) then error("Parameter amt must be number."); end
    --- @diagnostic disable-next-line: deprecated
    Damage(self:GetHandle(), amount);
end

-------------------------------------------------------------------------------
-- Health Values
-------------------------------------------------------------------------------
-- @section
-- These functions get and set health values on a game object.

--- Returns the fractional health of the game object between 0 and 1.
--- @usage if friend1:GetHealth() < 0.5 then friend1:Retreat("retreat_path"); end
--- @param self GameObject GameObject instance
--- @return number ratio health ratio
function GameObject.GetHealth(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetHealth(self:GetHandle());
end

--- Returns the current health value of the game object.
--- @param self GameObject GameObject instance
--- @return number current current health or nil
function GameObject.GetCurHealth(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetCurHealth(self:GetHandle());
end

--- Returns the maximum health value of the game object.
--- @param self GameObject GameObject instance
--- @return number max max health or nil
function GameObject.GetMaxHealth(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetMaxHealth(self:GetHandle());
end

--- Sets the current health of the game object.
--- @param self GameObject GameObject instance
--- @param health number health amount
function GameObject.SetCurHealth(self, health)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(health) then error("Parameter health must be number."); end
    --- @diagnostic disable-next-line: deprecated
    SetCurHealth(self:GetHandle(), health);
end

--- Sets the max health of the GameObject to the NewHealth value.
--- @param self GameObject GameObject instance
--- @param health number health amount
function GameObject.SetMaxHealth(self, health)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(health) then error("Parameter health must be number."); end
    --- @diagnostic disable-next-line: deprecated
    SetMaxHealth(self:GetHandle(), health);
end

--- Adds the health to the GameObject.
--- @param self GameObject GameObject instance
--- @param health number health amount
function GameObject.AddHealth(self, health)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(health) then error("Parameter health must be number."); end
    --- @diagnostic disable-next-line: deprecated
    AddHealth(self:GetHandle(), health);
end

--- GiveMaxHealth
--- @param self GameObject GameObject instance
function GameObject.GiveMaxHealth(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    GiveMaxHealth(self:GetHandle());
end

-------------------------------------------------------------------------------
-- Ammo Values
-------------------------------------------------------------------------------
-- @section
-- These functions get and set ammo values on a game object.

--- Returns the fractional ammo of the game object between 0 and 1.
--- @param self GameObject GameObject instance
--- @return number ratio ammo ratio
function GameObject.GetAmmo(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetAmmo(self:GetHandle());
end

--- Returns the current ammo value of the game object.
--- @param self GameObject GameObject instance
--- @return number current current ammo or nil
function GameObject.GetCurAmmo(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetCurAmmo(self:GetHandle());
end

--- Returns the maximum ammo value of the game object.
--- @param self GameObject GameObject instance
--- @return number max max ammo or nil
function GameObject.GetMaxAmmo(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetMaxAmmo(self:GetHandle());
end

--- Sets the current ammo of the game object.
--- @param self GameObject GameObject instance
--- @param ammo any ammo amount
function GameObject.SetCurAmmo(self, ammo)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(ammo) then error("Parameter ammo must be number."); end
    --- @diagnostic disable-next-line: deprecated
    SetCurAmmo(self:GetHandle(), ammo);
end

--- Sets the maximum ammo of the game object.
--- @param self GameObject GameObject instance
--- @param ammo any ammo amount
function GameObject.SetMaxAmmo(self, ammo)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(ammo) then error("Parameter ammo must be number."); end
    --- @diagnostic disable-next-line: deprecated
    SetMaxAmmo(self:GetHandle(), ammo);
end

--- Adds to the current ammo of the game object.
--- @param self GameObject GameObject instance
--- @param ammo any ammo amount
function GameObject.AddAmmo(self, ammo)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(ammo) then error("Parameter ammo must be number."); end
    --- @diagnostic disable-next-line: deprecated
    AddAmmo(self:GetHandle(), ammo);
end

--- Sets the unit's current ammo to maximum.
--- @param self GameObject GameObject instance
function GameObject.GiveMaxAmmo(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    GiveMaxAmmo(self:GetHandle());
end

-------------------------------------------------------------------------------
-- Team Number
-------------------------------------------------------------------------------
-- @section
-- These functions get and set team number. Team 0 is the neutral or environment team.

--- Returns the game object's team number.
--- @param self GameObject GameObject instance
--- @return integer Team number
function GameObject.GetTeamNum(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetTeamNum(self:GetHandle());
end

--- Sets the game object's team number.
--- @param self GameObject GameObject instance
--- @param team TeamNum new team number
function GameObject.SetTeamNum(self, team)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(team) then error("Parameter amt must be number."); end
    --- @diagnostic disable-next-line: deprecated
    SetTeamNum(self:GetHandle(), team);
end

--- Get perceived team number of the GameObject.
--- @param self GameObject GameObject instance
--- @return integer Team number
function GameObject.GetPerceivedTeam(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetPerceivedTeam(self:GetHandle());
end

--- Set perceived team number of the GameObject.
--- @param self GameObject GameObject instance
--- @param team TeamNum new team number
function GameObject.SetPerceivedTeam(self, team)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(team) then error("Parameter amt must be number."); end
    --- @diagnostic disable-next-line: deprecated
    SetPerceivedTeam(self:GetHandle(), team);
end

-------------------------------------------------------------------------------
-- Owner
-------------------------------------------------------------------------------
-- @section
-- These functions get and set owner. The default owner for a game object is the game object that created it.

--- Sets the game object's owner.
--- @param self GameObject
--- @param owner GameObject?
function GameObject.SetOwner(self, owner)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if owner ~= nil and not M.isgameobject(owner) then error("Parameter owner must be GameObject instance or nil."); end
    if owner == nil then
        --- @diagnostic disable-next-line: deprecated
        SetOwner(self:GetHandle(), nil);
        return;
    end
    --- @diagnostic disable-next-line: deprecated
    SetOwner(self:GetHandle(), owner:GetHandle());
end

--- Returns the game object's owner. Returns nil if it has none.
--- @param self GameObject
--- @return GameObject?
function GameObject.GetOwner(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetOwner(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

-------------------------------------------------------------------------------
-- Pilot Class
-------------------------------------------------------------------------------
-- @section
-- These functions get and set vehicle pilot class.

--- Sets the vehicle's pilot class to the given odf name. This does nothing useful for non-vehicle game objects. An odf name of nil resets the vehicle to the default assignment based on nation.
--- @param self GameObject
--- @param odf string?
function GameObject.SetPilotClass(self, odf)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(odf) and odf ~= nil then error("Parameter odf must be a string or nil."); end
    --- @diagnostic disable-next-line: deprecated
    SetPilotClass(self:GetHandle(), odf);
end

--- Returns the odf name of the vehicle's pilot class. Returns nil if none exists.
--- @param self GameObject
--- @return string?
function GameObject.GetPilotClass(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetPilotClass(self:GetHandle());
end

-------------------------------------------------------------------------------
-- Objective Marker
-------------------------------------------------------------------------------
-- @section
-- These functions control objective markers.
-- Objectives are visible to all teams from any distance and from any direction, with an arrow pointing to off-screen objectives. There is currently no way to make team-specific objectives.

--- Sets the game object as an objective to all teams.
--- @param self GameObject GameObject instance
function GameObject.SetObjectiveOn(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    SetObjectiveOn(self:GetHandle());

    --- @diagnostic disable-next-line: deprecated
    if not utility.isfunction(IsObjectiveOn) then
        self.cache_memo = unsaved(self.cache_memo)
        self.cache_memo.IsObjectiveOn = true;
    end
end

--- Sets the game object back to normal.
--- @param self GameObject GameObject instance
function GameObject.SetObjectiveOff(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    SetObjectiveOff(self:GetHandle());

    --- @diagnostic disable-next-line: deprecated
    if not utility.isfunction(IsObjectiveOn) then
        self.cache_memo = unsaved(self.cache_memo)
        self.cache_memo.IsObjectiveOn = nil; -- if a function to check this is implemented, use it instead
    end
end

--- If the game object an objective?
--- @param self GameObject GameObject instance
--- @return boolean true if the game object is an objective
function GameObject.IsObjectiveOn(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end

    --- @diagnostic disable-next-line: deprecated
    if utility.isfunction(IsObjectiveOn) then
        --- @diagnostic disable-next-line: deprecated
        return IsObjectiveOn(self:GetHandle());
    else
        if not self.cache_memo then return false; end
        return self.cache_memo.IsObjectiveOn ~= nil; -- if a function to check this is implemented, use it instead
    end
end

--- Sets the game object's visible name.
--- @param self GameObject GameObject instance
--- @return string Name of the objective/object
function GameObject.GetObjectiveName(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetObjectiveName(self:GetHandle());
end

--- Sets the game object's visible name.
--- @param self GameObject GameObject instance
--- @param name string Name of the objective
function GameObject.SetObjectiveName(self, name)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(name) then error("Parameter name must be a string."); end
    --- @diagnostic disable-next-line: deprecated
    SetObjectiveName(self:GetHandle(), name);
end

--- Sets the game object's visible name.
--- (Technicly a unique function, but effectively an alias for SetObjectiveName)
--- @param self GameObject GameObject instance
--- @param name string Name of the objective
--- @see GameObject.SetObjectiveName
function GameObject.SetName(self, name)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(name) then error("Parameter name must be a string."); end
    --- @diagnostic disable-next-line: deprecated
    SetName(self:GetHandle(), name);
end

-------------------------------------------------------------------------------
-- Distance
-------------------------------------------------------------------------------
-- @section
-- These functions measure and return the distance between a game object and a reference point.

--- Returns the distance in meters between the game object and a position vector, transform matrix, another object, or point on a named path.
--- @param self GameObject
--- @param target Vector|Matrix|GameObject|Handle|string Position vector, ransform matrix, Object, or path name.
--- @param point? integer If the target is a path this is the path point index, defaults to 0.
--- @return number
function GameObject.GetDistance(self, target, point)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        return GetDistance(self:GetHandle(), target:GetHandle(), point);
    elseif target ~= nil then
        --- @cast target Vector|Matrix|Handle|string
        --- @diagnostic disable-next-line: deprecated
        return GetDistance(self:GetHandle(), target, point);
    else
        error("Parameter target must be Vector, Matrix, GameObject, Handle, or path name.");
    end
end

--- Returns true if the units are closer than the given distance of each other. Returns false otherwise.
--- (This function is equivalent to GetDistance (h1, h2) < d)
--- @param self GameObject
--- @param target GameObject|Handle
--- @param dist number
--- @return boolean
function GameObject.IsWithin(self, target, dist)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        return IsWithin(self:GetHandle(), target:GetHandle(), dist);
    elseif target ~= nil then
        --- @cast target Handle
        --- @diagnostic disable-next-line: deprecated
        return IsWithin(self:GetHandle(), target, dist);
    else
        error("Parameter target must be GameObject or Handle.");
    end
end

--- Returns true if the bounding spheres of the two game objects are within the specified tolerance. The default tolerance is 1.3 meters if not specified.
--- [2.1+]
--- @param self GameObject
--- @param target GameObject|Handle
--- @param tolerance? number
--- @return boolean
function GameObject.IsTouching(self, target, tolerance)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        return IsTouching(self:GetHandle(), target:GetHandle(), tolerance);
    elseif target ~= nil then
        --- @cast target Handle
        --- @diagnostic disable-next-line: deprecated
        return IsTouching(self:GetHandle(), target, tolerance);
    else
        error("Parameter target must be GameObject or Handle.");
    end
end

-------------------------------------------------------------------------------
-- Nearest
-------------------------------------------------------------------------------
-- @section
-- These functions find and return the game object of the requested type closest to a reference point.

--- Returns the game object closest to a position vector, transform matrix, another object, or point on a named path.
--- @overload fun(target: Vector): GameObject?
--- @overload fun(target: Matrix): GameObject?
--- @overload fun(target: GameObject): GameObject?
--- @overload fun(target: Handle): GameObject?
--- @overload fun(target: string, point?: integer): GameObject?
--- @param target Vector|Matrix|GameObject|Handle|string Position vector, ransform matrix, Object, or path name.
--- @param point? integer If the target is a path this is the path point index, defaults to 0.
--- @return GameObject?
function M.GetNearestObject(target, point)
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        local handle = GetNearestObject(target:GetHandle(), point);
        if handle == nil then return nil end;
        return M.FromHandle(handle);
    elseif target ~= nil then
        --- @cast target Vector|Matrix|Handle|string
        --- @diagnostic disable-next-line: deprecated
        local handle = GetNearestObject(target, point);
        if handle == nil then return nil end;
        return M.FromHandle(handle);
    else
        error("Parameter target must be Vector, Matrix, GameObject, Handle, or path name.");
    end
end

--- Returns the game object closest to self.
--- @param self GameObject
--- @return GameObject?
function GameObject.GetNearestObject(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetNearestObject(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Returns the craft closest to a position vector, transform matrix, another object, or point on a named path.
--- @overload fun(target: Vector): GameObject?
--- @overload fun(target: Matrix): GameObject?
--- @overload fun(target: GameObject): GameObject?
--- @overload fun(target: Handle): GameObject?
--- @overload fun(target: string, point?: integer): GameObject?
--- @param target Vector|Matrix|GameObject|Handle|string Position vector, ransform matrix, Object, or path name.
--- @param point? integer If the target is a path this is the path point index, defaults to 0.
--- @return GameObject?
function M.GetNearestVehicle(target, point)
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        local handle =  GetNearestVehicle(target:GetHandle(), point);
        if handle == nil then return nil end;
        return M.FromHandle(handle);
    elseif target ~= nil then
        --- @cast target Vector|Matrix|Handle|string
        --- @diagnostic disable-next-line: deprecated
        local handle =  GetNearestVehicle(target, point);
        if handle == nil then return nil end;
        return M.FromHandle(handle);
    else
        error("Parameter target must be Vector, Matrix, GameObject, Handle, or path name.");
    end
end

--- Returns the craft closest to self.
--- @param self GameObject
--- @return GameObject?
function GameObject.GetNearestVehicle(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetNearestVehicle(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Returns the building closest to a position vector, transform matrix, another object, or point on a named path.
--- @overload fun(target: Vector): GameObject?
--- @overload fun(target: Matrix): GameObject?
--- @overload fun(target: GameObject): GameObject?
--- @overload fun(target: Handle): GameObject?
--- @overload fun(target: string, point?: integer): GameObject?
--- @param target Vector|Matrix|GameObject|Handle|string Position vector, ransform matrix, Object, or path name.
--- @param point? integer If the target is a path this is the path point index, defaults to 0.
--- @return GameObject?
function M.GetNearestBuilding(target, point)
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        local handle = GetNearestBuilding(target:GetHandle(), point);
        if handle == nil then return nil end;
        return M.FromHandle(handle);
    elseif target ~= nil then
        --- @cast target Vector|Matrix|Handle|string
        --- @diagnostic disable-next-line: deprecated
        local handle = GetNearestBuilding(target, point);
        if handle == nil then return nil end;
        return M.FromHandle(handle);
    else
        error("Parameter target must be Vector, Matrix, GameObject, Handle, or path name.");
    end
end

--- Returns the building closest to self.
--- @param self GameObject
--- @return GameObject?
function GameObject.GetNearestBuilding(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetNearestBuilding(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Returns the enemy closest to a position vector, transform matrix, another object, or point on a named path.
--- @overload fun(target: Vector): GameObject?
--- @overload fun(target: Matrix): GameObject?
--- @overload fun(target: GameObject): GameObject?
--- @overload fun(target: Handle): GameObject?
--- @overload fun(target: string, point?: integer): GameObject?
--- @param target Vector|Matrix|GameObject|Handle|string Position vector, ransform matrix, Object, or path name.
--- @param point? integer If the target is a path this is the path point index, defaults to 0.
--- @return GameObject?
function M.GetNearestEnemy(target, point)
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        local handle = GetNearestEnemy(target:GetHandle(), point);
        if handle == nil then return nil end;
        return M.FromHandle(handle);
    elseif target ~= nil then
        --- @cast target Vector|Matrix|Handle|string
        --- @diagnostic disable-next-line: deprecated
        local handle = GetNearestEnemy(target, point);
        if handle == nil then return nil end;
        return M.FromHandle(handle);
    else
        error("Parameter target must be Vector, Matrix, GameObject, Handle, or path name.");
    end
end

--- Returns the enemy closest to self.
--- @param self GameObject
--- @return GameObject?
function GameObject.GetNearestEnemy(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetNearestEnemy(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Returns the friend closest to a position vector, transform matrix, another object, or point on a named path.
--- [2.0+]
--- @overload fun(target: Vector): GameObject?
--- @overload fun(target: Matrix): GameObject?
--- @overload fun(target: GameObject): GameObject?
--- @overload fun(target: Handle): GameObject?
--- @overload fun(target: string, point?: integer): GameObject?
--- @param target Vector|Matrix|GameObject|Handle|string Position vector, ransform matrix, Object, or path name.
--- @param point? integer If the target is a path this is the path point index, defaults to 0.
--- @return GameObject?
function M.GetNearestFriend(target, point)
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        local handle = GetNearestFriend(target:GetHandle(), point);
        if handle == nil then return nil end;
        return M.FromHandle(handle);
    elseif target ~= nil then
        --- @cast target Vector|Matrix|Handle|string
        --- @diagnostic disable-next-line: deprecated
        local handle = GetNearestFriend(target, point);
        if handle == nil then return nil end;
        return M.FromHandle(handle);
    else
        error("Parameter target must be Vector, Matrix, GameObject, Handle, or path name.");
    end
end

--- Returns the friend closest to self.
--- @param self GameObject
--- @return GameObject?
function GameObject.GetNearestFriend(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetNearestFriend(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Returns the friend closest to the given reference point. Returns nil if none exists.
--- [2.1+]
--- @diagnostic disable: undefined-doc-param
--- @overload fun(h: GameObject): GameObject? --- [2.0+]
--- @overload fun(h: Handle): GameObject? --- [2.0+]
--- @overload fun(path: string, point?: integer): GameObject? --- [2.1+]
--- @overload fun(position: Vector): GameObject? --- [2.1+]
--- @overload fun(transform: Matrix): GameObject? --- [2.1+]
--- @param h Handle The reference game object.
--- @param path string The path name.
--- @param point? integer The point on the path (optional).
--- @param position Vector The position vector.
--- @param transform Matrix The transform matrix.
--- @return GameObject? object closest friend, or nil if none exists.
--- @diagnostic enable: undefined-doc-param
function M.GetNearestUnitOnTeam(...)
    local args = {...}
    if #args == 1 then
        if M.isgameobject(args[1]) then
            local self = args[1]
            --- @cast self GameObject
            --- @diagnostic disable-next-line: deprecated
            local handle = GetNearestUnitOnTeam(self:GetHandle());
            if handle == nil then return nil end;
            return M.FromHandle(handle);
        else
            local location = args[1]
            --- @cast location Vector|Matrix|Handle|string
            --- @diagnostic disable-next-line: deprecated
            local handle = GetNearestUnitOnTeam(location);
            if handle == nil then return nil end;
            return M.FromHandle(handle);
        end
    elseif #args == 2 then
        if utility.isstring(args[1]) then
            local path = args[1]
            --- @cast path string
            --- @diagnostic disable-next-line: deprecated
            local handle = GetNearestUnitOnTeam(path, args[2]);
            if handle == nil then return nil end;
            return M.FromHandle(handle);
        else
            error("Parameter path must be string.");
        end
    else
        error("Invalid number of arguments.");
    end
end

--- Returns the friend closest to self. Returns nil if none exists.
--- @param self GameObject
--- @return GameObject? object closest friend, or nil if none exists.
function GameObject.GetNearestUnitOnTeam(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetNearestUnitOnTeam(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Returns how many objects with the given team and odf name are closer than the given distance.
--- @param self GameObject
--- @param dist number
--- @param team TeamNum
--- @param odfname string
--- @return integer
function GameObject.CountUnitsNearObject(self, dist, team, odfname)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(dist) then error("Parameter dist must be number."); end
    if not utility.isnumber(team) then error("Parameter team must be number."); end
    if not utility.isstring(odfname) then error("Parameter odfname must be string."); end
    --- @diagnostic disable-next-line: deprecated
    return CountUnitsNearObject(self:GetHandle(), dist, team, odfname);
end

-------------------------------------------------------------------------------
-- Iterators
-------------------------------------------------------------------------------
-- @section
-- These functions return iterator functions for use with Lua's "for <variable> in <expression> do ... end" form. For example: "for h in AllCraft() do print(h, GetLabel(h)) end" will print the game object handle and label of every craft in the world.

--- Enumerates game objects within the given distance a target.
--- @param dist number
--- @param target Vector|Matrix|GameObject|Handle|string Position vector, ransform matrix, Object, or path name.
--- @param point? integer If the target is a path this is the path point index, defaults to 0.
--- @return function iterator Iterator of GameObject values
function M.ObjectsInRange(dist, target, point)
    if not utility.isnumber(dist) then error("Parameter dist must be number."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        return coroutine.wrap(function()
            --- @diagnostic disable-next-line: deprecated
            for handle in ObjectsInRange(dist, target:GetHandle(), point) do
                coroutine.yield(M.FromHandle(handle))
            end
        end)
    elseif target ~= nil then
        --- @cast target Vector|Matrix|Handle|string
        return coroutine.wrap(function()
            --- @diagnostic disable-next-line: deprecated
            for handle in ObjectsInRange(dist, target, point) do
                coroutine.yield(M.FromHandle(handle))
            end
        end)
    else
        error("Parameter target must be Vector, Matrix, GameObject, Handle, or path name.");
    end
end

--- Enumerates all game objects.
--- Use this function sparingly at runtime since it enumerates <em>all</em> game objects, including every last piece of scrap. If you're specifically looking for craft, use AllCraft() instead.
--- @return function iterator Iterator of GameObject values
function M.AllObjects()
    return coroutine.wrap(function()
        --- @diagnostic disable-next-line: deprecated
        for handle in AllObjects() do
            coroutine.yield(M.FromHandle(handle))
        end
    end)
end

--- Enumerates all craft.
--- @return function iterator Iterator of GameObject values
function M.AllCraft()
    return coroutine.wrap(function()
        --- @diagnostic disable-next-line: deprecated
        for handle in AllCraft() do
            coroutine.yield(M.FromHandle(handle))
        end
    end)
end

--- Enumerates all game objects currently selected by the local player.
--- @return function iterator Iterator of GameObject values
function M.SelectedObjects()
    return coroutine.wrap(function()
        --- @diagnostic disable-next-line: deprecated
        for handle in SelectedObjects() do
            coroutine.yield(M.FromHandle(handle))
        end
    end)
end

--- Enumerates all game objects marked as objectives.
--- @return function iterator Iterator of GameObject values
function M.ObjectiveObjects()
    return coroutine.wrap(function()
        --- @diagnostic disable-next-line: deprecated
        for handle in ObjectiveObjects() do
            coroutine.yield(M.FromHandle(handle))
        end
    end)
end

-------------------------------------------------------------------------------
-- Other - Custom Functions
-------------------------------------------------------------------------------
-- @section

-- Returns the scrap cost of the game object.
-- @param self GameObject GameObject instance
-- @return integer scrap cost
--function M.GetScrapCost(self)
--    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
--    
--    --- @todo move this to a cached ODF data handler
--    local odf = self:GetOdf();
--    if odf == nil then error("GetOdf() returned nil."); end
--    local odfHandle = OpenODF(odf);
--    if odfHandle == nil then error("OpenODF() returned nil."); end
--
--    local scrap = 2147483647; -- GameObject default
--    
--    local sig = self:GetClassSig();
--    if sig == utility.ClassSig.person then
--        scrap = 0;
--    end
--
--    scrap = GetODFInt(odfHandle, "GameObjectClass", "scrapCost", scrap);
--    return scrap;
--end

-- Returns the pilot cost of the game object.
-- @param self GameObject GameObject instance
-- @return integer pilot cost
--function M.GetPilotCost(self)
--    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
--    
--    --- @todo move this to a cached ODF data handler
--    local odf = self:GetOdf();
--    if odf == nil then error("GetOdf() returned nil."); end
--    local odfHandle = OpenODF(odf);
--    if odfHandle == nil then error("OpenODF() returned nil."); end
--
--    local pilot = 0; -- GameObject default
--
--    local sig = self:GetClassSig();
--    if sig == utility.ClassSig.craft then
--        pilot = 1;
--    elseif sig == utility.ClassSig.person then
--        pilot = 1;
--    elseif sig == utility.ClassSig.producer then
--        pilot = 0;
--    elseif sig == utility.ClassSig.sav then
--        pilot = 0;
--    elseif sig == utility.ClassSig.torpedo then
--        pilot = 0;
--    elseif sig == utility.ClassSig.turret then
--        pilot = 0;
--    end
--
--    local pilot = GetODFInt(odfHandle, "GameObjectClass", "pilotCost", pilot);
--    return pilot;
--end

-------------------------------------------------------------------------------
-- Other
-------------------------------------------------------------------------------
-- @section

--- Is the GameObject this odf?
--- @param self GameObject GameObject instance
--- @param odf string ODF filename
--- @usage enemy1:IsOdf("svturr")
function GameObject.IsOdf(self, odf)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(odf) then error("Parameter odf must be a string."); end
    --- @diagnostic disable-next-line: deprecated
    IsOdf(self:GetHandle(), odf);
end

--- Get odf of GameObject
--- @param self GameObject GameObject instance
function GameObject.GetOdf(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetOdf(self:GetHandle());
end

--- Get base of GameObject
--- @param self GameObject GameObject instance
--- @return string? character identifier for race
function GameObject.GetBase(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetBase(self:GetHandle());
end

--- Get label of GameObject
--- @param self GameObject GameObject instance
--- @return string? Label name string
function GameObject.GetLabel(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetLabel(self:GetHandle());
end

--- Is the GameObject this odf?
--- @param self GameObject GameObject instance
--- @param label string Label
--- @usage enemy1:SetLabel("special_object_7")
function GameObject.SetLabel(self, label)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(label) then error("Parameter label must be a string."); end
    --- @diagnostic disable-next-line: deprecated
    SetLabel(self:GetHandle(),label);
end

--- Returns the four-character class signature of the game object (e.g. "WING"). Returns nil if none exists.
--- @param self GameObject GameObject instance
--- @return string? ClassSig string
function GameObject.GetClassSig(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetClassSig(self:GetHandle());
end

--- Returns the class label of the game object (e.g. "wingman"). Returns nil if none exists.
--- @param self GameObject GameObject instance
--- @return string? Class label string
function GameObject.GetClassLabel(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetClassLabel(self:GetHandle());
end

--- Returns the numeric class identifier of the game object. Returns nil if none exists.
--- Looking up the class id number in the ClassId table will convert it to a string. Looking up the class id string in the ClassId table will convert it back to a number.
--- @param self GameObject GameObject instance
--- @return integer? ClassId number
function GameObject.GetClassId(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetClassId(self:GetHandle());
end

--- Returns the one-letter nation code of the game object (e.g. "a" for American, "b" for Black Dog, "c" for Chinese, and "s" for Soviet).
--- The nation code is usually but not always the same as the first letter of the odf name. The ODF file can override the nation in the [GameObjectClass] section, and player.odf is a hard-coded exception that uses "a" instead of "p".
--- @param self GameObject GameObject instance
--- @return string character identifier for race
function GameObject.GetNation(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetNation(self:GetHandle());
end

--- @diagnostic disable-next-line: undefined-global
if utility.isfunction(SetTeamSlot) then
    --- Set the game object in the specified team slot.
    --- This could have major sideffects so be careful with it.
    --- 
    --- This function may be nil if the base function is not available in the game.
    --- 
    --- @param self GameObject GameObject instance
    --- @param slot TeamSlotInteger Slot number, see TeamSlot
    --- @return GameObject? old_object The new game object formerly in the slot, or nil if the slot was empty
    --- @see ScriptUtils.TeamSlot
    function M.SetTeamSlot(self, slot)
        if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
        if not utility.isnumber(slot) then error("Parameter slot must be a number") end
        
        --- @diagnostic disable-next-line: undefined-global
        local handle = SetTeamSlot(self:GetHandle(), slot);

        if handle == nil then return nil end;
        return M.FromHandle(handle);
    end
end



hook.Add("DeleteObject", "GameObject_DeleteObject", function(object)
    local objectId = object:GetHandle();

    GameObjectAltered[objectId] = nil; -- remove any strong reference for being altered

    -- Alternate method where we delay deletion to next update
    -- BZ2 needs this because handles can be re-used in an upgrade, so we need to know if this has happened for an UpgradeObject event, but BZ1 doesn't have this.
    --debugprint('Decaying object ' .. tostring(objectId));
    --GameObjectDead[objectId] = object; -- store dead object for full cleanup next update (in BZ2 handle might be re-used)
end, config.get("hook_priority.DeleteObject.GameObject"));

--hook.Add("Update", "GameObject_Update", function(dtime)
--    for k,v in pairs(GameObjectDead) do
--        debugprint('Decayed object ' .. tostring(k));
--        GameObjectAltered[k] = nil; -- remove any strong reference for being altered
--        GameObjectDead[k] = nil; -- remove any strong reference for being dead
--    end
--end, config.get("hook_priority.Update.GameObject"));

customsavetype.Register(GameObject);

debugprint("_gameobject Loaded");

return M;