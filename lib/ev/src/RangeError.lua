local G, TypeError

local RangeError = {}

function RangeError:before_init(...) -- Temporarily here due to bug in oo library. https://github.com/luapower/oo/issues/1
  getmetatable(self).__tostring = function()
    return self.msg
  end
  return ...
end

function RangeError:override_init(_, stackLvl, parameterName, requirements, provided)
  self.name = 'RangeError'
  if type(stackLvl) == 'number' then
    self.stackLvl = stackLvl + 2
  else
    TypeError(4, 'stackLvl', 'number', stackLvl)
  end
  self.msg = 'Parameter "' .. tostring(parameterName) .. '" must be ' .. tostring(requirements) .. ', not ' .. tonumber(provided) .. '.'
  return self
end

function RangeError:after_init() -- Temporarily here due to bug in oo library. https://github.com/luapower/oo/issues/1
  G.process:emit('uncaughtException', self)
end

return function(inherits, Error, typeerror, g)
  G = g
  TypeError = typeerror
  RangeError = inherits(RangeError, 'RangeError', Error)
  return RangeError
end
