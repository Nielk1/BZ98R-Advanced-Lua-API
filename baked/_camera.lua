--- BZ98R LUA Extended API Camera.
---
--- Camera API wrapper.
---
--- @module '_camera'
--- @author John "Nielk1" Klein

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_camera Loading");

local config = require("_config");
local utility = require("_utility");
local gameobject = require("_gameobject");
local _api = require("_api");
local hook = require("_hook");

--- @class _camera
local M = {};

local WorldTime = 0;
local InCamera = false;
local CameraType = nil;
local CameraParams = nil;
local CameraTime = 0; -- time the last camera param set was applied
local CameraTargetDummy = nil;
local CameraWasCancelled = nil;

local function arrayEquals(a, b)
    if a == nil and b == nil then return true; end -- if both are nil, they are equal
    if a == nil or b == nil then return false; end -- if either is nil, they are not equal, can only get here if both not nil
    if #a ~= #b then return false; end
    for i = 1, #a do
        if a[i] ~= b[i] then return false; end
    end
    return true;
end

--- if the camera type or params are differnt from those passed in apply the new values and return true, else return false
--- @param type string?
--- @param params any[]?
--- @return boolean changed
local function CheckCameraType(type, params)
    if CameraType ~= type or not arrayEquals(CameraParams, params) then
        CameraType = type;
        CameraParams = params;
        CameraTime = WorldTime;
        if CameraTargetDummy then
            --- @diagnostic disable-next-line: deprecated
            RemoveObject(CameraTargetDummy);
        end
        CameraTargetDummy = nil; -- reset the dummy object if the camera type changes
        return true;
    end
    return false;
end


--BZCC functions to add
--SetCameraPosition(Vector pos, Vector dir)
--ResetCameraPosition()
--bool CameraPos(Handle me, Handle him, Vector PosA, Vector PosB, number Speed)
--CameraOf(Handle me, Vector offset)
--bool FreeCamera()
--bool FreeFinish()

--- @param path string
--- @param speed integer centimeters per second
--- @param time integer
--- @return Vector pos
--- @return Vector dir
--- @return boolean end
local function GetPathVectorAfterTime(path, speed, time)
    --- @todo edge case when path as 1 point

    local pathLength = GetPathPointCount(path);
    if pathLength == 0 then return SetVector(), SetVector(), true; end
    --- @diagnostic disable-next-line: return-type-mismatch
    if pathLength == 1 then return GetPosition(path, 0), SetVector(), true; end

    local distance = speed * time / 100;

    local currentDistance = 0;
    local lastPosition = nil;
    local direction = SetVector();
    for i = 0, pathLength - 1 do
        local currentPosition = GetPosition(path, i);
        if currentPosition == nil then
            error("GetPosition returned nil for path: " .. tostring(path) .. " at index: " .. tostring(i))
        end

        -- If this is not the first point, calculate the direction and distance
        if lastPosition then
            -- Calculate the vector difference between the current and last points
            local d = currentPosition - lastPosition;

            -- Calculate the distance between the two points
            local segmentLength = Length(d);

            -- Check if the desired distance is within this segment
            if currentDistance + segmentLength >= distance then
                -- Calculate the remaining distance to travel in this segment
                local remainingDistance = distance - currentDistance;

                -- Normalize the direction vector
                direction = Normalize(d);

                -- Calculate the position at the desired distance
                local position = lastPosition + direction * remainingDistance;

                return position, direction, false;
            end

            -- Update the current distance traveled
            currentDistance = currentDistance + segmentLength;

            -- Update the direction vector to the current segment's direction
            --direction = { x = dx / segmentLength, y = dy / segmentLength, z = dz / segmentLength }
        end

        -- Update the last position to the current position
        lastPosition = currentPosition;
    end

    -- If we reach here, we've traveled the entire path
    -- Return the last point and the last direction vector
    return lastPosition, direction, true;
end

