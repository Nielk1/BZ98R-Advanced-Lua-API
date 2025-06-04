--- BZ98R LUA Extended API pure lua bit library.
---
--- https://github.com/AlberTajuelo/bitop-lua/tree/master
---
--- @module '_bit'
---
--- MIT License
---
--- Copyright (c).    Licensed under the same terms as Lua (MIT).
---
--- Permission is hereby granted, free of charge, to any person obtaining a copy
--- of this software and associated documentation files (the "Software"), to deal
--- in the Software without restriction, including without limitation the rights
--- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--- copies of the Software, and to permit persons to whom the Software is
--- furnished to do so, subject to the following conditions:
---
--- The above copyright notice and this permission notice shall be included in all
--- copies or substantial portions of the Software.
---
--- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--- SOFTWARE.
---
--- @usage local bit = require("_bit");
--- local bit32.bor(1, 2) -- returns 3
---
--- @usage local bit32 = require("_bit").bit32;
--- local bit.bor(1, 2, 4) -- returns 7
---

local M = {}

local floor = math.floor

local MOD = 2^32
local MODM = MOD-1

local function memoize(f)

    local mt = {}
    local t = setmetatable({}, mt)

    function mt:__index(k)
        local v = f(k)
        t[k] = v
        return v
    end

    return t
end

local function make_bitop_uncached(t, m)
    local function bitop(a, b)
        local res,p = 0,1
        while a ~= 0 and b ~= 0 do
            local am, bm = a%m, b%m
            res = res + t[am][bm]*p
            a = (a - am) / m
            b = (b - bm) / m
            p = p*m
        end
        res = res + (a+b) * p
        return res
    end
    return bitop
end

local function make_bitop(t)
    local op1 = make_bitop_uncached(t, 2^1)
    local op2 = memoize(function(a)
        return memoize(function(b)
            return op1(a, b)
        end)
    end)
    return make_bitop_uncached(op2, 2^(t.n or 1))
end

--- Normalizes a number to the numeric range for bit operations and returns it.
--- This function is usually not needed since all bit operations already normalize all of their input arguments.
--- @param x integer
--- @return integer
function M.tobit(x)
    return x % 2^32
end

--- Returns the bitwise xor of its arguments.
--- @overload fun(a: integer, b: integer): integer
--- @diagnostic disable: undefined-doc-param
--- @param a integer
--- @param b integer
--- @return integer
--- @diagnostic enable: undefined-doc-param
--- @function bxor(a,b)
M.bxor = make_bitop {[0]={[0]=0,[1]=1},[1]={[0]=1,[1]=0}, n=4}
local bxor = M.bxor

--- Returns the bitwise xor of its arguments.
-- @tparam integer a
-- @tparam integer b
-- @treturn integer
-- @function bxor(a,b)

--- Returns the bitwise not of its argument.
--- @param a integer
--- @return integer
function M.bnot(a) return MODM - a end
local bnot = M.bnot

--- Returns the bitwise and of its arguments.
--- @param a integer
--- @param b integer
--- @return integer
function M.band(a,b) return ((a+b) - bxor(a,b))/2 end
local band = M.band

--- Returns the bitwise or of its arguments.
--- @param a integer
--- @param b integer
--- @return integer
function M.bor(a,b) return MODM - band(MODM - a, MODM - b) end
local bor = M.bor

local lshift, rshift -- forward declare

--- Bitwise logical right-shift.
--- @param a integer The number to shift.
--- @param disp integer The number of bits to shift.
--- @return integer
function M.rshift(a,disp) -- Lua5.2 insipred
    if disp < 0 then return lshift(a,-disp) end
    return floor(a % 2^32 / 2^disp)
end
rshift = M.rshift

--- Bitwise logical left-shift.
--- @param a integer The number to shift.
--- @param disp integer The number of bits to shift.
--- @return integer
function M.lshift(a,disp) -- Lua5.2 inspired
    if disp < 0 then return rshift(a,-disp) end
    return (a * 2^disp) % 2^32
