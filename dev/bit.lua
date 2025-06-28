--- BZ98R bit library stub.
---
--- @module 'bit'
---
--- @usage
--- local bit = require("bit");
--- local bit.bor(1, 2, 4) -- returns 7

local M = {};

--- Normalizes a number to the numeric range for bit operations and returns it.
--- This function is usually not needed since all bit operations already normalize all of their input arguments. Check the operational semantics for details.
--- @param x integer
--- @return integer
--- @function tobit
--- @usage print(0xffffffff)                --> 4294967295 (*)
--- print(bit.tobit(0xffffffff))     --> -1
--- printx(bit.tobit(0xffffffff))    --> 0xffffffff
--- print(bit.tobit(0xffffffff + 1)) --> 0
--- print(bit.tobit(2^40 + 1234))    --> 1234
function M.tobit(x) error("This function is provided by the engine."); end

--- Returns the bitwise not of its argument.
--- @param x integer
--- @return integer
--- @function bnot
function M.bnot(x) error("This function is provided by the engine."); end

--- Returns the bitwise and of its arguments.
-- @tparam integer a
-- @tparam integer b
-- @tparam integer ...
-- @treturn integer
-- @function band

--- Returns the bitwise and of its arguments.
--- @overload fun(a: integer, b: integer, ...: integer): integer
--- @param a integer
--- @param b integer
--- @param c integer
--- @param ... integer
--- @return integer
function M.band(a, b, c, ...) error("This function is provided by the engine."); end

--- Returns the bitwise or of its arguments.
-- @tparam integer a
-- @tparam integer b
-- @tparam integer ...
-- @treturn integer
-- @function bor

--- Returns the bitwise or of its arguments.
--- @overload fun(a: integer, b: integer, ...: integer): integer
--- @param a integer
--- @param b integer
--- @param c integer
--- @param ... integer
--- @return integer
function M.bor(a, b, c, ...) error("This function is provided by the engine."); end

--- Returns the bitwise xor of its arguments.
-- @tparam integer a
-- @tparam integer b
-- @tparam integer ...
-- @treturn integer
-- @function bxor

--- Returns the bitwise xor of its arguments.
--- @overload fun(a: integer, b: integer, ...: integer): integer
--- @param a integer
--- @param b integer
--- @param c integer
--- @param ... integer
--- @return integer
function M.bxor(a, b, c, ...) error("This function is provided by the engine."); end

--- Bitwise logical left-shift.
--- @param x integer The number to shift.
--- @param disp integer The number of bits to shift.
--- @return integer
--- @function lshift
function M.lshift(x,disp) error("This function is provided by the engine."); end

--- Bitwise logical right-shift.
--- @param x integer The number to shift.
--- @param disp integer The number of bits to shift.
--- @return integer
--- @function rshift
function M.rshift(x,disp) error("This function is provided by the engine."); end

--- Bitwise arithmetic right-shift.
--- @param x integer The number to shift.
--- @param disp integer The number of bits to shift.
--- @return integer
--- @function arshift
function M.arshift(x,disp) error("This function is provided by the engine."); end

--- Bitwise left rotation.
--- @param x integer The number to rotate.
--- @param disp integer The number of bits to rotate.
--- @return integer
--- @function rol
function M.rol(x, disp) error("This function is provided by the engine."); end

--- Bitwise right rotation.
--- @param x integer The number to rotate.
--- @param disp integer The number of bits to rotate.
--- @return integer
--- @function ror
function M.ror(x, disp) error("This function is provided by the engine."); end

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
function M.tohex(x, n) error("This function is provided by the engine."); end
