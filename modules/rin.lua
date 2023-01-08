local miku, throw, exception
do
  local _obj_0 = require("hatsune")
  miku, throw, exception = _obj_0.miku, _obj_0.throw, _obj_0.exception
end
local KagamineException = exception("KagamineException")
local version = "0.0.1"
local kagamine
do
  local _class_0
  local _base_0 = {
    used = false,
    _checkUsed = function(self)
      if self.used then
        return throw(KagamineException("Response already used"))
      end
    end,
    read = function(self, ...)
      self:_checkUsed()
      local result = self.body.read(...)
      if result == nil then
        self:close()
      end
      return result
    end,
    readLine = function(self, ...)
      self:_checkUsed()
      local result = self.body.readLine(...)
      if result == nil then
        self:close()
      end
      return result
    end,
    readAll = function(self)
      self:_checkUsed()
      local result = self.body.readAll()
      self:close()
      return result
    end,
    close = function(self)
      if self.used then
        return 
      end
      self.used = true
      return self.body:close()
    end,
    json = function(self)
      return textutils.unserializeJSON(self:readAll())
    end,
    lua = function(self)
      return textutils.unserialize(self:readAll())
    end,
    text = function(self)
      return self:readAll()
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, url, status, statusText, headers, body, error)
      self.url, self.status, self.statusText, self.headers, self.body, self.error = url, status, statusText, headers, body, error
    end,
    __base = _base_0,
    __name = "kagamine"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  kagamine = _class_0
end
local requestSeq = 0
local wrapResponse
wrapResponse = function(url, body, err)
  if not body then
    return kagamine(url, nil, nil, nil, nil, err)
  else
    local status, statusText = body.getResponseCode()
    local headers = body.getResponseHeaders()
    return kagamine(url, status, statusText, headers, body, err)
  end
end
local rin
rin = function(url, options)
  options = options or { }
  options.url = url .. "#" .. requestSeq
  requestSeq = requestSeq + 1
  return miku(function(resolve, reject)
    local ok = http.request(options)
    if not ok then
      return reject("http.request failed")
    else
      while true do
        local param = {
          coroutine.yield()
        }
        local event, eventUrl
        event, eventUrl = param[1], param[2]
        if event == "http_success" and eventUrl == options.url then
          local body = param[3]
          resolve(wrapResponse(url, body, nil))
          break
        elseif event == "http_failure" and eventUrl == options.url then
          local err, body = param[3], param[4]
          reject(wrapResponse(url, body, err))
          break
        end
      end
    end
  end)
end
return {
  kagamine = kagamine,
  rin = rin,
  KagamineException = KagamineException,
  version = version
}
