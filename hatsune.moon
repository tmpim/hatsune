version = "0.0.0"

export _HATSUNE_LOOP

logger = print
log = (msg) ->
  logger "hatsune: #{msg}"

setLogger = (fn) ->
  logger = fn

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
        error "#{process.name} died with an unhandled error:\n#{err}"

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
    args = {...}
    @onNamed "interval #{interval}", "timer", (event, id) ->
      if id == timer
        fn table.unpack args
        timer = os.startTimer interval

  timeout: (timeout, fn, ...) =>
    timer = os.startTimer timeout
    args = {...}
    @onNamed "timeout #{timeout}", "timer", (event, id) ->
      if id == timer
        fn table.unpack args

  schedule: (name, fn, ...) =>
    thread = coroutine.create (...) ->
      ok, err = xpcall fn, debug.traceback, ...
      if not ok
        coroutine.yield "aaaaa", err
    process = { :name, :thread }
    @execute process, ...
    table.insert @processes, process

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

local await, async, miku, awaitSafe

-- she's from the future
class miku
  value: nil
  error: nil
  fulfilled: false

  new: (@fn) =>
    @name = tostring(@)\sub 8
    @traceback = debug.traceback(nil, 3)
    @process = _HATSUNE_LOOP\schedule @name, @\_run if @fn

  @resolved: (value) ->
    with miku!
      \_resolve value

  @rejected: (error) ->
    with miku!
      \_reject error

  _run: =>
    ok, err = pcall @fn, @\_resolve, @\_reject
    if not ok
      @_reject err

  _fulfill: (value, error) =>
    @value = value
    @error = error
    @fulfilled = true
    os.queueEvent "miku", @

  _resolve: (value) =>
    @_fulfill value, nil

  _reject: (error) =>
    @_fulfill nil, error

  done: (resolved, rejected) =>
    first = @
    miku (resolve, reject) ->
      ok, result = awaitSafe first
      if ok and resolved
        resolve resolved result
      elseif rejected
        reject rejected result

  fail: (rejected) =>
    @done nil, rejected

  _returnAwait: =>
    if @value ~= nil
      return true, @value
    else
      return false, @error

  awaitSafe: =>
    if @fulfilled
      return @_returnAwait!
    else
      while true
        event, future = coroutine.yield!
        if event == "miku" and future == @
          return @_returnAwait!

  await: =>
    ok, result = @awaitSafe!
    if not ok
      error result
    result

async = (fn) ->
  (...) ->
    args = {...}
    miku (resolve, reject) ->
      resolve fn table.unpack args

awaitSafe = (future) ->
  if type future == "table" and future.__class == miku
    return future\awaitSafe!
  else
    return true, future

await = (future) ->
  if type future == "table" and future.__class == miku
    return future\await!
  else
    return future


{
  :await, :async, :hatsune, :miku,
  :awaitSafe,
  logger: setLogger,
  :version
}
