-- luacheck: globals describe context insulate expose it spec test randomize before_each after_each lazy_setup lazy_teardown setup teardown strict_setup strict_teardown finally pending spy stub mock async

local IPC = require('ipc')

local DUMMY_STR = 'ayylmao'
local NO_OP = function() end

describe('Class: EventEmitter', function()
  local eventEmitter

  before_each(function()
    eventEmitter = IPC.super()
  end)

  describe('Event: \'newListener\'', function()
    it('should be emitted on listener registration before the listener is added to its internal array of listeners', function()
      local emitted = false
      local arrayLen = #eventEmitter:listeners(DUMMY_STR)
      eventEmitter:on('newListener', function()
        emitted = true
      end)
      eventEmitter:on(DUMMY_STR, NO_OP)


    end) -- TODO

    it('should pass the event name and the event handler function to be added when emitted', function()
      stub(eventEmitter, 'emit')
      eventEmitter:on(DUMMY_STR, NO_OP)
      assert.stub(eventEmitter.emit).was.called_with(eventEmitter, 'newListener', DUMMY_STR, NO_OP)
    end)
  end)



end)
