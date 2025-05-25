--- BZ98R LUA Extended API Camera.
---
--- Camera API wrapper.
---
--- @module '_camera'
--- @author John "Nielk1" Klein

require("_fix");

--- @diagnostic disable-next-line: undefined-global
local debugprint = debugprint or function(...) end;

debugprint("_camera Loading");

local config = require("_config");
local utility = require("_utility");
local gameobject = require("_gameobject");
local _api = require("_api");
local hook = require("_hook");

local M = {};

local WorldTime = 0;
local InCamera = false;
local CameraType = nil;
local CameraParams = nil;
local CameraTime = 0; -- time the last camera param set was applied

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

local function GetPathVectorAfterTime(path, speed, time)
    --- @todo edge case when path as 1 point
    
    local pathLength = GetPathPointCount(path);
    if pathLength == 0 then return SetVector(), SetVector(); end
    if pathLength == 1 then return GetPosition(path, 0), SetVector(); end

    local distance = speed * time;

    local currentDistance = 0
    local lastPosition = nil
    local direction = { x = 0, y = 0, z = 0 }
    for i = 0, pathLength - 1 do
        local currentPosition = GetPosition(path, i)
        if currentPosition == nil then
            error("GetPosition returned nil for path: " .. tostring(path) .. " at index: " .. tostring(i))
        end

        -- If this is not the first point, calculate the direction and distance
        if lastPosition then
            -- Calculate the vector difference between the current and last points
            local dx = currentPosition.x - lastPosition.x
            local dy = currentPosition.y - lastPosition.y
            local dz = currentPosition.z - lastPosition.z

            -- Calculate the distance between the two points
            local segmentLength = math.sqrt(dx * dx + dy * dy + dz * dz)

            -- Check if the desired distance is within this segment
            if currentDistance + segmentLength >= distance then
                -- Calculate the remaining distance to travel in this segment
                local remainingDistance = distance - currentDistance

                -- Normalize the direction vector
                local magnitude = math.sqrt(dx * dx + dy * dy + dz * dz)
                direction = { x = dx / magnitude, y = dy / magnitude, z = dz / magnitude }

                -- Calculate the position at the desired distance
                local position = {
                    x = lastPosition.x + direction.x * remainingDistance,
                    y = lastPosition.y + direction.y * remainingDistance,
                    z = lastPosition.z + direction.z * remainingDistance
                }

                return direction, position
            end

            -- Update the current distance traveled
            currentDistance = currentDistance + segmentLength

            -- Update the direction vector to the current segment's direction
            direction = { x = dx / segmentLength, y = dy / segmentLength, z = dz / segmentLength }
        end

        -- Update the last position to the current position
        lastPosition = currentPosition
    end

    -- If we reach here, we've traveled the entire path
    -- Return the last point and the last direction vector
    return direction, lastPosition
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
        pos.y = GetFloorHeightAndNormal(pos) + height;
        return pos, Normalize(target_pos - pos);
    elseif CameraType == "CameraPathDir" then
        if not CameraParams or #CameraParams < 3 then
            error("CameraPathDir requires 3 parameters: path, height, speed");
        end
        local path = CameraParams[1];
        local height = CameraParams[2];
        local speed = CameraParams[3];
        local pos, dir = GetPathVectorAfterTime(path, speed, WorldTime - CameraTime);
        pos.y = GetFloorHeightAndNormal(pos) + height;
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
        local target_pos = GetPathVectorAfterTime(target, speed, WorldTime - CameraTime);
        pos.y = GetFloorHeightAndNormal(pos) + height;
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
--- @param height integer
--- @param speed integer
--- @param target GameObject|Handle
--- @return boolean
function M.CameraPath(path, height, speed, target)
    if gameobject.isgameobject(target) then
        --- @cast target GameObject
        target = target:GetHandle();
    end
    --- @cast target Handle
    CheckCameraType("CameraPath", {path, height, speed, target});
    --- @diagnostic disable-next-line: deprecated
    return CameraPath(path, height, speed, target);
end

--- Moves a cinematic camera long a path at a given height and speed while looking along the path direction.
--- Returns true when the camera arrives at its destination. Returns false otherwise.
--- @param path string
--- @param height integer
--- @param speed integer
--- @return boolean
function M.CameraPathDir(path, height, speed)
    CheckCameraType("CameraPathDir", {path, height, speed});
    --- @diagnostic disable-next-line: deprecated
    return CameraPathDir(path, height, speed);
