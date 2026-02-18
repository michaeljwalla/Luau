repeat wait() until game:IsLoaded()

local lp = game.Players.LocalPlayer
repeat wait() until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")

local lighting = game.Lighting
local funcs = require(game.ReplicatedStorage.functions)
local lastgraphics = (funcs:graphics() <= 3 and 3) or funcs:graphics()

local x,z = funcs:postocoord(game.Players.LocalPlayer.Character.HumanoidRootPart.Position)
for d = 1, lastgraphics do
	for i,v in pairs(funcs:radiustoplist(d,x,z)) do
		funcs:generate(v.X, v.Z)
	end
end
for i,v in pairs(funcs:getloadedtiles()) do
	if (math.abs(v.X - x) > lastgraphics) or math.abs(v.Z - z) > lastgraphics then v.Part:Destroy() end
end
funcs:updatewalls(lastgraphics)

game:GetService("RunService").Stepped:Connect(function()
	if not (lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')) then return end
	local radius = (funcs:graphics() <= 3 and 3) or funcs:graphics()
	local x,z = funcs:postocoord(game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.Position)
	if lastgraphics ~= radius then
		lastgraphics = radius
		for d = 1, radius do
			for i,v in pairs(funcs:radiustoplist(d,x,z)) do
				funcs:generate(v.X, v.Z)
			end
		end
		for i,v in pairs(funcs:getloadedtiles()) do
			if (math.abs(v.X - x) > radius) or math.abs(v.Z - z) > radius then print(x,z) v.Part:Destroy() end
		end
		funcs:updatewalls(radius, x, z)
	else funcs:generate(x,z) end
	
	game.Lighting.FogEnd = 50*radius
	game.Lighting.FogStart = 25*(radius-3)
end)