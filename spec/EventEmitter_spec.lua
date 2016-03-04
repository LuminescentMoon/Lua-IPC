-- luacheck: globals describe context insulate expose it spec test randomize before_each after_each lazy_setup lazy_teardown setup teardown strict_setup strict_teardown finally pending spy stub mock async

local EventEmitter = require('ipc').super

local DUMMY_NUM = math.random(1, 1000)
local DUMMY_STR = 'ayylmao'
local NO_OP = function() end

describe('Class: EventEmitter', function()
  local eventEmitter, EventEmitters

  before_each(function()
    eventEmitter = EventEmitter()
  end)

  local function resetEEArray()
    EventEmitters = {}
    for i = 1, 15 do
      EventEmitter[i] = EventEmitter()
    end
  end

  describe('Max listeners limit behavior', function()
    it('.defaultMaxListeners should be inherited by individual EventEmitter instances', function()
      assert.are.equal(EventEmitter.defaultMaxListeners, eventEmitter:getMaxListeners())
    end)
    it('.defaultMaxListeners changes should be propogated to all EventEmitter instances', function()
      resetEEArray()
      local function test()
        EventEmitter.defaultMaxListeners = math.random(1, 1000)
        for _, ee in ipairs(EventEmitters) do
          assert.are.equal(EventEmitter.defaultMaxListeners, ee:getMaxListeners())
        end
      end
      test()
      test()
    end)
    it('Limit set by :setMaxListeners() should override the inherited .defaultMaxListeners limit', function()
      local limit = math.random(1, 1000)
      eventEmitter:setMaxListeners(limit)
      assert.are.equal(limit, eventEmitter:getMaxListeners())
    end)
    pending('Warning should be output to log when the amount of listeners registered for an event exceed the limit')
    pending('Limit of 0 or math.huge should indicate an unlimited number of listeners')

    describe('Method: \':getMaxListeners\'', function()
      it('should return current max listener value', function()
        local function test()
          local limit = math.random(1, 1000)
          eventEmitter:setMaxListeners(limit)
          assert.are.equal(limit, eventEmitter:getMaxListeners())
        end
        test()
        test()
      end)
    end)

    describe('Method: \':setMaxListeners\'', function()
      it('should set the max listener value for the instance', function()
        resetEEArray()
        local numbers = {}
        for i = 1, #EventEmitters do
          numbers[i] = math.random(1, 1000)
          EventEmitters[i]:setMaxListeners(numbers[i])
        end
        for i = 1, #EventEmitters do
          assert.are.equal(numbers[i], EventEmitter[i]:getMaxListeners())
        end
      end)
      it('should return the eventEmitter instance', function()
        assert.are.equal(eventEmitter, eventEmitter:setMaxListeners(DUMMY_NUM))
      end)
    end)
  end)

  describe('Method: \':addListener\'', function()
    it('should be an alias for the method \':on\'', function()
      assert.are.equal(eventEmitter.on, eventEmitter.addListener)
    end)
  end)

  describe('Method: \':emit\'', function()
    pending('should call each listener registered to the specified event')
    pending('should call each listener in the order they were registered')
    pending('should pass the supplied arguments to each listener')
    pending('should return true if event had listeners and false otherwise')
  end)

  describe('Method: \':listenerCount\'', function()
    pending('should return the number of listeners listening to the specified event')
  end)

  describe('Method: \':listeners\'', function()
    pending('should return a copy of the array of listeners registered for the specified event')
  end)

  describe('Method: \':on\'', function()
    pending('should register specified listener function with specified event')
    pending('should add listener to end of internal array of listeners for event')
    pending('should return self so calls can be chained')
  end)

  describe('Method: \':once\'', function()
    pending('should register listener function with event')
    pending('should remove listener registered with this method on listener invoke')
    pending('should return self so calls can be chained')
  end)

  describe('Method: \':removeListener\'', function()
    pending('should remove specified listener function from the specified event')
    pending('should only at most remove one listener')
    pending('should return self so calls can be chained')
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
