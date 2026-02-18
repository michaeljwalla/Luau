local funcs = require(game.ReplicatedStorage.Functions)
local tbl = {}
local enabled = {Grass = false, Flower = false, Net = false, Water = false}
for i,v in pairs(script.Parent:GetChildren()) do
	if v:IsA("TextButton") then table.insert(tbl, v) end
end

local edit = script.Parent.IsEditing
local lastclick

for i,v in pairs(tbl) do
	v.MouseButton1Click:Connect(function()
		if lastclick == v then edit.Value = false v.BackgroundTransparency = 0.5 lastclick = nil return end
		edit.Value = true
		lastclick = v
		for i,v in pairs(tbl) do v.BackgroundTransparency = 0.5 end
		v.BackgroundTransparency = 0
	end)
end

local selection = workspace.SelectionBox
local mouse = game.Players.LocalPlayer:GetMouse()
local pos = game.Players.LocalPlayer.PlayerGui:WaitForChild("main"):WaitForChild("PosIndicator")


game:GetService("RunService").Heartbeat:Connect(function()
	local target = mouse.Target
	if not (target and target:IsDescendantOf(workspace.Map)) then return end
	if target:IsDescendantOf(workspace.Map.Jeroos) then pos.Text = "(".. math.floor(target:WaitForChild("Pos").Value/24) ..", ".. target.Pos.Value%24 ..")" else pos.Text = "("..target.Name:match("^%d+")..", "..target.Name:match("%d+$")..")" end 
	
	selection.Adornee =  target or selection.Adornee
end)

local rs = game:GetService("RunService").RenderStepped
mouse.Button1Down:Connect(function()
	--if workspace.Map.Jeroos:FindFirstChildWhichIsA("BasePart") then return funcs.coderunning(true) else funcs.coderunning(false) end
	local target = lastclick and mouse.Target
	local isdown
	isdown = mouse.Button1Up:Connect(function() isdown:Disconnect() end)
	while rs:Wait() and not funcs.coderunning() and isdown.Connected and lastclick do
		target = lastclick and mouse.Target
		if not selection.Adornee or not (target and funcs.namefrompart(target) ~= lastclick.Name) then continue end
		local row, column = target.Name:match("^%d+"),target.Name:match("%d+$")
		
		funcs.settile(row,column, lastclick.Name)
		selection.Adornee = nil	
	end
end)