--- @todo this function badly needs testing
--- @return Vector pos
--- @return Vector dir
function M.GetCameraPosition()
    if not InCamera then
        return SetVector(), SetVector();
    end

    if CameraType == "CameraPath" then
        if not CameraParams or #CameraParams < 4 then
            error("CameraPath requires 4 parameters: path, height, speed, target");
        end
        local path = CameraParams[1];
        local height = CameraParams[2];
        local speed = CameraParams[3];
        local target = CameraParams[4];
        local target_pos = GetPosition(target);
        local pos = GetPathVectorAfterTime(path, speed, WorldTime - CameraTime);
        pos.y = GetTerrainHeightAndNormal (pos) + height;
        return pos, Normalize(target_pos - pos);
    elseif CameraType == "CameraPathDir" then
        if not CameraParams or #CameraParams < 3 then
            error("CameraPathDir requires 3 parameters: path, height, speed");
        end
        local path = CameraParams[1];
        local height = CameraParams[2];
        local speed = CameraParams[3];
        local pos, dir = GetPathVectorAfterTime(path, speed, WorldTime - CameraTime);
        pos.y = GetTerrainHeightAndNormal (pos) + height;
        return pos, dir;
    elseif CameraType == "CameraPathPath" then
        if not CameraParams or #CameraParams < 4 then
            error("CameraPathPath requires 4 parameters: path, height, speed, target");
        end
        local path = CameraParams[1];
        local height = CameraParams[2];
        local speed = CameraParams[3];
        local target = CameraParams[4];
        local pos = GetPathVectorAfterTime(path, speed, WorldTime - CameraTime);
        local target_pos = GetPosition(target, 0);
        pos.y = GetTerrainHeightAndNormal (pos) + height;
        return pos, Normalize(target_pos - pos);
    elseif CameraType == "CameraPathPathFollow" then
        if not CameraParams or #CameraParams < 6 then
            error("CameraPathPathFollow requires 6 parameters: path, height, speed, target, target_speed");
        end
        local path = CameraParams[1];
        local height = CameraParams[2];
        local speed = CameraParams[3];
        local target = CameraParams[4];
        local target_height = CameraParams[5];
        local target_speed = CameraParams[6];
        local pos = GetPathVectorAfterTime(path, speed, WorldTime - CameraTime);
        local target_pos = GetPathVectorAfterTime(target, target_speed, WorldTime - CameraTime);
        target_pos.y = GetTerrainHeightAndNormal (target_pos) + target_height;
        pos.y = GetTerrainHeightAndNormal (pos) + height;
        return pos, Normalize(target_pos - pos);
    elseif CameraType == "CameraObject" then
        if not CameraParams or #CameraParams < 5 then
            error("CameraObject requires 5 parameters: base, right, up, forward, target");
        end
        local base = CameraParams[1];
        local right = CameraParams[2];
        local up = CameraParams[3];
        local forward = CameraParams[4];
        local offset = SetVector(right, up, forward);
        local target = CameraParams[5];
        
        local base_pos = GetPosition(base);
        --- @diagnostic disable-next-line: deprecated
        local base_transform = GetTransform(base);

        local pos = base_transform * offset + base_pos;
        return pos, Normalize(GetPosition(target) - pos);
    end

    return SetVector(), SetVector();
end

--- Starts the cinematic camera and disables normal input.
function M.CameraReady()
    InCamera = true;
    --- @diagnostic disable-next-line: deprecated
    CameraReady();
end

--- Moves a cinematic camera along a path at a given height and speed while looking at a target game object.
--- Returns true when the camera arrives at its destination. Returns false otherwise.
--- @param path string
--- @param height number meters above the ground
--- @param speed number speed in meters per second
--- @param target GameObject|Handle
--- @return boolean
function M.CameraPath(path, height, speed, target)
    if gameobject.isgameobject(target) then
        --- @cast target GameObject
        target = target:GetHandle();
    end
    height = math.floor(height * 100); -- convert to centimeters
    speed = math.floor(speed * 100); -- convert to centimeters per second
    --- @cast target Handle
    CheckCameraType("CameraPath", {path, height, speed, target});
    --- @diagnostic disable-next-line: deprecated
    return CameraPath(path, height, speed, target);
