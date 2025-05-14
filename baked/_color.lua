--- BZ98R LUA Extended API Color.
---
--- Crude custom type to make data not save/load exploiting the custom type system.
---
--- @module '_color'
--- @author John "Nielk1" Klein

debugprint("_color Loading");

local bit = require("_bit");

local M = {};

--- Convert human readable color names to BZ98R color labels.
--- @enum ColorLabel
M.ColorLabel = {
    Black       = "BLACK",     -- BLACK:     <div style="background-color: #000000; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">               ["Black"] = "BLACK"    </code></div>
    DarkGrey    = "DKGREY",    -- DKGREY:    <div style="background-color: #4C4C4C; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">            ["DarkGrey"] = "DKGREY"   </code></div>
    Grey        = "GREY",      -- GREY:      <div style="background-color: #999999; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">                ["Grey"] = "GREY"     </code></div>
    White       = "WHITE",     -- WHITE:     <div style="background-color: #FFFFFF; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">               ["White"] = "WHITE"    </code></div>
    Blue        = "BLUE",      -- BLUE:      <div style="background-color: #007FFF; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">                ["Blue"] = "BLUE"     </code></div>
    DarkBlue    = "DKBLUE",    -- DKBLUE:    <div style="background-color: #004C99; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">            ["DarkBlue"] = "DKBLUE"   </code></div>
    Green       = "GREEN",     -- GREEN:     <div style="background-color: #00FF00; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">               ["Green"] = "GREEN"    </code></div>
    DarkGreen   = "DKGREEN",   -- DKGREEN:   <div style="background-color: #009900; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">           ["DarkGreen"] = "DKGREEN"  </code></div>
    Yellow      = "YELLOW",    -- YELLOW:    <div style="background-color: #FFFF00; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">              ["Yellow"] = "YELLOW"   </code></div>
    DarkYellow  = "DKYELLOW",  -- DKYELLOW:  <div style="background-color: #999900; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">          ["DarkYellow"] = "DKYELLOW" </code></div>
    Red         = "RED",       -- RED:       <div style="background-color: #FF0000; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">                 ["Red"] = "RED"      </code></div>
    DarkRed     = "DKRED",     -- DKRED:     <div style="background-color: #990000; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">             ["DarkRed"] = "DKRED"    </code></div>

    Cyan        = "CYAN",      -- CYAN:      [2.2.315+] <div style="background-color: #00FFFF; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">2.2.315+         ["Cyan"] = "CYAN"     </code></div>
    DarkCyan    = "DKCYAN",    -- DKCYAN:    [2.2.315+] <div style="background-color: #009999; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">2.2.315+     ["DarkCyan"] = "DKCYAN"   </code></div>
    Magenta     = "MAGENTA",   -- MAGENTA:   [2.2.315+] <div style="background-color: #FF00FF; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">2.2.315+      ["Magenta"] = "MAGENTA"  </code></div>
    DarkMagenta = "DKMAGENTA", -- DKMAGENTA: [2.2.315+] <div style="background-color: #990099; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">2.2.315+  ["DarkMagenta"] = "DKMAGENTA"</code></div>

    ["Dark Grey"]    = "DKGREY",    -- DKGREY:
    ["Dark Blue"]    = "DKBLUE",    -- DKBLUE:
    ["Dark Green"]   = "DKGREEN",   -- DKGREEN:
    ["Dark Yellow"]  = "DKYELLOW",  -- DKYELLOW:
    ["Dark Red"]     = "DKRED",     -- DKRED:
    ["Dark Cyan"]    = "DKCYAN",    -- DKCYAN:    [2.2.315+]
    ["Dark Magenta"] = "DKMAGENTA", -- DKMAGENTA: [2.2.315+]
};

