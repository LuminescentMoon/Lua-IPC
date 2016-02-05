local oo

local tableop = {}
function tableop.merge(a, b)
  for k, v in pairs(b) do
    a[k] = v
  end
end

local function inherits(obj, objName, inheritable)
  local class = oo[objName](inheritable)
  tableop.merge(class, obj)
  return class
end

local vararg = {}

do
  local function helper(a, n, b, ...)
    if n == 0 then
      return a
    else
      return b, helper(a, n-1, ...)
    end
  end

  function vararg.append(a, ...)
    return vararg._helper(a, select('#', ...), ...)
  end
end

function vararg.ipairs(...)
  local i = 0
  local t = {}
  local l = select("#", ...)
  for n = 1, l do
    t[n] = select(n, ...)
  end
  for n = l+1, #t do
    t[n] = nil
  end
  return function()
    i = i + 1
    if i > l then return end
    return i, t[i]
  end
end

function vararg.pack(...)
  return {
    n = select('#', ...),
    ...
  }
end

function vararg.unpack(varargobj)
  return unpack(varargobj, 1, varargobj.n)
end

local typecheck = {}

function typecheck.isFalse(o)
  return type(o) == 'boolean' and not o
end

function typecheck.allString(...)
  for _, item in vararg.ipairs(...) do
    if type(item) ~= 'string' then
      return false
    end
  end
  return true
end

return function(currentDir)
  oo = require(currentDir .. '.lib.oo')
  return {
    vararg = vararg,
    type = typecheck,
    tableop = tableop,
    inherits = inherits
  }
end
