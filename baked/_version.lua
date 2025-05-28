--- BZ98R LUA Extended API Version Utility.
---
--- @module '_version'
--- @author John "Nielk1" Klein

local debugprint = debugprint or function(...) end;

debugprint("_version Loading");

local M = {};

local version_pattern = "^(%d+)(%.(%d+)(%.(%d+)(%.(%d+)((%a)(%d+)?)?)?)?)?$";

--- Compare two version strings.
--- This function compares two version strings in the format `d`, `d.d`, `d.d.d`, `d.d.d.d`, `d.d.d.da`, and `d.d.d.dad` where d is a digit and a is an alphanumeric character.
--- It returns -1 if version1 is less than version2, 1 if version1 is greater than version2, and 0 if they are equal.
--- @param version1 string The first version string
--- @param version2 string The second version string
--- @return number -1, 0, or 1 depending on the comparison result
function M.Compare(version1, version2)
    local g1_01, g1_02, g1_03, g1_04, g1_05, g1_06, g1_07, g1_08, g1_09, g1_10 = version1:match(version_pattern)
    local g2_01, g2_02, g2_03, g2_04, g2_05, g2_06, g2_07, g2_08, g2_09, g2_10 = version2:match(version_pattern)

    local captures = {
        {'d', g1_01, g2_01}, -- (d).d.d.dad
        {' ', g1_02, g2_02}, -- d(.d.d.dad)
        {'d', g1_03, g2_03}, -- d.(d).d.dad
        {' ', g1_04, g2_04}, -- d.d(.d.dad)
        {'d', g1_05, g2_05}, -- d.d.(d).dad
        {' ', g1_06, g2_06}, -- d.d.d(.dad)
        {'d', g1_07, g2_07}, -- d.d.d.(d)ad
        {' ', g1_08, g2_08}, -- d.d.d.d(ad)
        {'a', g1_09, g2_09}, -- d.d.d.d(a)d
        {'d', g1_10, g2_10}, -- d.d.d.da(d)
    }

    for i = 1, #captures do
        local type = captures[i][1];
        if type == 'd' then
            local v1 = tonumber(captures[i][2] or -1); -- version1 value
            local v2 = tonumber(captures[i][3] or -1); -- version2 value
            if v1 < v2 then return -1 end
            if v1 > v2 then return 1 end
        end
        if type == 'a' then
            local v1 = captures[i][2] or ""; -- version1 value
            local v2 = captures[i][3] or ""; -- version2 value
            if v1 < v2 then return -1 end
            if v1 > v2 then return 1 end
        end
    end
    return 0
end

-------------------------------------------------------------------------------
-- Utility - Core
-------------------------------------------------------------------------------
-- @section

--utility_module = setmetatable(utility_module, utility_module_meta);

debugprint("_version Loaded");

return M;