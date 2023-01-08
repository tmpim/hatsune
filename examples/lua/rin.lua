local rinModule = require("rin")
local hatsuneModule = require("hatsune")
local kagamine, rin = rinModule.kagamine, rinModule.rin
local await, hatsune, miku = hatsuneModule.await, hatsuneModule.hatsune, hatsuneModule.miku

local scheduler = hatsune()

local url = "https://example.com"

local function prettyPrintResponse(response)
  local body = response:text()
  local statusText = response.statusText and " (" .. tostring(response.statusText) .. ")" or ""
  print(url .. " responded with status code " .. response.status .. statusText .. ", body:\n" .. body)
end

scheduler:run(function()
  local response = await(rin(url))
  prettyPrintResponse(response)
end)
