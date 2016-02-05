local LuaSocket, Callable, Timers, EventEmitter, util

local Process = {}

local function queuesAreEmpty()
  return Timers.isEmpty()-- and Io.isEmpty()
end

function Process:override_emit(inherited, event, ...)
  local listenersRegistered = inherited(self, event, ...)
  if event == 'uncaughtException' and not listenersRegistered then
    local Error = ...
    Error:stack()
    Error:throw()
  end
  return listenersRegistered
end

function Process:_doNextTick()
  -- Imitate Node.JS's behavior of completely draining the nextTick queue before additional I/O is processed.
  -- As a result, recursively setting nextTick callbacks will block any I/O from happening, just like a while true loop.
  local nextTickQueue = self._nextTickQueue
  local i = 1
  while nextTickQueue[i] ~= nil do
    Callable.execute(nextTickQueue[i])
    nextTickQueue[i] = nil
    self._lowestUnusedIdx = i
    i = i + 1
    if nextTickQueue[i] == nil and nextTickQueue[1] ~= nil then
      i = 1
    end
  end
end

function Process:_doTimers()
  Timers._queue, Timers._buffer = Timers._buffer, Timers._queue
  for i, timer in ipairs(Timers._queue) do
    local success, errmsg = Timers._tick(timer)
    if util.type.isFalse(success) then
      error(errmsg)
    end
    Timers._queue[i] = nil
  end
end

function Process:_doIo()
end

function Process:_doTick()
  local deltaTime = LuaSocket.gettime() - self._lastTick
  self:_doNextTick()
  self:_doTimers()
  self:_doIo(deltaTime)
  self._lastTick = LuaSocket.gettime()
end

function Process:nextTick(callback, ...)
  local lowestUnusedIdx = self._lowestUnusedIdx
  self._nextTickQueue[lowestUnusedIdx] = Callable.make(callback, ...)
  self._lowestUnusedIdx = lowestUnusedIdx + 1
end

function Process:startLoop()
  self._lastTick = LuaSocket.gettime()
  while true do
    if not queuesAreEmpty() then
      self:_doTick()
    else
      self:emit('beforeExit')
      if queuesAreEmpty() then -- If they're still empty after emitting the 'beforeExit' event.
        os.exit(0)              -- We check this since this event is usually used to schedule more work.
      end
    end
    LuaSocket.select(nil, nil, 0.001) -- Sleep for 0.001 seconds. Prevents CPU rape.
  end
end

function Process:makeTickFunc()
  self._lastTick = LuaSocket.gettime()
  return function() self:_doTick() end
end

function Process:after_init()
  self._tickQueue = {}
  self._nextTickQueue = {}
  self._lowestUnusedIdx = 1
end

return function(currentDir)
  LuaSocket = require('socket')
  Callable = require(currentDir .. '.lib.callable').useMethod('table')

  util = require(currentDir .. '.lib.util')(currentDir)

  local G = {}

  local console = require(currentDir .. '.lib.log')()
  local Error = require(currentDir .. '.src.Error')(util.inherits, G)
  local TypeError = require(currentDir .. '.src.TypeError')(util.inherits, Error, G)
  local RangeError = require(currentDir .. '.src.RangeError')(util.inherits, Error, TypeError, G)
  EventEmitter = require(currentDir .. '.src.Events')(util.inherits, Error, TypeError, RangeError, console)

  Timers = require(currentDir .. '.src.Timers')(LuaSocket, Callable)
  -- Buffer = require(currentDir .. '.lib.Buffer')

  G.process = util.inherits(Process, 'Process', EventEmitter)() -- Singleton
  G.EventEmitter = EventEmitter
  G.util = util
  util.tableop.merge(G, Timers.exports)

  return G
end
