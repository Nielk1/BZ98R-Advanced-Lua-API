--- BZ98R LUA Extended API Color.
---
--- Collection of color enumerations and functions.
---
--- @module '_color'
--- @author John "Nielk1" Klein

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_color Loading");

--- @class _color
local M = {};

--- Convert human readable color names to BZ98R color labels.
--- @enum EColorLabel
local EColorLabel = {
    Black       = "BLACK",     -- <div class="colorbox" style="background-color: #000000; color: #FFF;"></div>
    DarkGrey    = "DKGREY",    -- <div class="colorbox" style="background-color: #4C4C4C; color: #FFF;"></div>
    Grey        = "GREY",      -- <div class="colorbox" style="background-color: #999999; color: #000;"></div>
    White       = "WHITE",     -- <div class="colorbox" style="background-color: #FFFFFF; color: #000;"></div>
    Blue        = "BLUE",      -- <div class="colorbox" style="background-color: #007FFF; color: #FFF;"></div>
    DarkBlue    = "DKBLUE",    -- <div class="colorbox" style="background-color: #004C99; color: #FFF;"></div>
    Green       = "GREEN",     -- <div class="colorbox" style="background-color: #00FF00; color: #000;"></div>
    DarkGreen   = "DKGREEN",   -- <div class="colorbox" style="background-color: #009900; color: #FFF;"></div>
    Yellow      = "YELLOW",    -- <div class="colorbox" style="background-color: #FFFF00; color: #000;"></div>
    DarkYellow  = "DKYELLOW",  -- <div class="colorbox" style="background-color: #999900; color: #FFF;"></div>
    Red         = "RED",       -- <div class="colorbox" style="background-color: #FF0000; color: #FFF;"></div>
    DarkRed     = "DKRED",     -- <div class="colorbox" style="background-color: #990000; color: #FFF;"></div>

    Cyan        = "CYAN",      -- {VERSION 2.2.315+} <div class="colorbox" style="background-color: #00FFFF; color: #000;"></div>
    DarkCyan    = "DKCYAN",    -- {VERSION 2.2.315+} <div class="colorbox" style="background-color: #009999; color: #FFF;"></div>
    Magenta     = "MAGENTA",   -- {VERSION 2.2.315+} <div class="colorbox" style="background-color: #FF00FF; color: #000;"></div>
    DarkMagenta = "DKMAGENTA", -- {VERSION 2.2.315+} <div class="colorbox" style="background-color: #990099; color: #FFF;"></div>

    BLACK     = "BLACK",     -- <div class="colorbox" style="background-color: #000000; color: #FFF;"></div>
    DKGREY    = "DKGREY",    -- <div class="colorbox" style="background-color: #4C4C4C; color: #FFF;"></div>
    GREY      = "GREY",      -- <div class="colorbox" style="background-color: #999999; color: #000;"></div>
    WHITE     = "WHITE",     -- <div class="colorbox" style="background-color: #FFFFFF; color: #000;"></div>
    BLUE      = "BLUE",      -- <div class="colorbox" style="background-color: #007FFF; color: #FFF;"></div>
    DKBLUE    = "DKBLUE",    -- <div class="colorbox" style="background-color: #004C99; color: #FFF;"></div>
    GREEN     = "GREEN",     -- <div class="colorbox" style="background-color: #00FF00; color: #000;"></div>
    DKGREEN   = "DKGREEN",   -- <div class="colorbox" style="background-color: #009900; color: #FFF;"></div>
    YELLOW    = "YELLOW",    -- <div class="colorbox" style="background-color: #FFFF00; color: #000;"></div>
    DKYELLOW  = "DKYELLOW",  -- <div class="colorbox" style="background-color: #999900; color: #FFF;"></div>
    RED       = "RED",       -- <div class="colorbox" style="background-color: #FF0000; color: #FFF;"></div>
    DKRED     = "DKRED",     -- <div class="colorbox" style="background-color: #990000; color: #FFF;"></div>
    
    CYAN      = "CYAN",      -- {VERSION 2.2.315+} <div class="colorbox" style="background-color: #00FFFF; color: #000;"></div>
    DKCYAN    = "DKCYAN",    -- {VERSION 2.2.315+} <div class="colorbox" style="background-color: #009999; color: #FFF;"></div>
    MAGENTA   = "MAGENTA",   -- {VERSION 2.2.315+} <div class="colorbox" style="background-color: #FF00FF; color: #000;"></div>
    DKMAGENTA = "DKMAGENTA", -- {VERSION 2.2.315+} <div class="colorbox" style="background-color: #990099; color: #FFF;"></div>

    ["Dark Grey"]    = "DKGREY",    -- <div class="colorbox" style="background-color: #4C4C4C; color: #FFF;"></div>
    ["Dark Blue"]    = "DKBLUE",    -- <div class="colorbox" style="background-color: #004C99; color: #FFF;"></div>
    ["Dark Green"]   = "DKGREEN",   -- <div class="colorbox" style="background-color: #009900; color: #FFF;"></div>
    ["Dark Yellow"]  = "DKYELLOW",  -- <div class="colorbox" style="background-color: #999900; color: #FFF;"></div>
    ["Dark Red"]     = "DKRED",     -- <div class="colorbox" style="background-color: #990000; color: #FFF;"></div>
    ["Dark Cyan"]    = "DKCYAN",    -- {VERSION 2.2.315+} <div class="colorbox" style="background-color: #009999; color: #FFF;"></div>
    ["Dark Magenta"] = "DKMAGENTA", -- {VERSION 2.2.315+} <div class="colorbox" style="background-color: #990099; color: #FFF;"></div>
};

