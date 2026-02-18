repeat wait() until game:IsLoaded()
local lp = game.Players.LocalPlayer
repeat wait() until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
local pos = script.Parent:WaitForChild('pos')
local funcs = require(game.ReplicatedStorage.functions)
game:GetService("RunService").RenderStepped:Connect(function()
	if not (lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")) then return end
	local x,z = funcs:postocoord(lp.Character.HumanoidRootPart.Position)
	if x == 0 then x = '0' else x = tostring(x) end
	if z == 0 then z = '0' else z = tostring(z) end
	pos.Text = string.format('%s, %s', x, z)
end)