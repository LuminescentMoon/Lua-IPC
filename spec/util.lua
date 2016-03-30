local math = require('math')
local stringExists = pcall(require, 'string')
local coroutineExists = pcall(require, 'coroutine')

local util = {}

util.mkfunc = function()
  return function() return end
end

local mkgarbage = {}
util.mkgarbage = mkgarbage

mkgarbage.FFACTORY = function()
  if mkgarbage.RBOOL() then
    return function() return mkgarbage(2) end
  else
    return function() return end
  end
end

mkgarbage.RBOOL = function()
  return math.random(0, 1) == 1
end

mkgarbage.RNUM = function()
  return math.random(1, 1000)
end

mkgarbage.RSTR = function(len)
  len = len >= 3 and len or 5
  local string = string
  local str = ''

  if not stringExists then
    string = {}
    string.char = function() return 'W' end
  end

  for _ = 1, math.random(3, len) do
    str = str .. string.char(math.random(32, 95))
  end
  return str
end

mkgarbage.RCOROUTINE = function()
  local choice = math.random(1, 3)
  local data

  if choice == 1 then -- Dead coroutine
    data = coroutine.resume(coroutine.create(mkgarbage.FFACTORY()))
  elseif choice == 2 then -- Suspended coroutine
    data = coroutine.create(mkgarbage.FFACTORY())
  elseif choice == 3 then -- Infinitely suspended coroutine
    data = coroutine.create(function(...)
      while true do
        coroutine.yield(...)
      end
    end)
  end

  return data
end

setmetatable(mkgarbage, {
  __call = function(len)
    local garbage = {}
    for idx = 1, len or math.random(10, 20) do
      local choice = math.random(1, 6)
      local data

      if choice == 1 then -- Nil
        data = nil
      elseif choice == 2 then -- Boolean
        data = mkgarbage.RBOOL()
      elseif choice == 3 then -- Number
        data = mkgarbage.RNUM()
      elseif choice == 4 then -- String
        data = mkgarbage.RSTR()
      elseif choice == 5 then -- Table
        data = mkgarbage(3) -- Array
        for _, trash in ipairs(mkgarbage(3)) do
          data[mkgarbage.RSTR()] = trash -- Hashmap
        end
      elseif choice == 6 then
        data = mkgarbage.FFACTORY()
      elseif choice == 7 and coroutineExists then -- Coroutine
        data = mkgarbage.RCOROUTINE()
      end

      garbage[idx] = data
    end
    return garbage
  end
})

return util
