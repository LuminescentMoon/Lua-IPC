local math = require('math')
local stringExists = pcall(require, 'string')
local coroutineExists = pcall(require, 'coroutine')

local util = {}

local function table_eq(table1, table2)
  local avoid_loops = {}
  local function recurse(t1, t2)
    -- compare value types
    if type(t1) ~= type(t2) then return false end
    -- Base case: compare simple values
    if type(t1) ~= 'table' then return t1 == t2 end
    -- Now, on to tables.
    -- First, let's avoid looping forever.
    if avoid_loops[t1] then return avoid_loops[t1] == t2 end
    avoid_loops[t1] = t2
    -- Copy keys from t2
    local t2keys = {}
    local t2tablekeys = {}
    for k, _ in pairs(t2) do
       if type(k) == 'table' then table.insert(t2tablekeys, k) end
       t2keys[k] = true
    end
    -- Let's iterate keys from t1
    for k1, v1 in pairs(t1) do
      local v2 = t2[k1]
      if type(k1) == 'table' then
        -- if key is a table, we need to find an equivalent one.
        local ok = false
        for i, tk in ipairs(t2tablekeys) do
          if table_eq(k1, tk) and recurse(v1, t2[tk]) then
            table.remove(t2tablekeys, i)
            t2keys[tk] = nil
            ok = true
            break
          end
        end
        if not ok then return false end
      else
        -- t1 has a key which t2 doesn't have, fail.
        if v2 == nil then return false end
        t2keys[k1] = nil
        if not recurse(v1, v2) then return false end
      end
    end
  -- if t2 has a key which t1 doesn't have, fail.
    if next(t2keys) then return false end
    return true
  end
  return recurse(table1, table2)
end

util.comparetable = table_eq

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
  len = len and len >= 3 or 5
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
  __call = function(_, len)
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