--- @alias ColorValue integer

--- Convert human readable color names to BZ98R color labels.
M.ColorLabel = EColorLabel;

--- Convert BZ98R color labels to RGB color codes.
--- This probably isn't useful but it's here.
--- @type table<string, ColorValue>
M.ColorValues = {
    BLACK     = 0x000000FF, -- <div class="colorbox" style="background-color: #000000; color: #FFF;"></div>
    DKGREY    = 0x4C4C4CFF, -- <div class="colorbox" style="background-color: #4C4C4C; color: #FFF;"></div>
    GREY      = 0x999999FF, -- <div class="colorbox" style="background-color: #999999; color: #000;"></div>
    WHITE     = 0xFFFFFFFF, -- <div class="colorbox" style="background-color: #FFFFFF; color: #000;"></div>
    BLUE      = 0x007FFFFF, -- <div class="colorbox" style="background-color: #007FFF; color: #FFF;"></div>
    DKBLUE    = 0x004C99FF, -- <div class="colorbox" style="background-color: #004C99; color: #FFF;"></div>
    GREEN     = 0x00FF00FF, -- <div class="colorbox" style="background-color: #00FF00; color: #000;"></div>
    DKGREEN   = 0x009900FF, -- <div class="colorbox" style="background-color: #009900; color: #FFF;"></div>
    YELLOW    = 0xFFFF00FF, -- <div class="colorbox" style="background-color: #FFFF00; color: #000;"></div>
    DKYELLOW  = 0x999900FF, -- <div class="colorbox" style="background-color: #999900; color: #FFF;"></div>
    RED       = 0xFF0000FF, -- <div class="colorbox" style="background-color: #FF0000; color: #FFF;"></div>
    DKRED     = 0x990000FF, -- <div class="colorbox" style="background-color: #990000; color: #FFF;"></div>
    
    CYAN      = 0x00FFFFFF, -- {VERSION 2.2.315+} <div class="colorbox" style="background-color: #00FFFF; color: #000;"></div>
    DKCYAN    = 0x009999FF, -- {VERSION 2.2.315+} <div class="colorbox" style="background-color: #009999; color: #FFF;"></div>
    MAGENTA   = 0xFF00FFFF, -- {VERSION 2.2.315+} <div class="colorbox" style="background-color: #FF00FF; color: #000;"></div>
    DKMAGENTA = 0x990099FF, -- {VERSION 2.2.315+} <div class="colorbox" style="background-color: #990099; color: #FFF;"></div>
};

