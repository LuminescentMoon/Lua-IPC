 -- https://nodejs.org/api/timers.html
local LuaSocket, Callable

local Timers = {
  _queue = {},
  _buffer = {},
  _type = {
    timeout = {},
    interval = {}
  },
  _references = 0
}

local buffer, queue, Type, references = Timers._buffer, Timers._queue, Timers._type, Timers._references

local deleteMarker = {}

local timer = {}
timer.__index = timer

function timer:ref()
  if not self.ref then
    self.ref = true
    references = references + 1
  end
  return self
end

function timer:unref()
  if self.ref then
    self.ref = false
    references = references - 1
  end
  return self
end

local function callbackIsCallable(callback)
  return type(callback) == 'function' or type(getmetatable(callback).__call) == 'function'
end

local function verifyArgs(callback, delay)
  assert(callbackIsCallable(callback), 'Attempted to pass uncallable object as a callback.')
  assert(type(delay) == 'number', 'Expected delay to be a number but found "' .. tostring(delay) .. '"')
end

local function fixDelay(delay)
  -- "To follow browser behavior, when using delays larger than 2147483647 milliseconds (approximately 25 days) or less than 1, Node.js will use 1 as the delay. "
  -- Divide delay by 1000 because we count time internally in seconds and delay is milliseconds.
  return ((delay > 2147483647 or delay < 1) and 1 or delay) / 1000
end

local function processTimeout(timer)
  local currentTime = LuaSocket.gettime()
  if currentTime - timer[4] >= timer[3] then -- If the time elapsed since last tick (deltaTime) is geq to the delay.
    timer[4] = currentTime                   -- Update time since last called.
    references = references - 1
    return Callable.execute(timer[1])
  else
    table.insert(buffer, timer)
  end
end

local function processInterval(timer)        -- Similiar to processTimeout()
  table.insert(buffer, timer)
  local currentTime = LuaSocket.gettime()
  if currentTime - timer[4] >= timer[3] then -- If the time elapsed since last tick (deltaTime) is geq to the delay.
    timer[4] = currentTime                   -- Update time since last called.
    return Callable.execute(timer[1])
  end
end

local function clearObj(timer)
  for i, currTimer in ipairs(buffer) do
    if currTimer == timer then
      table.remove(buffer, i)
      references = references - 1
      break
    end
  end
  for i, currTimer in ipairs(queue) do
    if currTimer == timer then
      references = references - 1
      queue[i] = deleteMarker           -- Replace it with a dummy value. Don't modify since it's possible
      break                             -- to clear an obj while event loop is iterating through the timers.
    end
  end
end

local exports = {
  clearImmediate = clearObj,
  clearTimeout = clearObj,
  clearInterval = clearObj
}

function exports.setImmediate(callback, ...)
  local immediateObj = Callable.make(callback, ...)
  if #buffer == 0 then
    buffer[1] = immediateObj
  else
    for i, _ in ipairs(buffer) do
      if not Callable.is(buffer[i + 1]) then      -- If timerobj is not directly callable, then it is not an immediateObj.
        table.insert(buffer, i + 1, immediateObj) -- We want to insert the new immediateObj directly after the last immediateObj.
        break
      end
    end
  end
  references = references + 1
  return immediateObj
end

function exports.setTimeout(callback, delay, ...)
  verifyArgs(callback, delay)
  delay = fixDelay(delay)

  local timeoutObj = setmetatable({
    Callable.make(callback, ...),
    Type.timeout,
    delay,
    LuaSocket.gettime()
  }, timer)

  table.insert(buffer, timeoutObj)
  references = references + 1
  return timeoutObj
end

function exports.setInterval(callback, delay, ...)
  local intervalObj = Timers.setTimeout(callback, delay, ...)
  intervalObj[2] = Type.interval
  return intervalObj
end

function Timers._tick(timer)
  if timer == deleteMarker then -- No need to manually delete since event loop drains queue automatically.
    return
  elseif Callable.is(timer) then -- immediateObj
    references = references - 1
    return Callable.execute(timer)
  elseif timer[2] == Type.interval then
    return processInterval(timer)
  elseif timer[2] == Type.timeout then
    return processTimeout(timer)
  else
    return false, 'Illegal timer added to queue.'
  end
end

function Timers.isEmpty()
  return references <= 0 -- Using leq just in case there's a bug that causes the references count to be negative.
end

Timers.exports = exports

return function(socket, call)
  LuaSocket = socket
  Callable = call
  return Timers
end
