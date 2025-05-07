--- BZ98R LUA Extended API GameObject.
-- 
-- GameObject wrapper functions.
-- 
-- Dependencies: @{_utility}, @{_config}, @{_hook}, @{_unsaved}, @{_customsavetype}
-- @module _gameobject
-- @author John "Nielk1" Klein

local debugprint = debugprint or function() end;

debugprint("_gameobject Loading");

local utility = require("_utility");
local config = require("_config");
local hook = require("_hook");
local unsaved = require("_unsaved");
local customsavetype = require("_customsavetype");

--- GameObject references swapped.
-- The GameObject's references have been swapped.
-- This means that every single reference to object A and object B are now swapped.
-- An actual swap didn't occur, but instead the data inside the objects was swapped.
-- Because the full data was swapped you may need to fixup some anomalies in the custom stored data.
--
-- Call method: @{_hook.CallAllNoReturn|CallAllNoReturn}
--
-- @event GameObject:SwapObjectReferences
-- @tparam GameObject A GameObject instance
-- @tparam GameObject B GameObject instance
-- @see _hook.Add

local _gameobject = {};

--- Is this object an instance of GameObject?
-- @param object Object in question
-- @treturn bool
function _gameobject.isgameobject(object)
    return (type(object) == "table" and object.__type == "GameObject");
end

local GameObjectMetatable = {};
GameObjectMetatable.__mode = "v";
local GameObjectWeakList = setmetatable({}, GameObjectMetatable);
local GameObjectAltered = {};
local GameObjectDead = {};

--- GameObject.
-- An object containing all functions and data related to a game object.
GameObject = {}; -- the table representing the class, which will double as the metatable for the instances
--GameObject.__index = GameObject; -- failed table lookups on the instances should fallback to the class table, to get methods
GameObject.__index = function(dtable, key)
    local retVal = rawget(dtable, key);
    if retVal ~= nil then return retVal; end
    local addonData = rawget(dtable, "addonData");
    if addonData ~= nil then
        retVal = rawget(rawget(dtable, "addonData"), key);
        if retVal ~= nil then return retVal; end
    end
    return rawget(GameObject, key); -- if you fail to get it from the subdata, move on to base (looking for functions)
end
GameObject.__newindex = function(dtable, key, value)
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

----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Core
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

--- Create new GameObject Intance.
-- @tparam handle handle Handle from BZ98R
-- @treturn GameObject
function _gameobject.FromHandle(handle)
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
-- @tparam GameObject self GameObject instance
-- @treturn Handle
function GameObject.GetHandle(self)
    return self.id;
end

--- Save event function.
-- INTERNAL USE.
-- @tparam GameObject self GameObject instance
-- @return ...
function GameObject.Save(self)
    return self.id;
end

--- Load event function.
-- INTERNAL USE.
-- @param id Handle
function GameObject.Load(id)
    return _gameobject.FromHandle(id);
end

--- BulkSave event function.
-- INTERNAL USE.
-- @return ...
function GameObject.BulkSave()
    -- store all the custom data we have for GameObjects by their handle keys
    local returnData = {};
    for k,v in pairs(GameObjectWeakList) do
        if v.addonData ~= nil then
            returnData[k] = v.addonData;
        end
    end
    
    -- store a list of handles that have already died (in theory this should always be empty but it might happen before Update can clean this)
    local returnDataDead = {};
    for k,v in pairs(GameObjectDead) do
        --table.insert(returnDataDead, v:GetHandle());
        table.insert(returnDataDead, k);
    end
    return returnData,returnDataDead;
end

