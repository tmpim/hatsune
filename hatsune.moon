version = "0.1.0"

export _HATSUNE_LOOP

logger = print
log = (msg) ->
  logger "hatsune: #{msg}"

setLogger = (fn) ->
  logger = fn

indent = (level, str) ->
  " "\rep(level) .. str

pretty = (value, level = 0) ->
  if type(value) == "table"
    if value.vararg
      return table.concat [pretty v for v in *value], ", "

    if getmetatable(value) and getmetatable(value).__tostring
      return "[#{value}]"

    body = table.concat [indent level + 1, "#{pretty k, level + 1}: #{pretty v, level + 1}" for k, v in pairs value], ",\n"
    return indent(level, "{") .. "\n#{body}\n" .. indent(level, "}")
  elseif type(value) == "function"
    return "[#{value}]"
  elseif type(value) == "string"
    return "\"#{value}\""
  else
    return tostring value

-- cute event loop
class hatsune
  shuttingDown: false

  new: =>
    @processes = {}
    _HATSUNE_LOOP = @

  run: (fn) =>
    @schedule "start", fn if fn
    while true
      count = @executeAll coroutine.yield!
      break if count == 0
    log "terminated" if not @shuttingDown

  executeAll: (event, ...) =>
    count = 0
    for pid, process in pairs @processes
      process = @execute process, event, ...
      if not process
        @processes[pid] = nil
      else
        @processes[pid] = process
        count += 1
    count

  execute: (process, ...) =>
    if coroutine.status(process.thread) == "suspended"
      _, msg, err = coroutine.resume process.thread, ...
      if msg == "aaaaa"
        error "#{process.name} died with an unhandled error:\n#{pretty err}"

    if coroutine.status(process.thread) == "dead"
      -- cleanup
      return nil
    else
      return process

  onNamed: (name, event, fn) =>
    @schedule name, ->
      while true
        data = { coroutine.yield! }
        if data[1] == event
          fn table.unpack data
        elseif data[1] == "terminate"
          break

  on: (event, fn) =>
    @onNamed "on #{event}", event, fn

  interval: (interval, fn, ...) =>
    timer = os.startTimer interval
    args = table.pack ...
    @onNamed "interval #{interval}", "timer", (event, id) ->
      if id == timer
        @schedule "spawned interval #{interval}", -> fn table.unpack args
        timer = os.startTimer interval

  timeout: (timeout, fn, ...) =>
    timer = os.startTimer timeout
    args = table.pack ...
    @onNamed "timeout #{timeout}", "timer", (event, id) ->
      if id == timer
        fn table.unpack args

  schedule: (name, fn, ...) =>
    thread = coroutine.create (...) ->
      ok, err = pcall fn, ...
      if not ok
        coroutine.yield "aaaaa", err
    process = { :name, :thread }
    @execute process, ...
    table.insert @processes, process
    process

  unschedule: (thread) =>
    for i, t in pairs @processes
      if t == thread
        @processes[i] = nil
        return true
    false

  shutdown: =>
    @shuttingDown = true
    os.queueEvent "terminate"

  exit: =>
    @shutdown!
    @processes = {}

local await, async, miku, awaitSafe, throw, Exception

-- she's from the future
idCounter = 0
class miku
  value: nil
  error: nil
  fulfilled: false

  new: (@fn) =>
    @id = idCounter
    idCounter += 1
    if idCounter > 1000000000000000
      idCounter = 0 -- Hope you don't have 1 quadrillion promises running at once :)

    @name = tostring(@)\sub 8
    @traceback = debug.traceback(nil, 3)
    @process = _HATSUNE_LOOP\schedule @name, @\_run if @fn

  @resolved: (...) ->
    with miku!
      \_resolve ...

  @rejected: (...) ->
    with miku!
      \_reject ...

  _handleError: (err) =>
    if type(err) == "table" and err.vararg
      @_reject table.unpack err
    elseif type(err) == "string"
      @_reject Exception err, 5
    else
      @_reject err

  _run: =>
    xpcall (-> @.fn @\_resolve, @\_reject), @\_handleError

  _fulfill: (value, error) =>
    @value = value
    @error = error
    @fulfilled = true
    os.queueEvent "miku", @

  _resolve: (...) =>
    value = table.pack ...
    @_fulfill value, nil

  _reject: (...) =>
    error = table.pack ...
    @_fulfill nil, error

  done: (resolved, rejected) =>
    first = @
    miku (resolve, reject) ->
      awaited = table.pack awaitSafe first
      { ok } = awaited
      if ok and resolved
        resolve resolved select 2, table.unpack awaited
      elseif rejected
        reject rejected select 2, table.unpack awaited

  fail: (rejected) =>
    @done nil, rejected

  _returnAwait: =>
    if @value ~= nil
      return true, table.unpack @value
    else
      return false, table.unpack @error

  awaitSafe: =>
    if @fulfilled
      return @_returnAwait!
    else
      while true
        event, future = coroutine.yield!
        if event == "miku" and future.id == @id
          return @_returnAwait!

  await: =>
    awaited = table.pack @awaitSafe!
    { ok } = awaited
    if not ok
      throw select 2, table.unpack awaited
    select 2, table.unpack awaited

async = (fn) ->
  (...) ->
    args = table.pack ...
    miku (resolve, reject) ->
      resolve fn table.unpack args

awaitSafe = (future, ...) ->
  if type future == "table" and future.__class == miku
    return future\awaitSafe!
  else
    return true, future, ...

await = (future, ...) ->
  if type future == "table" and future.__class == miku
    return future\await!
  else
    return future, ...

throw = (...) ->
  err = table.pack ...
  err.vararg = true
  error err

class Exception
  new: (@message, level) =>
    @traceback = debug.traceback nil, level or 3

  __tostring: => "#{@@__name}: #{@message}, #{@traceback}"

exception = (name) ->
  class extends Exception
    __name: name

    __tostring: => "#{@__name}: #{@message}, #{@traceback}"

{
  :await, :async, :hatsune, :miku,
  :awaitSafe, :throw, :exception, :Exception,
  logger: setLogger,
  :version
}
