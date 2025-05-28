local statemachine = require("_statemachine");
local hook = require("_hook");
local gameobject = require("_gameobject");
local bit = require("_bit");
local color = require("_color");

statemachine.Create("Cheat_BZRAVE",
    function (state, key) if key == "Ctrl+Shift+B" then state:next(); end end,
    function (state, key) if key == "Ctrl+Shift+Z" then state:next(); else state:switch(1); end end,
    function (state, key) if key == "Ctrl+Shift+R" then state:next(); else state:switch(1); end end,
    function (state, key) if key == "Ctrl+Shift+A" then state:next(); else state:switch(1); end end,
    function (state, key) if key == "Ctrl+Shift+V" then state:next(); else state:switch(1); end end,
    function (state, key) if key == "Ctrl+Shift+E" then
        --ColorFade(1.0, 5.0, 128, 0, 255);
        StartSound("grave00.wav");

        local player = gameobject.GetPlayer();
        if player and player:IsCraft() then
            player:GiveWeapon("gtechno", 0)
            player:GiveWeapon("gtechno", 1)
            player:GiveWeapon("gtechno", 2)
            player:GiveWeapon("gtechno", 3)
            player:GiveWeapon("gtechno", 4)
        end

        -- if this works properly the hookName and Cheat_BZRAVE_effect should be in a closure that the hook function has access to
        local hookName = "Mission:Update:Cheat_BZRAVE_effect_" .. tostring(GetTime());
        local Cheat_BZRAVE_effect = statemachine.Start("Cheat_BZRAVE_effect");
        hook.Add("Update", hookName, function (dtime, ttime)
            local success, retval = Cheat_BZRAVE_effect:run();
            if not success or retval then
                hook.Remove("Update", hookName);
            end
        end);

        state:switch(1);
        return true;
    else state:switch(1); end end
);
--- @class Cheat_BZRAVE_effect_state : StateMachineIter
--- @field rave_index number
statemachine.Create("Cheat_BZRAVE_effect",
    function (state)
        --- @cast state Cheat_BZRAVE_effect_state
        state.rave_index = 1;
        state:next();
        state:SecondsHavePassed(); -- make sure it's reset before we start a lap based usage
    end,
    { "color", function (state)
        --- @cast state Cheat_BZRAVE_effect_state
        if state:SecondsHavePassed(0.4, true) or state.rave_index == 1 then
            local rgba = color.RAVE_COLOR[state.rave_index];
            local r = bit.rshift(rgba, 24) -- Extract the red component
            local g = bit.band(bit.rshift(rgba, 16), 0xFF) -- Extract the green component
            local b = bit.band(bit.rshift(rgba, 8), 0xFF)  -- Extract the blue component

            ColorFade(1.0, 5.0, r, g, b);

            -- run through the rave color list once, which is as long as the music
            state.rave_index = state.rave_index + 1;
            if state.rave_index > #color.RAVE_COLOR then
                state:SecondsHavePassed(); -- probably not needed but just in case
                state:switch(nil);
                return true;
            end
        end
    end }
);
local Cheat_BZRAVE = statemachine.Start("Cheat_BZRAVE");
hook.Add("GameKey", "Mission:GameKey:Cheat_BZRAVE", function (key)
    local success, result = Cheat_BZRAVE:run(key);
    --if result then
    --    debugprint("BZRAVE stopping more hooks");
    --    return hook.AbortResult();
    --end
end);