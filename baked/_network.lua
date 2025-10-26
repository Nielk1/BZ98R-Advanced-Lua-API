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

--- Send a script-defined message across the network.
--- To is the player network id of the recipient. None, nil, or 0 broadcasts to all players.
--- Type is a one-character string indicating the script-defined message type.
--- Other parameters will be sent as data and passed to the recipient's Receive function as parameters. Send supports nil, boolean, handle, integer, number, string, vector, and matrix data types. It does not support function, thread, or arbitrary userdata types.
--- The sent packet can contain up to 244 bytes of data (255 bytes maximum for an Anet packet minus 6 bytes for the packet header and 5 bytes for the reliable transmission header)
--- <table style="border-collapse:collapse;border:3px solid black;"><tbody>
---   <tr><th style="border:2px solid black;" colspan="2">Type</th><th style="border:2px solid black;">Bytes</th></tr>
---   <tr><td style="border:2px solid black;" colspan="2">nil</td><td style="border:2px solid black;">1</td></tr>
---   <tr><td style="border:2px solid black;" colspan="2">boolean</td><td style="border:2px solid black;">1</td></tr>
---   <tr><td style="border:2px solid black;" rowspan="2">handle</td><td style="border:2px solid black;">invalid (zero)</td><td style="border:2px solid black;">1</td></tr>
---   <tr><td style="border:2px solid black;">valid (nonzero)</td><td style="border:2px solid black;">1 + sizeof(int) = 5</td></tr>
---   <tr><td style="border:2px solid black;" rowspan="5">number</td><td style="border:2px solid black;">zero</td><td style="border:2px solid black;">1</td></tr>
---   <tr><td style="border:2px solid black;">char (integer -128 to 127)</td><td style="border:2px solid black;">1 + sizeof(char) = 2</td></tr>
---   <tr><td style="border:2px solid black;">short (integer -32768 to 32767)</td><td style="border:2px solid black;">1 + sizeof(short) = 3</td></tr>
---   <tr><td style="border:2px solid black;">int (integer)</td><td style="border:2px solid black;">1 + sizeof(int) = 5</td></tr>
---   <tr><td style="border:2px solid black;">double (non-integer)</td><td style="border:2px solid black;">1 + sizeof(double) = 9</td></tr>
---   <tr><td style="border:2px solid black;" rowspan="2">string</td><td style="border:2px solid black;">length &lt; 31</td><td style="border:2px solid black;">1 + length</td></tr>
---   <tr><td style="border:2px solid black;">length &gt;= 31</td><td style="border:2px solid black;">2 + length</td></tr>
---   <tr><td style="border:2px solid black;" rowspan="2">table</td><td style="border:2px solid black;">count &lt; 31</td><td style="border:2px solid black;">1 + count + size of keys and values</td></tr>
---   <tr><td style="border:2px solid black;">count &gt;= 31</td><td style="border:2px solid black;">2 + count + size of keys and values</td></tr>
---   <tr><td style="border:2px solid black;" rowspan="2">userdata</td><td style="border:2px solid black;">VECTOR_3D</td><td style="border:2px solid black;">1 + sizeof(VECTOR_3D) = 13</td></tr>
---   <tr><td style="border:2px solid black;">MAT_3D</td><td style="border:2px solid black;">1 + sizeof(REDUCED_MAT) = 12</td></tr>
--- </tbody></table>
--- @param to integer
--- @param type string
--- @vararg any
function M.Send(to, type, ...)
    --- @diagnostic disable-next-line: deprecated
    Send(to, type, ...);
end


local network_emulation = {};

--- Non non-network games just hard-wire it to trigger Receive
if not M.IsNetGame() then
--- [[START_IGNORE]]
    M.Send = function(to, type, ...)
        -- if the message is not broadcast or to self
        if to ~= nil and to ~= 0 and to ~= 1 then
            return;
        end
        
        table.insert(network_emulation, {to, type, {...}});
    end
-- [[END_IGNORE]]
end

local routines = {};

--- Register a coroutine to be executed each Update until it finishes.
--- @param fun thread|function Coroutine or function that returns nil|false when finished
function M.Defer(fun)
    routines[fun] = true;
end

hook.Add("Update", "_network_Update", function(dtime, ttime)
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
            local to = packet[1];
            local type = packet[2];
            local args = packet[3];
            --- @diagnostic disable-next-line: deprecated
            Receive(to, type, table.unpack(args));
        end
        network_emulation = {};
    end
end, config.get("hook_priority.Update.Network"));

logger.print(logger.LogLevel.DEBUG, nil, "_network Loaded");

return M;