--- BZ98R LUA Extended API GameObject.
---
--- GameObject wrapper functions.
---
--- @module '_gameobject'
--- @author John "Nielk1" Klein

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_gameobject Loading");

local utility = require("_utility");
local config = require("_config");
local hook = require("_hook");
local customsavetype = require("_customsavetype");
local network = require("_network");

--- @class _gameobject
local M = {};

--- Is this object an instance of GameObject?
--- @param object any Object in question
--- @return boolean
function M.isgameobject(object)
    --return (type(object) == "table" and object.__type == "GameObject");
    return customsavetype.Implements(object, "GameObject");
end

--- Extract the GameObject from this object that implements GameObject.
--- @param object any Object in question
--- @return GameObject?
function M.extractgameobject(object)
    return customsavetype.Extract(object, "GameObject");
end

local GameObjectWeakList_MT = {};
GameObjectWeakList_MT.__mode = "v";
local GameObjectWeakList = setmetatable({}, GameObjectWeakList_MT);
--- @diagnostic disable-next-line: unused-local -- used to strong-reference hold objects with custom data until they are removed from game world
local GameObjectAltered = {}; -- used to strong-reference hold objects with custom data until they are removed from game world
--local GameObjectDead = {}; -- used to hold dead objects till next update for cleanup

local GameObjectSeqNoMemo = {}; -- maps sequence numbers to handles
local GameObjectSeqNoDeadMemo = setmetatable({}, GameObjectWeakList_MT); -- maps sequence numbers to dead game objects to handle the edge-cases

--- GameObject
--- An object containing all functions and data related to a game object.
--- @class GameObject : CustomSavableType
--- @field id Handle Handle used by BZ98R
--- @field addonData table Extended data saved into the object
--- @field cache_memo table Unsaved data used for housekeeping that is regenerated at load
local GameObject = {}; -- the table representing the class, which will double as the metatable for the instances

--- @param table table
--- @param key any
--- @return any? value
function GameObject.__index(table, key)
    -- local table takes priority
    local retVal = rawget(table, key);
    if retVal ~= nil then
        return retVal;
    end

    -- next check the addonData table
    if rawget(table, "addonData") ~= nil and rawget(rawget(table, "addonData"), key) ~= nil then
        return rawget(rawget(table, "addonData"), key);
    end

    -- next check the metatable
    local mt = getmetatable(table)
    local retVal = mt and rawget(mt, key)
    if retVal ~= nil then
        return retVal
    end

    return nil;
end

--- @param table table
--- @param key any
--- @param value any
function GameObject.__newindex(table, key, value)
    if key == "addonData" then
        rawset(table, "addonData", value);
        local objectId = table:GetHandle();--string.sub(tostring(table:GetHandle()),4);
        GameObjectAltered[objectId] = table;
    elseif key ~= "id" and key ~= "addonData" then
        local addonData = rawget(table, "addonData");
        if addonData == nil then
            rawset(table, "addonData", {});
            addonData = rawget(table, "addonData");
        end
        rawset(addonData, key, value);
        local objectId = table:GetHandle();--string.sub(tostring(table:GetHandle()),4);
        GameObjectAltered[objectId] = table;
        --- @todo consider removing object from GameObjectAltered if addonData is empty
    else
        rawset(table, key, value);
    end
end

GameObject.__type = "GameObject";
GameObject.__noref = true;
GameObject.__tostring = function(self)
    return "GameObject: " .. tostring(self:GetHandle());
end

--- @section Core

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
    GameObjectSeqNoMemo[self:GetSeqNo()] = objectId;
    return self;
end

--- Create a new GameObject instance.
--- This works via a lookup table so it can fail easily.
--- @param seqNo integer Sequence number of the object
--- @return GameObject?
function M.FromSeqNo(seqNo)
    local objectId = GameObjectSeqNoMemo[seqNo];
    if objectId ~= nil then
        return M.FromHandle(objectId);
    end
    local deadObject = GameObjectSeqNoDeadMemo[seqNo];
    if deadObject ~= nil then
        return deadObject; -- return the dead object reference if it's still around
    end
    return nil;
end

--- Get Handle used by BZ98R.
--- @param self GameObject GameObject instance
--- @return Handle
function GameObject:GetHandle()
    return self.id;
end

--- Get the SeqNo of the GameObject.
--- Note that the SeqNo is rather useless.
--- @param self GameObject GameObject instance
--- @return integer SeqNo
function GameObject:GetSeqNo()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    return tonumber(tostring(self:GetHandle()):sub(-5), 16);
end

--- Save event function.
--- {INTERNAL USE}
--- @param self GameObject GameObject instance
--- @return any ...
function GameObject:Save()
    return self.id;
end

--- Load event function.
--- {INTERNAL USE}
--- @param id any Handle
--- @return GameObject?
function GameObject.Load(id)
    return M.FromHandle(id);
end

--- TypeSave event function.
--- {INTERNAL USE}
--- @return any ...
function GameObject:TypeSave()
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

--- TypeLoad event function.
--- {INTERNAL USE}
--- @param data any Object data
function GameObject.TypeLoad(data)
-- Xparam dataDead Dead object data
--function GameObject:TypeLoad(data,dataDead)
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
            logger.print(logger.LogLevel.DEBUG, nil, "TypeLoad GameObject ObjectiveObjects: "..tostring(h));
            lastObject = h;
        end
    end

    for k,v in pairs(data) do
        local newGameObject = M.FromHandle(k);
        newGameObject.addonData = v;

        -- IsObjectiveOn Memo
        local objectiveData = _ObjectiveObjects[k];
        if objectiveData ~= nil then
            newGameObject.cache_memo = customsavetype.NoSave({ IsObjectiveOn = true });
            _ObjectiveObjects[k] = nil; -- does this speed things up or slow them down?
        end
    end
    --for k,v in pairs(dataDead) do
    --    local newGameObject = _gameobject.FromHandle(v); -- this will be either a new GameObject or an existing one from the above addon data filling loop
    --    GameObjectDead[v] = newGameObject;
    --end

    --- @todo skip this if we have access to SeqNo functions
    --- @diagnostic disable-next-line: empty-block
    for _ in M.AllObjects() do end -- make every GameObject construct for side-effects (SeqNo memo)
end

--- @section Object Creation / Destruction