end
lshift = M.lshift

--- Converts its first argument to a hex string. The number of hex digits is given by the absolute value of the optional second argument. Positive numbers between 1 and 8 generate lowercase hex digits. Negative numbers generate uppercase hex digits. Only the least-significant 4*|n| bits are used. The default is to generate 8 lowercase hex digits.
--- @param x number The number to convert to hex.
--- @param n? number The number of hex digits to generate. Positive numbers generate lowercase hex digits, negative numbers generate uppercase hex digits.
--- @return string The hex string representation of the number.
--- @usage print(bit.tohex(1))              --> 00000001
--- print(bit.tohex(-1))             --> ffffffff
--- print(bit.tohex(0xffffffff))     --> ffffffff
--- print(bit.tohex(-1, -8))         --> FFFFFFFF
--- print(bit.tohex(0x21, 4))        --> 0021
--- print(bit.tohex(0x87654321, 4))  --> 4321
function M.tohex(x, n) -- BitOp style
    n = n or 8
    local up
    if n <= 0 then
        if n == 0 then return '' end
        up = true
        n = - n
    end
    x = band(x, 16^n-1)
    return ('%0'..n..(up and 'X' or 'x')):format(x)
end
local tohex = M.tohex

--- Extract bits
--- @param n integer The number to extract bits from.
--- @param field integer The starting bit position to extract from.
--- @param width? integer The number of bits to extract. Defaults to 1.
--- @return integer extracted The extracted bits.
function M.extract(n, field, width) -- Lua5.2 inspired
    width = width or 1
    return band(rshift(n, field), 2^width-1)
end
local extract = M.extract

--- Replace bits
--- @param n integer The number to replace bits in.
--- @param v integer The value to insert.
--- @param field integer The starting bit position to replace.
--- @param width? integer The number of bits to replace. Defaults to 1.
--- @return integer replaced The number with the replaced bits.
function M.replace(n, v, field, width) -- Lua5.2 inspired
    width = width or 1
    local mask1 = 2^width-1
    v = band(v, mask1) -- required by spec?
    local mask = bnot(lshift(mask1, field))
    return band(n, mask) + lshift(v, field)
end
local replace = M.replace

--- Swaps the bytes of its argument and returns it.
--- This can be used to convert little-endian 32 bit numbers to big-endian 32 bit numbers or vice versa.
--- @param x integer The number to swap.
--- @return integer
function M.bswap(x) -- BitOp style
    local a = band(x, 0xff); x = rshift(x, 8)
    local b = band(x, 0xff); x = rshift(x, 8)
    local c = band(x, 0xff); x = rshift(x, 8)
    local d = band(x, 0xff)
    return lshift(lshift(lshift(a, 8) + b, 8) + c, 8) + d
end
local bswap = M.bswap

--- Bitwise left rotation.
--- @param x integer The number to rotate.
--- @param disp integer The number of bits to rotate.
--- @return integer
function M.rrotate(x, disp) -- Lua5.2 inspired
    disp = disp % 32
    local low = band(x, 2^disp-1)
    return rshift(x, disp) + lshift(low, 32-disp)
end
local rrotate = M.rrotate

--- Bitwise right rotation.
--- @param x integer The number to rotate.
--- @param disp integer The number of bits to rotate.
--- @return integer
function M.lrotate(x, disp) -- Lua5.2 inspired
    return rrotate(x, -disp)
end
local lrotate = M.lrotate

M.rol = M.lrotate -- LuaOp inspired
M.ror = M.rrotate -- LuaOp insipred

--- Bitwise arithmetic right-shift.
--- @param x integer The number to shift.
--- @param disp integer The number of bits to shift.
--- @return integer
function M.arshift(x, disp) -- Lua5.2 inspired
    local z = rshift(x, disp)
    if x >= 0x80000000 then z = z + lshift(2^disp-1, 32-disp) end
    return z
