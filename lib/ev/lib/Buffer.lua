--[[

Copyright 2014-2015 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

local exports = {} -- CHANGED

exports.name = "luvit/buffer"
exports.version = "1.0.1-3"
exports.dependencies = {
  "luvit/core@1.0.5"
}
exports.license = "Apache 2"
exports.homepage = "https://github.com/luvit/luvit/blob/master/deps/buffer.lua"
exports.description = "A mutable buffer using ffi for luvit."
exports.tags = {"luvit", "buffer"}

-- CHANGED: Inlined object code.
--[[
This is the most basic object in Luvit. It provides simple prototypal
inheritance and inheritable constructors. All other objects inherit from this.
]]
local Object = {}
Object.meta = {__index = Object}

-- Create a new instance of this object
function Object:create()
  local meta = rawget(self, "meta")
  if not meta then error("Cannot inherit from instance object") end
  return setmetatable({}, meta)
end

--[[
Creates a new instance and calls `obj:initialize(...)` if it exists.
    local Rectangle = Object:extend()
    function Rectangle:initialize(w, h)
      self.w = w
      self.h = h
    end
    function Rectangle:getArea()
      return self.w * self.h
    end
    local rect = Rectangle:new(3, 4)
    p(rect:getArea())
]]
function Object:new(...)
  local obj = self:create()
  if type(obj.initialize) == "function" then
    obj:initialize(...)
  end
  return obj
end

--[[
Creates a new sub-class.
    local Square = Rectangle:extend()
    function Square:initialize(w)
      self.w = w
      self.h = h
    end
]]

function Object:extend()
  local obj = self:create()
  local meta = {}
  -- move the meta methods defined in our ancestors meta into our own
  --to preserve expected behavior in children (like __tostring, __add, etc)
  for k, v in pairs(self.meta) do
    meta[k] = v
  end
  meta.__index = obj
  meta.super=self
  obj.meta = meta
  return obj
end

local ffi = require('ffi')


ffi.cdef([[
  void *malloc (size_t __size);
  void free (void *__ptr);
]])

local buffer = exports

local Buffer = Object:extend()
buffer.Buffer = Buffer

--avoid bugs when link with static run times lib, eg. /MT link flags
local C = ffi.os=='Windows' and ffi.load('msvcrt') or ffi.C

function Buffer:initialize(length)
  if type(length) == "number" then
    self.length = length
    self.ctype = ffi.gc(ffi.cast("unsigned char*", C.malloc(length)), C.free)
  elseif type(length) == "string" then
    local string = length
    self.length = #string
    self.ctype = ffi.gc(ffi.cast("unsigned char*", C.malloc(self.length)), C.free)
    ffi.copy(self.ctype,string,self.length)
  else
    error("Input must be a string or number")
  end
end

function Buffer.meta:__ipairs()
  local index = 0
  return function ()
    if index < self.length then
      index = index + 1
      return index, self[index]
    end
  end
end

function Buffer.meta:__tostring()
  return ffi.string(self.ctype,self.length)
end

function Buffer.meta:__concat(other)
  return tostring(self) .. tostring(other)
end

function Buffer.meta:__index(key)
  if type(key) == "number" then
    if key < 1 or key > self.length then error("Index out of bounds") end
    return self.ctype[key - 1]
  end
  return Buffer[key]
end

function Buffer.meta:__newindex(key, value)
  if type(key) == "number" then
    if key < 1 or key > self.length then error("Index out of bounds") end
    self.ctype[key - 1] = value
    return
  end
  rawset(self, key, value)
end

function Buffer:inspect()
  local parts = {}
  for i = 1, tonumber(self.length) do
    parts[i] = bit.tohex(self[i], 2)
  end
  return "<Buffer " .. table.concat(parts, " ") .. ">"
end

local function compliment8(value)
  return value < 0x80 and value or -0x100 + value
end

function Buffer:readUInt8(offset)
  return self[offset]
end

function Buffer:readInt8(offset)
  return compliment8(self[offset])
end

local function compliment16(value)
  return value < 0x8000 and value or -0x10000 + value
end

function Buffer:readUInt16LE(offset)
  return bit.lshift(self[offset + 1], 8) +
                    self[offset]
end

function Buffer:readUInt16BE(offset)
  return bit.lshift(self[offset], 8) +
                    self[offset + 1]
end

function Buffer:readInt16LE(offset)
  return compliment16(self:readUInt16LE(offset))
end

function Buffer:readInt16BE(offset)
  return compliment16(self:readUInt16BE(offset))
end

function Buffer:readUInt32LE(offset)
  return self[offset + 3] * 0x1000000 +
         bit.lshift(self[offset + 2], 16) +
         bit.lshift(self[offset + 1], 8) +
                    self[offset]
end

function Buffer:readUInt32BE(offset)
  return self[offset] * 0x1000000 +
         bit.lshift(self[offset + 1], 16) +
         bit.lshift(self[offset + 2], 8) +
                    self[offset + 3]
end

function Buffer:readInt32LE(offset)
  return bit.tobit(self:readUInt32LE(offset))
end

function Buffer:readInt32BE(offset)
  return bit.tobit(self:readUInt32BE(offset))
end

function Buffer:toString(i, j)
  local offset = i and i - 1 or 0
  return ffi.string(self.ctype + offset, (j or self.length) - offset)
end

return buffer
