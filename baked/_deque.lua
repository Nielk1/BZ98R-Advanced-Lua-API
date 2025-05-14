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

debugprint("_deque Loading");

local customsavetype = require("_customsavetype");

--- @param self Deque
--- @param x T
--- @function push_right
local push_right = function(self, x)
    assert(x ~= nil)
    self.tail = self.tail + 1
    self[self.tail] = x
end

--- @param self Deque
--- @param x T
--- @function push_left
local push_left = function(self, x)
    assert(x ~= nil)
    self[self.head] = x
    self.head = self.head - 1
end

--- @param self Deque
--- @return T
--- @function peek_right
local peek_right = function(self)
    return self[self.tail]
end

--- @param self Deque
--- @function peek_left
--- @return T
local peek_left = function(self)
    return self[self.head+1]
end

--- @param self Deque
--- @return T
--- @function pop_right
local pop_right = function(self)
    if self:is_empty() then return nil end
    local r = self[self.tail]
    self[self.tail] = nil
    self.tail = self.tail - 1
    return r
end

--- @param self Deque
--- @return T
--- @function pop_left
local pop_left = function(self)
    if self:is_empty() then return nil end
    local r = self[self.head+1]
    self.head = self.head + 1
    local r = self[self.head]
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
--- @param x T
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
--- @param x T
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
--- @return table<number, T>
--- @function contents
local contents = function(self)
    local r = {}
    for i=self.head+1,self.tail do
        r[i-self.head] = self[i]
    end
    return r
end

--- @param self Deque
--- @return function
--- @function iter_right
local iter_right = function(self)
    local i = self.tail+1
    return function()
        if i > self.head+1 then
            i = i-1
            return self[i]
        end
    end
end

--- @param self Deque
--- @return function
--- @function iter_left
local iter_left = function(self)
    local i = self.head
    return function()
        if i < self.tail then
            i = i+1
            return self[i]
        end
    end
end

--- @generic T
--- @class Deque<T> : CustomSavableType
--- @field head number The index of the first element.
--- @field tail number The index of the last element.
--- @field [number] T The elements stored in the deque.
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
    iter_right = iter_right,
    iter_left = iter_left,
    length = length,
    is_empty = is_empty,
    contents = contents,
}

methods.__type = "Deque";

--- @generic T
--- @return Deque<T>
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
-- @param template
-- @param active_states
-- @param addonData
function methods.Load(contents)
    local queue = new();
    for i = 1, #contents do
        queue:push_right(contents[i]);
    end
    return queue;
end

customsavetype.Register(methods);

debugprint("_deque Loaded");

return {
    new = new,
}