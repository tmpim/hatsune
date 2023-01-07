local version = "0.0.0"
local logger = print
local log
log = function(msg)
  return logger("hatsune: " .. tostring(msg))
end
local setLogger
setLogger = function(fn)
  logger = fn
end
local hatsune
do
  local _class_0
  local _base_0 = {
    shuttingDown = false,
    run = function(self, fn)
      if fn then
        self:schedule("start", fn)
      end
      while true do
        local count = self:executeAll(coroutine.yield())
        if count == 0 then
          break
        end
      end
      if not self.shuttingDown then
        return log("terminated")
      end
    end,
    executeAll = function(self, event, ...)
      local count = 0
      for pid, process in pairs(self.processes) do
        process = self:execute(process, event, ...)
        if not process then
          self.processes[pid] = nil
        else
          self.processes[pid] = process
          count = count + 1
        end
      end
      return count
    end,
    execute = function(self, process, ...)
      if coroutine.status(process.thread) == "suspended" then
        local _, msg, err = coroutine.resume(process.thread, ...)
        if msg == "aaaaa" then
          error(tostring(process.name) .. " died with an unhandled error:\n" .. tostring(err))
        end
      end
      if coroutine.status(process.thread) == "dead" then
        return nil
      else
        return process
      end
    end,
    onNamed = function(self, name, event, fn)
      return self:schedule(name, function()
        while true do
          local data = {
            coroutine.yield()
          }
          if data[1] == event then
            fn(table.unpack(data))
          elseif data[1] == "terminate" then
            break
          end
        end
      end)
    end,
    on = function(self, event, fn)
      return self:onNamed("on " .. tostring(event), event, fn)
    end,
    interval = function(self, interval, fn, ...)
      local timer = os.startTimer(interval)
      local args = {
        ...
      }
      return self:onNamed("interval " .. tostring(interval), "timer", function(event, id)
        if id == timer then
          fn(table.unpack(args))
          timer = os.startTimer(interval)
        end
      end)
    end,
    timeout = function(self, timeout, fn, ...)
      local timer = os.startTimer(timeout)
      local args = {
        ...
      }
      return self:onNamed("timeout " .. tostring(timeout), "timer", function(event, id)
        if id == timer then
          return fn(table.unpack(args))
        end
      end)
    end,
    schedule = function(self, name, fn, ...)
      local thread = coroutine.create(function(...)
        local ok, err = xpcall(fn, debug.traceback, ...)
        if not ok then
          return coroutine.yield("aaaaa", err)
        end
      end)
      local process = {
        name = name,
        thread = thread
      }
      self:execute(process, ...)
      return table.insert(self.processes, process)
    end,
    unschedule = function(self, thread)
      for i, t in pairs(self.processes) do
        if t == thread then
          self.processes[i] = nil
          return true
        end
      end
      return false
    end,
    shutdown = function(self)
      self.shuttingDown = true
      return os.queueEvent("terminate")
    end,
    exit = function(self)
      self:shutdown()
      self.processes = { }
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self.processes = { }
      _HATSUNE_LOOP = self
    end,
    __base = _base_0,
    __name = "hatsune"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  hatsune = _class_0
end
local await, async, miku, awaitSafe
do
  local _class_0
  local _base_0 = {
    value = nil,
    error = nil,
    fulfilled = false,
    _run = function(self)
      local ok, err = pcall(self.fn, (function()
        local _base_1 = self
        local _fn_0 = _base_1._resolve
        return function(...)
          return _fn_0(_base_1, ...)
        end
      end)(), (function()
        local _base_1 = self
        local _fn_0 = _base_1._reject
        return function(...)
          return _fn_0(_base_1, ...)
        end
      end)())
      if not ok then
        return self:_reject(err)
      end
    end,
    _fulfill = function(self, value, error)
      self.value = value
      self.error = error
      self.fulfilled = true
      return os.queueEvent("miku", self)
    end,
    _resolve = function(self, value)
      return self:_fulfill(value, nil)
    end,
    _reject = function(self, error)
      return self:_fulfill(nil, error)
    end,
    done = function(self, resolved, rejected)
      local first = self
      return miku(function(resolve, reject)
        local ok, result = awaitSafe(first)
        if ok and resolved then
          return resolve(resolved(result))
        elseif rejected then
          return reject(rejected(result))
        end
      end)
    end,
    fail = function(self, rejected)
      return self:done(nil, rejected)
    end,
    _returnAwait = function(self)
      if self.value ~= nil then
        return true, self.value
      else
        return false, self.error
      end
    end,
    awaitSafe = function(self)
      if self.fulfilled then
        return self:_returnAwait()
      else
        while true do
          local event, future = coroutine.yield()
          if event == "miku" and future == self then
            return self:_returnAwait()
          end
        end
      end
    end,
    await = function(self)
      local ok, result = self:awaitSafe()
      if not ok then
        error(result)
      end
      return result
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, fn)
      self.fn = fn
      self.name = tostring(self):sub(8)
      self.traceback = debug.traceback(nil, 3)
      if self.fn then
        self.process = _HATSUNE_LOOP:schedule(self.name, (function()
          local _base_1 = self
          local _fn_0 = _base_1._run
          return function(...)
            return _fn_0(_base_1, ...)
          end
        end)())
      end
    end,
    __base = _base_0,
    __name = "miku"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.resolved = function(value)
    do
      local _with_0 = miku()
      _with_0:_resolve(value)
      return _with_0
    end
  end
  self.rejected = function(error)
    do
      local _with_0 = miku()
      _with_0:_reject(error)
      return _with_0
    end
  end
  miku = _class_0
end
async = function(fn)
  return function(...)
    local args = {
      ...
    }
    return miku(function(resolve, reject)
      return resolve(fn(table.unpack(args)))
    end)
  end
end
awaitSafe = function(future)
  if type(future == "table" and future.__class == miku) then
    return future:awaitSafe()
  else
    return true, future
  end
end
await = function(future)
  if type(future == "table" and future.__class == miku) then
    return future:await()
  else
    return future
  end
end
return {
  await = await,
  async = async,
  hatsune = hatsune,
  miku = miku,
  awaitSafe = awaitSafe,
  logger = setLogger,
  version = version
}