end

--- Moves a cinematic camera along a path at a given height and speed while looking at a target path.
--- Returns true when the camera arrives at its destination. Returns false otherwise.
--- @param path string
--- @param height integer
--- @param speed integer
--- @param target string
--- @return boolean
function M.CameraPathPath(path, height, speed, target)
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
--- @diagnostic disable: undefined-doc-param
--- @overload fun(base: GameObject|Handle, right: number, up: number, foward: number, target: GameObject|Handle): boolean
--- @overload fun(base: GameObject|Handle, offset:Vector, target: GameObject|Handle): boolean
--- @param base GameObject|Handle
--- @param right number Meters to the right of the base object. (0.01 resolution)
--- @param up number Meters above the base object. (0.01 resolution)
--- @param forward number Meters in front of the base object. (0.01 resolution)
--- @param offset Vector
--- @param target GameObject|Handle
--- @return boolean
function M.CameraObject(...)
    local args = {...}
    local base = args[1];
    local target;
    local right;
    local up;
    local forward;
    if #args == 5 then
        target = args[5];
        right = args[2];
        up = args[3];
        forward = args[4];
    elseif #args == 3 then
        if not utility.isVector(args[2]) then error("Parameter offset must be a Vector."); end
        target = args[3];
        right = args[2].x;
        up = args[2].y;
        forward = args[2].z;
    else
        error("Invalid number of arguments. Expected 3 or 5.");
    end
    if gameobject.isgameobject(base) then
        --- @cast base GameObject
        base = base:GetHandle();
    end
    if gameobject.isgameobject(target) then
        --- @cast target GameObject
        target = target:GetHandle();
    end
    --- @cast base Handle
    --- @cast right number
    --- @cast up number
    --- @cast forward number
    --- @cast target Handle
    if not utility.isHandle(base) then
        error("Parameter base must be Handle or GameObject instance.");
    end
    if not utility.isHandle(target) then
        error("Parameter target must be Handle or GameObject instance.");
    end
    if not utility.isnumber(right) or not utility.isnumber(up) or not utility.isnumber(forward) then
        error("Parameters right, up, and forward must be numbers.");
    end
    CheckCameraType("CameraObject", {base, right, up, forward, target});
    --- @diagnostic disable-next-line: deprecated
    return CameraObject(base, math.floor(right * 100), math.floor(up * 100), math.floor(forward * 100), target);
end

--- Offsets a cinematic camera from a base game object while looking at a target game object.
-- Returns true if the base or handle game object does not exist. Returns false otherwise.
--- @overload fun(base: GameObject|Handle, right: number, up: number, foward: number, target: GameObject|Handle): boolean
--- @overload fun(base: GameObject|Handle, offset:Vector, target: GameObject|Handle): boolean
-- @param base GameObject|Handle
-- @param right number Meters to the right of the base object. (0.01 resolution)
-- @param up number Meters above the base object. (0.01 resolution)
-- @param forward number Meters in front of the base object. (0.01 resolution)
-- @param target GameObject|Handle
-- @return boolean
-- @function CameraObject

--- Offsets a cinematic camera from a base game object while looking at a target game object.
-- Returns true if the base or handle game object does not exist. Returns false otherwise.
-- @param base GameObject|Handle
-- @param offset Vector
-- @param target GameObject|Handle
-- @return boolean
-- @function CameraObject

--- Finishes the cinematic camera and enables normal input.
--- Always returns true.
function M.CameraFinish()
    InCamera = false;
    CheckCameraType(nil, nil);
    --- @diagnostic disable-next-line: deprecated
    CameraFinish();
end

--- Returns true if the player canceled the cinematic. Returns false otherwise.
--- @return boolean
function M.CameraCancelled()
    --- @diagnostic disable-next-line: deprecated
    return CameraCancelled();
end

--- Camera is currently active
--- @return boolean
function M.InCamera()
    return InCamera;
end

hook.Add("Update", "_camera.Update", function(dtime, ttime)
    WorldTime = ttime;
end, config.get("hook_priority.Update.Camera"));

debugprint("_camera Loaded");

return M;