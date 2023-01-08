import await, async, hatsune, miku, awaitSafe, throw from require "hatsune"

scheduler = hatsune!

reject = async (...) ->
  print "rejecting", ...
  throw ...

scheduler\run ->
  print awaitSafe reject "foo", "bar", "baz"