--- Creates a GameObject with the given odf name, team number, and location.
---
--- {(i)Multiplayer(i) Objects built by the host are always synchronized, objects built by clients will
--- always be desynchronized initially, but can be synchronized by calling SetLocal().}
--- @param odf string Object Definition File (without ".odf")
--- @param team TeamNum Team number for the object, 0 to 15
--- @param pos Vector|Matrix|GameObject|Handle|string Vector, Matrix, GameObject, or pathpoint by name
--- @param point integer? index
--- @return GameObject? object Newly built GameObject
function M.BuildObject(odf, team, pos, point)
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
---
--- {(!!)(!!) Unsafe to use on a handle passed in by CreateObject(h), doing so will crash the game. If you need this functionality,
--- you should defer the deletion until the next Update.}
---
--- {(!)Multiplayer(!) Very dangerous. There are innumerable cases which can cause objects to be improperly deleted and/or
--- spawn explosion chunks which may only be visible to certain players. In order to safely delete a distributed object,
--- ALL players must call RemoveObject(h) on the target object simultaneously. Additionally, attempting to delete the starting
--- recycler in a strategy or MPI game will crash the game.}
--- @param self GameObject GameObject instance
function GameObject:RemoveObject()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end

    --- @diagnostic disable-next-line: deprecated
    RemoveObject(self:GetHandle());
end

if network.IsNetGame() then
    -- [[START_IGNORE]]
    GameObject.RemoveObject = function(self)
        if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
        network.Send(0, "_", "GameObject", "RemoveObject", self:GetSeqNo())
    end

    local packet_id = config.get("network_packet_id.api");
    hook.Add("Receive", "GameObject_Receive", function(sender, channel, mod, fun, seqNo)
        if channel ~= packet_id then return end
        if seqNo and mod == "GameObject" and fun == "RemoveObject" then
            local gameObject = M.FromSeqNo(seqNo);
            if gameObject ~= nil then
                --- @diagnostic disable-next-line: deprecated
                RemoveObject(gameObject:GetHandle());
            else
                -- register a coroutine that tries to remove the object for 1 second before giving up
                local endTime = GetTime() + 1;
                local co = coroutine.create(function()
                    while GetTime() < endTime do
                        local obj = M.FromSeqNo(seqNo);
                        if obj ~= nil then
                            --- @diagnostic disable-next-line: deprecated
                            RemoveObject(obj:GetHandle());
                            return;
                        end
                        coroutine.yield();
                    end
                end);
                network.Defer(co);
            end
        end
    end, config.get("hook_priority.Receive.GameObject"))
    -- [[END_IGNORE]]
end

--- Get GameObject by Label.
--- @param key string Label
--- @return GameObject? object GameObject with Label or nil if none found
function M.GetGameObject(key)
    --- @diagnostic disable-next-line: deprecated
    local handle = GetHandle(key);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- @section Info Display

--- Returns true if the game object inspected by the info display matches the current game object.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject:IsInfo()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsInfo(self:GetHandle());
end

--- @section Condition Checks

--- Is the GameObject this odf?
--- @param self GameObject GameObject instance
--- @param odf string ODF filename
--- ```lua
--- enemy1:IsOdf("svturr")
--- ```
function GameObject:IsOdf(odf)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(odf) then error("Parameter odf must be a string."); end
    --- @diagnostic disable-next-line: deprecated
    IsOdf(self:GetHandle(), odf);
end

--- Get odf of GameObject
--- @param self GameObject GameObject instance
function GameObject:GetOdf()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetOdf(self:GetHandle());
end

--- Get base of GameObject
--- @param self GameObject GameObject instance
--- @return string? character identifier for race
function GameObject:GetBase()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetBase(self:GetHandle());
end

--- Get label of GameObject
--- @param self GameObject GameObject instance
--- @return string? Label name string
function GameObject:GetLabel()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetLabel(self:GetHandle());
end

--- Is the GameObject this odf?
--- @param self GameObject GameObject instance
--- @param label string Label
--- ```lua
--- enemy1:SetLabel("special_object_7")
--- ```
function GameObject:SetLabel(label)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(label) then error("Parameter label must be a string."); end
    --- @diagnostic disable-next-line: deprecated
    SetLabel(self:GetHandle(),label);
end

--- Returns the four-character class signature of the game object (e.g. "WING"). Returns nil if none exists.
--- @param self GameObject GameObject instance
--- @return string? ClassSig string
function GameObject:GetClassSig()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetClassSig(self:GetHandle());
end

--- Returns the class label of the game object (e.g. "wingman"). Returns nil if none exists.
--- @param self GameObject GameObject instance
--- @return string? Class label string
function GameObject:GetClassLabel()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetClassLabel(self:GetHandle());
end

--- Returns the numeric class identifier of the game object. Returns nil if none exists.
--- Looking up the class id number in the ClassId table will convert it to a string. Looking up the class id string in the ClassId table will convert it back to a number.
--- @param self GameObject GameObject instance
--- @return integer? ClassId number
function GameObject:GetClassId()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetClassId(self:GetHandle());
end

--- Returns the one-letter nation code of the game object (e.g. "a" for American, "b" for Black Dog, "c" for Chinese, and "s" for Soviet).
--- The nation code is usually but not always the same as the first letter of the odf name. The ODF file can override the nation in the [GameObjectClass] section, and player.odf is a hard-coded exception that uses "a" instead of "p".
--- @param self GameObject GameObject instance
--- @return string character identifier for race
function GameObject:GetNation()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetNation(self:GetHandle());
end

--- Does the GameObject exist in the world?
--- Returns true if the game object exists. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject:IsValid()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsValid(self:GetHandle());
end

--- Is the GameObject alive and is still pilot controlled?
--- Returns true if the game object exists and (if the object is a vehicle) controlled. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject:IsAlive()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsAlive(self:GetHandle());
end

--- Is the GameObject alive and piloted?
--- Returns true if the game object exists and (if the object is a vehicle) controlled and piloted. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject:IsAliveAndPilot()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsAliveAndPilot(self:GetHandle());
end

--- Returns true if it's a Craft.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject:IsCraft()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsCraft(self:GetHandle());
end

--- Returns true if it's a Building.
--- Does not include guntowers.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject:IsBuilding()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsBuilding(self:GetHandle());
end

--- Returns true if it's a person.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject:IsPerson()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsPerson(self:GetHandle());
end

--- Returns true if the game object exists and has less health than the threshold. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @param threshold number? float
--- @return boolean
function GameObject:IsDamaged(threshold)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsDamaged(self:GetHandle(), threshold);
end

--- Returns true if the game object was recycled by a Construction Rig on the given team.
--- {VERSION 2.1+}
--- @param self GameObject GameObject instance
--- @param team TeamNum
--- @return boolean
function GameObject:IsRecycledByTeam(team)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsRecycledByTeam(self:GetHandle(), team);
end

--- @section Team Number
--- These functions get and set team number. Team 0 is the neutral or environment team.

--- Returns the game object's team number.
--- @param self GameObject GameObject instance
--- @return integer Team number
function GameObject:GetTeamNum()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetTeamNum(self:GetHandle());
end

--- Sets the game object's team number.
--- @param self GameObject GameObject instance
--- @param team TeamNum new team number
function GameObject:SetTeamNum(team)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(team) then error("Parameter amt must be number."); end
    --- @diagnostic disable-next-line: deprecated
    SetTeamNum(self:GetHandle(), team);
end

--- Get perceived team number of the GameObject.
--- @param self GameObject GameObject instance
--- @return integer Team number
function GameObject:GetPerceivedTeam()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetPerceivedTeam(self:GetHandle());
end