end
local arshift = M.arshift

--- Bitwise test.
--- Checks if any of the bits match.
--- @param x integer The number to test.
--- @param y integer The number to test against.
--- @return boolean
function M.btest(x, y) -- Lua5.2 inspired
    return band(x, y) ~= 0
end

--
-- Start Lua 5.2 "bit32" compat section.
--

--- @class bit32
M.bit32 = {} -- Lua 5.2 'bit32' compatibility

--- Returns the bitwise not of its argument.
--- @param x integer
--- @return integer
--- @function bit32.bnot
local function bit32_bnot(x)
    return (-1 - x) % MOD
end
M.bit32.bnot = bit32_bnot

--- Returns the bitwise xor of its arguments.
-- @tparam integer a
-- @tparam integer b
-- @tparam integer ...
-- @treturn integer
-- @function bit32.bxor

--- Returns the bitwise xor of its arguments.
--- @overload fun(a: integer, b: integer, ...: integer): integer
--- @param a integer
--- @param b integer
--- @param c integer
--- @param ... integer
--- @return integer
local function bit32_bxor(a, b, c, ...)
    local z
    if b then
        a = a % MOD
        b = b % MOD
        z = bxor(a, b)
        if c then
            z = bit32_bxor(z, c, ...)
        end
        return z
    elseif a then
        return a % MOD
    else
        return 0
    end
end
M.bit32.bxor = bit32_bxor

--- Returns the bitwise and of its arguments.
-- @tparam integer a
-- @tparam integer b
-- @tparam integer ...
-- @treturn integer
-- @function bit32.band

--- Returns the bitwise and of its arguments.
--- @overload fun(a: integer, b: integer, ...: integer): integer
--- @param a integer
--- @param b integer
--- @param c integer
--- @param ... integer
--- @return integer
local function bit32_band(a, b, c, ...)
    local z
    if b then
        a = a % MOD
        b = b % MOD
        z = ((a+b) - bxor(a,b)) / 2
        if c then
            z = bit32_band(z, c, ...)
        end
        return z
    elseif a then
        return a % MOD
    else
        return MODM
    end
end
M.bit32.band = bit32_band

--- Returns the bitwise or of its arguments.
-- @tparam integer a
-- @tparam integer b
-- @tparam integer ...
-- @treturn integer
-- @function bit32.bor

--- Returns the bitwise or of its arguments.
--- @overload fun(a: integer, b: integer, ...: integer): integer
--- @param a integer
--- @param b integer
--- @param c integer
--- @param ... integer
--- @return integer
local function bit32_bor(a, b, c, ...)
    local z
    if b then
        a = a % MOD
        b = b % MOD
        z = MODM - band(MODM - a, MODM - b)
        if c then
            z = bit32_bor(z, c, ...)
        end
        return z
    elseif a then
        return a % MOD
    else
        return 0
    end
end
M.bit32.bor = bit32_bor

--- Bitwise test.
--- Checks if any of the bits match.
--- @param ... integer
--- @return boolean
--- @function bit32.btest
function M.bit32.btest(...)
    return bit32_band(...) ~= 0
end

--- Bitwise left rotation.
--- @param x integer The number to rotate.
--- @param disp integer The number of bits to rotate.
--- @return integer
--- @function bit32.lrotate
function M.bit32.lrotate(x, disp)
    return lrotate(x % MOD, disp)
end

--- Bitwise right rotation.
--- @param x integer The number to rotate.
--- @param disp integer The number of bits to rotate.
--- @return integer
--- @function bit32.rrotate
function M.bit32.rrotate(x, disp)
    return rrotate(x % MOD, disp)
end

--- Bitwise logical left-shift.
--- @param x integer The number to shift.
--- @param disp integer The number of bits to shift.
--- @return integer
--- @function bit32.lshift
function M.bit32.lshift(x,disp)
    if disp > 31 or disp < -31 then return 0 end
    return lshift(x % MOD, disp)
