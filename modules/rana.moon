import miku from require "hatsune"

-- poor womans implementation of js generator functions in moonscript
-- there is no concept of "async" generators here, but thats because lua is async-by-default
-- (and frankly i think async generators make no sense)

yield = (...) ->
  coroutine.yield "rana", ...

class rana
  new: (@fn, ...) =>
    @thread = coroutine.create @fn
    @args = table.pack ...

  run: (...) =>
    -- coroutine has finished
    if coroutine.status(@thread) == "dead"
      return nil

    args = table.pack ...

    while true
      result = table.pack coroutine.resume @thread, table.unpack args
      { ok, event } = result
      if not ok
        error event

      if event == "rana"
        return select 3, table.unpack result
      elseif coroutine.status(@thread) == "dead"
        return

      args = table.pack coroutine.yield select 2, table.unpack result

  __call: (...) =>
    if @args
      args = @args
      @args = nil
      @run table.unpack args
    else
      @run ...

generator = (fn) ->
  (...) ->
    rana fn, ...

{ :yield, :rana, :generator }
