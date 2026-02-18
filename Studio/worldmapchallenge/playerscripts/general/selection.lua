local selection = workspace:WaitForChild("hey").Part
local map = workspace:WaitForChild("hello exploiter")
local tween = game:GetService("TweenService")
local mouse = game.Players.LocalPlayer:GetMouse()
game:GetService("RunService").Stepped:Connect(function()
	local target = mouse.Target
	if target and ((target.Name == 'Pin' and target:WaitForChild("Source").Value and target.Source.Value ~= selection.Adornee.Value) or (target:IsDescendantOf(map) and target:IsA("Part") and selection.Position ~= target.Position)) then
		local target = (target.Name == 'Pin' and target.Source.Value) or target
		selection.Adornee.Value = target
		tween:Create(selection, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Size = target.Size * 0.9, Position = target.Position}):Play()
	end
end)
local tweenin = tween:Create(selection.Parent, TweenInfo.new(5, Enum.EasingStyle.Linear), {Color3 = Color3.new(1,1,1)})
local tweenout = tween:Create(selection.Parent, TweenInfo.new(5, Enum.EasingStyle.Linear), {Color3 = Color3.new(0,0.5,0)})
while true do
	tweenin:Play()
	tweenin.Completed:Wait()
	tweenout:Play()
	tweenout.Completed:Wait()
end