--- BulkLoad event function.
-- INTERNAL USE.
-- @param data Object data
-- @param dataDead Dead object data
function GameObject.BulkLoad(data,dataDead)
    local _ObjectiveObjects = {};
    if not utility.isfunction(IsObjectiveOn) then
        for h in ObjectiveObjects() do
            _ObjectiveObjects[h] = true;
        end
    end

    for k,v in pairs(data) do
        local newGameObject = _gameobject.FromHandle(k);
        newGameObject.addonData = v;

        -- IsObjectiveOn Memo
        local objectiveData = _ObjectiveObjects[k];
        if objectiveData ~= nil then
            newGameObject.cache_memo = { IsObjectiveOn = true };
            _ObjectiveObjects[k] = nil; -- does this speed things up or slow them down?
        end
    end
    for k,v in pairs(dataDead) do
        local newGameObject = _gameobject.FromHandle(v); -- this will be either a new GameObject or an existing one from the above addon data filling loop
        GameObjectDead[v] = newGameObject;
    end
end

--- BulkPostLoad event function.
-- INTERNAL USE.
function GameObject.BulkPostLoad()

end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Object Creation / Destruction
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

--- Build Object.
-- @tparam string odf Object Definition File (without ".odf")
-- @tparam int team Team number for the object, 0 to 15
-- @param pos Position as GameObject, Vector, or Matrix
-- @treturn GameObject Newly built GameObject
-- @function BuildGameObject

--- Build Object.
-- @tparam string odf Object Definition File (without ".odf")
-- @tparam int team Team number for the object, 0 to 15
-- @tparam string pos Pathpoint Name
-- @tparam[opt] integer point index
-- @treturn GameObject Newly built GameObject
function _gameobject.BuildGameObject(odf, team, pos, point)
    local handle = nil;
    if (point ~= nil) then
        handle = BuildObject(odf, team, pos, point);
    elseif _gameobject.isgameobject(pos) then
        handle = BuildObject(odf, team, pos:GetHandle());
    else
        handle = BuildObject(odf, team, pos);
    end
    if handle == nil then return nil end;
    return _gameobject.FromHandle(handle);
end

