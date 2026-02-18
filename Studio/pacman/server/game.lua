--!strict
local rs = game:GetService("ReplicatedStorage")
local modules = rs:WaitForChild("Modules")
--
local entityMaker = require(modules:WaitForChild("Entity"))
local mapMaker = require(modules:WaitForChild("Map"))
local startGame = rs:WaitForChild"StartGame"
--
local playerId: number = 1 --decide which entity to use as player (should only have ONE entity w/ id 1)
local mapLayout = mapMaker.Layout
--
local maze = mapMaker.ConstructMaze(mapLayout)
if not maze then return end
--spawn in entities from server (idk why i chose to do it here)
for i,v in next, script:GetChildren() do
	local ent = v:Clone()
	ent.PrimaryPart.CFrame = (maze:FindFirstChild("Origin")::BasePart).CFrame --ensures type is a part (kinda silly but u gotta follow ALL rules for strict)
	ent.Parent = maze:FindFirstChild("Entities")
end
maze.Parent = workspace --parenting last always good practice
--
local newPlr = game:GetService("Players").PlayerAdded:Wait() --assuming this is singleplayer.....

newPlr.CharacterAdded:Wait()
startGame:FireClient(newPlr, mapLayout, maze, playerId) --the client will do the rest (ex positioning)