--- Convert BZ98R color labels to RGB color codes.
--- This probably isn't useful but it's here.
--- @enum ColorValues : ColorValue
M.ColorValues = {
    BLACK     = 0x000000FF, -- 0x000000FF: <div style="background-color: #000000; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">               ["BLACK"] = 0x000000FF</code></div>
    DKGREY    = 0x4C4C4CFF, -- 0x4C4C4CFF: <div style="background-color: #4C4C4C; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">              ["DKGREY"] = 0x4C4C4CFF</code></div>
    GREY      = 0x999999FF, -- 0x999999FF: <div style="background-color: #999999; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">                ["GREY"] = 0x999999FF</code></div>
    WHITE     = 0xFFFFFFFF, -- 0xFFFFFFFF: <div style="background-color: #FFFFFF; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">               ["WHITE"] = 0xFFFFFFFF</code></div>
    BLUE      = 0x007FFFFF, -- 0x007FFFFF: <div style="background-color: #007FFF; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">                ["BLUE"] = 0x007FFFFF</code></div>
    DKBLUE    = 0x004C99FF, -- 0x004C99FF: <div style="background-color: #004C99; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">              ["DKBLUE"] = 0x004C99FF</code></div>
    GREEN     = 0x00FF00FF, -- 0x00FF00FF: <div style="background-color: #00FF00; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">               ["GREEN"] = 0x00FF00FF</code></div>
    DKGREEN   = 0x009900FF, -- 0x009900FF: <div style="background-color: #009900; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">             ["DKGREEN"] = 0x009900FF</code></div>
    YELLOW    = 0xFFFF00FF, -- 0xFFFF00FF: <div style="background-color: #FFFF00; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">              ["YELLOW"] = 0xFFFF00FF</code></div>
    DKYELLOW  = 0x999900FF, -- 0x999900FF: <div style="background-color: #999900; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">            ["DKYELLOW"] = 0x999900FF</code></div>
    RED       = 0xFF0000FF, -- 0xFF0000FF: <div style="background-color: #FF0000; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">                 ["RED"] = 0xFF0000FF</code></div>
    DKRED     = 0x990000FF, -- 0x990000FF: <div style="background-color: #990000; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">               ["DKRED"] = 0x990000FF</code></div>
    
    CYAN      = 0x00FFFFFF, -- 0x00FFFFFF: [2.2.315+] <div style="background-color: #00FFFF; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">2.2.315+        ["CYAN"] = 0x00FFFFFF</code></div>
    DKCYAN    = 0x009999FF, -- 0x009999FF: [2.2.315+] <div style="background-color: #009999; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">2.2.315+      ["DKCYAN"] = 0x009999FF</code></div>
    MAGENTA   = 0xFF00FFFF, -- 0xFF00FFFF: [2.2.315+] <div style="background-color: #FF00FF; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">2.2.315+     ["MAGENTA"] = 0xFF00FFFF</code></div>
    DKMAGENTA = 0x990099FF, -- 0x990099FF: [2.2.315+] <div style="background-color: #990099; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">2.2.315+   ["DKMAGENTA"] = 0x990099FF</code></div>
};

--- RAVE GUN! color cycle.
--- Each color is represented as a hexadecimal number: 0xRRGGBBFF.
--- @type table<integer, ColorValue>
M.RAVE_COLOR = {
     [1] = 0xFF0000FF, -- 0xFF0000FF: <div style="background-color: #FF0000; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;"> [1] = 0xFF0000FF</code></div>
     [2] = 0xFF3300FF, -- 0xFF3300FF: <div style="background-color: #FF3300; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;"> [2] = 0xFF3300FF</code></div>
     [3] = 0xFF6600FF, -- 0xFF6600FF: <div style="background-color: #FF6600; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;"> [3] = 0xFF6600FF</code></div>
     [4] = 0xFF9900FF, -- 0xFF9900FF: <div style="background-color: #FF9900; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;"> [4] = 0xFF9900FF</code></div>
     [5] = 0xFFCC00FF, -- 0xFFCC00FF: <div style="background-color: #FFCC00; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;"> [5] = 0xFFCC00FF</code></div>
     [6] = 0xFFFF00FF, -- 0xFFFF00FF: <div style="background-color: #FFFF00; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;"> [6] = 0xFFFF00FF</code></div>
     [7] = 0xCCFF00FF, -- 0xCCFF00FF: <div style="background-color: #CCFF00; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;"> [7] = 0xCCFF00FF</code></div>
     [8] = 0x99FF00FF, -- 0x99FF00FF: <div style="background-color: #99FF00; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;"> [8] = 0x99FF00FF</code></div>
     [9] = 0x66FF00FF, -- 0x66FF00FF: <div style="background-color: #66FF00; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;"> [9] = 0x66FF00FF</code></div>
    [10] = 0x33FF00FF, -- 0x33FF00FF: <div style="background-color: #33FF00; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[10] = 0x33FF00FF</code></div>
    [11] = 0x00FF00FF, -- 0x00FF00FF: <div style="background-color: #00FF00; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[11] = 0x00FF00FF</code></div>
    [12] = 0x00FF33FF, -- 0x00FF33FF: <div style="background-color: #00FF33; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[12] = 0x00FF33FF</code></div>
    [13] = 0x00FF66FF, -- 0x00FF66FF: <div style="background-color: #00FF66; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[13] = 0x00FF66FF</code></div>
    [14] = 0x00FF99FF, -- 0x00FF99FF: <div style="background-color: #00FF99; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[14] = 0x00FF99FF</code></div>
    [15] = 0x00FFCCFF, -- 0x00FFCCFF: <div style="background-color: #00FFCC; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[15] = 0x00FFCCFF</code></div>
    [16] = 0x00FFFFFF, -- 0x00FFFFFF: <div style="background-color: #00FFFF; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[16] = 0x00FFFFFF</code></div>
    [17] = 0x00CCFFFF, -- 0x00CCFFFF: <div style="background-color: #00CCFF; color: #000; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[17] = 0x00CCFFFF</code></div>
    [18] = 0x0099FFFF, -- 0x0099FFFF: <div style="background-color: #0099FF; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[18] = 0x0099FFFF</code></div>
    [19] = 0x0066FFFF, -- 0x0066FFFF: <div style="background-color: #0066FF; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[19] = 0x0066FFFF</code></div>
    [20] = 0x0033FFFF, -- 0x0033FFFF: <div style="background-color: #0033FF; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[20] = 0x0033FFFF</code></div>
    [21] = 0x0000FFFF, -- 0x0000FFFF: <div style="background-color: #0000FF; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[21] = 0x0000FFFF</code></div>
    [22] = 0x3300FFFF, -- 0x3300FFFF: <div style="background-color: #3300FF; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[22] = 0x3300FFFF</code></div>
    [23] = 0x6600FFFF, -- 0x6600FFFF: <div style="background-color: #6600FF; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[23] = 0x6600FFFF</code></div>
    [24] = 0x9900FFFF, -- 0x9900FFFF: <div style="background-color: #9900FF; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[24] = 0x9900FFFF</code></div>
    [25] = 0xCC00FFFF, -- 0xCC00FFFF: <div style="background-color: #CC00FF; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[25] = 0xCC00FFFF</code></div>
    [26] = 0xFF00FFFF, -- 0xFF00FFFF: <div style="background-color: #FF00FF; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[26] = 0xFF00FFFF</code></div>
    [27] = 0xFF00CCFF, -- 0xFF00CCFF: <div style="background-color: #FF00CC; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[27] = 0xFF00CCFF</code></div>
    [28] = 0xFF0099FF, -- 0xFF0099FF: <div style="background-color: #FF0099; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[28] = 0xFF0099FF</code></div>
    [29] = 0xFF0066FF, -- 0xFF0066FF: <div style="background-color: #FF0066; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[29] = 0xFF0066FF</code></div>
    [30] = 0xFF0033FF, -- 0xFF0033FF: <div style="background-color: #FF0033; color: #FFF; text-align: center; display: block; float:right; margin-left: 4px; margin-top: 1px; width:  300px; height: 1em; line-height: 1em; border: 1px solid black;"><code style="white-space: pre;">[30] = 0xFF0033FF</code></div>
};

