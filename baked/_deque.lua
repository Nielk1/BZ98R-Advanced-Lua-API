--- BZ98R LUA Extended API dequeue library.
---
--- https://github.com/catwell/cw-lua/blob/master/deque/deque.lua
---
--- @module '_deque'
--- @author Pierre 'catwell' Chapuis
---
--- Deque implementation by Pierre 'catwell' Chapuis
---
--- Copyright (C) by Pierre Chapuis
---
--- Permission is hereby granted, free of charge, to any person obtaining a copy
--- of this software and associated documentation files (the "Software"), to deal
--- in the Software without restriction, including without limitation the rights
--- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--- copies of the Software, and to permit persons to whom the Software is
--- furnished to do so, subject to the following conditions:
---
--- The above copyright notice and this permission notice shall be included in
--- all copies or substantial portions of the Software.
---
--- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--- THE SOFTWARE.

local logger = require("_logger");

logger.print(logger.LogLevel.DEBUG, nil, "_deque Loading");

local customsavetype = require("_customsavetype");

--- @param self Deque
--- @param x any
--- @function push_right
local push_right = function(self, x)
    assert(x ~= nil)
    self.tail = self.tail + 1
    self[self.tail] = x
end

--- @param self Deque
--- @param x any
--- @function push_left
local push_left = function(self, x)
    assert(x ~= nil)
    self[self.head] = x
    self.head = self.head - 1
end

--- @param self Deque
--- @return any
--- @function peek_right
local peek_right = function(self)
    return self[self.tail]
end

--- @param self Deque
--- @function peek_left
--- @return any
local peek_left = function(self)
    return self[self.head+1]
end

--- @param self Deque
--- @return any
--- @function pop_right
local pop_right = function(self)
    if self:is_empty() then return nil end
    local r = self[self.tail]
    self[self.tail] = nil
    self.tail = self.tail - 1
    return r
end

--- @param self Deque
--- @return any
--- @function pop_left
local pop_left = function(self)
    if self:is_empty() then return nil end
    local r = self[self.head + 1]
    self.head = self.head + 1
    --local r = self[self.head]
    self[self.head] = nil
    return r
end

--- @param self Deque
--- @param n number
--- @function rotate_right
local rotate_right = function(self, n)
    n = n or 1
    if self:is_empty() then return nil end
    for i=1,n do self:push_left(self:pop_right()) end
end

--- @param self Deque
--- @param n number
--- @function rotate_left
local rotate_left = function(self, n)
    n = n or 1
    if self:is_empty() then return nil end
    for i=1,n do self:push_right(self:pop_left()) end
end

local _remove_at_internal = function(self, idx)
    for i=idx, self.tail do self[i] = self[i+1] end
    self.tail = self.tail - 1
end

--- @param self Deque
--- @param x any
--- @return boolean
--- @function remove_right
local remove_right = function(self, x)
    for i=self.tail,self.head+1,-1 do
        if self[i] == x then
            _remove_at_internal(self, i)
            return true
        end
    end
    return false
end

--- @param self Deque
--- @param x any
--- @return boolean
--- @function remove_left
local remove_left = function(self, x)
    for i=self.head+1,self.tail do
        if self[i] == x then
            _remove_at_internal(self, i)
            return true
        end
    end
    return false
end

--- @param self Deque
--- @return number
--- @function length
local length = function(self)
    return self.tail - self.head
end

--- @param self Deque
--- @return boolean
--- @function is_empty
local is_empty = function(self)
    return self:length() == 0
end

--- @param self Deque
--- @return table<number, any>
--- @function contents
local contents = function(self)
    local r = {}
    for i=self.head+1,self.tail do
        r[i-self.head] = self[i]
    end
    return r
end

--- @param self Deque
--- @return fun():any, integer
--- @function iter_right
local iter_right = function(self)
    local i = self.tail+1
    return function()
        if i > self.head+1 then
            i = i-1
            return self[i], i - self.head
        end
        --- @diagnostic disable-next-line: missing-return-value
        return nil;
    end
end

