local LuaSocket, MessagePack, localhost, vararg

local IPC = {
  _VERSION = '0.0.1-EarlyAccess'
}

local function hasData(socket)
  return LuaSocket.select({socket}, nil, 0)[1] == socket
end

function IPC.setFilter(self, port)
  local address = port == '*' and '*' or localhost
  return self.__socket:setpeername(address, port)
end

function IPC.after_init(self, port)
  local socket, success, err
  socket, err = LuaSocket.udp()
  if socket == nil then return nil, err end
  success, err = socket:setsockname(localhost, port)
  if not success then return nil, err end
  success, err = socket:setoption('dontroute', true)
  if not success then return nil, err end
  socket:settimeout(0)
  self.__socket = socket
  return 1
end

function IPC.send(self, channel, ...)
  if type(channel) == 'string' then
    local args = (...) and vararg.pack(...) or nil
    return self.__socket:send(MessagePack.pack({channel, args}))
  else
    return nil, 'Channel (arg #1) must be a string.'
  end
end

function IPC.pump(self)
  local socket = self.__socket
  while hasData(socket) == true do
    local data
    data = socket:receive(65507) -- UDP max datagram size taking protocol overheads into account.
    data = MessagePack.unpack(data)
    if type(data) == 'table' and type(data[1]) == 'string' then
      local args = type(data[2]) == 'table' and vararg.unpack(data[2]) or nil
      self:emit(data[1], args)
    end
  end
  return 1
end

return function(currentDir)
  local G = require(currentDir .. '.lib.ev')(currentDir .. '.lib.ev')
  vararg = G.util.vararg

  LuaSocket = require('socket')
  MessagePack = require(currentDir .. '.lib.MessagePack')
  MessagePack.set_string('binary')

  local err
  localhost, err = LuaSocket.dns.toip('localhost')

  if localhost == nil then
    return nil, err
  end

  local inherits = G.util.inherits
  return inherits(IPC, 'IPC', G.EventEmitter)
end
