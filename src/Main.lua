local LuaSocket, MessagePack

local IPC = {
  _VERSION = '0.0.1-EarlyAccess'
}

function IPC:setFilter(port)

end

return function(currentDir)
  local G = require(currentDir .. '.lib.ev')(currentDir .. '.lib.ev')

  LuaSocket = require('socket')
  MessagePack = require(currentDir .. '.lib.MessagePack')

  local inherits = G.util.inherits
  return inherits(IPC, 'IPC', G.EventEmitter)
end