--- @param self Deque
--- @return fun():any, integer
--- @function iter_left
local iter_left = function(self)
    local i = self.head
    return function()
        if i < self.tail then
            i = i+1
            return self[i], i - self.head
        end
        --- @diagnostic disable-next-line: missing-return-value
        return nil;
    end
end

--- Removes an element at the given relative index.
--- @param self Deque The deque instance.
--- @param relative_index number The relative index of the element to remove (1-based, as used by `contents` and iterators).
--- @return boolean True if the element was successfully removed, false if the index is out of bounds.
--- @function remove_at_relative
--- @todo untested AI generated
local remote_at = function(self, relative_index)
    local absolute_index = self.head + relative_index
    if absolute_index > self.tail or absolute_index <= self.head then
        return false -- Index is out of bounds
    end
    _remove_at_internal(self, absolute_index)
    return true
end

--- Internal function to remove multiple indexes from the deque.
--- @param self Deque The deque instance.
--- @param indexes number[] A sorted list of absolute indexes to remove.
--- @todo untested AI generated
local _remove_multiple_at_internal = function(self, indexes)
    local shift = 0 -- Tracks how far elements need to be shifted
    local next_index_to_remove = 1 -- Pointer to the current index in the `indexes` array

    for i = self.head + 1, self.tail do
        if next_index_to_remove <= #indexes and i == indexes[next_index_to_remove] then
            -- Skip this index (it's being removed)
            shift = shift + 1
            next_index_to_remove = next_index_to_remove + 1
        else
            -- Shift the current element left by the accumulated shift amount
            self[i - shift] = self[i]
        end
    end

    -- Clear the now-unused tail elements
    for i = self.tail - shift + 1, self.tail do
        self[i] = nil
    end

    -- Update the tail pointer
    self.tail = self.tail - shift
end

--- Removes multiple elements at the given relative indexes.
--- @param self Deque The deque instance.
--- @param relative_indexes number[] A list of relative indexes to remove (1-based, as used by `contents` and iterators).
--- @return boolean True if at least one element was removed, false if no valid indexes were provided.
--- @function remove_multiple_at_relative
--- @todo untested AI generated
local remove_multiple = function(self, relative_indexes)
    -- Convert relative indexes to absolute indexes
    local absolute_indexes = {}
    for _, relative_index in ipairs(relative_indexes) do
        local absolute_index = self.head + relative_index
        if absolute_index > self.head and absolute_index <= self.tail then
            table.insert(absolute_indexes, absolute_index)
        end
    end

    -- If no valid indexes, return false
    if #absolute_indexes == 0 then
        return false
    end

    -- Sort the absolute indexes in ascending order
    table.sort(absolute_indexes)

    -- Call the internal function to remove the elements
    _remove_multiple_at_internal(self, absolute_indexes)

    return true
end

--- @class Deque : CustomSavableType
--- @field head number The index of the first element.
--- @field tail number The index of the last element.
--- @field [number] any The elements stored in the deque.
local methods = {
    push_right = push_right,
    push_left = push_left,
    peek_right = peek_right,
    peek_left = peek_left,
    pop_right = pop_right,
    pop_left = pop_left,
    rotate_right = rotate_right,
    rotate_left = rotate_left,
    remove_right = remove_right,
    remove_left = remove_left,
    remote_at = remote_at,
    remove_multiple = remove_multiple,
    iter_right = iter_right,
    iter_left = iter_left,
    length = length,
    is_empty = is_empty,
    contents = contents,
}

methods.__type = "Deque";

--- @return Deque
--- @function new
local new = function()
    local r = {head = 0, tail = 0}
    return setmetatable(r, {__index = methods})
end

-------------------------------------------------------------------------------
-- Deque - Core
-------------------------------------------------------------------------------
-- @section

--- Save event function.
--
-- INTERNAL USE.
-- @param self StateSetRunner instance
-- @return ...
function methods.Save(self)
    return self:contents();
end

--- Load event function.
--
-- INTERNAL USE.
-- @param contents
function methods.Load(contents)
    local queue = new();
    for i = 1, #contents do
        queue:push_right(contents[i]);
    end
    return queue;
end

customsavetype.Register(methods);

logger.print(logger.LogLevel.DEBUG, nil, "_deque Loaded");

return {
    new = new,
}