local G

local function buildList(optional, array)
  assert(type(optional) == 'boolean')
  local conjunction = optional and 'or' or 'and'
  local string = ''
  if type(array) ~= 'table' then
    string = tostring(array)
  elseif #array > 2 then
    for i, item in ipairs(array) do
      item = tostring(item)
      if array[i + 1] == nil then
        string = string .. conjunction .. ' ' .. item
      else
        string = string .. item .. ', '
      end
    end
  elseif #array == 2 then
    string = tostring(array[1]) .. ' ' .. conjunction .. ' ' .. tostring(array[2])
  elseif #array == 1 then
    string = tostring(array[1])
  else -- #array <= 0
    string = 'table'
  end
  return string
end

local TypeError = {}

function TypeError:before_init(...) -- Temporarily here due to bug in oo library. https://github.com/luapower/oo/issues/1
  getmetatable(self).__tostring = function()
    return self.msg
  end
  return ...
end

function TypeError:override_init(_, stackLvl, parameterNames, expectedTypes, providedType)
  providedType = type(providedType) == 'string' and providedType or type(providedType)
  local pluralS = type(parameterNames) == 'table' and #parameterNames > 1 and 's' or ''
  local conjunction = type(expectedTypes) == 'table' and #expectedTypes == 2 and ' either' or ''
  parameterNames, expectedTypes = buildList(false, parameterNames), buildList(true, expectedTypes) -- TODO: Different messages depending on if method, function, field, or object.
  self.name = 'TypeError'
  if type(stackLvl) == 'number' then
    self.stackLvl = stackLvl + 2
  else
    TypeError(4, 'stackLvl', 'number', stackLvl)
  end
  self.msg = 'Parameter' .. pluralS .. ' "' .. parameterNames .. '" must be' .. conjunction .. ' a ' .. expectedTypes .. ', not ' .. providedType .. '.'
  return self
end

function TypeError:after_init() -- Temporarily here due to bug in oo library. https://github.com/luapower/oo/issues/1
  self:stack()
  G.process:emit('uncaughtException', self)
end

return function(inherits, Error, g)
  G = g
  TypeError = inherits(TypeError, 'TypeError', Error)
  return TypeError
end