--- RAVE GUN! color cycle.
--- Each color is represented as a hexadecimal number: 0xRRGGBBFF.
--- <div class="colorbox" style="background-color: #FF0000; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #FF3300; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #FF6600; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #FF9900; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #FFCC00; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #FFFF00; color: #000;"></div>
--- <div class="colorbox" style="background-color: #CCFF00; color: #000;"></div>
--- <div class="colorbox" style="background-color: #99FF00; color: #000;"></div>
--- <div class="colorbox" style="background-color: #66FF00; color: #000;"></div>
--- <div class="colorbox" style="background-color: #33FF00; color: #000;"></div>
--- <div class="colorbox" style="background-color: #00FF00; color: #000;"></div>
--- <div class="colorbox" style="background-color: #00FF33; color: #000;"></div>
--- <div class="colorbox" style="background-color: #00FF66; color: #000;"></div>
--- <div class="colorbox" style="background-color: #00FF99; color: #000;"></div>
--- <div class="colorbox" style="background-color: #00FFCC; color: #000;"></div>
--- <div class="colorbox" style="background-color: #00FFFF; color: #000;"></div>
--- <div class="colorbox" style="background-color: #00CCFF; color: #000;"></div>
--- <div class="colorbox" style="background-color: #0099FF; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #0066FF; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #0033FF; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #0000FF; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #3300FF; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #6600FF; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #9900FF; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #CC00FF; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #FF00FF; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #FF00CC; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #FF0099; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #FF0066; color: #FFF;"></div>
--- <div class="colorbox" style="background-color: #FF0033; color: #FFF;"></div>
--- @type ColorValue[]
M.RAVE_COLOR = {
     [1] = 0xFF0000FF, -- <div class="colorbox" style="background-color: #FF0000; color: #FFF;"></div>
     [2] = 0xFF3300FF, -- <div class="colorbox" style="background-color: #FF3300; color: #FFF;"></div>
     [3] = 0xFF6600FF, -- <div class="colorbox" style="background-color: #FF6600; color: #FFF;"></div>
     [4] = 0xFF9900FF, -- <div class="colorbox" style="background-color: #FF9900; color: #FFF;"></div>
     [5] = 0xFFCC00FF, -- <div class="colorbox" style="background-color: #FFCC00; color: #FFF;"></div>
     [6] = 0xFFFF00FF, -- <div class="colorbox" style="background-color: #FFFF00; color: #000;"></div>
     [7] = 0xCCFF00FF, -- <div class="colorbox" style="background-color: #CCFF00; color: #000;"></div>
     [8] = 0x99FF00FF, -- <div class="colorbox" style="background-color: #99FF00; color: #000;"></div>
     [9] = 0x66FF00FF, -- <div class="colorbox" style="background-color: #66FF00; color: #000;"></div>
    [10] = 0x33FF00FF, -- <div class="colorbox" style="background-color: #33FF00; color: #000;"></div>
    [11] = 0x00FF00FF, -- <div class="colorbox" style="background-color: #00FF00; color: #000;"></div>
    [12] = 0x00FF33FF, -- <div class="colorbox" style="background-color: #00FF33; color: #000;"></div>
    [13] = 0x00FF66FF, -- <div class="colorbox" style="background-color: #00FF66; color: #000;"></div>
    [14] = 0x00FF99FF, -- <div class="colorbox" style="background-color: #00FF99; color: #000;"></div>
    [15] = 0x00FFCCFF, -- <div class="colorbox" style="background-color: #00FFCC; color: #000;"></div>
    [16] = 0x00FFFFFF, -- <div class="colorbox" style="background-color: #00FFFF; color: #000;"></div>
    [17] = 0x00CCFFFF, -- <div class="colorbox" style="background-color: #00CCFF; color: #000;"></div>
    [18] = 0x0099FFFF, -- <div class="colorbox" style="background-color: #0099FF; color: #FFF;"></div>
    [19] = 0x0066FFFF, -- <div class="colorbox" style="background-color: #0066FF; color: #FFF;"></div>
    [20] = 0x0033FFFF, -- <div class="colorbox" style="background-color: #0033FF; color: #FFF;"></div>
    [21] = 0x0000FFFF, -- <div class="colorbox" style="background-color: #0000FF; color: #FFF;"></div>
    [22] = 0x3300FFFF, -- <div class="colorbox" style="background-color: #3300FF; color: #FFF;"></div>
    [23] = 0x6600FFFF, -- <div class="colorbox" style="background-color: #6600FF; color: #FFF;"></div>
    [24] = 0x9900FFFF, -- <div class="colorbox" style="background-color: #9900FF; color: #FFF;"></div>
    [25] = 0xCC00FFFF, -- <div class="colorbox" style="background-color: #CC00FF; color: #FFF;"></div>
    [26] = 0xFF00FFFF, -- <div class="colorbox" style="background-color: #FF00FF; color: #FFF;"></div>
    [27] = 0xFF00CCFF, -- <div class="colorbox" style="background-color: #FF00CC; color: #FFF;"></div>
    [28] = 0xFF0099FF, -- <div class="colorbox" style="background-color: #FF0099; color: #FFF;"></div>
    [29] = 0xFF0066FF, -- <div class="colorbox" style="background-color: #FF0066; color: #FFF;"></div>
    [30] = 0xFF0033FF, -- <div class="colorbox" style="background-color: #FF0033; color: #FFF;"></div>
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

--- @param r integer The red component (0-255)
--- @param g integer The green component (0-255)
--- @param b integer The blue component (0-255)
--- @param a integer The alpha component (0-255)
--- @return ColorValue color The merged color value (0xRRGGBBAA)
function M.MergeColorValue(r, g, b, a)
    -- Merge the red, green, blue, and alpha components into a single color value
    return bit.lshift(r, 24) + bit.lshift(g, 16) + bit.lshift(b, 8) + (a or 0x000000FF);
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

--- Ansi color codes for terminal output sorted by game color codes.
--- @type table<ColorLabel, string>
M.AnsiColorEscapeMap = {
    RESET     = "\27[0m",
    _         = "\27[0m",
    BLACK     = "\27[30m",
    DKGREY    = "\27[90m",
    GREY      = "\27[37m",
    WHITE     = "\27[97m",
    BLUE      = "\27[94m",
    DKBLUE    = "\27[34m",
    GREEN     = "\27[92m",
    DKGREEN   = "\27[32m",
    YELLOW    = "\27[93m",
    DKYELLOW  = "\27[33m",
    RED       = "\27[91m",
    DKRED     = "\27[31m",
    CYAN      = "\27[96m",
    DKCYAN    = "\27[36m",
    MAGENTA   = "\27[95m",
    DKMAGENTA = "\27[35m",
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


-- Print Color Tests
logger.print(logger.LogLevel.DEBUG, nil, "Game Color Pallet Test");

logger.print(logger.LogLevel.DEBUG, nil, "COLOR TEST Exact ["..
    M.RGBAtoAnsi24Escape(M.ColorValues.BLACK    ).."██"..
    M.RGBAtoAnsi24Escape(M.ColorValues.DKGREY   ).."██"..
    M.RGBAtoAnsi24Escape(M.ColorValues.GREY     ).."██"..
    M.RGBAtoAnsi24Escape(M.ColorValues.WHITE    ).."██"..
    M.RGBAtoAnsi24Escape(M.ColorValues.BLUE     ).."██"..
    M.RGBAtoAnsi24Escape(M.ColorValues.DKBLUE   ).."██"..
    M.RGBAtoAnsi24Escape(M.ColorValues.GREEN    ).."██"..
    M.RGBAtoAnsi24Escape(M.ColorValues.DKGREEN  ).."██"..
    M.RGBAtoAnsi24Escape(M.ColorValues.YELLOW   ).."██"..
    M.RGBAtoAnsi24Escape(M.ColorValues.DKYELLOW ).."██"..
    M.RGBAtoAnsi24Escape(M.ColorValues.RED      ).."██"..
    M.RGBAtoAnsi24Escape(M.ColorValues.DKRED    ).."██"..
    M.RGBAtoAnsi24Escape(M.ColorValues.CYAN     ).."██"..
    M.RGBAtoAnsi24Escape(M.ColorValues.DKCYAN   ).."██"..
    M.RGBAtoAnsi24Escape(M.ColorValues.MAGENTA  ).."██"..
    M.RGBAtoAnsi24Escape(M.ColorValues.DKMAGENTA).."██"..
    M.AnsiColorEscapeMap._.."]");

logger.print(logger.LogLevel.DEBUG, nil, "COLOR TEST 256   ["..
    M.RGBAtoAnsi256Escape(M.ColorValues.BLACK    ).."██"..
    M.RGBAtoAnsi256Escape(M.ColorValues.DKGREY   ).."██"..
    M.RGBAtoAnsi256Escape(M.ColorValues.GREY     ).."██"..
    M.RGBAtoAnsi256Escape(M.ColorValues.WHITE    ).."██"..
    M.RGBAtoAnsi256Escape(M.ColorValues.BLUE     ).."██"..
    M.RGBAtoAnsi256Escape(M.ColorValues.DKBLUE   ).."██"..
    M.RGBAtoAnsi256Escape(M.ColorValues.GREEN    ).."██"..
    M.RGBAtoAnsi256Escape(M.ColorValues.DKGREEN  ).."██"..
    M.RGBAtoAnsi256Escape(M.ColorValues.YELLOW   ).."██"..
    M.RGBAtoAnsi256Escape(M.ColorValues.DKYELLOW ).."██"..
    M.RGBAtoAnsi256Escape(M.ColorValues.RED      ).."██"..
    M.RGBAtoAnsi256Escape(M.ColorValues.DKRED    ).."██"..
    M.RGBAtoAnsi256Escape(M.ColorValues.CYAN     ).."██"..
    M.RGBAtoAnsi256Escape(M.ColorValues.DKCYAN   ).."██"..
    M.RGBAtoAnsi256Escape(M.ColorValues.MAGENTA  ).."██"..
    M.RGBAtoAnsi256Escape(M.ColorValues.DKMAGENTA).."██"..
    M.AnsiColorEscapeMap._.."]");

logger.print(logger.LogLevel.DEBUG, nil, "COLOR TEST 16p   ["..
    M.AnsiColorEscapeMap.BLACK    .."██"..
    M.AnsiColorEscapeMap.DKGREY   .."██"..
    M.AnsiColorEscapeMap.GREY     .."██"..
    M.AnsiColorEscapeMap.WHITE    .."██"..
    M.AnsiColorEscapeMap.BLUE     .."██"..
    M.AnsiColorEscapeMap.DKBLUE   .."██"..
    M.AnsiColorEscapeMap.GREEN    .."██"..
    M.AnsiColorEscapeMap.DKGREEN  .."██"..
    M.AnsiColorEscapeMap.YELLOW   .."██"..
    M.AnsiColorEscapeMap.DKYELLOW .."██"..
    M.AnsiColorEscapeMap.RED      .."██"..
    M.AnsiColorEscapeMap.DKRED    .."██"..
    M.AnsiColorEscapeMap.CYAN     .."██"..
    M.AnsiColorEscapeMap.DKCYAN   .."██"..
    M.AnsiColorEscapeMap.MAGENTA  .."██"..
    M.AnsiColorEscapeMap.DKMAGENTA.."██"..
    M.AnsiColorEscapeMap._.."]");

logger.print(logger.LogLevel.DEBUG, nil, "Rave Color Pallet Test");

local rave_exact = "";
for i = 1, #M.RAVE_COLOR do
    rave_exact = rave_exact..M.RGBAtoAnsi24Escape(M.RAVE_COLOR[i]).."█";
end
logger.print(logger.LogLevel.DEBUG, nil, "COLOR TEST RAVE Exact    ["..rave_exact..M.AnsiColorEscapeMap._.."]");

local rave_256 = "";
for i = 1, #M.RAVE_COLOR do
    rave_256 = rave_256..M.RGBAtoAnsi256Escape(M.RAVE_COLOR[i]).."█";
end
logger.print(logger.LogLevel.DEBUG, nil, "COLOR TEST RAVE 256      ["..rave_256..M.AnsiColorEscapeMap._.."]");

local rave_16Map = "";
for i = 1, #M.RAVE_COLOR do
    rave_16Map = rave_16Map..M.RGBAtoAnsi24Escape(M.ColorValues[M.GetClosestColorCode(M.RAVE_COLOR[i])]).."█";
end
logger.print(logger.LogLevel.DEBUG, nil, "COLOR TEST RAVE 16->Exact["..rave_16Map..M.AnsiColorEscapeMap._.."]");

local rave_16 = "";
for i = 1, #M.RAVE_COLOR do
    rave_16 = rave_16..M.AnsiColorEscapeMap[M.GetClosestColorCode(M.RAVE_COLOR[i])].."█";
end
logger.print(logger.LogLevel.DEBUG, nil, "COLOR TEST RAVE 16p      ["..rave_16..M.AnsiColorEscapeMap._.."]");




logger.print(logger.LogLevel.DEBUG, nil, "_color Loaded");

return M;