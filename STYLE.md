# Coding style

### General
- Globals: Never.
- Indentation: 2 spaces.

### Naming
- lowerCamelCase for methods (e.g. ```o:setProperty()```).
- UpperCamelCase for objects.
- ALL_CAPS with underscores as spaces for constants.

## API Usage

##### Must target Lua 5.1's API
It is the most widely used Lua version and LuaJIT has 100% API compatibility with it.

##### No usage of module()
Use the new method of create modules. See [this](http://lua-users.org/wiki/ModulesTutorial).

##### No usage of debug.*
An exception applies for code with the sole purpose of debugging.

## Syntax

##### No implicit self argument
Do not use the semicolon to declare methods with an implicit ```self``` argument. Always explicitly declare it.

### Error handling

##### No usage of error() or assert() for libraries
Always return with ```nil``` and a string containing an error message when an error occurs.

##### Return number ```1``` upon success if there's nothing to return

##### Short-circuit error returns
Check as early as possible for errors and return as soon as possible if an error is encountered.

Don't:
```lua
local function receive(socket)
  if isSocket(socket) then
    local data = msg.unpack(socket:receive())
    handleData(data)
    return 1
  else
    return nil, 'socket (arg #1) is not a socket.'
  end
end
```

Do:
```lua
local function receive(socket)
  if not isSocket(socket) then
    return nil, 'socket (arg #1) is not a socket.'
  end
  local data = msg.unpack(socket:receive())
  handleData(data)
  return 1
end
```

### Types

##### Explicit type checking
No implicit truthiness checks. E.g. when checking for a nil value, use ```if value == nil then```, not ```if not value then```; if checking if a table exists, use ```if type(table) == 'table' then```, not ```if table then```.

##### No arithmetic operations on strings, nor string operations on numbers.
Do not use implicit type conversions for strings and numbers. Always use ```tostring()``` and ```tonumber()``` beforehand.
