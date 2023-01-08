import await, async, hatsune, miku, awaitSafe, throw, exception, Exception from require "hatsune"

reject = async ->
  throw Exception "rejected"

MyException = exception "MyException"

otherReject = async ->
  throw MyException "hello, this is a custom exception!"

brokenPromise = async ->
  callSomeFunctionThatDoesNotExist!

scheduler = hatsune!

scheduler\run ->
  print select 2, awaitSafe reject!

  ok, err = awaitSafe otherReject!
  print "err is #{err.__name}"

  ok, err = awaitSafe brokenPromise!
  print err