--- @param color ColorValue The RGBA color value (0xRRGGBBAA)
--- @return integer red The red component (0-255)
--- @return integer green The green component (0-255)
--- @return integer blue The blue component (0-255)
--- @return integer alpha The alpha component (0-255)
function M.SplitColorValue(color)
    -- Extract the red, green, and blue components from the RGBA color
    local r = bit.band(bit.rshift(color, 24), 0xFF);
    local g = bit.band(bit.rshift(color, 16), 0xFF);
    local b = bit.band(bit.rshift(color, 8 ), 0xFF);
    local a = bit.band(color, 0xFF);

    return r, g, b, a
end

--- Calculate the distance between two RGB colors.
--- This function calculates the squared distance between two RGB colors.
--- @param r1 integer The red component of the first color (0-255)
--- @param g1 integer The green component of the first color (0-255)
--- @param b1 integer The blue component of the first color (0-255)
--- @param r2 integer The red component of the second color (0-255)
--- @param g2 integer The green component of the second color (0-255)
--- @param b2 integer The blue component of the second color (0-255)
--- @return integer distance The squared distance between the two colors
local function color_distance(r1, g1, b1, r2, g2, b2)
    return (r1 - r2) ^ 2 + (g1 - g2) ^ 2 + (b1 - b2) ^ 2
end

--- Get the closest game color code based on RGB values.
--- This function takes RGB values and finds the closest game color code.
--- @param r integer The red component (0-255)
--- @param g integer The green component (0-255)
--- @param b integer The blue component (0-255)
--- @return ColorLabel color The closest game color code
local function RGBGetClosestGameColor(r, g, b)
    -- Find the closest color
    local closest_color = nil
    local closest_distance = math.huge -- Start with a very large distance
    for name, color in pairs(M.ColorValues) do
        local pallet_r, pallet_g, pallet_b = M.SplitColorValue(color);
        local dist = color_distance(r, g, b, pallet_r, pallet_g, pallet_b)
        if dist < closest_distance then
            closest_distance = dist
            closest_color = name
        end
    end

    return closest_color or "DKGREY"
end

--- Convert RGBA color to the closest game color code.
--- This function takes an RGBA color and finds the closest game color code.
--- @param color ColorValue|integer The RGBA color value (0xRRGGBBAA)
--- @return ColorLabel color The closest game color code
function M.GetClosestColorCode(color)
    -- Extract the red, green, and blue components from the RGBA color
    local r, g, b = M.SplitColorValue(color);

    -- Convert the RGB values to an ANSI 256 color code
    return RGBGetClosestGameColor(r, g, b);
