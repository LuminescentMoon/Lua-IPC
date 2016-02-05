local LuaSocket, MessagePack

local Server = {}

function Server.init()
  return setmetatable({}, Server)
end



return function(socket, msgpack)
  LuaSocket = socket
  MessagePack = msgpack
  return Server.init
end
