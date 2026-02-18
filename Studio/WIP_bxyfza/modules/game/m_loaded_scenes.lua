--!strict
local sc = require(script.Parent)
export type Scene = sc.Scene

local module: { [string]: Scene } = {}

return module