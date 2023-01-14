local miku
miku = require("hatsune").miku
local yield
yield = function(...)
  return coroutine.yield("rana", ...)
end
local rana
do
  local _class_0
  local _base_0 = {
    run = function(self, ...)
      if coroutine.status(self.thread) == "dead" then
        return nil
      end
      local args = table.pack(...)
      while true do
        local result = table.pack(coroutine.resume(self.thread, table.unpack(args)))
        local ok, event
        ok, event = result[1], result[2]
        if not ok then
          error(event)
        end
        if event == "rana" then
          return select(3, table.unpack(result))
        elseif coroutine.status(self.thread) == "dead" then
          return 
        end
        args = table.pack(coroutine.yield(select(2, table.unpack(result))))
      end
    end,
    __call = function(self, ...)
      if self.args then
        local args = self.args
        self.args = nil
        return self:run(table.unpack(args))
      else
        return self:run(...)
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, fn, ...)
      self.fn = fn
      self.thread = coroutine.create(self.fn)
      self.args = table.pack(...)
    end,
    __base = _base_0,
    __name = "rana"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  rana = _class_0
end
local generator
generator = function(fn)
  return function(...)
    return rana(fn, ...)
  end
end
return {
  yield = yield,
  rana = rana,
  generator = generator
}
