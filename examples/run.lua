package.path = package.path .. ";../?.lua"
local args = {...}
require(args[1])
