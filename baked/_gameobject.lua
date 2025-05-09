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
--- @class GameObject
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

-------------------------------------------------------------------------------
-- Core
-------------------------------------------------------------------------------
-- @section

--- Create new GameObject Intance.
--- @param handle Handle Handle from BZ98R
--- @return GameObject
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
        if v.addonData ~= nil then
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
    if not utility.isfunction(IsObjectiveOn) then
        for h in ObjectiveObjects() do
            _ObjectiveObjects[h] = true;
        end
    end

    for k,v in pairs(data) do
        local newGameObject = M.FromHandle(k);
        newGameObject.addonData = v;

        -- IsObjectiveOn Memo
        local objectiveData = _ObjectiveObjects[k];
        if objectiveData ~= nil then
            newGameObject.cache_memo = { IsObjectiveOn = true };
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
--- @param team integer Team number for the object, 0 to 15
--- @param pos Vector|Matrix|GameObject|Handle|string Vector, Matrix, GameObject, or pathpoint by name
--- @param point? integer index
--- @return GameObject? object Newly built GameObject
function M.BuildGameObject(odf, team, pos, point)
    local handle = nil;
    if M.isgameobject(pos) then
        --- @cast pos GameObject
        --- @diagnostic disable-next-line: deprecated
        handle = BuildObject(odf, team, pos:GetHandle());
    elseif point ~= nil then
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
--- @param slot integer Slot number, see TeamSlot
--- @see ScriptUtils.TeamSlot
--- @param team? integer Team number, 0 to 15
function M.GetTeamSlot(slot, team)
    if not utility.isnumber(slot) then error("Parameter slot must be a number") end
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number") end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetTeamSlot(slot, team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Get Player GameObject of team.
--- @param team? integer Team number of player
--- @return GameObject? player GameObject of player or nil
function M.GetPlayerGameObject(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    --- @diagnostic disable-next-line: deprecated
    local handle = GetPlayerHandle(team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Get Recycler GameObject of team.
--- @param team? integer Team number of player
--- @return GameObject? recycler GameObject of recycler or nil
function M.GetRecyclerGameObject(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    --- @diagnostic disable-next-line: deprecated
    local handle = GetRecyclerHandle(team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Get Factory GameObject of team.
--- @param team? integer Team number of player
--- @return GameObject? factory GameObject of factory or nil
function M.GetFactoryGameObject(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    --- @diagnostic disable-next-line: deprecated
    local handle = GetFactoryHandle(team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Get Armory GameObject of team.
--- @param team? integer Team number of player
--- @return GameObject? armory of armory or nil
function M.GetArmoryGameObject(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    --- @diagnostic disable-next-line: deprecated
    local handle = GetArmoryHandle(team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Get Factory GameObject of team.
--- @param team? integer Team number of player
--- @return GameObject? constructor of constructor or nil
function M.GetConstructorGameObject(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    --- @diagnostic disable-next-line: deprecated
    local handle = GetConstructorHandle(team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

-------------------------------------------------------------------------------
-- Orders
-------------------------------------------------------------------------------
-- @section

--- Order GameObject to Attack target GameObject.
--- @param self GameObject GameObject instance
--- @param target GameObject Target GameObject
--- @param priority integer Order priority, >0 removes user control
function GameObject.Attack(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        Attack(self:GetHandle(), target:GetHandle(), priority);
    else
        --Attack(self:GetHandle(), target, priority);
        error("Parameter target must be GameObject instance.");
    end
end

--- Order GameObject to Goto target Vector, Matrix, GameObject, or Path.
--- @function GameObject.Goto
--- @param self GameObject GameObject instance
--- @param target Vector|Matrix|GameObject|string Target Path name
--- @param priority? integer Order priority, >0 removes user control
function GameObject.Goto(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        Goto(self:GetHandle(), target:GetHandle(), priority);
    elseif target ~= nil then
        --- @cast target Vector|Matrix|string
        Goto(self:GetHandle(), target, priority);
    else
        error("Parameter target must be Vector, Matrix, GameObject, or path name.");
    end
end

--- Order GameObject to Mine target Path.
--- @param self GameObject GameObject instance
--- @param target Vector|Matrix|string Target Vector, Matrix, or Path name
--- @param priority integer Order priority, >0 removes user control
function GameObject.Mine(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if target ~= nil then
        Mine(self:GetHandle(), target, priority);
    else
        error("Parameter target must be Vector, Matrix, GameObject, or path name.");
    end
end

--- Order GameObject to Follow target GameObject.
--- @param self GameObject GameObject instance
--- @param target any Target GameObject instance
--- @param priority integer Order priority, >0 removes user control
function GameObject.Follow(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        Follow(self:GetHandle(), target:GetHandle(), priority);
    else
        --Follow(self:GetHandle(), target, priority);
        error("Parameter target must be GameObject instance.");
    end
end

--- Is the GameObject following the target GameObject?
--- @param self GameObject GameObject instance
--- @param target any Target GameObject instance
--- @return boolean following true if following, false otherwise
function GameObject.IsFollowing(self, target)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not M.isgameobject(target) then error("Parameter target must be GameObject instance."); end
    return IsFollowing(self:GetHandle(), target:GetHandle());
end

--- Order GameObject to Defend area.
--- @param self GameObject GameObject instance
--- @param priority integer Order priority, >0 removes user control
function GameObject.Defend(self, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    Defend(self:GetHandle(), priority);
end

--- Order GameObject to Defend2 target GameObject.
--- @param self GameObject GameObject instance
--- @param target any Target GameObject instance
--- @param priority integer Order priority, >0 removes user control
function GameObject.Defend2(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not M.isgameobject(target) then error("Parameter target must be GameObject instance."); end
    --if _gameobject.isgameobject(target) then
        Defend2(self:GetHandle(), target:GetHandle(), priority);
    --else
    --    Defend2(self:GetHandle(), target, priority);
    --end
end

--- Order GameObject to Stop.
--- @param self GameObject GameObject instance
--- @param priority integer Order priority, >0 removes user control
function GameObject.Stop(self, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    Stop(self:GetHandle(), priority);
end

--- Order GameObject to Patrol target path.
--- @param self GameObject GameObject instance
--- @param target any Target Path name
--- @param priority integer Order priority, >0 removes user control
function GameObject.Patrol(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        Patrol(self:GetHandle(), target:GetHandle(), priority);
    else
        Patrol(self:GetHandle(), target, priority);
    end
end

--- Order GameObject to Retreat.
--- @param self GameObject GameObject instance
--- @param target any Target GameObject or Path name
--- @param priority integer Order priority, >0 removes user control
function GameObject.Retreat(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        Retreat(self:GetHandle(), target:GetHandle(), priority);
    else
        Retreat(self:GetHandle(), target, priority)
    end
end

--- Order GameObject to GetIn target GameObject.
--- @param self GameObject GameObject instance
--- @param target GameObject Target GameObject
--- @param priority integer Order priority, >0 removes user control
function GameObject.GetIn(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not M.isgameobject(self) then error("Parameter target must be GameObject instance."); end
    --if _gameobject.isgameobject(target) then
        GetIn(self:GetHandle(), target:GetHandle(), priority);
    --else
    --    GetIn(self:GetHandle(), target, priority)
    --end
end

--- Order GameObject to Pickup target GameObject.
--- @param self GameObject GameObject instance
--- @param target GameObject Target GameObject
--- @param priority integer Order priority, >0 removes user control
function GameObject.Pickup(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not M.isgameobject(target) then error("Parameter target must be GameObject instance."); end
    --if _gameobject.isgameobject(target) then
        Pickup(self:GetHandle(), target:GetHandle(), priority);
    --else
    --    Pickup(self:GetHandle(), target, priority)
    --end
end

--- Order GameObject to Pickup target path name.
--- @param self GameObject GameObject instance
--- @param target any Target vector, matrix, or path name
--- @param priority integer Order priority, >0 removes user control
function GameObject.Dropoff(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    Dropoff(self:GetHandle(), target, priority)
end

--- Order GameObject to Build target config.
--- Oddly this function does not include a location for the action, might want to use the far more powerful orders system.
--- @param self GameObject GameObject instance
--- @param odf string Object Definition
--- @param priority integer Order priority, >0 removes user control
function GameObject.Build(self, odf, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    Build(self:GetHandle(), target, priority)
end

--- Order GameObject to BuildAt target GameObject.
--- @param self GameObject GameObject instance
--- @param odf string Object Definition
--- @param target GameObject Target GameObject instance, vector, matrix, or path name
--- @param priority integer Order priority, >0 removes user control
function GameObject.BuildAt(self, odf, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        BuildAt(self:GetHandle(), odf, target:GetHandle(), priority);
    else
        BuildAt(self:GetHandle(), odf, target, priority)
    end
end

--- Order GameObject to Formation follow target GameObject.
--- @param self GameObject GameObject instance
--- @param target any Target GameObject instance
--- @param priority integer Order priority, >0 removes user control
function GameObject.Formation(self, target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not M.isgameobject(target) then error("Parameter target must be GameObject instance."); end
    --if _gameobject.isgameobject(target) then
        Formation(self:GetHandle(), target:GetHandle(), priority);
    --else
    --    Formation(self:GetHandle(), target, priority);
    --end
end

--- Order GameObject to Hunt area.
--- @param self GameObject GameObject instance
--- @param priority integer Order priority, >0 removes user control
function GameObject.Hunt(self, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    Hunt(self:GetHandle(), priority);
end

-------------------------------------------------------------------------------
-- Position & Velocity
-------------------------------------------------------------------------------
-- @section

--- Get object's position vector.
--- @param self GameObject GameObject instance
--- @return Vector
function GameObject.GetPosition(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetPosition(self:GetHandle());
end

--- Get front vector.
--- @param self GameObject GameObject instance
--- @return Vector
function GameObject.GetFront(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetFront(self:GetHandle());
end

--- Set the position of the GameObject.
--- @param self GameObject GameObject instance
--- @param position any Vector position, Matrix position, or path name
--- @param point? int Index of the path point in the path (optional)
function GameObject.SetPosition(self, position, point)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if point ~= nil then
        SetPosition(self:GetHandle(), position, point);
    else
        SetPosition(self:GetHandle(), position);
    end
end

--- Get object's tranform matrix.
--- @param self GameObject GameObject instance
--- @return Matrix
function GameObject.GetTransform(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetTransform(self:GetHandle());
end

--- Set the tranform matrix of the GameObject.
--- @param self GameObject GameObject instance
--- @param transform Matrix transform matrix
function GameObject.SetTransform(self, transform)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    SetTransform(self:GetHandle(), transform);
end

--- Get object's velocity vector.
--- @param self GameObject GameObject instance
--- @return Vector Vector (0,0,0) if the handle is invalid or isn't movable.
function GameObject.GetVelocity(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetVelocity(self:GetHandle());
end

--- Set the velocity of the GameObject.
--- @param self GameObject GameObject instance
--- @param vel Vector Vector velocity
function GameObject.SetVelocity(self, vel)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    SetVelocity(self:GetHandle(), vel);
end

--- Get object's omega.
--- @param self GameObject GameObject instance
--- @return Vector Vector, (0,0,0) if the handle is invalid or isn't movable.
function GameObject.GetOmega(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetOmega(self:GetHandle());
end

--- Set the omega of the GameObject.
--- @param self GameObject GameObject instance
--- @param omega any
function GameObject.SetOmega(self, omega)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    SetOmega(self:GetHandle(),omega);
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
    return IsValid(self:GetHandle());
end

--- Is the GameObject alive and is still pilot controlled?
--- Returns true if the game object exists and (if the object is a vehicle) controlled. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject.IsAlive(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return IsAlive(self:GetHandle());
end

--- Is the GameObject alive and piloted?
--- Returns true if the game object exists and (if the object is a vehicle) controlled and piloted. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject.IsAliveAndPilot(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return IsAliveAndPilot(self:GetHandle());
end

--- Returns true if it's a Craft.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject.IsCraft(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return IsCraft(self:GetHandle());
end

--- Returns true if it's a person.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject.IsPerson(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return IsPerson(self:GetHandle());
end

--- Returns true if it's a Building.
--- Does not include guntowers.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject.IsBuilding(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return IsBuilding(self:GetHandle());
end

--- Checks if the GameObject has cargo (tug).
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject.HasCargo(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    HasCargo(self:GetHandle());
end

--- What tug GameObject is tugging this if any?
--- @param self GameObject GameObject instance
--- @return GameObject GameObject of the GameObject carried by the GameObject, or nil
function GameObject.GetCargo(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    local handle = GetCargo(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- What tug GameObject is tugging this if any?
--- @param self GameObject GameObject instance
--- @return GameObject GameObject of the tug carrying the GameObject, or nil
function GameObject.GetTug(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    local handle = GetTug(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Has the GameObject hopped out of a vehicle? What vehicle?
--- @param self GameObject GameObject instance
--- @return GameObject GameObject of the vehicle that the pilot most recently hopped out of, or nil
function GameObject.HoppedOutOf(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    local handle = HoppedOutOf(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

-------------------------------------------------------------------------------
-- Damage, Health, and Ammo
-------------------------------------------------------------------------------
-- @section

--- Applies damage to the game object.
--- @param self GameObject GameObject instance
--- @param amt number damage amount
function GameObject.Damage(self, amt)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amt) then error("Parameter amt must be number."); end
    Damage(self:GetHandle(), amt);
end

--- Get health ratio of GameObject.
--- @usage if friend1:GetHealth() < 0.5 then friend1:Retreat("retreat_path"); end
--- @param self GameObject GameObject instance
--- @return number health ratio
function GameObject.GetHealth(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetHealth(self:GetHandle());
end

--- Get current health of GameObject.
--- @param self GameObject GameObject instance
--- @return number current health or nil
function GameObject.GetCurHealth(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetCurHealth(self:GetHandle());
end

--- Get max health of GameObject.
--- @param self GameObject GameObject instance
--- @return number max health or nil
function GameObject.GetMaxHealth(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetMaxHealth(self:GetHandle());
end

--- Sets the current health of the GameObject to the NewHealth value.
--- @param self GameObject GameObject instance
--- @param amt any health amount
function GameObject.SetCurHealth(self, amt)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amt) then error("Parameter amt must be number."); end
    SetCurHealth(self:GetHandle(), amt);
end

--- Sets the max health of the GameObject to the NewHealth value.
--- @param self GameObject GameObject instance
--- @param amt any health amount
function GameObject.SetMaxHealth(self, amt)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amt) then error("Parameter amt must be number."); end
    SetMaxHealth(self:GetHandle(), amt);
end

--- Adds the health to the GameObject.
--- @param self GameObject GameObject instance
--- @param amt any health amount
function GameObject.AddHealth(self, amt)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amt) then error("Parameter amt must be number."); end
    AddHealth(self:GetHandle(), amt);
end

--- GiveMaxHealth
--- @param self GameObject GameObject instance
function GameObject.GiveMaxHealth(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    GiveMaxHealth(self:GetHandle());
end

--- Get ammo ratio of GameObject.
--- @param self GameObject GameObject instance
--- @return number ammo ratio
function GameObject.GetAmmo(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetAmmo(self:GetHandle());
end

--- Get current ammo of GameObject.
--- @param self GameObject GameObject instance
--- @return number current ammo or nil
function GameObject.GetCurAmmo(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetCurAmmo(self:GetHandle());
end

--- Get max ammo of GameObject.
--- @param self GameObject GameObject instance
--- @return number max ammo or nil
function GameObject.GetMaxAmmo(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetMaxAmmo(self:GetHandle());
end

--- Sets the current ammo of the GameObject to the NewAmmo value.
--- @param self GameObject GameObject instance
--- @param amt any ammo amount
function GameObject.SetCurAmmo(self, amt)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amt) then error("Parameter amt must be number."); end
    SetCurAmmo(self:GetHandle(), amt);
end

--- Sets the max ammo of the GameObject to the NewAmmo value.
--- @param self GameObject GameObject instance
--- @param amt any ammo amount
function GameObject.SetMaxAmmo(self, amt)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amt) then error("Parameter amt must be number."); end
    SetMaxAmmo(self:GetHandle(), amt);
end

--- Adds the ammo to the GameObject.
--- @param self GameObject GameObject instance
--- @param amt any ammo amount
function GameObject.AddAmmo(self, amt)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amt) then error("Parameter amt must be number."); end
    AddAmmo(self:GetHandle(), amt);
end

--- GiveMaxAmmo
--- @param self GameObject GameObject instance
function GameObject.GiveMaxAmmo(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    GiveMaxAmmo(self:GetHandle());
end


-------------------------------------------------------------------------------
-- Team
-------------------------------------------------------------------------------
-- @section

--- Get team number of the GameObject.
--- @param self GameObject GameObject instance
--- @return integer Team number
function GameObject.GetTeamNum(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetTeamNum(self:GetHandle());
end

--- Set team number of the GameObject.
--- @param self GameObject GameObject instance
--- @param team integer new team number
function GameObject.SetTeamNum(self, team)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(team) then error("Parameter amt must be number."); end
    SetTeamNum(self:GetHandle(), team);
end

--- Get perceived team number of the GameObject.
--- @param self GameObject GameObject instance
--- @return integer Team number
function GameObject.GetPerceivedTeam(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetPerceivedTeam(self:GetHandle());
end

--- Set perceived team number of the GameObject.
--- @param self GameObject GameObject instance
--- @param team integer new team number
function GameObject.SetPerceivedTeam(self, team)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(team) then error("Parameter amt must be number."); end
    SetPerceivedTeam(self:GetHandle(), team);
end

-------------------------------------------------------------------------------
-- Pilot Class
-------------------------------------------------------------------------------
-- @section
-- These functions get and set vehicle pilot class.

--- Sets the vehicle's pilot class to the given odf name. This does nothing useful for non-vehicle game objects. An odf name of nil resets the vehicle to the default assignment based on nation.
--- @param h handle
--- @param odfname string
function GameObject.SetPilotClass(h, odfname)
    if not M.isgameobject(h) then error("Parameter h must be GameObject instance."); end
    if not utility.isstring(odfname) and odfname ~= nil then error("Parameter odfname must be a string or nil."); end
    SetPilotClass(h:GetHandle(), odfname);
end

--- Returns the odf name of the vehicle's pilot class. Returns nil if none exists.
--- @param h handle
--- @return string
function GameObject.GetPilotClass(h)
    if not M.isgameobject(h) then error("Parameter h must be GameObject instance."); end
    return GetPilotClass(h:GetHandle());
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
    SetObjectiveOn(self:GetHandle());

    if not utility.isfunction(IsObjectiveOn) then
        self.cache_memo = unsaved(self.cache_memo)
        self.cache_memo.IsObjectiveOn = true;
    end
end

--- Sets the game object back to normal.
--- @param self GameObject GameObject instance
function GameObject.SetObjectiveOff(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    SetObjectiveOff(self:GetHandle());

    if not utility.isfunction(IsObjectIsObjectiveOnive) then
        self.cache_memo = unsaved(self.cache_memo)
        self.cache_memo.IsObjectiveOn = nil; -- if a function to check this is implemented, use it instead
    end
end

--- If the game object an objective?
--- @param self GameObject GameObject instance
--- @return bool true if the game object is an objective
function GameObject.IsObjectiveOn(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end

    if utility.isfunction(IsObjectiveOn) then
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
    return GetObjectiveName(self:GetHandle());
end

--- Sets the game object's visible name.
--- @param self GameObject GameObject instance
--- @param name string Name of the objective
function GameObject.SetObjectiveName(self, name)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(name) then error("Parameter name must be a string."); end
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
    SetName(self:GetHandle(), name);
end


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
  IsOdf(self:GetHandle(), odf);
end

--- Get odf of GameObject
--- @param self GameObject GameObject instance
function GameObject.GetOdf(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetOdf(self:GetHandle());
end

--- Get base of GameObject
--- @param self GameObject GameObject instance
--- @return string character identifier for race
function GameObject.GetBase(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetBase(self:GetHandle());
end

--- Get label of GameObject
--- @param self GameObject GameObject instance
--- @return string Label name string
function GameObject.GetLabel(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetLabel(self:GetHandle());
end

--- Is the GameObject this odf?
--- @param self GameObject GameObject instance
--- @param label string Label
--- @usage enemy1:SetLabel("special_object_7")
function GameObject.SetLabel(self, label)
  if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
  if not utility.isstring(label) then error("Parameter label must be a string."); end
  SetLabel(self:GetHandle(),label);
end

--- Get nation of GameObject
--- @param self GameObject GameObject instance
--- @return string character identifier for race
function GameObject.GetNation(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetNation(self:GetHandle());
end

--- Get ClassSig of GameObject
--- @param self GameObject GameObject instance
function GameObject.GetClassSig(self)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetClassSig(self:GetHandle());
end

--- @diagnostic disable-next-line: undefined-global
if utility.isfunction(SetTeamSlot) then
    --- Set the game object in the specified team slot.
    --- This could have major sideffects so be careful with it.
    --- 
    --- This function may be nil if the base function is not available in the game.
    --- 
    --- @param self GameObject GameObject instance
    --- @param slot integer Slot number, see TeamSlot
    --- @return GameObject? old_object The new game object formerly in the slot, or nil if the slot was empty
    --- @see ScriptUtils.TeamSlot
    function M:SetTeamSlot(self, slot)
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