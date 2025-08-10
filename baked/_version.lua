--- BZ98R LUA Extended API Version Utility.
---
--- @module '_version'
--- @author John "Nielk1" Klein

local api_version = "0.1.2"; -- API version of this module

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_version Loading");

local optional = require("_optional");
local bzcp_success, bzcp = optional("_bzcp");

--- The game version.
--
-- Example: "2.2.315"
-- @see ScriptUtils.GameVersion
-- @string game

--- The Lua version.
--
-- Example: "Lua 5.1"
-- @string lua

--- The version of this LUA Extended API.
--
-- Example: "0.1.1"
-- @string api

--- The BZCP version, if available.
--
-- Example: "0.3"
-- @string[opt] bzcp

--- The BZCP shim version, if available.
--
-- Example: 1
-- @field[opt] shim integer

--- Compare two version strings.
--- @tparam string version1 The first version string
--- @tparam string version2 The second version string
--- @treturn integer -1, 0, or 1 depending on the comparison result
--- @function Compare

--- @class _version
--- @field game string The game version, e.g. "2.2.315"
--- @field lua string The Lua version, e.g. "Lua 5.1"
--- @field api string The version of this LUA Extended API, e.g. "0.1.1"
--- @field bzcp? string The BZCP version, if available, e.g. "0.3"
--- @field shim? integer The BZCP shim version, if available, e.g. 1
local M = {};

local M_MT = {};
M_MT.__index = function(table, key)
    if key == "game" then return _G.GameVersion; end
    if key == "lua" then return _G._VERSION; end
    if key == "api" then return api_version; end
    if key == "bzcp" then
        if bzcp_success then
            return bzcp.version;
        else
            return nil; -- bzcp not available
        end
    end
    if key == "shim" then
        if bzcp_success then
            return bzcp.version_shim;
        else
            return nil; -- bzcp not available
        end
    end

    return rawget(table, key) or rawget(M_MT, key); -- move on to base (looking for functions)
end
M = setmetatable(M, M_MT);


-- Split version string into tokens: numbers and letters
local function version_tokens(version)
    local tokens = {}
    -- Split on dots, then further split each part into number/letter/number
    for part in version:gmatch("[^%.]+") do
        local i = 1
        while i <= #part do
            local num = part:match("^%d+", i)
            if num then
                table.insert(tokens, tonumber(num))
                i = i + #num
            else
                local letter = part:match("^%a", i)
                if letter then
                    table.insert(tokens, letter)
                    i = i + 1
                else
                    -- If not a digit or letter, skip (shouldn't happen)
                    i = i + 1
                end
            end
        end
    end
    return tokens
end

--- Compare two version strings.
--- This function compares two version strings in the format `d`, `d.d`, `d.d.d`, `d.d.d.d`, `d.d.d.da`, and `d.d.d.dad` where d is a digit and a is an alphanumeric character.
--- It returns -1 if version1 is less than version2, 1 if version1 is greater than version2, and 0 if they are equal.
--- @overload fun(version1: string, version2: string): integer
--- @param version1 string The first version string
--- @param version2 string The second version string
--- @return integer -1, 0, or 1 depending on the comparison result
function M.Compare(version1, version2)
    local t1 = version_tokens(version1)
    local t2 = version_tokens(version2)
    local len = math.max(#t1, #t2)
    for i = 1, len do
        local v1 = t1[i]
        local v2 = t2[i]
        if v1 == nil then return -1 end
        if v2 == nil then return 1 end
        if type(v1) == "number" and type(v2) == "number" then
            if v1 < v2 then return -1 end
            if v1 > v2 then return 1 end
        elseif type(v1) == "string" and type(v2) == "string" then
            if v1 < v2 then return -1 end
            if v1 > v2 then return 1 end
        else
            -- number < letter
            if type(v1) == "number" then return -1 end
            if type(v2) == "number" then return 1 end
        end
    end
    return 0
end

--- #section Utility - Core

--utility_module = setmetatable(utility_module, utility_module_meta);

logger.print(logger.LogLevel.DEBUG, nil, "_version Loaded");

return M;