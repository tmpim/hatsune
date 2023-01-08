local version = "0.1.0"
local logger = print
local log
log = function(msg)
  return logger("hatsune: " .. tostring(msg))
end
local setLogger
setLogger = function(fn)
  logger = fn
end
local indent
indent = function(level, str)
  return (" "):rep(level) .. str
end
local pretty
pretty = function(value, level)
  if level == nil then
    level = 0
  end
  if type(value) == "table" then
    if value.vararg then
      return table.concat((function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #value do
          local v = value[_index_0]
          _accum_0[_len_0] = pretty(v)
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(), ", ")
    end
    if getmetatable(value) and getmetatable(value).__tostring then
      return "[" .. tostring(value) .. "]"
    end
    local body = table.concat((function()
      local _accum_0 = { }
      local _len_0 = 1
      for k, v in pairs(value) do
        _accum_0[_len_0] = indent(level + 1, tostring(pretty(k, level + 1)) .. ": " .. tostring(pretty(v, level + 1)))
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)(), ",\n")
    return indent(level, "{") .. "\n" .. tostring(body) .. "\n" .. indent(level, "}")
  elseif type(value) == "function" then
    return "[" .. tostring(value) .. "]"
  elseif type(value) == "string" then
    return "\"" .. tostring(value) .. "\""
  else
    return tostring(value)
  end
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
          error(tostring(process.name) .. " died with an unhandled error:\n" .. tostring(pretty(err)))
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
      local args = table.pack(...)
      return self:onNamed("interval " .. tostring(interval), "timer", function(event, id)
        if id == timer then
          fn(table.unpack(args))
          timer = os.startTimer(interval)
        end
      end)
    end,
    timeout = function(self, timeout, fn, ...)
      local timer = os.startTimer(timeout)
      local args = table.pack(...)
      return self:onNamed("timeout " .. tostring(timeout), "timer", function(event, id)
        if id == timer then
          return fn(table.unpack(args))
        end
      end)
    end,
    schedule = function(self, name, fn, ...)
      local thread = coroutine.create(function(...)
        local ok, err = pcall(fn, ...)
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
local await, async, miku, awaitSafe, throw, Exception
do
  local _class_0
  local _base_0 = {
    value = nil,
    error = nil,
    fulfilled = false,
    _handleError = function(self, err)
      if type(err) == "table" and err.vararg then
        return self:_reject(table.unpack(err))
      else
        return self:_reject(Exception(err, 5))
      end
    end,
    _run = function(self)
      return xpcall(self.fn, (function()
        local _base_1 = self
        local _fn_0 = _base_1._handleError
        return function(...)
          return _fn_0(_base_1, ...)
        end
      end)(), (function()
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
    end,
    _fulfill = function(self, value, error)
      self.value = value
      self.error = error
      self.fulfilled = true
      return os.queueEvent("miku", self)
    end,
    _resolve = function(self, ...)
      local value = table.pack(...)
      return self:_fulfill(value, nil)
    end,
    _reject = function(self, ...)
      local error = table.pack(...)
      return self:_fulfill(nil, error)
    end,
    done = function(self, resolved, rejected)
      local first = self
      return miku(function(resolve, reject)
        local awaited = table.pack(awaitSafe(first))
        local ok
        ok = awaited[1]
        if ok and resolved then
          return resolve(resolved(select(2, table.unpack(awaited))))
        elseif rejected then
          return reject(rejected(select(2, table.unpack(awaited))))
        end
      end)
    end,
    fail = function(self, rejected)
      return self:done(nil, rejected)
    end,
    _returnAwait = function(self)
      if self.value ~= nil then
        return true, table.unpack(self.value)
      else
        return false, table.unpack(self.error)
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
      local awaited = table.pack(self:awaitSafe())
      local ok
      ok = awaited[1]
      if not ok then
        throw(select(2, table.unpack(awaited)))
      end
      return select(2, table.unpack(awaited))
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
  self.resolved = function(...)
    do
      local _with_0 = miku()
      _with_0:_resolve(...)
      return _with_0
    end
  end
  self.rejected = function(...)
    do
      local _with_0 = miku()
      _with_0:_reject(...)
      return _with_0
    end
  end
  miku = _class_0
end
async = function(fn)
  return function(...)
    local args = table.pack(...)
    return miku(function(resolve, reject)
      return resolve(fn(table.unpack(args)))
    end)
  end
end
awaitSafe = function(future, ...)
  if type(future == "table" and future.__class == miku) then
    return future:awaitSafe()
  else
    return true, future, ...
  end
end
await = function(future, ...)
  if type(future == "table" and future.__class == miku) then
    return future:await()
  else
    return future, ...
  end
end
throw = function(...)
  local err = table.pack(...)
  err.vararg = true
  return error(err)
end
do
  local _class_0
  local _base_0 = {
    __tostring = function(self)
      return tostring(self.__class.__name) .. ": " .. tostring(self.message) .. ", " .. tostring(self.traceback)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, message, level)
      self.message = message
      self.traceback = debug.traceback(nil, level or 3)
    end,
    __base = _base_0,
    __name = "Exception"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Exception = _class_0
end
local exception
exception = function(name)
  do
    local _class_0
    local _parent_0 = Exception
    local _base_0 = {
      __name = name,
      __tostring = function(self)
        return tostring(self.__name) .. ": " .. tostring(self.message) .. ", " .. tostring(self.traceback)
      end
    }
    _base_0.__index = _base_0
    setmetatable(_base_0, _parent_0.__base)
    _class_0 = setmetatable({
      __init = function(self, ...)
        return _class_0.__parent.__init(self, ...)
      end,
      __base = _base_0,
      __name = nil,
      __parent = _parent_0
    }, {
      __index = function(cls, name)
        local val = rawget(_base_0, name)
        if val == nil then
          local parent = rawget(cls, "__parent")
          if parent then
            return parent[name]
          end
        else
          return val
        end
      end,
      __call = function(cls, ...)
        local _self_0 = setmetatable({}, _base_0)
        cls.__init(_self_0, ...)
        return _self_0
      end
    })
    _base_0.__class = _class_0
    if _parent_0.__inherited then
      _parent_0.__inherited(_parent_0, _class_0)
    end
    return _class_0
  end
end
return {
  await = await,
  async = async,
  hatsune = hatsune,
  miku = miku,
  awaitSafe = awaitSafe,
  throw = throw,
  exception = exception,
  Exception = Exception,
  logger = setLogger,
  version = version
}
