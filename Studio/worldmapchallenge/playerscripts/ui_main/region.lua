local lp = game.Players.LocalPlayer
if lp.Character then for i,v in pairs(lp.Character:GetDescendants()) do if v:IsA("BasePart") then v.CastShadow = false end end lp.Character.DescendantAdded:Connect(function(v)if v:IsA("BasePart") then v.CastShadow = false end end) end
lp.CharacterAdded:Connect(function(char)
	char.DescendantAdded:Connect(function(v)
		if v:IsA("BasePart") then v.CastShadow = false end
	end)
end)

local text = script.Parent
local map = workspace['hello exploiter']
local funcs = require(game.ReplicatedStorage.Functions)
local t = tick()-0.1
local part = Instance.new("Part", workspace)
local function floor(vector)
	return Vector3.new(math.floor(vector.X), math.floor(vector.Y), math.floor(vector.Z))
end
part.Anchored = true
part.CanCollide = true
part.Size = Vector3.new(1,115,1)
part.CanCollide = false
part.Transparency = 1

print('horrible raycasting (not reliable)(dont look at top bar)(idk how to fix it someone help me)')
con = game:GetService('RunService').Heartbeat:Connect(function()
	if funcs.Challenge or (tick()-t < 0.1) then return else t = tick() end
	local hrp = funcs.DoRaycast() and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then text.Visible = false return else text.Visible = true end
	if hrp.CFrame.p.Y > 200 then lp:Kick("what's the point though") con:Disconnect() return end
	local ray = Ray.new(floor(hrp.CFrame.p) + Vector3.new(0,15,0), floor(hrp.CFrame.p) - Vector3.new(0,100,0))
	local result = workspace:FindPartOnRayWithWhitelist(ray, {map})
	--part.Position = hrp.CFrame.p
	if not result then text.Text = '' return end
	text.Text = 'Welcome to:\n'..funcs.GetRegionFromPart(result)
end)