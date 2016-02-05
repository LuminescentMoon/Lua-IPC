--- LateCall - A library for deferring the execution of a callable object (function or table with __call set) with certain arguments.

-- Takes a function to callback and a variable list of arguments to call the callback with and returns a function that when executed, returns the result of calling the callback with said list of arguments.

local function isFunc(o)
  return type(o) == 'function' or (type(o) == 'table' and type(getmetatable(o)) == 'table' and type(getmetatable(o).__call) == 'function')
end

----------------------
-- Tableless version
----------------------

local function _packHelper(...)
  while true do
    coroutine.yield(...)
  end
end

local function packC(...)
  local o = coroutine.create(_packHelper)
  coroutine.resume(o, ...)
  return o
end

local function unpackC(o)
  return select(2, coroutine.resume(o))
end

local function makeC(callback, ...)
  return packC(callback, ...)
end

local function executeC(callable)
  if isFunc(callable) then
    return callable()
  else
    local callback = unpackC(callable)
    return callback(select(2, unpackC(callable)))
  end
end

local function isCallableC(possibleCallable)
  return isFunc(possibleCallable) or (type(possibleCallable) == 'thread' and type((unpackC(possibleCallable)) == 'function'))
end

----------------------
-- Table version
----------------------

local function packT(...)
  return {
    n = select('#', ...),
    ...
  }
end

local function unpackT(t)
  return unpack(t, 1, t.n)
end

local function makeT(callback, ...)
  if ... then
    local callable = packT(...)
    callable.func = callback
    return callable
  else
    return callback
  end
end

local function executeT(callable)
  if isFunc(callable) then
    return callable()
  else
    return callable.func(unpackT(callable))
  end
end

local function isCallableT(possibleCallable)
  return isFunc(possibleCallable) or (type(possibleCallable) == 'table' and type(possibleCallable.func) == 'function')
end

----------------------
-- Exports
----------------------

local Callable = {}

function Callable.useMethod(method)
  if method == 'coroutine' then
    Callable.make = makeC
    Callable.execute = executeC
    Callable.is = isCallableC
  elseif method == 'table' then
    Callable.make = makeT
    Callable.execute = executeT
    Callable.is = isCallableT
  else
    error('Invalid working method.')
  end
  return Callable
end

return Callable
