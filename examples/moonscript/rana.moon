import yield, rana, generator from require "rana"

myGenerator = generator ->
  yield "Hello,"
  sleep 1
  yield "this"
  sleep 1
  yield "is"
  sleep 1
  yield "rana!"

for x in myGenerator!
  write "#{x} "
write "\n"

coolGenerator = generator (n) ->
  for i = 1, n
    write "#{yield!} "
    sleep 1
  write "\n"

say = coolGenerator 5
say! -- First call is somewhat special, it cannot be passed an argument (since the args to the generator are passed first)
say "You"
say "can"
say "also"
say "pass"
say "arguments!"
