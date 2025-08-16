--- BZ98R LUA Extended API Cheat.
---
--- General cheat code handler.
--- 
--- Register custom cheat codes and hook the "Cheat" event to detect them.
---
--- @module '_cheatcode'
--- @author John "Nielk1" Klein
--- ```lua
--- require("_cheatcode").CreateCode("BZSKIP", "apcann.wav", 0, 0, 255);
--- local hook = require("_hook");
--- local camera = require("_camera");
--- hook.Add("Cheat", "Mission:Cheat", function (cheat)
---     if cheat == "BZSKIP" then
---         local machine_state = mission_data.mission_states.StateMachines.main_objectives;
---         machine_state:SecondsHavePassed(); -- clear timer in case we were in one
---         camera.End(); -- protected camera exit that won't crash
---         machine_state:next(); -- move to the next state
---     end
--- end);
--- ```

local statemachine = require("_statemachine");
local hook = require("_hook");

--- Cheat key combo event
---
--- @diagnostic disable: undefined-doc-param
--- @hook Add CallAllNoReturn
--- @param cheat string The cheat code that was activated.
--- @alias Cheat fun(key: string)
--- @diagnostic enable: undefined-doc-param

--- @class _cheatcode
local _cheatcode = {};

--- Existing cheat codes
--- @type table<string, CheatCodeStateMachineIter>
local existing = {};

--- @class CheatCodeStateMachineIter : StateMachineIter
--- @field code string
--- @field index number
--- @field sound string?
--- @field r integer
--- @field g integer
--- @field b integer
--- @field once boolean?
--- @local

statemachine.Create("CheatCode",
    function (state, key)
        --- @cast state CheatCodeStateMachineIter
        print("CheatCode", state.code, state.index, key, "Ctrl+Shift+" .. state.code:sub(state.index, state.index));
        if key == "Ctrl+Shift+" .. state.code:sub(state.index, state.index) then
            state.index = state.index + 1;
            if state.index > #state.code then
                -- all keys pressed, trigger the cheat
                state.index = 1;
                ColorFade(1.0, 5.0, state.r, state.g, state.b);
                if state.sound then
                    StartSound(state.sound);
                end
                hook.CallAllNoReturn("Cheat", state.code);
                if state.once then
                    state:switch(nil);
                    existing[state.code] = nil;
                end
                return true;
            end
        else
            -- reset index if wrong key pressed
            state.index = 1;
        end
        return false;
    end
);

--- Create a new cheat code.
--- @param name string The name of the cheat code, must be all uppercase letters
--- @param sound string? Optional sound to play when the cheat is activated
--- @param r integer Color flash red component (0-255)
--- @param g integer Color flash green component (0-255)
--- @param b integer Color flash blue component (0-255)
--- @param once boolean? If true, the cheat can only be used once
--- @return _cheatcode
function _cheatcode.CreateCode(name, sound, r, g, b, once)
    if not name:match("^[A-Z]+$") then
        error("Cheat code name must be all uppercase letters.");
    end
    if existing[name] then
        error("Cheat code '" .. name .. "' already exists.");
    end
    local machine = statemachine.Start("CheatCode", nil, {
        code = name,
        index = 1,
        sound = sound,
        r = r,
        g = g,
        b = b,
        once = once or false
    });
    --- @cast machine CheatCodeStateMachineIter
    existing[name] = machine;
    return _cheatcode;
end

hook.Add("GameKey", "CheatCode:GameKey", function (key)
    for _, machine in pairs(existing) do
        local success, result = machine:run(key);
        --[[if success and result then
            -- if the cheat code was successfully triggered all other machines reset
            --- @todo consider removing this reset
            for _, machine2 in pairs(existing) do
                if machine2 ~= machine then
                    machine2.index = 1;
                end
            end
        end--]]
    end
end);

return _cheatcode;