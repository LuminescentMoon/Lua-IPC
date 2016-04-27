local Error, TypeError, RangeError, console

local EventEmitter = {}

EventEmitter.defaultMaxListeners = 10

function EventEmitter:init(...)
  self._events = {}
  return ...
end

local function checkTypes(event, listener, ignoreListener)
  if not (type(event) == 'string' or type(event) == 'table') then
    TypeError(3, 'event', {'string', 'table'}, event)
  end
  if not ignoreListener and listener ~= nil then
    if not type(listener) == 'function' or not (type(listener) == 'table' and type(getmetatable(listener).__call) == 'function') then
      TypeError(3, 'listener', 'callable', listener)
    end
  end
end

function EventEmitter:removeListener(event, listener)
  checkTypes(event, listener)
  local events = self._events
  local registry = events[event]
  if registry == nil then -- No listeners registered for event.
    return self
  end
  for i, currlistener in ipairs(registry) do
    if currlistener == listener then
      table.remove(registry, i)
      if #registry == 0 then -- Remove event's listener array if there's no more listeners.
        events[event] = nil
      end
      if events.removeListener then -- https://nodejs.org/api/events.html#events_event_removelistener
        self:emit('removeListener', event, listener)
      end
      break
    end
  end
  return self
end

function EventEmitter:emit(event, ...)
  checkTypes(event, nil, true)
  local registry = self._events[event]
  if registry == nil then -- No listeners registered to event.
    if event == 'error' then
      Error(...)
    end
    return false
  end
  for _, listener in ipairs(registry) do      -- Deviates from Node.JS. Can't set this (self) in Lua.
    local success, err = pcall(listener, ...) -- https://nodejs.org/api/events.html#events_passing_arguments_and_this_to_listeners
    if not success then
      Error(err)
    end
  end
  return true
end

function EventEmitter:on(event, listener)
  checkTypes(event, listener)
  local events = self._events
  if not events[event] then
    events[event] = {}
  end
  local registry = events[event]

  if events.newListener then -- https://nodejs.org/api/events.html#events_event_newlistener
    self:emit('newListener', event, listener)
  end
  table.insert(registry, listener)
  if #registry > self:getMaxListeners() then
    console.warn('Event "' .. event .. '" listener count exceeds max limit. Possible memory leak.')
  end
  return self
end

EventEmitter.addListener = EventEmitter.on

function EventEmitter:once(event, listener)
  checkTypes(event, listener)
  local wrapper
  wrapper = function(...)
    listener(...)
    self:removeListener(event, wrapper)
  end
  self:on(event, wrapper)
  return self
end

function EventEmitter:listenerCount(event)
  checkTypes(event)
  local events = self._events
  return events[event] and #events[event] or 0 -- Guard against attempt to index nil value since we remove the listener table for an event with 0 listeners.
end

function EventEmitter:listeners(event)
  checkTypes(event, nil, true)
  local copy = {}
  for i, listener in ipairs(self._events[event]) do
    copy[i] = listener
  end
  return copy
end

function EventEmitter:getMaxListeners()
  return self.maxListeners or self.super.defaultMaxListeners
end

function EventEmitter:setMaxListeners(number)
  if number < 0 then
    RangeError(2, 'number', 'greater than or equal to 0', number)
  end
  self.maxListeners = number
  return self
end

function EventEmitter:removeAllListeners(event) -- Removes all listeners, or those of the specified event.
  local events = self._events
  if event ~= nil then
    checkTypes(event, nil, true)
    events[event] = nil
  else
    self._events = {}
  end
  return self
end

return function(inherits, error, typeerror, rangeerror, con)
  Error, TypeError, RangeError, console = error, typeerror, rangeerror, con
  EventEmitter = inherits(EventEmitter, 'EventEmitter')
  return EventEmitter
end
