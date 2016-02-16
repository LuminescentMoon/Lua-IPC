package = "Lua-IPC"
version = "scm-1"

source = {
  url = "https://github.com/Luminess/Lua-IPC"
}

description = {
  summary = "Inter-process communications between Lua runtimes using LuaSocket",
  license = "MIT/X11",
  homepage = "https://github.com/Luminess/Lua-IPC",
  maintainer = "Howard Nguyen"
}

dependencies = {
  "lua >= 5.1",
  "luasocket"
}

build = {
  type = "builtin",
  modules = {
    ipc = "./src/Main.lua"
  }
}
