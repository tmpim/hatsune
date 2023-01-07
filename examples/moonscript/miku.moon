import await, async, hatsune, miku, awaitSafe from require "hatsune"

scheduler = hatsune!

-- this is an async function, which automatically returns a miku (future/promise) for you
get = async (value) ->
  sleep 1
  value

-- this is a longer form of the above, which also allows you to reject with a value rather than just throwing an error
getMiku = (value) ->
  miku (resolve, reject) ->
    sleep 1
    resolve value

reject = async ->
  error "rejected"

-- longer form of the above
rejectMiku = ->
  miku (resolve, reject) ->
    reject "rejected"

scheduler\run ->
  print await get "Hello, this is an example of hatsune!"
  await getMiku("There are many ways to use this library, here are a few!")\done print
  print awaitSafe rejectMiku!
  await reject!
