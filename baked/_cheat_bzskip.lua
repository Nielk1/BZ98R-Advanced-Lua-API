--- BZ98R LUA Extended API Cheat.
---
--- BZSKIP cheat
---
--- @module '_cheat_bzskip'
--- @author John "Nielk1" Klein
--- ```lua
--- require("_cheat_bzrave");
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

statemachine.Create("Cheat_BZSKIP",
    function (state, key) if key == "Ctrl+Shift+B" then state:next(); end end,
    function (state, key) if key == "Ctrl+Shift+Z" then state:next(); else state:switch(1); end end,
    function (state, key) if key == "Ctrl+Shift+S" then state:next(); else state:switch(1); end end,
    function (state, key) if key == "Ctrl+Shift+K" then state:next(); else state:switch(1); end end,
    function (state, key) if key == "Ctrl+Shift+I" then state:next(); else state:switch(1); end end,
    function (state, key) if key == "Ctrl+Shift+P" then
        ColorFade(1.0, 5.0, 0, 0, 255);
        StartSound("apcann.wav");

        --[[
        local machine_state = mission_data.mission_states.StateMachines.main_objectives;
        --- @cast machine_state StateMachineIter
        machine_state:SecondsHavePassed(); -- clear timer in case we were in one
        --CameraFinish(); -- clearing a camera when there is none will crash
        machine_state:next(); -- move to the next state
        ]]

        hook.CallAllNoReturn("Cheat", "BZSKIP");

        state:switch(1);
        return true;
    else state:switch(1); end end
);
local Cheat_BZSKIP = statemachine.Start("Cheat_BZSKIP");
hook.Add("GameKey", "Mission:GameKey:Cheat_BZSKIP", function (key)
    local success, result = Cheat_BZSKIP:run(key);
    --if result then
    --    logger.print(logger.LogLevel.DEBUG, nil, "BZSKIP stopping more hooks");
    --    return hook.AbortResult();
    --end
end);