end

--- Bitwise logical right-shift.
--- @param x integer The number to shift.
--- @param disp integer The number of bits to shift.
--- @return integer
--- @function bit32.rshift
function M.bit32.rshift(x,disp)
    if disp > 31 or disp < -31 then return 0 end
    return rshift(x % MOD, disp)
end

--- Bitwise arithmetic right-shift.
--- @param x integer The number to shift.
--- @param disp integer The number of bits to shift.
--- @return integer
--- @function bit32.arshift
function M.bit32.arshift(x,disp)
    x = x % MOD
    if disp >= 0 then
        if disp > 31 then
            return (x >= 0x80000000) and MODM or 0
        else
            local z = rshift(x, disp)
            if x >= 0x80000000 then z = z + lshift(2^disp-1, 32-disp) end
            return z
        end
    else
        return lshift(x, -disp)
    end
end


--- Extract bits
--- @param x integer The number to extract bits from.
--- @param field integer The starting bit position to extract from.
--- @param width? integer The number of bits to extract. Defaults to 1.
--- @return integer extracted The extracted bits.
--- @function bit32.extract
function M.bit32.extract(x, field, width)
    width = width or 1
    if field < 0 or field > 31 or width < 0 or field+width > 32 then error 'out of range' end
    x = x % MOD
    return extract(x, field, width)
end

--- Replace bits
--- @param x integer The number to replace bits in.
--- @param v integer The value to insert.
--- @param field integer The starting bit position to replace.
--- @param width? integer The number of bits to replace. Defaults to 1.
--- @return integer replaced The number with the replaced bits.
--- @function bit32.replace
function M.bit32.replace(x, v, field, width)
    width = width or 1
    if field < 0 or field > 31 or width < 0 or field+width > 32 then error 'out of range' end
    x = x % MOD
    v = v % MOD
    return replace(x, v, field, width)
end


--
-- Start LuaBitOp "bit" compat section.
--

M.bit = {} -- LuaBitOp "bit" compatibility

function M.bit.tobit(x)
    x = x % MOD
    if x >= 0x80000000 then x = x - MOD end
    return x
end
local bit_tobit = M.bit.tobit

function M.bit.tohex(x, ...)
    return tohex(x % MOD, ...)
end

function M.bit.bnot(x)
    return bit_tobit(bnot(x % MOD))
end

local function bit_bor(a, b, c, ...)
    if c then
        return bit_bor(bit_bor(a, b), c, ...)
    elseif b then
        return bit_tobit(bor(a % MOD, b % MOD))
    else
        return bit_tobit(a)
    end
end
M.bit.bor = bit_bor

local function bit_band(a, b, c, ...)
    if c then
        return bit_band(bit_band(a, b), c, ...)
    elseif b then
        return bit_tobit(band(a % MOD, b % MOD))
    else
        return bit_tobit(a)
    end
end
M.bit.band = bit_band

local function bit_bxor(a, b, c, ...)
    if c then
        return bit_bxor(bit_bxor(a, b), c, ...)
    elseif b then
        return bit_tobit(bxor(a % MOD, b % MOD))
    else
        return bit_tobit(a)
    end
end
M.bit.bxor = bit_bxor

function M.bit.lshift(x, n)
    return bit_tobit(lshift(x % MOD, n % 32))
end

function M.bit.rshift(x, n)
    return bit_tobit(rshift(x % MOD, n % 32))
end

function M.bit.arshift(x, n)
    return bit_tobit(arshift(x % MOD, n % 32))
end

function M.bit.rol(x, n)
    return bit_tobit(lrotate(x % MOD, n % 32))
end

function M.bit.ror(x, n)
    return bit_tobit(rrotate(x % MOD, n % 32))
end

function M.bit.bswap(x)
    return bit_tobit(bswap(x % MOD))
end

return M