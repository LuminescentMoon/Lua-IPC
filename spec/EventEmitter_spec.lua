-- luacheck: globals describe context insulate expose it spec test randomize before_each after_each lazy_setup lazy_teardown setup teardown strict_setup strict_teardown finally pending spy stub mock async

local math = require('math')
local util = require('..spec.util')

local EventEmitter = require('ipc')().super

local DUMMY_NUM = math.random(1, 1000)
local ITERS = 15
local DUMMY_STR = 'ayylmao'
local NO_OP = function() end

describe('Class: EventEmitter', function()
  local eventEmitter, EventEmitters

  before_each(function()
    eventEmitter = EventEmitter()
  end)

  local function resetEEArray()
    EventEmitters = {}
    for i = 1, ITERS do
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
    it('should call each listener registered to the specified event', function()
      eventEmitter:setMaxListeners(ITERS)
      local listeners = {}
      for i = 1, ITERS do
        local func = stub()
        listeners[i] = func
        eventEmitter:on(DUMMY_STR, func)
      end
      eventEmitter:emit(DUMMY_STR)
      eventEmitter:emit(DUMMY_STR)
      for i = 1, #listeners do
        assert.stub(listeners[i]).was.called(2)
      end
    end)
    it('should call each listener in the order they were registered', function()
      local order = 1
      local nums = {}
      for i = 1, ITERS do
        local rnumber = math.random(1, 1000)
        nums[i] = rnumber
        eventEmitter:on(DUMMY_STR, function()
          assert.are.equal(rnumber, nums[order])
          order = order + 1
        end)
      end
    end)
    it('should pass the supplied arguments to each listener', function()
      local listeners = {}
      for i = 1, ITERS do
        local func = stub()
        listeners[i] = func
        eventEmitter:on(DUMMY_STR, func)
      end
      local function test()
        local garbage = util.mkgarbage(5)
        eventEmitter:emit(DUMMY_STR, garbage)
        for i = 1, #listeners do
          assert.stub(listeners[i]).was.called_with(garbage) -- TODO: Deep compare table
        end
      end
      test()
      test()
    end)
    it('should return true if event had listeners and false otherwise', function()
      eventEmitter:on(DUMMY_STR)
      assert.is_true(eventEmitter:emit(DUMMY_STR))
      assert.is_false(eventEmitter:emit(''))
    end)
  end)

  describe('Method: \':listenerCount\'', function()
    it('should return the number of listeners listening to the specified event', function()
      for _ = 1, ITERS do
        eventEmitter:on(DUMMY_STR, NO_OP)
      end
      assert.are.equal(ITERS, eventEmitter:listenerCount(DUMMY_STR))
    end)
  end)

  describe('Method: \':listeners\'', function()
    it('should return a copy of the array of listeners registered for the specified event', function()
      local listeners = {}
      for i = 1, ITERS do
        local func = util.mkfunc()
        listeners[i] = func
        eventEmitter:on(DUMMY_STR, func)
      end
      assert.are_not.equal(eventEmitter._events[DUMMY_STR], eventEmitter:listeners(DUMMY_STR))
      for i, listener in ipairs(eventEmitter:listeners(DUMMY_STR)) do
        assert.are.equal(listeners[i], listener)
      end
    end)
  end)

  describe('Method: \':on\'', function()
    it('should register specified listener function with specified event', function()
      eventEmitter:on(DUMMY_STR, NO_OP)
      assert.are.equal(NO_OP, eventEmitter._events[DUMMY_STR][1])
    end)
    it('should add listener to end of internal array of listeners for event', function()
      eventEmitter._events[DUMMY_STR] = {}
      local func = util.mkfunc()
      for i = 1, ITERS do
        eventEmitter._events[DUMMY_STR][i] = NO_OP
      end
      eventEmitter:on(DUMMY_STR, func)
      assert.are.equal(func, eventEmitter._events[DUMMY_STR][#eventEmitter._events[DUMMY_STR]])
    end)
    it('should return self so calls can be chained', function()
      assert.are.equal(eventEmitter, eventEmitter:on(DUMMY_STR, NO_OP))
    end)
  end)

  describe('Method: \':once\'', function()
    it('should register listener function with event', function()
      eventEmitter:once(DUMMY_STR, NO_OP)
      assert.are.equal(NO_OP, eventEmitter._events[DUMMY_STR][1].func)
    end)
    it('should remove listener registered with this method on listener invoke', function()
      eventEmitter:once(DUMMY_STR, NO_OP)
      eventEmitter:emit(DUMMY_STR)
      assert.are.equal(nil, eventEmitter._events[DUMMY_STR])
    end)
    it('should return self so calls can be chained', function()
      assert.are.equal(eventEmitter, eventEmitter:once(DUMMY_STR, NO_OP))
    end)
  end)

  describe('Method: \':removeListener\'', function()
    it('should remove specified listener function from the specified event', function()
      local emitted, evcalled, func = false, false
      for _ = 1, ITERS do
        func = util.mkfunc()
        eventEmitter:on(DUMMY_STR, func)
      end
      func = function()
        emitted = true
      end
      eventEmitter:on(DUMMY_STR, func)
      eventEmitter:on('removeListener', function(event, listener)
        assert.are.equal(DUMMY_STR, event)
        assert.are.equal(func, listener)
        evcalled = true
      end)
      eventEmitter:removeListener(DUMMY_STR, func)
      assert.is_true(evcalled)
      eventEmitter:emit(DUMMY_STR)
      assert.is_not_true(emitted)
    end)
    it('should only at most remove one listener', function()
      for _ = 1, ITERS do
        eventEmitter:on(DUMMY_STR, NO_OP)
      end
      local amount = #eventEmitter:listeners(DUMMY_STR)
      eventEmitter:removeListener(DUMMY_STR, NO_OP)
      assert.is_true(#eventEmitter:listeners(DUMMY_STR) + 1 == amount)
    end)
    it('should return self so calls can be chained', function()
      assert.are.equal(eventEmitter, eventEmitter:removeListener(DUMMY_STR, NO_OP))
    end)
  end)

  describe('Event: \'newListener\'', function()
    it('should be emitted on listener registration', function()
      local emitted1, emitted2 = false, false
      eventEmitter:on(DUMMY_STR, function()
        emitted1 = true
      end)
      eventEmitter:once(DUMMY_STR, function()
        emitted2 = true
      end)
      eventEmitter:emit(DUMMY_STR)
      assert.is_true(emitted1)
      assert.is_true(emitted2)
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
      eventEmitter:on('newListener', NO_OP)
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
      eventEmitter:on('removeListener', NO_OP)
      stub(eventEmitter, 'emit')
      eventEmitter:removeListener(DUMMY_STR, NO_OP)
      assert.stub(eventEmitter.emit).was.called_with(eventEmitter, 'removeListener', DUMMY_STR, NO_OP)
    end)
  end)
end)
