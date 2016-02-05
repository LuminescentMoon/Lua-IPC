local LuaSocket, MessagePack, setInterval

local function isConnected(socket)
  return tostring(socket):find('connected') and true or false
end

local Client = {}

function Client.listen(self, port)
  if self.socket then Client.disconnect(self) end
  local socket = LuaSocket.udp()
  socket:setsockname('127.0.0.1', port)
  socket:settimeout(0)
  setInterval(Client._tick, self)
  self.socket = socket
end

function Client.from(self, port)

end

function Client.disconnect(self)
  self.socket:close()
  self.socket = nil
end

function Client._receive(self, data)
  local event = MessagePack.unpack(data)
  if type(event) == 'table' and type(event[1]) == 'string' then
    self:emit(event[1], select(1, unpack(event)))
  end
end

function Client._tick(self)
  while LuaSocket.select({self.socket}, nil, 0)[1] do
    Client._receive(self, self.socket:receive(65536))
  end
end

return function(inherits, EventEmitter, socket, msgpack, setinterval)
  LuaSocket = socket
  MessagePack = msgpack
  setInterval = setinterval
  return inherits(Client, 'Client', EventEmitter)
end
