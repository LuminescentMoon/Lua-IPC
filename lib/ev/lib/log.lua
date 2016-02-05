local oo = require('oo')

local Log = oo.Log()

local function bracket(string)
  return '[' .. string .. ']'
end

local function getFormattedTime()
  return os.date('%X')
end

local function genMsg(level, prefix, msg)
  print(bracket(getFormattedTime() .. ' ' .. level) .. prefix .. ': ' .. msg)
end

function Log:init(name)
  if name then
    self.namePrefix = ' ' .. bracket(name)
  else
    self.namePrefix = ''
  end
end

function Log:info(msg)
  genMsg('INFO', self.namePrefix, msg)
end

function Log:warn(msg)
  genMsg('WARN', self.namePrefix, msg)
end
function Log:error(msg)
  genMsg('ERROR', self.namePrefix, msg)
end

return Log
