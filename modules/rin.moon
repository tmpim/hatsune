import miku, throw, exception from require "hatsune"

KagamineException = exception "KagamineException"

version = "0.0.1"

-- http response class
class kagamine
  used: false

  new: (@url, @status, @statusText, @headers, @body, @error) =>

  _checkUsed: =>
    if @used
      throw KagamineException "Response already used"

  read: (...) =>
    @_checkUsed!
    result = @body.read ...
    @close! if result == nil
    result

  readLine: (...) =>
    @_checkUsed!
    result = @body.readLine ...
    @close! if result == nil
    result

  readAll: =>
    @_checkUsed!
    result = @body.readAll!
    @close!
    result

  close: =>
    return if @used
    @used = true
    @body\close!

  json: =>
    return textutils.unserializeJSON @readAll!

  lua: =>
    return textutils.unserialize @readAll!

  text: =>
    return @readAll!

requestSeq = 0

wrapResponse = (url, body, err) ->
  if not body
    return kagamine url, nil, nil, nil, nil, err
  else
    status, statusText = body.getResponseCode!
    headers = body.getResponseHeaders!
    return kagamine url, status, statusText, headers, body, err

-- fetch-like http implementation for computercraft
rin = (url, options) ->
  options = options or {}
  options.url = url .. "#" .. requestSeq
  requestSeq += 1

  miku (resolve, reject) ->
    ok = http.request options
    if not ok
      reject "http.request failed"
    else
      while true
        param = { coroutine.yield! }
        { event, eventUrl } = param
        if event == "http_success" and eventUrl == options.url
          body = param[3]
          resolve wrapResponse url, body, nil
          break
        elseif event == "http_failure" and eventUrl == options.url
          err, body = param[3], param[4]
          reject wrapResponse url, body, err
          break

{
  :kagamine, :rin, :KagamineException,
  :version
}