--- Remove GameObject from world.
-- @tparam GameObject self GameObject instance
function GameObject.RemoveObject(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    RemoveObject(self:GetHandle());
end

--- Get Player GameObject of team.
-- @tparam[opt] int team Team number of player
-- @treturn GameObject GameObject of player or nil
function _gameobject.GetPlayerGameObject(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    local handle = GetPlayerHandle(team);
    if handle == nil then return nil end;
    return _gameobject.FromHandle(handle);
end

--- Get Recycler GameObject of team.
-- @tparam[opt] int team Team number of player
-- @treturn GameObject GameObject of player or nil
function _gameobject.GetRecyclerGameObject(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    local handle = GetRecyclerHandle(team);
    if handle == nil then return nil end;
    return _gameobject.FromHandle(handle);
end

--- Get Factory GameObject of team.
-- @tparam[opt] int team Team number of player
-- @treturn GameObject GameObject of player or nil
function _gameobject.GetFactoryGameObject(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    local handle = GetFactoryHandle(team);
    if handle == nil then return nil end;
    return _gameobject.FromHandle(handle);
end

--- Get Armory GameObject of team.
-- @tparam[opt] int team Team number of player
-- @treturn GameObject GameObject of player or nil
function _gameobject.GetArmoryGameObject(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    local handle = GetArmoryHandle(team);
    if handle == nil then return nil end;
    return _gameobject.FromHandle(handle);
end

--- Get Factory GameObject of team.
-- @tparam[opt] int team Team number of player
-- @treturn GameObject GameObject of player or nil
function _gameobject.GetConstructorGameObject(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    local handle = GetConstructorHandle(team);
    if handle == nil then return nil end;
    return _gameobject.FromHandle(handle);
end

--- Get GameObject by Label.
-- @param key Label
-- @treturn GameObject GameObject with Label or nil if none found
function _gameobject.GetGameObject(key)
    local handle = GetHandle(key);
    if handle == nil then return nil end;
    return _gameobject.FromHandle(handle);
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Orders
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

--- Order GameObject to Attack target GameObject.
-- @tparam GameObject self GameObject instance
-- @tparam GameObject target Target GameObject
-- @tparam int priority Order priority, >0 removes user control
function GameObject.Attack(self, target, priority)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if _gameobject.isgameobject(target) then
        Attack(self:GetHandle(), target:GetHandle(), priority);
    else
        Attack(self:GetHandle(), target, priority);
    end
end

--- Order GameObject to Goto target GameObject
-- @function GameObject.Goto
-- @tparam GameObject self GameObject instance
-- @param target Target GameObject
-- @tparam[opt] int priority Order priority, >0 removes user control

--- Order GameObject to Goto target Vector
-- @function GameObject.Goto
-- @tparam GameObject self GameObject instance
-- @param target Target Vector
-- @tparam[opt] int priority Order priority, >0 removes user control

--- Order GameObject to Goto target Vector
-- @function GameObject.Goto
-- @tparam GameObject self GameObject instance
-- @param target Target Matrix
-- @tparam[opt] int priority Order priority, >0 removes user control

--- Order GameObject to Goto target Path.
-- @function GameObject.Goto
-- @tparam GameObject self GameObject instance
-- @param target Target Path name
-- @tparam int point Path point index, 0 based
-- @tparam[opt] int priority Order priority, >0 removes user control

function GameObject.Goto(self, target, priority, extra)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if _gameobject.isgameobject(target) then
        Goto(self:GetHandle(), target:GetHandle(), priority);
    else
        Goto(self:GetHandle(), target, priority);
    end
end

--- Order GameObject to Mine target Path.
-- @tparam GameObject self GameObject instance
-- @param target Target Vector, Matrix, or Path name
-- @tparam int priority Order priority, >0 removes user control
function GameObject.Mine(self, target, priority)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if _gameobject.isgameobject(target) then
        Mine(self:GetHandle(), target:GetHandle(), priority);
    else
        Mine(self:GetHandle(), target, priority);
    end
end

--- Order GameObject to Follow target GameObject.
-- @tparam GameObject self GameObject instance
-- @param target Target GameObject instance
-- @tparam int priority Order priority, >0 removes user control
function GameObject.Follow(self, target, priority)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if _gameobject.isgameobject(target) then
        Follow(self:GetHandle(), target:GetHandle(), priority);
    else
        Follow(self:GetHandle(), target, priority);
    end
end

--- Is the GameObject following the target GameObject?
-- @tparam GameObject self GameObject instance
-- @param target Target GameObject instance
function GameObject.Follow(self, target)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not _gameobject.isgameobject(target) then error("Parameter target must be GameObject instance."); end
    IsFollowing(self:GetHandle(), target:GetHandle());
end

--- Order GameObject to Defend area.
-- @tparam GameObject self GameObject instance
-- @tparam int priority Order priority, >0 removes user control
function GameObject.Defend(self, priority)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    Defend(self:GetHandle(), priority);
end

--- Order GameObject to Defend2 target GameObject.
-- @tparam GameObject self GameObject instance
-- @param target Target GameObject instance
-- @tparam int priority Order priority, >0 removes user control
function GameObject.Defend2(self, target, priority)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not _gameobject.isgameobject(target) then error("Parameter target must be GameObject instance."); end
    --if _gameobject.isgameobject(target) then
        Defend2(self:GetHandle(), target:GetHandle(), priority);
    --else
    --    Defend2(self:GetHandle(), target, priority);
    --end
end

--- Order GameObject to Stop.
-- @tparam GameObject self GameObject instance
-- @tparam int priority Order priority, >0 removes user control
function GameObject.Stop(self, priority)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    Stop(self:GetHandle(), priority);
end

--- Order GameObject to Patrol target path.
-- @tparam GameObject self GameObject instance
-- @param target Target Path name
-- @tparam int priority Order priority, >0 removes user control
function GameObject.Patrol(self, target, priority)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if _gameobject.isgameobject(target) then
        Patrol(self:GetHandle(), target:GetHandle(), priority);
    else
        Patrol(self:GetHandle(), target, priority);
    end
end

--- Order GameObject to Retreat.
-- @tparam GameObject self GameObject instance
-- @param target Target GameObject or Path name
-- @tparam int priority Order priority, >0 removes user control
function GameObject.Retreat(self, target, priority)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if _gameobject.isgameobject(target) then
        Retreat(self:GetHandle(), target:GetHandle(), priority);
    else
        Retreat(self:GetHandle(), target, priority)
    end
end

--- Order GameObject to GetIn target GameObject.
-- @tparam GameObject self GameObject instance
-- @tparam GameObject target Target GameObject
-- @tparam int priority Order priority, >0 removes user control
function GameObject.GetIn(self, target, priority)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not _gameobject.isgameobject(self) then error("Parameter target must be GameObject instance."); end
    --if _gameobject.isgameobject(target) then
        GetIn(self:GetHandle(), target:GetHandle(), priority);
    --else
    --    GetIn(self:GetHandle(), target, priority)
    --end
end

--- Order GameObject to Pickup target GameObject.
-- @tparam GameObject self GameObject instance
-- @tparam GameObject target Target GameObject
-- @tparam int priority Order priority, >0 removes user control
function GameObject.Pickup(self, target, priority)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not _gameobject.isgameobject(target) then error("Parameter target must be GameObject instance."); end
    --if _gameobject.isgameobject(target) then
        Pickup(self:GetHandle(), target:GetHandle(), priority);
    --else
    --    Pickup(self:GetHandle(), target, priority)
    --end
end

--- Order GameObject to Pickup target path name.
-- @tparam GameObject self GameObject instance
-- @param target Target vector, matrix, or path name
-- @tparam int priority Order priority, >0 removes user control
function GameObject.Dropoff(self, target, priority)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    Dropoff(self:GetHandle(), target, priority)
end

--- Order GameObject to Build target config.
-- Oddly this function does not include a location for the action, might want to use the far more powerful orders system.
-- @tparam GameObject self GameObject instance
-- @tparam string odf Object Definition
-- @tparam int priority Order priority, >0 removes user control
function GameObject.Build(self, odf, priority)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    Build(self:GetHandle(), target, priority)
end

--- Order GameObject to BuildAt target GameObject.
-- @tparam GameObject self GameObject instance
-- @tparam string odf Object Definition
-- @tparam GameObject target Target GameObject instance, vector, matrix, or path name
-- @tparam int priority Order priority, >0 removes user control
function GameObject.BuildAt(self, odf, target, priority)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if _gameobject.isgameobject(target) then
        BuildAt(self:GetHandle(), odf, target:GetHandle(), priority);
    else
        BuildAt(self:GetHandle(), odf, target, priority)
    end
end

--- Order GameObject to Formation follow target GameObject.
-- @tparam GameObject self GameObject instance
-- @param target Target GameObject instance
-- @tparam int priority Order priority, >0 removes user control
function GameObject.Formation(self, target, priority)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not _gameobject.isgameobject(target) then error("Parameter target must be GameObject instance."); end
    --if _gameobject.isgameobject(target) then
        Formation(self:GetHandle(), target:GetHandle(), priority);
    --else
    --    Formation(self:GetHandle(), target, priority);
    --end
end

--- Order GameObject to Hunt area.
-- @tparam GameObject self GameObject instance
-- @tparam int priority Order priority, >0 removes user control
function GameObject.Hunt(self, priority)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    Hunt(self:GetHandle(), priority);
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Position & Velocity
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

--- Get object's position vector.
-- @tparam GameObject self GameObject instance
-- @treturn Vector
function GameObject.GetPosition(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetPosition(self:GetHandle());
end

--- Get front vector.
-- @tparam GameObject self GameObject instance
-- @treturn Vector
function GameObject.GetFront(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetFront(self:GetHandle());
end

--- Set the position of the GameObject.
-- @tparam GameObject self GameObject instance
-- @param position Vector position, Matrix position, or path name
-- @tparam[opt] int point Index of the path point in the path (optional)
function GameObject.SetPosition(self, position, point)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if point ~= nil then
        SetPosition(self:GetHandle(), position, point);
    else
        SetPosition(self:GetHandle(), position);
    end
end

--- Get object's tranform matrix.
-- @tparam GameObject self GameObject instance
-- @treturn Matrix
function GameObject.GetTransform(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetTransform(self:GetHandle());
end

--- Set the tranform matrix of the GameObject.
-- @tparam GameObject self GameObject instance
-- @tparam Matrix transform transform matrix
function GameObject.SetTransform(self, transform)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    SetTransform(self:GetHandle(), transform);
end

--- Get object's velocity vector.
-- @tparam GameObject self GameObject instance
-- @treturn Vector Vector, (0,0,0) if the handle is invalid or isn't movable.
function GameObject.GetVelocity(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetVelocity(self:GetHandle());
end

--- Set the velocity of the GameObject.
-- @tparam GameObject self GameObject instance
-- @tparam Vector vel Vector velocity
function GameObject.SetVelocity(self, vel)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    SetVelocity(self:GetHandle(), vel);
end

--- Get object's omega.
-- @tparam GameObject self GameObject instance
-- @treturn Vector Vector, (0,0,0) if the handle is invalid or isn't movable.
function GameObject.GetOmega(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetOmega(self:GetHandle());
end

--- Set the omega of the GameObject.
-- @tparam GameObject self GameObject instance
-- @param omega
function GameObject.SetOmega(self, omega)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    SetOmega(self:GetHandle(),omega);
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Condition Checks
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

--- Is the GameObject alive and is still pilot controlled?
-- @tparam GameObject self GameObject instance
-- @treturn bool
function GameObject.IsAlive(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return IsAlive2(self:GetHandle());
end

--- Is the GameObject alive and piloted?
-- Returns true if the handle passed in is a user's pilot, returns false if dead, no AI pilot, or pilotClass is NULL.
-- @tparam GameObject self GameObject instance
-- @treturn bool
function GameObject.IsAliveAndPilot(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return IsAliveAndPilot(self:GetHandle());
end

--- Returns true if it's a Craft.
-- @tparam GameObject self GameObject instance
-- @treturn bool
function GameObject.IsCraft(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return IsCraft(self:GetHandle());
end

--- Returns true if it's a person.
-- @tparam GameObject self GameObject instance
-- @treturn bool
function GameObject.IsPerson(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return IsPerson(self:GetHandle());
end

--- Returns true if it's a Building.
-- Does not include guntowers.
-- @tparam GameObject self GameObject instance
-- @treturn bool
function GameObject.IsBuilding(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return IsBuilding(self:GetHandle());
end

--- Checks if the GameObject has cargo (tug).
-- @tparam GameObject self GameObject instance
-- @treturn bool
function GameObject.HasCargo(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    HasCargo(self:GetHandle());
end

--- What tug GameObject is tugging this if any?
-- @tparam GameObject self GameObject instance
-- @treturn GameObject GameObject of the GameObject carried by the GameObject, or nil
function GameObject.GetCargo(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    local handle = GetCargo(self:GetHandle());
    if handle == nil then return nil end;
    return _gameobject.FromHandle(handle);
end

--- What tug GameObject is tugging this if any?
-- @tparam GameObject self GameObject instance
-- @treturn GameObject GameObject of the tug carrying the GameObject, or nil
function GameObject.GetTug(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    local handle = GetTug(self:GetHandle());
    if handle == nil then return nil end;
    return _gameobject.FromHandle(handle);
end

--- Has the GameObject hopped out of a vehicle? What vehicle?
-- @tparam GameObject self GameObject instance
-- @treturn GameObject GameObject of the vehicle that the pilot most recently hopped out of, or nil
function GameObject.HoppedOutOf(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    local handle = HoppedOutOf(self:GetHandle());
    if handle == nil then return nil end;
    return _gameobject.FromHandle(handle);
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Damage, Health, and Ammo
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

--- Cause GameObject to take damage.
-- Note that if the damager is set the amt will be an integer.
-- @tparam GameObject self GameObject instance
-- @param amt damage amount
function GameObject.Damage(self, amt)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amt) then error("Parameter amt must be number."); end
    Damage(self:GetHandle(), amt);
end

--- Get health ratio of GameObject.
-- @usage if friend1:GetHealth() < 0.5 then friend1:Retreat("retreat_path"); end
-- @tparam GameObject self GameObject instance
-- @return number health ratio
function GameObject.GetHealth(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetHealth(self:GetHandle());
end

--- Get current health of GameObject.
-- @tparam GameObject self GameObject instance
-- @return number current health or nil
function GameObject.GetCurHealth(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetCurHealth(self:GetHandle());
end

--- Get max health of GameObject.
-- @tparam GameObject self GameObject instance
-- @return number max health or nil
function GameObject.GetMaxHealth(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetMaxHealth(self:GetHandle());
end

--- Sets the current health of the GameObject to the NewHealth value.
-- @tparam GameObject self GameObject instance
-- @param amt health amount
function GameObject.SetCurHealth(self, amt)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amt) then error("Parameter amt must be number."); end
    SetCurHealth(self:GetHandle(), amt);
end

--- Sets the max health of the GameObject to the NewHealth value.
-- @tparam GameObject self GameObject instance
-- @param amt health amount
function GameObject.SetMaxHealth(self, amt)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amt) then error("Parameter amt must be number."); end
    SetMaxHealth(self:GetHandle(), amt);
end

--- Adds the health to the GameObject.
-- @tparam GameObject self GameObject instance
-- @param amt health amount
function GameObject.AddHealth(self, amt)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amt) then error("Parameter amt must be number."); end
    AddHealth(self:GetHandle(), amt);
end

--- GiveMaxHealth
-- @tparam GameObject self GameObject instance
function GameObject.GiveMaxHealth(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    GiveMaxHealth(self:GetHandle());
end

--- Get ammo ratio of GameObject.
-- @tparam GameObject self GameObject instance
-- @return number ammo ratio
function GameObject.GetAmmo(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetAmmo(self:GetHandle());
end

--- Get current ammo of GameObject.
-- @tparam GameObject self GameObject instance
-- @return number current ammo or nil
function GameObject.GetCurAmmo(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetCurAmmo(self:GetHandle());
end

--- Get max ammo of GameObject.
-- @tparam GameObject self GameObject instance
-- @return number max ammo or nil
function GameObject.GetMaxAmmo(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetMaxAmmo(self:GetHandle());
end

--- Sets the current ammo of the GameObject to the NewAmmo value.
-- @tparam GameObject self GameObject instance
-- @param amt ammo amount
function GameObject.SetCurAmmo(self, amt)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amt) then error("Parameter amt must be number."); end
    SetCurAmmo(self:GetHandle(), amt);
end

--- Sets the max ammo of the GameObject to the NewAmmo value.
-- @tparam GameObject self GameObject instance
-- @param amt ammo amount
function GameObject.SetMaxAmmo(self, amt)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amt) then error("Parameter amt must be number."); end
    SetMaxAmmo(self:GetHandle(), amt);
end

--- Adds the ammo to the GameObject.
-- @tparam GameObject self GameObject instance
-- @param amt ammo amount
function GameObject.AddAmmo(self, amt)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amt) then error("Parameter amt must be number."); end
    AddAmmo(self:GetHandle(), amt);
end

--- GiveMaxAmmo
-- @tparam GameObject self GameObject instance
function GameObject.GiveMaxAmmo(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    GiveMaxAmmo(self:GetHandle());
end


----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Team
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

--- Get team number of the GameObject.
-- @tparam GameObject self GameObject instance
-- @treturn int Team number
function GameObject.GetTeamNum(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetTeamNum(self:GetHandle());
end

--- Set team number of the GameObject.
-- @tparam GameObject self GameObject instance
-- @tparam int team new team number
function GameObject.SetTeamNum(self, team)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(team) then error("Parameter amt must be number."); end
    SetTeamNum(self:GetHandle(), team);
end

--- Get perceived team number of the GameObject.
-- @tparam GameObject self GameObject instance
-- @treturn int Team number
function GameObject.GetPerceivedTeam(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetPerceivedTeam(self:GetHandle());
end

--- Set perceived team number of the GameObject.
-- @tparam GameObject self GameObject instance
-- @tparam int team new team number
function GameObject.SetPerceivedTeam(self, team)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(team) then error("Parameter amt must be number."); end
    SetPerceivedTeam(self:GetHandle(), team);
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Objective Marker
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section
-- These functions control objective markers.
-- Objectives are visible to all teams from any distance and from any direction, with an arrow pointing to off-screen objectives. There is currently no way to make team-specific objectives.

--- Sets the game object as an objective to all teams.
-- @tparam GameObject self GameObject instance
function GameObject.SetObjectiveOn(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    SetObjectiveOn(self:GetHandle());

    if not utility.isfunction(IsObjectiveOn) then
        self.cache_memo = unsaved(self.cache_memo)
        self.cache_memo.IsObjectiveOn = true;
    end
end

--- Sets the game object back to normal.
-- @tparam GameObject self GameObject instance
function GameObject.SetObjectiveOff(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    SetObjectiveOff(self:GetHandle());

    if not utility.isfunction(IsObjectIsObjectiveOnive) then
        self.cache_memo = unsaved(self.cache_memo)
        self.cache_memo.IsObjectiveOn = nil; -- if a function to check this is implemented, use it instead
    end
end

--- If the game object an objective?
-- @tparam GameObject self GameObject instance
-- @treturn bool true if the game object is an objective
function GameObject.IsObjectiveOn(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end

    if utility.isfunction(IsObjectiveOn) then
        return IsObjectiveOn(self:GetHandle());
    else
        if not self.cache_memo then return false; end
        return self.cache_memo.IsObjectiveOn ~= nil; -- if a function to check this is implemented, use it instead
    end
end

--- Sets the game object's visible name.
-- @tparam GameObject self GameObject instance
-- @treturn string Name of the objective/object
function GameObject.GetObjectiveName(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetObjectiveName(self:GetHandle());
end

--- Sets the game object's visible name.
-- @tparam GameObject self GameObject instance
-- @tparam string name Name of the objective
function GameObject.SetObjectiveName(self, name)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(name) then error("Parameter name must be a string."); end
    SetObjectiveName(self:GetHandle(), name);
end

--- Sets the game object's visible name.
-- (Technicly a unique function, but effectively an alias for SetObjectiveName)
-- @tparam GameObject self GameObject instance
-- @tparam string name Name of the objective
-- @see GameObject.SetObjectiveName
function GameObject.SetName(self, name)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(name) then error("Parameter name must be a string."); end
    SetName(self:GetHandle(), name);
end


----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Other
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @section

--- Is the GameObject this odf?
-- @tparam GameObject self GameObject instance
-- @tparam string odf ODF filename
-- @usage enemy1:IsOdf("svturr")
function GameObject.IsOdf(self, odf)
  if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
  if not utility.isstring(odf) then error("Parameter odf must be a string."); end
  IsOdf(self:GetHandle(), odf);
end

--- Get odf of GameObject
-- @tparam GameObject self GameObject instance
function GameObject.GetOdf(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetOdf(self:GetHandle());
end

--- Get base of GameObject
-- @tparam GameObject self GameObject instance
-- @treturn string character identifier for race
function GameObject.GetBase(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetBase(self:GetHandle());
end

--- Get label of GameObject
-- @tparam GameObject self GameObject instance
-- @treturn string Label name string
function GameObject.GetLabel(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetLabel(self:GetHandle());
end

--- Is the GameObject this odf?
-- @tparam GameObject self GameObject instance
-- @tparam string label Label
-- @usage enemy1:SetLabel("special_object_7")
function GameObject.SetLabel(self, label)
  if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
  if not utility.isstring(label) then error("Parameter label must be a string."); end
  SetLabel(self:GetHandle(),label);
end

--- Get nation of GameObject
-- @tparam GameObject self GameObject instance
-- @treturn string character identifier for race
function GameObject.GetNation(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetNation(self:GetHandle());
end

--- Get ClassSig of GameObject
-- @tparam GameObject self GameObject instance
function GameObject.GetClassSig(self)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return GetClassSig(self:GetHandle());
end

--- Swap all GameObject references to another GameObject.
-- This is possible because all functions that return GameObjects ensure they use a common reference.
-- This updates the object inside that reference effectively swapping all references between the two object.
-- It really is a scary operation.
--
-- Triggers "GameObject:SwapObjectReferences" event.
--
-- @tparam GameObject self GameObject instance
-- @tparam GameObject object GameObject to replace with
function GameObject.SwapObjectReferences(self, object)
    if not _gameobject.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not _gameobject.isgameobject(object) then error("Parameter object must be GameObject instance."); end

    local ownHandle = self:GetHandle();
    local newHandle = object:GetHandle();
    
    if ownHandle == newHandle then return end -- no need to replace with self

    -- because these 2 tables are shared references all over the code, we are going to do absolute black magic
    -- we are going to swap the full contents of the inside of both with each other

    -- move old object metadata to new handle
    GameObjectWeakList[newHandle] = self; 
    GameObjectWeakList[ownHandle] = object;

    local ownIsDead = GameObjectDead[ownHandle] and true or false;
    local newIsDead = GameObjectDead[newHandle] and true or false;

    local ownIsAltered = GameObjectAltered[ownHandle] and true or false;
    local newIsAltered = GameObjectAltered[newHandle] and true or false;

    -- this feels wrong, but I'm pretty sure it's correct
    GameObjectDead[newHandle] = ownIsDead and self or nil;
    GameObjectDead[ownHandle] = newIsDead and object or nil;

    -- if we have custom data, stuff us in the new tracking table, else nil
    GameObjectAltered[newHandle] = ownIsAltered and self or nil;
    GameObjectAltered[ownHandle] = newIsAltered and object or nil;

    self.id = newHandle; -- update self to new handle
    object.id = ownHandle; -- update self to new handle

    local ownAddon = rawget(self, "addonData");
    local newAddon = rawget(object, "addonData");
    rawset(object, "addonData", ownAddon);
    rawset(self, "addonData", newAddon);

    -- Warn listeners that a swap occured, they might need to fix some addonData.
    hook.CallAllNoReturn("GameObject:SwapObjectReferences", self, object);
end

hook.Add("GameObject:SwapObjectReferences", "GameObject:SwapObjectReferences_GameObject", function(objectA, objectB)
    -- this could have been done where the hook was called, but it's here to act as an example

    -- cleanup data that shouldn't have been swapped since it's tied to game state
    if not utility.isfunction(IsObjectiveOn) then
        objectA.cache_memo = unsaved(objectA.cache_memo);
        objectB.cache_memo = unsaved(objectB.cache_memo);
        local ObjectiveA = objectA.cache_memo.IsObjectiveOn;
        objectA.cache_memo.IsObjectiveOn = objectB.cache_memo.IsObjectiveOn;
        objectB.cache_memo.IsObjectiveOn = ObjectiveA;
    end
end, config.get("hook_priority.GameObject_SwapObjectReferences.GameObject"));

hook.Add("DeleteObject", "GameObject_DeleteObject", function(object)
    local objectId = object:GetHandle();
    debugprint('Decaying object ' .. tostring(objectId));
    GameObjectDead[objectId] = object; -- store dead object for full cleanup next update (handle might be re-used)
end, config.get("hook_priority.DeleteObject.GameObject"));

hook.Add("Update", "GameObject_Update", function(dtime)
    for k,v in pairs(GameObjectDead) do
        debugprint('Decayed object ' .. tostring(k));
        GameObjectAltered[k] = nil; -- remove any strong reference for being altered
        GameObjectDead[k] = nil; -- remove any strong reference for being dead
    end
end, config.get("hook_priority.Update.GameObject"));

customsavetype.Register(GameObject);

debugprint("_gameobject Loaded");

return _gameobject;