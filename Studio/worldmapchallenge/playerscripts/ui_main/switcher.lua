local funcs = require(game.ReplicatedStorage.Functions)
funcs.Challenge(true)
local challenges = require(game.ReplicatedStorage.Challenges)
local text = script.Parent.Welcome

local chosen = challenges.__deepcopy("Default")
local tries = {}

local currentcountry = chosen.__random()
text.Text = string.format("(%d) Select: %s", 0, currentcountry.Index)
tries[currentcountry.Index] = (tries[currentcountry.Index] and tries[currentcountry.Index] + 1) or 0
local timer = script.Parent:WaitForChild("Timer")
local debris = game:GetService('Debris')
local completed = false
local roundlen = chosen.__length()
local ding = game.ReplicatedStorage.Ding
script.Parent:WaitForChild("PinCount").Text = ("%d / %d"):format(funcs.PinCount())
workspace.Pins.ChildAdded:Connect(function(v)
	if completed then return end
	local source = v:WaitForChild("Source")
	while not source.Value do wait() end
	local isfound = funcs.GetCountryFromPart(source.Value) == currentcountry.Index
	if isfound then
		v:WaitForChild("Locked").Value = true
		chosen = chosen:__update(currentcountry.Index)
		currentcountry = chosen.__random()
		v:WaitForChild("bb").Enabled = true
		local x = ding:Clone()
		x.Parent = game.SoundService
		x:Play()
		debris:AddItem(x, x.TimeLength/x.PlaybackSpeed)		
		if not currentcountry.Index then
			completed = true
			local choices, totaltries = roundlen, 0
			for i,v in pairs(tries) do totaltries = totaltries + v+1 end
			text.Text = ("Tries: %d Countries: %d\nScore: %d%% Time: %s"):format(totaltries, choices, 100*tonumber(tostring(choices/totaltries):match("%d?%.?%d?%d")), timer.Text)
			return
		end
		tries[currentcountry.Index] = (tries[currentcountry.Index] and tries[currentcountry.Index] + 1) or 0
		text.Text = string.format("(%d) Select: %s", tries[currentcountry.Index], currentcountry.Index)
		game.StarterGui:SetCore("SendNotification", {Title = "Congrats", Text = ("%d / %d Complete."):format(roundlen-chosen.__length(), roundlen)})
		
		local target = v:WaitForChild("Source")
		local filteringcountry = target.Value.Parent:FindFirstChild("IsCountry")
		for i,v in pairs(target.Value.Parent:GetDescendants()) do
			if not v:IsA("Part") then
				if filteringcountry and v:IsA("ObjectValue") and v.Name == 'ApartOf' and v.Value then
					for _,x in pairs(v.Value:GetDescendants()) do
						if not x:IsA("Part") then continue end
						x.Material = "Neon"
					end
				end
				continue
			end
			v.Material = "Neon"
		end
		else do
			tries[currentcountry.Index] = (tries[currentcountry.Index] and tries[currentcountry.Index] + 1) or 1
			text.Text = string.format("(%d) Select: %s", tries[currentcountry.Index], currentcountry.Index)
		end
	end
	
end)