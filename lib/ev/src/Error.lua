local G

local Error = {}

function Error:before_init(...)
  getmetatable(self).__tostring = function()
    return self.msg
  end
  return ...
end

function Error:init(msg)
  self.stackLvl = 2
  self.name = 'Error'
  self.msg = msg
  return self
end

function Error:after_init()
  G.process:emit('uncaughtException', self)
end

function Error:stack(level)
  if type(level) ~= 'number' then
    self.stackLvl = self.stackLvl + 1
  else
    self.stackLvl = self.stackLvl + level
  end
  return self
end

function Error:throw()
  error(self.name .. ': ' .. tostring(self.msg), self.stackLvl)
end

return function(inherits, g)
  G = g
  return inherits(Error, 'Error')
end