--- Set perceived team number of the GameObject.
--- @param self GameObject GameObject instance
--- @param team TeamNum new team number
function GameObject:SetPerceivedTeam(team)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(team) then error("Parameter amt must be number."); end
    --- @diagnostic disable-next-line: deprecated
    SetPerceivedTeam(self:GetHandle(), team);
end

--- @section Target
--- These function get and set a unit's target.

--- Set this as the local player's target.
--- @param self GameObject
function GameObject:SetAsUserTarget()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    SetUserTarget(self:GetHandle());
end

--- Returns the local player's target. Returns nil if it has none.
--- @return GameObject?
function M.GetUserTarget()
    --- @diagnostic disable-next-line: deprecated
    local handle = GetUserTarget();
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Set the game object's target.
--- @param self GameObject
--- @param target GameObject|Handle|nil
function GameObject:SetTarget(target)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if target ~= nil and not M.isgameobject(target) and not utility.isHandle(target) then error("Parameter target must be GameObject instance, Handle, or nil."); end
    if target == nil then
        --- @diagnostic disable-next-line: deprecated
        SetTarget(self:GetHandle(), nil);
        return;
    end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        SetTarget(self:GetHandle(), target:GetHandle());
    else
        --- @cast target Handle
        --- @diagnostic disable-next-line: deprecated
        SetTarget(self:GetHandle(), target);
    end
end

--- Set this object as another object's target.
--- @param self GameObject
--- @param targeter GameObject|Handle
function GameObject:SetAsTarget(self, targeter)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not M.isgameobject(targeter) and not utility.isHandle(targeter) then error("Parameter targeter must be GameObject instance or Handle."); end
    if M.isgameobject(targeter) then
        --- @cast targeter GameObject
        --- @diagnostic disable-next-line: deprecated
        SetTarget(targeter:GetHandle(), self:GetHandle());
    else
        --- @cast targeter Handle
        --- @diagnostic disable-next-line: deprecated
        SetTarget(targeter, self:GetHandle());
    end
end

