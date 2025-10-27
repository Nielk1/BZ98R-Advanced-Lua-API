--- BZ98R LUA Extended API ODF Handler.
---
--- Network functions and tools.
---
--- @module '_network'
--- @author John "Nielk1" Klein

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_network Loading");

--- @class _network
local M = {};

local config = require("_config");
local hook = require("_hook");

--- Mapping of network IDs to team IDs.
--- @type table<integer, TeamNum>
M.NetToTeam = {}

--- Mapping of team IDs to network IDs.
--- @type table<TeamNum, integer>
M.TeamToNet = {}

--- The local machine's network ID
--- Should almost never be nil
--- @type integer?
M.NetID = nil;

--- Returns true if the game is a network game. Returns false otherwise.
--- @return boolean
function M.IsNetGame()
    --- @diagnostic disable-next-line: deprecated
    return IsNetGame();
end

--- Returns true if the local machine is hosting a network game. Returns false otherwise.
--- @return boolean
function M.IsHosting()
    --- @diagnostic disable-next-line: deprecated
    return IsHosting();
end

--- Adds a system text message to the chat window on the local machine.
--- @param message string
function M.DisplayMessage(message)
    --- @diagnostic disable-next-line: deprecated
    DisplayMessage(message);
end

--- Send a script-defined message across the network.
--- To is the player network id of the recipient. None, nil, or 0 broadcasts to all players.
--- Type is a one-character string indicating the script-defined message type.
--- Other parameters will be sent as data and passed to the recipient's Receive function as parameters. Send supports nil, boolean, handle, integer, number, string, vector, and matrix data types. It does not support function, thread, or arbitrary userdata types.
--- The sent packet can contain up to 244 bytes of data (255 bytes maximum for an Anet packet minus 6 bytes for the packet header and 5 bytes for the reliable transmission header)
--- <table><tbody>
---   <tr><th colspan="2">Type</th><th>Bytes</th></tr>
---   <tr><td colspan="2">nil</td><td>1</td></tr>
---   <tr><td colspan="2">boolean</td><td>1</td></tr>
---   <tr><td rowspan="2">handle</td><td>invalid (zero)</td><td>1</td></tr>
---   <tr><td>valid (nonzero)</td><td>1 + sizeof(int) = 5</td></tr>
---   <tr><td rowspan="5">number</td><td>zero</td><td>1</td></tr>
---   <tr><td>char (integer -128 to 127)</td><td>1 + sizeof(char) = 2</td></tr>
---   <tr><td>short (integer -32768 to 32767)</td><td>1 + sizeof(short) = 3</td></tr>
---   <tr><td>int (integer)</td><td>1 + sizeof(int) = 5</td></tr>
---   <tr><td>double (non-integer)</td><td>1 + sizeof(double) = 9</td></tr>
---   <tr><td rowspan="2">string</td><td>length &lt; 31</td><td>1 + length</td></tr>
---   <tr><td>length &gt;= 31</td><td>2 + length</td></tr>
---   <tr><td rowspan="2">table</td><td>count &lt; 31</td><td>1 + count + size of keys and values</td></tr>
---   <tr><td>count &gt;= 31</td><td>2 + count + size of keys and values</td></tr>
---   <tr><td rowspan="2">userdata</td><td>VECTOR_3D</td><td>1 + sizeof(VECTOR_3D) = 13</td></tr>
---   <tr><td>MAT_3D</td><td>1 + sizeof(REDUCED_MAT) = 12</td></tr>
--- </tbody></table>
--- @param to integer
--- @param type string
--- @vararg any
function M.Send(to, type, ...)
    --- @todo Break packets apart if they are too big, might be worth having a special "SendBig" function as finding where to split or if need to is slow
    --- Use a format like to, SPLIT_ID, Part, Parts, Len, {...} where Len is there to deal with nils at bookends

    --- @diagnostic disable-next-line: deprecated
    Send(to, type, ...);
