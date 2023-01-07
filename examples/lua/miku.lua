local hatsuneModule = require("hatsune")
local await, async, hatsune, miku, awaitSafe = hatsuneModule.await, hatsuneModule.async, hatsuneModule.hatsune, hatsuneModule.miku, hatsuneModule.awaitSafe

local scheduler = hatsune()

-- this is an async function, which automatically returns a miku (future/promise) for you
local get = async(function(value)
  sleep(1)
  return value
end)

-- this is a longer form of the above, which also allows you to reject with a value rather than just throwing an error
local getMiku = function(value)
  return miku(function(resolve, reject)
    sleep(1)
    resolve(value)
  end)
end

local reject = async(function()
  error("rejected")
end)

-- longer form of the above
local rejectMiku = function()
  return miku(function(resolve, reject)
    reject("rejected")
  end)
end

scheduler:run(function()
  print(await(get("Hello, this is an example of hatsune!")))
  getMiku("There are many ways to use this library, here are a few!"):done(print):await()
  print(awaitSafe(rejectMiku()))
  await(reject())
end)
