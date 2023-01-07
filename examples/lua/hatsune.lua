local hatsuneModule = require("hatsune")
local hatsune = hatsuneModule.hatsune

-- create a new scheduler
local scheduler = hatsune()

-- register an event listener for mouse clicks
scheduler:on("mouse_click", function(_, button, x, y)
  print("Mouse clicked at: " .. tostring(button) .. " at " .. tostring(x) .. ", " .. tostring(y))
end)

-- register a timeout to shutdown the scheduler after 5 seconds
scheduler:timeout(5, function()
  print("The program ran for 5 seconds. Exiting...")
  scheduler:shutdown()
end)

-- register an interval to print the number of seconds passed every second
local timePassed = 0
scheduler:interval(1, function()
  timePassed = timePassed + 1
  print(timePassed .. " seconds have passed.")
end)

-- start the scheduler
scheduler:run()