end

--- Moves a cinematic camera along a path at a given height and speed while looking at a target path.
--- Returns true when the camera arrives at its destination. Returns false otherwise.
--- @param path string
--- @param height number meters above the ground
--- @param speed number speed in meters per second
--- @param target string
--- @param target_height number?
--- @param target_speed number? defaults to the same as speed
--- @return boolean
function M.CameraPathPathFollow(path, height, speed, target, target_height, target_speed)
    target_height = target_height or 0;
    target_speed = target_speed or speed;
    speed = math.floor(speed * 100); -- convert to centimeters per second
    height = math.floor(height * 100); -- convert to centimeters
    target_height = math.floor(target_height * 100); -- convert to centimeters
    target_speed = math.floor(target_speed * 100); -- convert to centimeters per second
    CheckCameraType("CameraPathPathFollow", {path, height, speed, target, target_height, target_speed});
    local target_pos = GetPosition(target);
    if not target_pos then
        error("Target position is nil for target: " .. tostring(target));
    end
    target_pos.y = GetTerrainHeightAndNormal (target_pos) + target_height;
    if not CameraTargetDummy then
        --- @diagnostic disable-next-line: deprecated
        CameraTargetDummy = BuildObject("apcamr", 0, target_pos);
        if not CameraTargetDummy then
            error("Failed to create camera target dummy for target: " .. tostring(target));
        end
        --- @diagnostic disable-next-line: deprecated
        Hide(CameraTargetDummy);
    end
    --- @diagnostic disable-next-line: deprecated
    return CameraPath(path, height, speed, CameraTargetDummy);
end

--- Moves a cinematic camera long a path at a given height and speed while looking along the path direction.
--- Returns true when the camera arrives at its destination. Returns false otherwise.
--- @param path string
--- @param height number
--- @param speed number
--- @return boolean
function M.CameraPathDir(path, height, speed)
    height = math.floor(height * 100); -- convert to centimeters
    speed = math.floor(speed * 100); -- convert to centimeters per second
    CheckCameraType("CameraPathDir", {path, height, speed});
    --- @diagnostic disable-next-line: deprecated
    return CameraPathDir(path, height, speed);
end

--- Moves a cinematic camera along a path at a given height and speed while looking at a target path point.
--- Returns true when the camera arrives at its destination. Returns false otherwise.
--- @param path string
--- @param height number
--- @param speed number
--- @param target string
--- @return boolean
function M.CameraPathPath(path, height, speed, target)
    height = math.floor(height * 100); -- convert to centimeters
    speed = math.floor(speed * 100); -- convert to centimeters per second
    CheckCameraType("CameraPathPath", {path, height, speed, target});
    --- @diagnostic disable-next-line: deprecated
    return CameraPathPath(path, height, speed, target);
end

--- Returns true when the camera arrives at its destination. Returns false otherwise.
--- @return boolean
function M.PanDone()
    --- @diagnostic disable-next-line: deprecated
    return PanDone();
end