end

-------------------------------------------------------------------------------
-- Ansi Color Escape Codes
-------------------------------------------------------------------------------
-- @section

--- Ansi color codes for terminal output sorted by game color codes.
--- @type table<ColorLabel, string>
--- @enum AnsiColorEscapeMap
M.AnsiColorEscapeMap = {
    RESET     = "\27[0m",
    _         = "\27[0m",
    BLACK     = "\27[22;30m",
    DKGREY    = "\27[2;37m",
    GREY      = "\27[22;37m",
    WHITE     = "\27[97m",
    BLUE      = "\27[22;34m",
    DKBLUE    = "\27[2;34m",
    GREEN     = "\27[22;32m",
    DKGREEN   = "\27[2;32m",
    YELLOW    = "\27[22;33m",
    DKYELLOW  = "\27[2;33m",
    RED       = "\27[22;31m",
    DKRED     = "\27[2;31m",
    CYAN      = "\27[22;96m",
    DKCYAN    = "\27[22;36m",
    MAGENTA   = "\27[22;95m",
    DKMAGENTA = "\27[2;95m",
};

--- @param r integer The red component (0-255)
--- @param g integer The green component (0-255)
--- @param b integer The blue component (0-255)
--- @return integer closest_color The closest ANSI 256 color code (0-255)
local function Ansi24to256(r, g, b)
    -- Define the 6x6x6 RGB color cube values
    local color_cube = {0, 95, 135, 175, 215, 255}

    -- Define the grayscale range
    local grayscale = {}
    for i = 0, 23 do
        grayscale[i + 1] = 8 + i * 10
    end

    -- Helper function to calculate the Euclidean distance
    local function distance(r1, g1, b1, r2, g2, b2)
        return (r1 - r2) ^ 2 + (g1 - g2) ^ 2 + (b1 - b2) ^ 2
    end

    -- Find the closest match in the 6x6x6 color cube
    local closest_color = nil
    local closest_distance = math.huge
    for r_index = 1, #color_cube do
        for g_index = 1, #color_cube do
            for b_index = 1, #color_cube do
                local cr, cg, cb = color_cube[r_index], color_cube[g_index], color_cube[b_index]
                local dist = distance(r, g, b, cr, cg, cb)
                if dist < closest_distance then
                    closest_distance = dist
                    closest_color = 16 + (r_index - 1) * 36 + (g_index - 1) * 6 + (b_index - 1)
                end
            end
        end
    end

    -- Find the closest match in the grayscale range
    for i, gray in ipairs(grayscale) do
        local dist = distance(r, g, b, gray, gray, gray)
        if dist < closest_distance then
            closest_distance = dist
            closest_color = 232 + (i - 1)
        end
    end

    if closest_color == nil then
        closest_color = 0 -- Default to black if no match found
    end
    return closest_color
end

--- Convert RGBA color to ANSI 256 color escape code.
--- This function takes an RGBA color and converts it to an ANSI 256 color code.
--- It uses a color cube and grayscale range to find the closest match.
--- @param color ColorValue The RGBA color value (0xRRGGBBAA)
--- @return integer pallet_index The ANSI 256 color code (0-255)
function M.RGBAtoAnsi256(color)
    -- Extract the red, green, and blue components from the RGBA color
    local r = bit.band(bit.rshift(color, 24), 0xFF);
    local g = bit.band(bit.rshift(color, 16), 0xFF);
    local b = bit.band(bit.rshift(color, 8 ), 0xFF);

    -- Convert the RGB values to an ANSI 256 color code
    return Ansi24to256(r, g, b)
end

--- Convert RGBA color to ANSI 256 color escape code.
--- This function takes an RGBA color and converts it to an ANSI 256 color escape code.
--- @param color ColorValue|integer The RGBA color value (0xRRGGBBAA)
--- @return string escape The ANSI 256 color escape code
function M.RGBAtoAnsi256Escape(color)
    return "\27[38;5;" .. M.RGBAtoAnsi256(color) .. "m"
end

--- Convert RGBA color to ANSI 24-bit color escape code.
--- This function takes an RGBA color and converts it to an ANSI 24-bit color escape code.
--- @param color ColorValue|integer The RGBA color value (0xRRGGBBAA)
--- @return string escape The ANSI 24-bit color escape code
function M.RGBAtoAnsi24Escape(color)
    -- Extract the red, green, and blue components from the RGBA color
    local r, g, b = M.SplitColorValue(color);

    return "\27[38;2;"..r..";"..g..";"..b.."m"
end




debugprint("_color Loaded");

return M;

-- Late aliases to prevent LDoc confusion

--- @alias ColorValue integer