--- Returns the game object's target. Returns nil if it has none.
--- @param self GameObject
--- @return GameObject?
function GameObject:GetTarget()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetTarget(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- @section Owner
--- These functions get and set owner. The default owner for a game object is the game object that created it.

--- Sets the game object's owner.
--- @todo confirm owner can be nil
--- @param self GameObject
--- @param owner GameObject?
function GameObject:SetOwner(owner)
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
function GameObject:GetOwner()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetOwner(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- @section Pilot Class
--- These functions get and set vehicle pilot class.

--- Sets the vehicle's pilot class to the given odf name. This does nothing useful for non-vehicle game objects. An odf name of nil resets the vehicle to the default assignment based on nation.
--- @param self GameObject
--- @param odf string?
function GameObject:SetPilotClass(odf)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(odf) and odf ~= nil then error("Parameter odf must be a string or nil."); end
    --- @diagnostic disable-next-line: deprecated
    SetPilotClass(self:GetHandle(), odf);
end

--- Returns the odf name of the vehicle's pilot class. Returns nil if none exists.
--- @param self GameObject
--- @return string?
function GameObject:GetPilotClass()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetPilotClass(self:GetHandle());
end

--- @section Position & Velocity

--- Get object's position vector.
--- @param self GameObject GameObject instance
--- @return Vector?
function GameObject:GetPosition()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetPosition(self:GetHandle());
end

--- Get front vector.
--- @param self GameObject GameObject instance
--- @return Vector?
function GameObject:GetFront()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetFront(self:GetHandle());
end

--- Set the position of the GameObject.
--- @param self GameObject GameObject instance
--- @param position Vector|Matrix|string Vector position, Matrix position, or path name
--- @param point integer? Index of the path point in the path (optional)
function GameObject:SetPosition(position, point)
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
function GameObject:GetTransform()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetTransform(self:GetHandle());
end

--- Set the tranform matrix of the GameObject.
--- @param self GameObject GameObject instance
--- @param transform Matrix transform matrix
function GameObject:SetTransform(transform)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isMatrix(transform) then error("Parameter transform must be a Matrix") end
    --- @diagnostic disable-next-line: deprecated
    SetTransform(self:GetHandle(), transform);
end

--- Get object's velocity vector.
--- @param self GameObject GameObject instance
--- @return Vector Vector (0,0,0) if the handle is invalid or isn't movable.
function GameObject:GetVelocity()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetVelocity(self:GetHandle());
end

--- Set the velocity of the GameObject.
--- @param self GameObject GameObject instance
--- @param velocity Vector Vector velocity
function GameObject:SetVelocity(velocity)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isVector(velocity) then error("Parameter velocity must be a Vector") end
    --- @diagnostic disable-next-line: deprecated
    SetVelocity(self:GetHandle(), velocity);
end

--- Get object's omega.
--- @param self GameObject GameObject instance
--- @return Vector Vector (0,0,0) if the handle is invalid or isn't movable.
function GameObject:GetOmega()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetOmega(self:GetHandle());
end

--- Set the omega of the GameObject.
--- @param self GameObject GameObject instance
--- @param omega any
function GameObject:SetOmega(omega)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isVector(omega) then error("Parameter omega must be a Vector") end
    --- @diagnostic disable-next-line: deprecated
    SetOmega(self:GetHandle(), omega);
end

--- @section Shot
--- These functions query a game object for information about ordnance hits.

--- Returns who scored the most recent hit on the game object. Returns nil if none exists.
--- @param self GameObject
--- @return GameObject?
function GameObject:GetWhoShotMe()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetWhoShotMe(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Returns the last time an enemy shot the game object.
--- @param self GameObject
--- @return number float
function GameObject:GetLastEnemyShot()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetLastEnemyShot(self:GetHandle());
end

--- Returns the last time a friend shot the game object.
--- @param self GameObject
--- @return number float
function GameObject:GetLastFriendShot()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetLastFriendShot(self:GetHandle());
end

--- @section Alliances
--- These functions control and query alliances between teams.
--- The team manager assigns each player a separate team number, starting with 1 and going as high as 15. Team 0 is the neutral "environment" team.
--- Unless specifically overridden, every team is friendly with itself, neutral with team 0, and hostile to everyone else.

--- Order GameObject to Attack target GameObject.
--- @param self GameObject GameObject instance
--- @param target GameObject|Handle Target GameObject
--- @return boolean Ally Do we consider this an ally?
function GameObject:IsAlly(target)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if M.isgameobject(target) then
        --- @cast target GameObject
        --- @diagnostic disable-next-line: deprecated
        return IsAlly(self:GetHandle(), target:GetHandle());
    elseif target ~= nil then
        --- @cast target Handle
        --- @diagnostic disable-next-line: deprecated
        return IsAlly(self:GetHandle(), target);
    else
        error("Parameter target must be GameObject or Handle.");
    end
end

--- @section Objective Marker
--- These functions control objective markers.
--- Objectives are visible to all teams from any distance and from any direction, with an arrow pointing to off-screen objectives. There is currently no way to make team-specific objectives.

--- Sets the game object as an objective to all teams.
--- @param self GameObject GameObject instance
function GameObject:SetObjectiveOn()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    SetObjectiveOn(self:GetHandle());

    --- @diagnostic disable-next-line: deprecated
    if not utility.isfunction(IsObjectiveOn) then
        self.cache_memo = customsavetype.NoSave(self.cache_memo)
        self.cache_memo.IsObjectiveOn = true;
    end
end

--- Sets the game object back to normal.
--- @param self GameObject GameObject instance
function GameObject:SetObjectiveOff()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    SetObjectiveOff(self:GetHandle());

    --- @diagnostic disable-next-line: deprecated
    if not utility.isfunction(IsObjectiveOn) then
        self.cache_memo = customsavetype.NoSave(self.cache_memo)
        self.cache_memo.IsObjectiveOn = nil; -- if a function to check this is implemented, use it instead
    end
end

--- If the game object an objective?
--- @param self GameObject GameObject instance
--- @return boolean true if the game object is an objective
function GameObject:IsObjectiveOn()
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
function GameObject:GetObjectiveName()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetObjectiveName(self:GetHandle());
end

--- Sets the game object's visible name.
--- @param self GameObject GameObject instance
--- @param name string Name of the objective
function GameObject:SetObjectiveName(name)
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
function GameObject:SetName(name)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(name) then error("Parameter name must be a string."); end
    --- @diagnostic disable-next-line: deprecated
    SetName(self:GetHandle(), name);
end

--- @section Distance
--- These functions measure and return the distance between a game object and a reference point.

--- Returns the distance in meters between the game object and a position vector, transform matrix, another object, or point on a named path.
--- @param self GameObject
--- @param target Vector|Matrix|GameObject|Handle|string Position vector, ransform matrix, Object, or path name.
--- @param point integer? If the target is a path this is the path point index, defaults to 0.
--- @return number
function GameObject:GetDistance(target, point)
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
function GameObject:IsWithin(target, dist)
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
--- {VERSION 2.1+}
--- @param self GameObject
--- @param target GameObject|Handle
--- @param tolerance number?
--- @return boolean
function GameObject:IsTouching(target, tolerance)
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

--- @section Nearest
--- These functions find and return the game object of the requested type closest to a reference point.

--- Returns the game object closest to a position vector, transform matrix, another object, or point on a named path.
--- @diagnostic disable: undefined-doc-param
--- @overload fun(object: GameObject|Handle): object: GameObject?
--- @overload fun(position: Vector): object: GameObject?
--- @overload fun(transform: Matrix): object: GameObject?
--- @overload fun(name: string, point?: integer): object: GameObject?
--- @param object GameObject|Handle The reference game object.
--- @param position Vector The position vector.
--- @param transform Matrix The transform matrix.
--- @param name string The path name.
--- @param point integer? The point on the path (optional).
--- @return GameObject? object
--- @diagnostic enable: undefined-doc-param
function M.GetNearestObject(...)
    local args = {...}
    local target = args[1];
    local point = args[2];
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
function GameObject:GetNearestObject()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetNearestObject(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Returns the craft closest to a position vector, transform matrix, another object, or point on a named path.
--- @diagnostic disable: undefined-doc-param
--- @overload fun(object: GameObject|Handle): object: GameObject?
--- @overload fun(position: Vector): object: GameObject?
--- @overload fun(transform: Matrix): object: GameObject?
--- @overload fun(name: string, point?: integer): object: GameObject?
--- @param object GameObject|Handle The reference game object.
--- @param position Vector The position vector.
--- @param transform Matrix The transform matrix.
--- @param name string The path name.
--- @param point integer? The point on the path (optional).
--- @return GameObject? object
--- @diagnostic enable: undefined-doc-param
function M.GetNearestVehicle(...)
    local args = {...}
    local target = args[1];
    local point = args[2];
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
function GameObject:GetNearestVehicle()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetNearestVehicle(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Returns the building closest to a position vector, transform matrix, another object, or point on a named path.
--- @diagnostic disable: undefined-doc-param
--- @overload fun(object: GameObject|Handle): object: GameObject?
--- @overload fun(position: Vector): object: GameObject?
--- @overload fun(transform: Matrix): object: GameObject?
--- @overload fun(name: string, point?: integer): object: GameObject?
--- @param object GameObject|Handle The reference game object.
--- @param position Vector The position vector.
--- @param transform Matrix The transform matrix.
--- @param name string The path name.
--- @param point integer? The point on the path (optional).
--- @return GameObject? object
--- @diagnostic enable: undefined-doc-param
function M.GetNearestBuilding(...)
    local args = {...}
    local target = args[1];
    local point = args[2];
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
function GameObject:GetNearestBuilding()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetNearestBuilding(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Returns the enemy closest to a position vector, transform matrix, another object, or point on a named path.
--- @diagnostic disable: undefined-doc-param
--- @overload fun(object: GameObject|Handle): object: GameObject?
--- @overload fun(position: Vector): object: GameObject?
--- @overload fun(transform: Matrix): object: GameObject?
--- @overload fun(name: string, point?: integer): object: GameObject?
--- @param object GameObject|Handle The reference game object.
--- @param position Vector The position vector.
--- @param transform Matrix The transform matrix.
--- @param name string The path name.
--- @param point integer? The point on the path (optional).
--- @return GameObject? object
--- @diagnostic enable: undefined-doc-param
function M.GetNearestEnemy(...)
    local args = {...}
    local target = args[1];
    local point = args[2];
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
function GameObject:GetNearestEnemy()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetNearestEnemy(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Returns the friend closest to a position vector, transform matrix, another object, or point on a named path.
--- {VERSION 2.0+}
--- @diagnostic disable: undefined-doc-param
--- @overload fun(object: GameObject|Handle): object: GameObject?
--- @overload fun(position: Vector): object: GameObject?
--- @overload fun(transform: Matrix): object: GameObject?
--- @overload fun(name: string, point?: integer): object: GameObject?
--- @param object GameObject|Handle The reference game object.
--- @param position Vector The position vector.
--- @param transform Matrix The transform matrix.
--- @param name string The path name.
--- @param point integer? The point on the path (optional).
--- @return GameObject? object
--- @diagnostic enable: undefined-doc-param
function M.GetNearestFriend(...)
    local args = {...}
    local target = args[1];
    local point = args[2];
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
function GameObject:GetNearestFriend()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetNearestFriend(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Returns the friend closest to the given reference point. Returns nil if none exists.
--- @diagnostic disable: undefined-doc-param
--- @overload fun(object: GameObject|Handle): object: GameObject? --- {VERSION 2.0+}
--- @overload fun(position: Vector): object: GameObject? --- {VERSION 2.1+}
--- @overload fun(transform: Matrix): object: GameObject? --- {VERSION 2.1+}
--- @overload fun(name: string, point?: integer): object: GameObject? --- {VERSION 2.1+}
--- @param object GameObject|Handle The reference game object.
--- @param position Vector The position vector.
--- @param transform Matrix The transform matrix.
--- @param name string The path name.
--- @param point integer? The point on the path (optional).
--- @return GameObject? object closest friend, or nil if none exists.
--- @diagnostic enable: undefined-doc-param
function M.GetNearestUnitOnTeam(...)
    local args = {...}
    if #args == 1 then
        if M.isgameobject(args[1]) then
            local object = args[1]
            --- @cast object GameObject
            --- @diagnostic disable-next-line: deprecated
            local handle = GetNearestUnitOnTeam(object:GetHandle());
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
function GameObject:GetNearestUnitOnTeam()
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
function GameObject:CountUnitsNearObject(dist, team, odfname)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(dist) then error("Parameter dist must be number."); end
    if not utility.isnumber(team) then error("Parameter team must be number."); end
    if not utility.isstring(odfname) then error("Parameter odfname must be string."); end
    --- @diagnostic disable-next-line: deprecated
    return CountUnitsNearObject(self:GetHandle(), dist, team, odfname);
end

--- @section Iterators
--- These functions return iterator functions for use with Lua's "for <variable> in <expression> do ... end" form. For example: "for h in AllCraft() do print(h, GetLabel(h)) end" will print the game object handle and label of every craft in the world.

--- Enumerates game objects within the given distance a target.
--- @param dist number
--- @param target Vector|Matrix|GameObject|Handle|string Position vector, ransform matrix, Object, or path name.
--- @param point integer? If the target is a path this is the path point index, defaults to 0.
--- @return fun(): GameObject iterator Iterator of GameObject values
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
--- @return fun(): GameObject iterator Iterator of GameObject values
function M.AllObjects()
    return coroutine.wrap(function()
        --- @diagnostic disable-next-line: deprecated
        for handle in AllObjects() do
            coroutine.yield(M.FromHandle(handle))
        end
    end)
end

--- Enumerates all craft.
--- @return fun(): GameObject iterator Iterator of GameObject values
function M.AllCraft()
    return coroutine.wrap(function()
        --- @diagnostic disable-next-line: deprecated
        for handle in AllCraft() do
            coroutine.yield(M.FromHandle(handle))
        end
    end)
end

--- Enumerates all game objects currently selected by the local player.
--- @return fun(): GameObject iterator Iterator of GameObject values
function M.SelectedObjects()
    return coroutine.wrap(function()
        --- @diagnostic disable-next-line: deprecated
        for handle in SelectedObjects() do
            coroutine.yield(M.FromHandle(handle))
        end
    end)
end

--- Enumerates all game objects marked as objectives.
--- @return fun(): GameObject iterator Iterator of GameObject values
function M.ObjectiveObjects()
    return coroutine.wrap(function()
        --- @diagnostic disable-next-line: deprecated
        for handle in ObjectiveObjects() do
            coroutine.yield(M.FromHandle(handle))
        end
    end)
end

--- @section Team Slots
--- These functions look up game objects in team slots.

--- Get the game object in the specified team slot.
--- @see ScriptUtils.TeamSlot
--- @param slot TeamSlotInteger Slot number, see TeamSlot
--- @param team TeamNum? Team number, 0 to 15
--- @return GameObject? object GameObject in the slot or nil if none found
function M.GetTeamSlot(slot, team)
    if not utility.isnumber(slot) then error("Parameter slot must be a number") end
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number") end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetTeamSlot(slot, team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- @diagnostic disable-next-line: undefined-global
if utility.isfunction(SetTeamSlot) then
    --- Set the game object in the specified team slot.
    --- This could have major sideffects so be careful with it.
    --- 
    --- {VERSION 2.2.315+}
    --- 
    --- Sets the game object in the specified team slot.
    --- @param self GameObject GameObject instance
    --- @param slot TeamSlotInteger Slot number, see TeamSlot
    --- @return GameObject? old_object The new game object formerly in the slot, or nil if the slot was empty
    --- @see ScriptUtils.TeamSlot
    function GameObject:SetTeamSlot(slot)
        if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
        if not utility.isnumber(slot) then error("Parameter slot must be a number") end
        
        --- @diagnostic disable-next-line: undefined-global
        local handle = SetTeamSlot(self:GetHandle(), slot);

        if handle == nil then return nil end;
        return M.FromHandle(handle);
    end
end

--- Get Player GameObject of team.
--- @param team TeamNum? Team number of player
--- @return GameObject? player GameObject of player or nil
--- @todo depricate functions like this and move them to a team manager, because of the issue noted on scriptutils for GetTeamSlot.
function M.GetPlayer(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    --- @diagnostic disable-next-line: deprecated
    local handle = GetPlayerHandle(team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Get Recycler GameObject of team.
--- @param team TeamNum? Team number of player
--- @return GameObject? recycler GameObject of recycler or nil
function M.GetRecycler(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    --- @diagnostic disable-next-line: deprecated
    local handle = GetRecyclerHandle(team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Get Factory GameObject of team.
--- @param team TeamNum? Team number of player
--- @return GameObject? factory GameObject of factory or nil
function M.GetFactory(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    --- @diagnostic disable-next-line: deprecated
    local handle = GetFactoryHandle(team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Get Armory GameObject of team.
--- @param team TeamNum? Team number of player
--- @return GameObject? armory of armory or nil
function M.GetArmory(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    --- @diagnostic disable-next-line: deprecated
    local handle = GetArmoryHandle(team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Get Factory GameObject of team.
--- @param team TeamNum? Team number of player
--- @return GameObject? constructor of constructor or nil
function M.GetConstructor(team)
    if team ~= nil and not utility.isnumber(team) then error("Parameter team must be a number if supplied") end;
    --- @diagnostic disable-next-line: deprecated
    local handle = GetConstructorHandle(team);
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- @section Deploy
--- These functions control deployable craft (such as Turret Tanks or Producer units).

--- Returns true if the game object is a deployed craft. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @return boolean
--- @function IsDeployed
function GameObject:IsDeployed()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsDeployed(self:GetHandle());
end

--- Tells the game object to deploy.
--- @param self GameObject GameObject instance
--- @function Deploy
function GameObject:Deploy()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    Deploy(self:GetHandle());
end

--- @section Selection
--- These functions access selection state (i.e. whether the player has selected a game object)

--- Returns true if the game object is selected. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject:IsSelected()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsSelected(self:GetHandle());
end

--- @section Mission-Critical
--- {VERSION 2.0+}
--- The "mission critical" property indicates that a game object is vital to the success of the mission and disables the "Pick Me Up" and "Recycle" commands that (eventually) cause IsAlive() to report false.

--- Returns true if the game object is marked as mission-critical. Returns false otherwise.
--- {VERSION 2.0+}
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject:IsCritical()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsCritical(self:GetHandle());
end

--- Sets the game object's mission-critical status.
--- If critical is true or not specified, the object is marked as mission-critical. Otherwise, the object is marked as not mission critical.
--- {VERSION 2.0+}
--- @param self GameObject GameObject instance
--- @param critical boolean? defaults to true
function GameObject:SetCritical(critical)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if critical ~= nil and not utility.isboolean(critical) then error("Parameter critical must be boolean or nil."); end
    --- @diagnostic disable-next-line: deprecated
    SetCritical(self:GetHandle(), critical);
end

--- @section Weapon
--- These functions access unit weapons and damage.

--- Sets what weapons the unit's AI process will use.
--- To calculate the mask value, add up the values of the weapon hardpoint slots you want to enable.
--- weaponHard1: 1 weaponHard2: 2 weaponHard3: 4 weaponHard4: 8 weaponHard5: 16
--- @param self GameObject GameObject instance
--- @param mask integer
function GameObject:SetWeaponMask(mask)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(mask) then error("Parameter mask must be number."); end
    --- @diagnostic disable-next-line: deprecated
    SetWeaponMask(self:GetHandle(), mask);
end

--- Gives the game object the named weapon in the given slot. If no slot is given, it chooses a slot based on hardpoint type and weapon priority like a weapon powerup would. If the weapon name is empty, nil, or blank and a slot is given, it removes the weapon in that slot.
--- Returns true if it succeeded. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @param weaponname string?
--- @param slot integer?
function GameObject:GiveWeapon(weaponname, slot)
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
--- @return string?
function GameObject:GetWeaponClass(slot)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(slot) then error("Parameter slot must be number.") end
    --- @diagnostic disable-next-line: deprecated
    return GetWeaponClass(self:GetHandle(), slot);
end

--- Tells the game object to fire at the given target.
--- @param self GameObject GameObject instance
--- @param target GameObject|Handle
function GameObject:FireAt(target)
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
function GameObject:Damage(amount)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(amount) then error("Parameter amt must be number."); end
    --- @diagnostic disable-next-line: deprecated
    Damage(self:GetHandle(), amount);
end

--- @section Unit Commands
--- These functions send commands to units or query their command state.

--- Returns true if the game object can be commanded. Returns false otherwise.
--- @param self GameObject
--- @return boolean
function GameObject:CanCommand()
    if not M.isgameobject(self) then error("Parameter me must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return CanCommand(self:GetHandle());
end

--- Returns true if the game object is a producer that can build at the moment. Returns false otherwise.
--- The concept here is that the builder either A: Does not need to deploy or B: Does need to deploy but is deployed.
--- @param self GameObject
--- @return boolean
function GameObject:CanBuild()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return CanBuild(self:GetHandle());
end

--- Returns true if the game object is a producer and currently busy. Returns false otherwise.
--- An undeployed builder that needs to deploy will always indicate false.
--- A deployed (if needed) producer with a buildClass set is considered busy. The buildClass may be cleared after the CreateObject call.
--- @param self GameObject
--- @return boolean
function GameObject:IsBusy()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsBusy(self:GetHandle());
end

--- Returns true if the game object has reached the end of the named path. Returns false otherwise.
--- {VERSION 2.1+}
--- @param self GameObject
--- @param path string
--- @return boolean
function GameObject:IsAtEndOfPath(path)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(path) then error("Parameter path must be a string") end
    --- @diagnostic disable-next-line: deprecated
    return IsAtEndOfPath(self:GetHandle(), path);
end

--- Returns the current command for the game object. Looking up the command number in the AiCommand table will convert it to a string. Looking up the command string in the AiCommand table will convert it back to a number.
--- @param self GameObject
--- @return AiCommand
function GameObject:GetCurrentCommand()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetCurrentCommand(self:GetHandle());
end

--- Returns the target of the current command for the game object. Returns nil if it has none.
--- @param self GameObject
--- @return GameObject?
function GameObject:GetCurrentWho()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetCurrentWho(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Gets the independence of a unit.
--- @param self GameObject
--- @return integer
function GameObject:GetIndependence()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetIndependence(self:GetHandle());
end

--- Sets the independence of a unit. 1 (the default) lets the unit take initiative (e.g. attack nearby enemies), while 0 prevents that.
--- @param self GameObject
--- @param independence integer
function GameObject:SetIndependence(independence)
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
--- @param priority integer?
--- @param who GameObject|Handle?
--- @param where Matrix|Vector|string?
--- @param when number?
--- @param param string?
function GameObject:SetCommand(command, priority, who, where, when, param)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(command) then error("Parameter command must be a number") end
    if priority ~= nil and not utility.isnumber(priority) then error("Parameter priority must be a number") end
    if who ~= nil and not (M.isgameobject(who) or utility.isstring(who)) then error("Parameter who must be GameObject or string") end
    if where ~= nil and not (utility.isMatrix(where) or utility.isVector(where) or utility.isstring(where)) then error("Parameter where must be Matrix, Vector, or string") end
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
--- @param priority integer? Order priority, >0 removes user control
function GameObject:Attack(target, priority)
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
--- @function GameObject:Goto
--- @param self GameObject GameObject instance
--- @param target Vector|Matrix|GameObject|Handle|string Target Path name
--- @param priority integer? Order priority, >0 removes user control
function GameObject:Goto(target, priority)
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
--- @param priority integer? Order priority, >0 removes user control
function GameObject:Mine(target, priority)
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
--- @param priority integer? Order priority, >0 removes user control
function GameObject:Follow(target, priority)
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
function GameObject:IsFollowing(target)
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
--- @param priority integer? Order priority, >0 removes user control
function GameObject:Defend(priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    Defend(self:GetHandle(), priority);
end

--- Order GameObject to Defend2 target GameObject.
--- @param self GameObject GameObject instance
--- @param target GameObject|Handle Target GameObject instance
--- @param priority integer? Order priority, >0 removes user control
function GameObject:Defend2(target, priority)
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
--- @param priority integer? Order priority, >0 removes user control
function GameObject:Stop(priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    Stop(self:GetHandle(), priority);
end

--- Order GameObject to Patrol target path.
--- @param self GameObject GameObject instance
--- @param target string Target Path name
--- @param priority integer? Order priority, >0 removes user control
function GameObject:Patrol(target, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(target) then error("Parameter target must be a string") end
    --- @diagnostic disable-next-line: deprecated
    Patrol(self:GetHandle(), target, priority);
end

--- Order GameObject to Retreat.
--- @param self GameObject GameObject instance
--- @param target GameObject|Handle|string Target GameObject or Path name
--- @param priority integer? Order priority, >0 removes user control
function GameObject:Retreat(target, priority)
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
--- @param priority integer? Order priority, >0 removes user control
function GameObject:GetIn(target, priority)
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
--- @param priority integer? Order priority, >0 removes user control
function GameObject:Pickup(target, priority)
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
--- @param priority integer? Order priority, >0 removes user control
function GameObject:Dropoff(target, priority)
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
--- @param priority integer? Order priority, >0 removes user control
function GameObject:Build(odf, priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(odf) then error("Parameter odf must be a string") end
    --- @diagnostic disable-next-line: deprecated
    Build(self:GetHandle(), odf, priority)
end

--- Order GameObject to BuildAt target GameObject.
--- @param self GameObject GameObject instance
--- @param odf string Object Definition
--- @param target Vector|Matrix|GameObject|Handle|string Target GameObject instance, vector, matrix, or path name
--- @param priority integer? Order priority, >0 removes user control
function GameObject:BuildAt(odf, target, priority)
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
--- @param priority integer? Order priority, >0 removes user control
function GameObject:Formation(target, priority)
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
--- @param priority integer? Order priority, >0 removes user control
function GameObject:Hunt(priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    Hunt(self:GetHandle(), priority);
end

--- Order GameObject to Recycle.
--- @param self GameObject GameObject instance
--- @param priority integer? Order priority, >0 removes user control
function GameObject:Recycle(priority)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    Recycle(self:GetHandle(), priority);
end

--- @section Tug Cargo
--- These functions query Tug and Cargo.

--- Returns true if the GameObject is a tug carrying cargo.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject:HasCargo()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return HasCargo(self:GetHandle());
end

--- Returns the GameObject of the cargo if the GameObject is a tug carrying cargo. Returns nil otherwise.
--- @param self GameObject GameObject instance
--- @return GameObject? GameObject of the GameObject carried by the GameObject, or nil
function GameObject:GetCargo()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetCargo(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- Returns the GameObject of the tug carrying the object. Returns nil if not carried.
--- @param self GameObject GameObject instance
--- @return GameObject? GameObject of the tug carrying the GameObject, or nil
function GameObject:GetTug()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = GetTug(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- @section Pilot Actions
--- These functions control the pilot of a vehicle.

--- Commands the vehicle's pilot to eject.
--- @param self GameObject
function GameObject:EjectPilot()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    EjectPilot(self:GetHandle());
end

--- Commands the vehicle's pilot to hop out.
--- @param self GameObject
function GameObject:HopOut()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    HopOut(self:GetHandle());
end

--- Kills the vehicle's pilot as if sniped.
--- @param self GameObject
function GameObject:KillPilot()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    KillPilot(self:GetHandle());
end

--- Removes the vehicle's pilot cleanly.
--- @param self GameObject
function GameObject:RemovePilot()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    RemovePilot(self:GetHandle());
end

--- Returns the vehicle that the pilot GameObject most recently hopped out of.
--- @param self GameObject GameObject instance
--- @return GameObject? GameObject of the vehicle that the pilot most recently hopped out of, or nil
function GameObject:HoppedOutOf()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = HoppedOutOf(self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- @section Health Values
--- These functions get and set health values on a game object.

--- Returns the fractional health of the game object between 0 and 1.
--- ```lua
--- if friend1:GetHealth() < 0.5 then
---     friend1:Retreat("retreat_path");
--- end
--- ```
--- @param self GameObject GameObject instance
--- @return number ratio health ratio
function GameObject:GetHealth()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetHealth(self:GetHandle());
end

--- Returns the current health value of the game object.
--- @param self GameObject GameObject instance
--- @return number current current health or nil
function GameObject:GetCurHealth()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetCurHealth(self:GetHandle());
end

--- Returns the maximum health value of the game object.
--- @param self GameObject GameObject instance
--- @return number max max health or nil
function GameObject:GetMaxHealth()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetMaxHealth(self:GetHandle());
end

--- Sets the current health of the game object.
--- @param self GameObject GameObject instance
--- @param health number health amount
function GameObject:SetCurHealth(health)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(health) then error("Parameter health must be number."); end
    --- @diagnostic disable-next-line: deprecated
    SetCurHealth(self:GetHandle(), health);
end

--- Sets the max health of the GameObject to the NewHealth value.
--- @param self GameObject GameObject instance
--- @param health number health amount
function GameObject:SetMaxHealth(health)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(health) then error("Parameter health must be number."); end
    --- @diagnostic disable-next-line: deprecated
    SetMaxHealth(self:GetHandle(), health);
end

--- Adds the health to the GameObject.
--- @param self GameObject GameObject instance
--- @param health number health amount
function GameObject:AddHealth(health)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(health) then error("Parameter health must be number."); end
    --- @diagnostic disable-next-line: deprecated
    AddHealth(self:GetHandle(), health);
end

--- GiveMaxHealth
--- @param self GameObject GameObject instance
function GameObject:GiveMaxHealth()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    GiveMaxHealth(self:GetHandle());
end

--- @section Ammo Values
--- These functions get and set ammo values on a game object.

--- Returns the fractional ammo of the game object between 0 and 1.
--- @param self GameObject GameObject instance
--- @return number ratio ammo ratio
function GameObject:GetAmmo()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetAmmo(self:GetHandle());
end

--- Returns the current ammo value of the game object.
--- @param self GameObject GameObject instance
--- @return number current current ammo or nil
function GameObject:GetCurAmmo()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetCurAmmo(self:GetHandle());
end

--- Returns the maximum ammo value of the game object.
--- @param self GameObject GameObject instance
--- @return number max max ammo or nil
function GameObject:GetMaxAmmo()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return GetMaxAmmo(self:GetHandle());
end

--- Sets the current ammo of the game object.
--- @param self GameObject GameObject instance
--- @param ammo any ammo amount
function GameObject:SetCurAmmo(ammo)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(ammo) then error("Parameter ammo must be number."); end
    --- @diagnostic disable-next-line: deprecated
    SetCurAmmo(self:GetHandle(), ammo);
end

--- Sets the maximum ammo of the game object.
--- @param self GameObject GameObject instance
--- @param ammo any ammo amount
function GameObject:SetMaxAmmo(ammo)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(ammo) then error("Parameter ammo must be number."); end
    --- @diagnostic disable-next-line: deprecated
    SetMaxAmmo(self:GetHandle(), ammo);
end

--- Adds to the current ammo of the game object.
--- @param self GameObject GameObject instance
--- @param ammo any ammo amount
function GameObject:AddAmmo(ammo)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isnumber(ammo) then error("Parameter ammo must be number."); end
    --- @diagnostic disable-next-line: deprecated
    AddAmmo(self:GetHandle(), ammo);
end

--- Sets the unit's current ammo to maximum.
--- @param self GameObject GameObject instance
function GameObject:GiveMaxAmmo()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    GiveMaxAmmo(self:GetHandle());
end

--- @section Network
--- LuaMission currently has limited network support, but can detect if the mission is being run in multiplayer and if the local machine is hosting.

--- Sets the game object as local to the machine the script is running on, transferring ownership from its original owner if it was remote.
--- Important safety tip: only call this on one machine at a time!
--- @param self GameObject GameObject instance
function GameObject:SetLocal()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    SetLocal(self:GetHandle());
end

--- Returns true if the game is local to the machine the script is running on. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject:IsLocal()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsLocal(self:GetHandle());
end

--- Returns true if the game object is remote to the machine the script is running on. Returns false otherwise.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject:IsRemote()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsRemote(self:GetHandle());
end

--- Returns true if the game object is initialized, meaning it has been created and is either local or remote.
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject:IsInitialized()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    local h = self:GetHandle();
    --- @diagnostic disable-next-line: deprecated
    return IsLocal(h) or IsRemote(h);
end

--- @section Portal Functions
--- {VERSION 2.1+}
--- These functions control the Portal building introduced in The Red Odyssey expansion.

--- Sets the specified Portal direction to "out", indicated by a blue visual effect while active.
--- {VERSION 2.1+}
--- @param self GameObject GameObject instance
function GameObject:PortalOut()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    PortalOut(self:GetHandle());
end

--- Sets the specified Portal direction to "in", indicated by an orange visual effect while active.
--- {VERSION 2.1+}
--- @param self GameObject GameObject instance
function GameObject:PortalIn()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    PortalIn(self:GetHandle());
end

--- {VERSION 2.1+}
--- @param self GameObject GameObject instance
function GameObject:DeactivatePortal()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    DeactivatePortal(self:GetHandle());
end

--- Activates the specified Portal, starting the visual effect.
--- {VERSION 2.1+}
--- @param self GameObject GameObject instance
function GameObject:ActivatePortal()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    ActivatePortal(self:GetHandle());
end

--- Returns true if the specified Portal direction is "in". Returns false otherwise.
--- {VERSION 2.1+}
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject:PortalDirectionIsIn()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsIn(self:GetHandle());
end

--- Returns true if the specified Portal is active. Returns false otherwise.
--- Important: note the capitalization!
--- {VERSION 2.1+}
--- @param self GameObject GameObject instance
--- @return boolean
--- @diagnostic disable-next-line: lowercase-global
function GameObject:PortalIsActive()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return isPortalActive(self:GetHandle());
end

--- Creates a game object with the given odf name and team number at the location of a portal.
--- The object is created at the location of the visual effect and given a 50 m/s initial velocity.
--- {VERSION 2.1+}
--- @param self GameObject GameObject instance
--- @param odfname string
--- @param teamnum TeamNum
--- @return GameObject?
function GameObject:BuildObjectAtPortal(odfname, teamnum)
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    if not utility.isstring(odfname) then error("Parameter odfname must be a string."); end
    if not utility.isnumber(teamnum) then error("Parameter teamnum must be a number."); end
    --- @diagnostic disable-next-line: deprecated
    local handle = BuildObjectAtPortal(odfname, teamnum, self:GetHandle());
    if handle == nil then return nil end;
    return M.FromHandle(handle);
end

--- @section Cloak
--- {VERSION 2.1+}
--- These functions control the cloaking state of craft capable of cloaking.

--- Makes the specified unit cloak if it can.
--- Note: unlike SetCommand(h, AiCommand.CLOAK), this does not change the unit's current command.
--- {VERSION 2.1+}
--- @param self GameObject GameObject instance
function GameObject:Cloak()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    Cloak(self:GetHandle());
end

--- Makes the specified unit de-cloak if it can.
--- Note: unlike SetCommand(h, AiCommand.DECLOAK), this does not change the unit's current command.
--- {VERSION 2.1+}
--- @param self GameObject GameObject instance
function GameObject:Decloak()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    Decloak(self:GetHandle());
end

--- Instantly sets the unit as cloaked (with no fade out).
--- {VERSION 2.1+}
--- @param self GameObject GameObject instance
function GameObject:SetCloaked()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    SetCloaked(self:GetHandle());
end

--- Instant sets the unit as uncloaked (with no fade in).
--- {VERSION 2.1+}
--- @param self GameObject GameObject instance
function GameObject:SetDecloaked()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    SetDecloaked(self:GetHandle());
end

--- Returns true if the unit is cloaked. Returns false otherwise
--- {VERSION 2.1+}
--- @param self GameObject GameObject instance
--- @return boolean
function GameObject:IsCloaked()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    return IsCloaked(self:GetHandle());
end

--- @section Hide
--- {VERSION 2.1+}
--- These functions hide and show game objects. When hidden, the object is invisible (similar to Phantom VIR and cloak) and undetectable on radar (similar to RED Field and cloak). The effect is similar to but separate from cloaking. For the most part, AI units ignore the hidden state.

--- Hides a game object.
--- {VERSION 2.1+}
--- @param self GameObject GameObject instance
function GameObject:Hide()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    Hide(self:GetHandle());
end

--- Un-hides a game object.
--- {VERSION 2.1+}
--- @param self GameObject GameObject instance
function GameObject:UnHide()
    if not M.isgameobject(self) then error("Parameter self must be GameObject instance."); end
    --- @diagnostic disable-next-line: deprecated
    UnHide(self:GetHandle());
end

--- @section Event Hooks
--- Hook to game events.

hook.Add("DeleteObject", "GameObject_DeleteObject", function(object)
    local objectId = object:GetHandle();

    -- store the dead object as a weak reference just in case something's still using it
    -- if nothing's tracking it then it will be gone soon
    GameObjectSeqNoDeadMemo[object:GetSeqNo()] = object;

    -- stop tracking the object's sequence number
    GameObjectSeqNoMemo[object:GetSeqNo()] = nil;

    GameObjectAltered[objectId] = nil; -- remove any strong reference for being altered

    -- Alternate method where we delay deletion to next update
    -- BZ2 needs this because handles can be re-used in an upgrade, so we need to know if this has happened for an UpgradeObject event, but BZ1 doesn't have this.
    --logger.print(logger.LogLevel.DEBUG, nil, 'Decaying object ' .. tostring(objectId));
    --GameObjectDead[objectId] = object; -- store dead object for full cleanup next update (in BZ2 handle might be re-used)
end, config.get("hook_priority.DeleteObject.GameObject"));

hook.Add("Start", "GameObject_Start", function()
    --- @todo skip this if we have access to SeqNo functions
    --- @diagnostic disable-next-line: empty-block
    for _ in M.AllObjects() do end -- make every GameObject construct for side-effects (SeqNo memo)
end, config.get("hook_priority.Start.GameObject"));

--hook.Add("Update", "GameObject_Update", function(dtime)
--    for k,v in pairs(GameObjectDead) do
--        logger.print(logger.LogLevel.DEBUG, nil, 'Decayed object ' .. tostring(k));
--        GameObjectAltered[k] = nil; -- remove any strong reference for being altered
--        GameObjectDead[k] = nil; -- remove any strong reference for being dead
--    end
--end, config.get("hook_priority.Update.GameObject"));

customsavetype.Register(GameObject);

logger.print(logger.LogLevel.DEBUG, nil, "_gameobject Loaded");

return M;