end

local network_emulation = {};

if M.IsNetGame() then
    local gameobject = require("_gameobject");

    hook.Add("CreatePlayer", "_network:CreatePlayer", function(id, name, team)
        M.NetToTeam[id] = team;
        M.TeamToNet[team] = id;

        --- @todo confirm if this part of the code works
        local player = gameobject.GetPlayer();
        if player and player:GetTeamNum() == team then
            M.NetID = id;
        end
    end, config.lock().hook_priority.CreatePlayer.Network);
    hook.Add("AddPlayer", "_network:AddPlayer", function(id, name, team)
        M.NetToTeam[id] = team;
        M.TeamToNet[team] = id;
    end, config.lock().hook_priority.AddPlayer.Network);
    hook.Add("RemovePlayer", "_network:RemovePlayer", function(id, name, team)
        M.NetToTeam[id] = nil;
        M.TeamToNet[team] = nil;
    end, config.lock().hook_priority.RemovePlayer.Network);
else
    -- [[START_IGNORE]]

    M.NetID = 1;
    M.NetToTeam[M.NetID] = 1;
    M.TeamToNet[1] = M.NetID;

    M.Send = function(to, type, ...)
        -- if the message is not broadcast or to self
        if to ~= nil and to ~= 0 and to ~= 1 then
            return;
        end
        
        table.insert(network_emulation, {type, {...}, select('#', ...)});
    end

    local objective = require("_objective");
    local objective_index = 1;
    local objectives_shown = {};
    M.DisplayMessage = function(message)
        objective.AddObjective(tostring(objective_index) .. ".NTWRK", "WHITE", 8, message, nil, true);
        objectives_shown[objective_index] = GetTime() + 8;
        objective_index = objective_index + 1;
    end

    -- Remove old objectives after some delay
    hook.Add("Update", "_network:Update:Objectives", function(dtime, ttime)
        local now = GetTime();
        local remove = {};
        for index, expire_time in pairs(objectives_shown) do
            if now > expire_time then
                objective.RemoveObjective(tostring(index) .. ".NTWRK");
                table.insert(remove, index);
            end
        end
        for _, index in ipairs(remove) do
            objectives_shown[index] = nil;
        end
        if next(objectives_shown) == nil then
            objective_index = 1;
        end
    end, config.lock().hook_priority.Update.NetworkObjectives);

    -- [[END_IGNORE]]
end

local routines = {};

--- Register a coroutine to be executed each Update until it finishes.
--- @param fun thread|function Coroutine or function that returns nil|false when finished
function M.Defer(fun)
    routines[fun] = true;
end

hook.Add("Update", "_network:Update", function(dtime, ttime)
    local dead = {};

    for routine, _ in pairs(routines) do
        local t = type(routine);
        if t == "function"  then
            if not routine() then
                table.insert(dead, routine);
            end
        elseif t == "thread" then
            local status, res = coroutine.resume(routine, dtime, ttime);
            if not status then
                logger.print(logger.LogLevel.ERROR, nil, "_network: Error in delayed routine: "..tostring(res));
                table.insert(dead, routine);
            elseif coroutine.status(routine) == "dead" then
                table.insert(dead, routine);
            end
        else
            logger.print(logger.LogLevel.ERROR, nil, "_network: Invalid routine type registered: "..tostring(type(routine)));
            table.insert(dead, routine);
        end
    end

    for _, routine in ipairs(dead) do
        routines[routine] = nil;
    end

    -- Emulate network messages last, to simulate some network-y-ness
    if network_emulation[1] then
        for _, packet in ipairs(network_emulation) do
            --- @diagnostic disable-next-line: deprecated
            Receive(1, packet[1], table.unpack(packet[2], 1, packet[3]));
        end
        network_emulation = {};
    end
end, config.lock().hook_priority.Update.Network);

logger.print(logger.LogLevel.DEBUG, nil, "_network Loaded");

return M;