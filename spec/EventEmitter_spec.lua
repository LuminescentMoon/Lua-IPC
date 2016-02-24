-- luacheck: globals describe context insulate expose it spec test randomize before_each after_each lazy_setup lazy_teardown setup teardown strict_setup strict_teardown finally pending spy stub mock async

local EventEmitter = require('ipc').super

local DUMMY_STR = 'ayylmao'
local NO_OP = function() end

describe('Class: EventEmitter', function()
  local eventEmitter

  before_each(function()
    eventEmitter = EventEmitter()
  end)

  describe('Max listeners limit behavior', function()
    pending('.defaultMaxListeners should be inherited by individual EventEmitter instances')
    pending('.defaultMaxListeners changes should be propogated to all EventEmitter instances')
    pending('Limit set by :setMaxListeners() should override the inherited .defaultMaxListeners limit')
    pending('Warning should be output to log when the amount of listeners registered for an event exceed the limit')
    pending('Limit of 0 or math.huge should indicate an unlimited number of listeners')

    describe('Method: \'getMaxListeners\'', function()
      pending('should return current max listener value')
      pending('should respect the current instance\'s max listener value over the default')
      pending('should return .defaultMaxListeners if max listener value is not set for the instance')
    end)

    describe('Method: \'setMaxListeners\'', function()
      pending('should set the max listener value for the instance')
      pending('should return the eventEmitter instance')
    end)
  end)

  describe('Event: \'newListener\'', function()
    it('should be emitted on listener registration', function()
      local emitted = false
      eventEmitter:on(DUMMY_STR, function()
        emitted = true
      end)
      eventEmitter:emit(DUMMY_STR)
      assert.is_true(emitted)
    end)

    it('should be emitted before listener is added', function()
      local function count(event) return #eventEmitter:listeners(event) end
      eventEmitter:on('newListener', function()
        assert.are.equal(0, count(DUMMY_STR))
      end)
      eventEmitter:on(DUMMY_STR, NO_OP)
      assert.are.equal(1, count(DUMMY_STR))
    end)

    it('should pass to listeners the event name and the handler function to be added when emitted', function()
      stub(eventEmitter, 'emit')
      eventEmitter:on(DUMMY_STR, NO_OP)
      assert.stub(eventEmitter.emit).was.called_with(eventEmitter, 'newListener', DUMMY_STR, NO_OP)
    end)
  end)

  describe('Event: \'removeListener\'', function()
    it('should be emitted on listener removal', function()
      local emitted = false
      eventEmitter:on('removeListener', function()
        emitted = true
      end)
      eventEmitter:on(DUMMY_STR, NO_OP)
      eventEmitter:removeListener(DUMMY_STR, NO_OP)
      assert.is_true(emitted)
    end)

    it('should be emitted after removing a listener', function()
      local function count(event) return #eventEmitter:listeners(event) end
      eventEmitter:on('removeListener', function()
        assert.are.equal(0, count(DUMMY_STR))
      end)
      eventEmitter:on(DUMMY_STR, NO_OP)
      eventEmitter:removeListener(DUMMY_STR, NO_OP)
    end)

    it('should pass to listeners the event name and the handler function removed when emitted', function()
      eventEmitter:on(DUMMY_STR, NO_OP)
      stub(eventEmitter, 'emit')
      eventEmitter:removeListener(DUMMY_STR, NO_OP)
      assert.stub(eventEmitter.emit).was.called_with(eventEmitter, 'removeListener', DUMMY_STR, NO_OP)
    end)
  end)
end)
