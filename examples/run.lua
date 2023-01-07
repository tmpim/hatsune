package.path = package.path .. ";../?.lua;../modules/?.lua"
local args = {...}
require(args[1])
