local Client, Server

local IPC = {
  _VERSION = '0.0.1-EarlyAccess'
}

function IPC.client()
  return Client()
end

function IPC.server()
  return Server()
end

return function(currentDir)
  local G = require(currentDir .. '.lib.ev')(currentDir .. '.lib.ev')

  local LuaSocket = require('socket')
  local MessagePack = require(currentDir .. '.lib.MessagePack')

  local inherits = G.util.inherits

  Client = require(currentDir .. '.src.Client')(inherits, G.EventEmitter, LuaSocket, MessagePack, G.setInterval)
  Server = require(currentDir .. '.src.Server')(LuaSocket, MessagePack)

  return IPC
end
