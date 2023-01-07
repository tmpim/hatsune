import hatsune from require "hatsune"

-- create a new scheduler
scheduler = hatsune!

-- register an event listener for mouse clicks
scheduler\on "mouse_click", (_, button, x, y) ->
  print "Mouse clicked at: #{button} at #{x}, #{y}"

-- register a timeout to shutdown the scheduler after 5 seconds
scheduler\timeout 5, ->
  print "The program ran for 5 seconds. Exiting..."
  scheduler\shutdown!

-- register an interval to print the number of seconds passed every second
timePassed = 0
scheduler\interval 1, ->
  timePassed += 1
  print "#{timePassed} seconds have passed."

-- start the scheduler
scheduler\run!