--- Offsets a cinematic camera from a base game object while looking at a target game object.
--- Returns true if the base or handle game object does not exist. Returns false otherwise.
--- @overload fun(base: GameObject|Handle, offset:Vector, target: GameObject|Handle): boolean
--- @diagnostic disable: undefined-doc-param
--- @param base GameObject|Handle
--- @param right number Meters to the right of the base object.
--- @param up number Meters above the base object.
--- @param forward number Meters in front of the base object.
--- @param offset Vector
--- @param target GameObject|Handle
--- @diagnostic enable: undefined-doc-param
--- @return boolean Exists true if the base or handle game object does not exist. Returns false otherwise.
function M.CameraObject(base, right, up, forward, target)
    if gameobject.isgameobject(base) then
        --- @cast base GameObject
        base = base:GetHandle();
    elseif not utility.isHandle(base) then
        error("Parameter base must be Handle or GameObject instance.");
    end
    --- @cast base Handle

    if right and up and not forward and not target
       and utility.isVector(right) then
        -- order is important here
        --- @diagnostic disable-next-line: cast-type-mismatch
        --- @cast up GameObject|Handle
        target = up;
        --- @diagnostic disable-next-line: cast-type-mismatch
        --- @cast right Vector
        up = math.floor(right.y * 100); -- convert to centimeters
        forward = math.floor(right.z * 100); -- convert to centimeters
        right = math.floor(right.x * 100); -- convert to centimeters
    elseif utility.isnumber(right) and utility.isnumber(up) and utility.isnumber(forward) then
        right = math.floor(right * 100); -- convert to centimeters
        up = math.floor(up * 100); -- convert to centimeters
        forward = math.floor(forward * 100); -- convert to centimeters
    else
        error("Parameters right, up, and forward must be numbers or offset must be a Vector.");
    end

    if gameobject.isgameobject(target) then
        --- @cast target GameObject
        target = target:GetHandle();
    elseif not utility.isHandle(target) then
        error("Parameter target must be Handle or GameObject instance.");
    end
    --- @cast target Handle

    CheckCameraType("CameraObject", {base, right, up, forward, target});
    --- @diagnostic disable-next-line: deprecated
    return CameraObject(base, right, up, forward, target);
end

--- Finishes the cinematic camera and enables normal input.
--- Does nothing if camera is not active.
function M.CameraFinish()
    if not InCamera then
        return;
    end
    InCamera = false;
    CheckCameraType(nil, nil);
    --- @diagnostic disable-next-line: deprecated
    CameraFinish();
    CameraWasCancelled = nil;
end

--- Returns true if the player canceled the cinematic. Returns false otherwise.
--- @return boolean
function M.CameraCancelled()
    if not InCamera then
        -- if not in camera, cannot be cancelled, just call original just in case
        --- @diagnostic disable-next-line: deprecated
        return CameraCancelled();
    end
    --- @diagnostic disable-next-line: deprecated
    CameraWasCancelled = CameraWasCancelled or CameraCancelled();
    return CameraWasCancelled;
end

--- Resets the camera cancelled flag.
function M.ResetCameraCancelled()
    CameraWasCancelled = nil;
end

--- Camera is currently active
--- @return boolean
function M.InCamera()
    return InCamera;
end

hook.Add("Update", "_camera:Update", function(dtime, ttime)
    WorldTime = ttime;
    if InCamera then
        if CameraType == "CameraPathPathFollow" then
            if CameraTargetDummy then
                if not CameraParams or #CameraParams < 6 then
                    error("CameraPathPathFollow requires 6 parameters: path, height, speed, target, target_speed");
                end
                --local path = CameraParams[1];
                --local height = CameraParams[2];
                --local speed = CameraParams[3];
                local target = CameraParams[4];
                local target_height = CameraParams[5];
                local target_speed = CameraParams[6];
                local target_pos, direction, over = GetPathVectorAfterTime(target, target_speed, WorldTime - CameraTime);
                target_pos.y = (GetTerrainHeightAndNormal (target_pos) or 0) + target_height;
                --print("Target Position:", target_pos.x, target_pos.y, target_pos.z, WorldTime - CameraTime);
                --- @diagnostic disable-next-line: deprecated
                SetPosition(CameraTargetDummy, target_pos);
                if not over then
                    --- @diagnostic disable-next-line: deprecated
                    SetVelocity(CameraTargetDummy, direction * target_speed / 100);
                end
            end
        end
    end
end, config.get("hook_priority.Update.Camera"));

hook.AddSaveLoad("_camera", function()
    return CameraTargetDummy;
end, function(_CameraTargetDummy)
    if _CameraTargetDummy then
        --- @diagnostic disable-next-line: deprecated
        RemoveObject(_CameraTargetDummy);
    end
end);

logger.print(logger.LogLevel.DEBUG, nil, "_camera Loaded");

return M;