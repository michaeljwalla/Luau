local map = game.Workspace['hello exploiter']
local pins = workspace.Pins
local funcs = {}

local pinlocked = false

funcs.GetRegionFromPart = function(part)
	local name = {}
	local parent = part.Parent
	while true do
		if parent.Name == 'hello exploiter' then break end
		table.insert(name, parent.Name)
		parent = parent.Parent
	end
	local result = ''
	for i,v in pairs(name) do result ..= v..' ' end
	return result:sub(1,#result-1)
end
funcs.GetCountryFromPart = function(part)
	return part.Parent and part.Parent.Name:gsub(" %-", "")
end
local lastcam = workspace.CurrentCamera
local lasttween = game:GetService("TweenService"):Create(lastcam, TweenInfo.new(1, Enum.EasingStyle.Circular), {CFrame = CFrame.new(Vector3.new(0,300,0), Vector3.new()) * CFrame.Angles(0,0,math.rad(-90))})
funcs.GetCameraTween = function()
	if workspace.CurrentCamera ~= lastcam then lasttween:Destroy() lastcam = workspace.CurrentCamera end
	lasttween = game:GetService("TweenService"):Create(lastcam, TweenInfo.new(1, Enum.EasingStyle.Circular), {CFrame = CFrame.new(Vector3.new(0,300,0), Vector3.new()) * CFrame.Angles(0,0,math.rad(-90))})
	return lasttween
end
local curpins, maxpins = 34,34
funcs.PlacePin = function(part)
	if pinlocked then return end
	if not funcs.Challenge() or curpins < 1 then return end
	if  not (part and part:IsDescendantOf(map) and part.Name == 'Part') then return end
	local pin = script.Pin:Clone()
	pin.Position = part.Position + Vector3.new(0,6.425,0)
	pin.Source.Value = part
	pin.bb.Label.Text = funcs.GetRegionFromPart(part)
	pin.Parent = pins
	curpins -= 1
end
local raycast = true
funcs.ToggleRaycast = function(value)
	if value == nil then raycast = not raycast else raycast = value end
end
funcs.DoRaycast = function()
	return raycast
end
funcs.GetPinFromPart = function(part)
	for i,v in pairs(pins:GetChildren()) do if v.Source.Value == part then return v end end
	return false
end
funcs.SetPins = function(num, max)
	if tonumber(num) then curpins = math.floor(math.abs(num)) end
	if tonumber(max) then maxpins = math.floor(math.abs(max)) end
end
funcs.PinCount = function()
	return curpins, maxpins
end
funcs.PinLock = function(toggle)
	if toggle == nil then return pinlocked end
	pinlocked = toggle
end
cactive = true
funcs.Challenge = function(toggle)
	if toggle == nil then return cactive end
	cactive = toggle
	return
end
return funcs