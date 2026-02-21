
shared.track, shared.name = nil, nil --optional tracers to track a player (set first var to a username, 2nd var is optional nickname)
local lp = game.Players.LocalPlayer
print('checking whitelist..')
--[[

whitelist system removed, enjoy unobfuscated

]]

local reloaded
if _G.connections then reloaded = true for i,v in pairs(_G.connections) do v:Disconnect() end end
if _G.tracers then for i,v in pairs(_G.tracers) do v.Tracer:Destroy() v.Billboard:Destroy() end end
if game.CoreGui:FindFirstChild("bellgui") then game.CoreGui.bellgui:Destroy() end
if _G.update then _G.update = false end
game.RunService.RenderStepped:Wait()

if not lp.Character then game.ReplicatedStorage.Remotes.Ready:FireServer() lp.CharacterAdded:Wait() end
local t = lp.Character:WaitForChild("HumanoidRootPart", 5)
assert(t, "Couldnt find HumanoidRootPart")
local opttrackplr, tplrname = shared.track, shared.name
--variables
_G.tracers = {}
_G.connections = {}
_G.update = true
local slider = {}

slider.Options = {}
slider.Actives = {}
local anticams = {}
local mouse = game.Players.LocalPlayer:GetMouse()
local plr = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local menuLast = UDim2.new(0.5,-400,0.5,-150)
local panic = false
--ui
local defaultbg = Color3.new(1/3,1/3,1/3)
local enabledbg = Color3.new(1/4,1/4,1/4)
local sui = Instance.new("ScreenGui", game.CoreGui)
sui.Name = "bellgui"
local ons = Instance.new("Frame",sui)
ons.Size = UDim2.new(1,0,1,0)
ons.BackgroundTransparency = 1
ons.Name = "EnabledOptions"
local mm = Instance.new("Frame", sui)
mm.Visible = false
mm.Size = UDim2.new(0,200,0,0)
mm.Name = "MainMenu"
mm.BackgroundColor3 = defaultbg
mm.Position = menuLast
local dragbar = Instance.new("TextLabel", mm)
dragbar.Size = UDim2.new(1,0,0,25)
dragbar.Position = UDim2.new(0,0,0,-25)
dragbar.BackgroundColor3 = Color3.new(1/6,1/6,1/6)
dragbar.Name = "Top"
dragbar.Text = "    Main"
dragbar.Font = Enum.Font.SourceSans
dragbar.TextColor3 = Color3.new(1, 1, 1)
dragbar.TextSize = 14
dragbar.TextXAlignment = "Left"
local questionbox = Instance.new("TextButton", dragbar)
questionbox.Name = "InfoButton"
questionbox.Size = UDim2.new(0,24,0,24)
questionbox.Position = UDim2.new(1,-25,0,0)
questionbox.Text = "?"
questionbox.BackgroundColor3 = Color3.new(1/6,1/6,1/6)
questionbox.BorderSizePixel = 0
questionbox.TextColor3 = Color3.new(1,1,1)
questionbox.TextSize = 14
questionbox.Font = Enum.Font.SourceSans
local extrainfo = Instance.new("TextLabel", dragbar)
extrainfo.Size = UDim2.new(0,125,0,50)
extrainfo.Position = UDim2.new(0,0,0,0)
extrainfo.BackgroundColor3 = Color3.new(1/6,1/6,1/6)
extrainfo.Text = "; to hide menu\nrCtrl to hide everything\nClick below to unload"
extrainfo.TextColor3 = Color3.new(1,1,1)
extrainfo.TextSize = 14
extrainfo.ZIndex = 0
extrainfo.Font = Enum.Font.SourceSans
local unloadscript = Instance.new("TextButton", extrainfo)
unloadscript.Name = "Unload"
unloadscript.Text = "Unload"
unloadscript.Size = UDim2.new(1,0,0,15)
unloadscript.BackgroundColor3 = Color3.new(1/6,1/6,1/6)
unloadscript.Position = UDim2.new(0,0,1,0)
unloadscript.TextColor3 = Color3.new(1,1,1)
unloadscript.TextSize = 14
unloadscript.Font = Enum.Font.SourceSans
 
local dtrack = Instance.new("TextLabel", ons)
dtrack.Size = UDim2.new(0,150,0,25)
dtrack.Position = UDim2.new(0,0,1,-25)
dtrack.Font = Enum.Font.SourceSans
dtrack.TextColor3 = Color3.new(1, 1, 1)
dtrack.TextSize = 14
dtrack.BackgroundColor3 = defaultbg
dtrack.TextScaled = true
dtrack.TextWrapped = true
dtrack.Visible = false
 
local espgui = Instance.new("BillboardGui")
local esp = Instance.new("TextLabel",espgui)
espgui.Name = "ESP";
espgui.ResetOnSpawn = true
espgui.AlwaysOnTop = true;
espgui.LightInfluence = 0;
espgui.SizeOffset = Vector2.new(0.5,-0.5)
espgui.Size = UDim2.new(1.75, 0, 1.75, 0);
esp.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
esp.Text = ""
esp.Size = UDim2.new(0.0001, 0.00001, 0.0001, 0.00001);
esp.BorderSizePixel = 4;
esp.BorderColor3 = Color3.new(1,1,1)
esp.BorderSizePixel = 0
esp.Font = "GothamSemibold"
esp.TextSize = 48
esp.TextColor3 = Color3.new(1,0,0)
 
            
local tracerbase = Instance.new("Part")
tracerbase.CFrame = game.Workspace[game.Players.LocalPlayer.Name].HumanoidRootPart.CFrame
tracerbase.Anchored = true
tracerbase.CanCollide = false
tracerbase.Transparency = 0.5
tracerbase.Orientation = Vector3.new(0,0,0)
tracerbase.Material = "Neon"
tracerbase.Size = Vector3.new(0.2,.2,0)
tracerbase.Name = "Tracer"
tracerbase.BrickColor = BrickColor.new("Really red")
 
local remotePress = Instance.new("TextButton")
remotePress.BackgroundColor3 = Color3.new(0.333333, 0.333333, 0.333333)
remotePress.Size = UDim2.new(0, 150, 0, 25)
remotePress.Font = Enum.Font.SourceSans
remotePress.TextColor3 = Color3.new(1, 1, 1)
remotePress.TextScaled = true
remotePress.TextSize = 14
remotePress.TextWrapped = true
remotePress.Position = UDim2.new(0, 0, 1, -50)
remotePress.Name = "Remote"
--functions and table-functions
function rift(tbl, item) --remove item from table
    for i,v in pairs(tbl) do
        if v == item then table.remove(tbl, i) break end
    end
end

function comma(amount)
  local formatted = amount
  while true do  
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end
function newtracer(lookAt, text, optsize)
    if typeof(lookAt) ~= "Instance" then return false end
    for i,v in pairs(_G.tracers) do
        if v.Tracking == lookAt then return end 
    end
    local tracer = tracerbase:Clone()
    tracer.Parent = lookAt
    local billboard = espgui:Clone()
    billboard.Parent = lookAt
    billboard.TextLabel.Text = text
    billboard.TextLabel.TextSize = optsize or espgui.TextLabel.TextSize
    table.insert(_G.tracers, {Tracer = tracer, Tracking = lookAt, Billboard = billboard})
end
function updatetracers()
    if not plr.Character and plr.Character.HumanoidRootPart then return end
    local tremoved = 0
    for i,v in pairs(_G.tracers) do
        local tracer, lookAt = v.Tracer, v.Tracking
        if not (tracer.Parent or lookAt.Parent) then tracer:Destroy() table.remove(_G.tracers, i-tremoved) tremoved = tremoved + 1 end
        if tracer.Parent or lookAt.Parent then
            lookAt = lookAt.Position
            pcall(function()
                pos = plr.Character.HumanoidRootPart.Position
                tracer.Size = Vector3.new(tracer.Size["X"], tracer.Size["Y"], (pos - lookAt).Magnitude)
                avg = Vector3.new((pos["X"]+lookAt["X"]) / 2,(pos["Y"]+lookAt["Y"]) / 2,(pos["Z"]+lookAt["Z"]) / 2)
                tracer.CFrame = CFrame.new(avg, lookAt)
            end)
        end
    end
end
function notify(title, text, duration, icon)
    local options = {}
    if not title and text then return end
    options.Title = title
    options.Text = text
    if duration then options.Duration = duration else do options.Duration = 5 end end
    if icon then options.Icon = icon end
    game.StarterGui:SetCore("SendNotification", options)
end
 
function unloadall()
    _G.update = false
    for i,v in pairs(_G.connections) do v:Disconnect() end
    wait(0.1)
    for i,v in pairs(slider.Options) do v.Value = false end
    for i,v in pairs(_G.tracers) do v.Tracer:Destroy() v.Billboard:Destroy() end
    for i,v in pairs(slider.Actives) do v:Stop() end
    sui:Destroy()
end
function newtween(obj,ti,opt)
    return game:GetService("TweenService"):Create(obj, TweenInfo.new(ti), opt)
end
function draggable(inst,dragwhat)
    function mousePos()
        return {x = mouse.X, y = mouse.Y}
    end
    local start, curPos
    local movewithme
    inst.InputBegan:Connect(function(InputObject)
        if InputObject.UserInputType == Enum.UserInputType.MouseButton1 then
            movewithme = mouse.Button1Down:Connect(function()
                inst.BackgroundColor3 = Color3.new(1/8,1/8,1/8)
                start = mousePos()
                while task.wait() and movewithme.Connected do
                    curPos = mousePos()
                    menuLast = mm.Position
                    if curPos.x ~= start.x or curPos.y ~= start.y then
                        dragwhat.Position = dragwhat.Position + UDim2.new(0,curPos.x - start.x,0, curPos.y - start.y)
                        start = mousePos()
                    end
                end
                inst.BackgroundColor3 = Color3.new(1/6,1/6,1/6)
            end)
        end
    end)
    local mouseConnection
    mouseConnection = mouse.Button1Up:Connect(function()
        if not inst or not inst.Parent then mouseConnection:Disconnect() else do
            start = mousePos()
            curPos = start
            pcall(function()movewithme:Disconnect()end)
        end end
    end)
end
local togglemenu = function()
    mm.Visible = not mm.Visible
end
local btnupdate = function(tbl)
    tbl.Button.MouseButton1Down:Connect(function()
        local btn = tbl.Button
        local value = not tbl.Value
        tbl.Value = value
        local name = tbl.Index
        local textvalue
        if value then textvalue = "Enabled" btn.BackgroundColor3 = enabledbg else do textvalue = "Disabled" btn.BackgroundColor3 = defaultbg end end
        btn.Text = string.format("%s: %s", name, textvalue)
    end)
end
 
slider.new = function(name, islabel, value)
    if not islabel and not (value == true or value == false) then return end
    local btn
    if islabel then
        btn = Instance.new("TextLabel", mm)
        btn.BackgroundColor3 = Color3.new(1/6,1/6,1/6)
        btn.Text = name
        slider.Options[name] = {Index = name, Value = value, Button = btn}
    else do
        btn = Instance.new("TextButton", mm)
        btn.BackgroundColor3 = defaultbg
        slider.Options[name] = {Index = name, Value = value, Button = btn}
        if value then value = "Enabled" btn.BackgroundColor3 = enabledbg else do value = "Disabled" btn.BackgroundColor3 = defaultbg end end
        btn.Text = string.format("%s: %s", name, value)
    end
    end
    local y = (#mm:GetChildren()-2)*25
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(1,0,0,25)
    btn.Position = UDim2.new(0,0,0,y)
    btn.Font = Enum.Font.SourceSans
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 14
    btn.TextXAlignment = "Left"
    return slider.Options[name]
end
local confunl = 0
local lastpressed = 0
unloadscript.MouseButton1Down:Connect(function()
    confunl = confunl + 1
    lastpressed = tick()
    while (tick()-lastpressed) < 5 do
        wait()
        unloadscript.Text = "Confirm?"
        if confunl >= 2 then unloadall() break end
    end
    unloadscript.Text = "Unload"
    confunl = 0
end)

slider.Actives["Track Disasters"] = {Object = dtrack,
	Stop = function()
		if dtrack.Visible then dtrack.Visible = false end 
		local trackplr = game.Players:FindFirstChild(opttrackplr)
		if trackplr and trackplr.Character and trackplr.Character:FindFirstChild("HumanoidRootPart") then
			local tracked
			for i,v in pairs(_G.tracers) do if v.Tracking == trackplr.Character.HumanoidRootPart then v.Tracer:Destroy() v.Billboard:Destroy() table.remove(_G.tracers, i) break end end
		end
	end,
	Start = function()
		for i,v in pairs(game.Players:GetPlayers()) do
			if not opttrackplr or not typeof(opttrackplr) == "string" or opttrackplr == "" then break end
			if v ~= plr and string.lower(v.Name):find(string.lower(opttrackplr)) == 1 then opttrackplr = v.Name _G.track = opttrackplr break end
		end
		local trackplr = game.Players:FindFirstChild(opttrackplr)
		if trackplr and trackplr.Character and trackplr.Character:FindFirstChild("HumanoidRootPart") then
			local tracked
			for i,v in pairs(_G.tracers) do if v.Tracking == trackplr.Character.HumanoidRootPart then tracked = true break end end
			if not tracked then newtracer(trackplr.Character.HumanoidRootPart, tplrname or opttrackplr, 24) end
		end
		if not dtrack.Visible then dtrack.Visible = true end
		local found = false
		for i,v in pairs(game.Workspace.Disaster:GetChildren()) do
			if v:IsA("Model") then found = v break end
		end
		if found then
			dtrack.Text = found.Name
            dtrack.BackgroundTransparency = 0
            dtrack.TextColor3 = Color3.new(1,1,1)
			else do 
				dtrack.Text = "..."
                dtrack.BackgroundTransparency = .5
                dtrack.TextColor3 = Color3.new(0.2,0.2,0.2)
            end
        end
	end}

slider.Actives["Remove Fog"] = {Stop = function() game.Lighting.FogEnd = game.Lighting.ServerFogEnd.Value end, Start = function() game.Lighting.FogEnd = 100000 end}
for i,v in pairs(game.Workspace.Lobby.Bricks:getChildren()) do
    if v.Name:find("AntiCam") then
        table.insert(anticams,v)
    end
end
slider.Actives["Unlock Border View"] = {
    Stop = function()
        for i,v in pairs(anticams) do
            v.Position = Vector3.new(v.Position.X, 40, v.Position.Z)        
        end
    end,
    Start = function()
        for i,v in pairs(anticams) do
            v.Position = Vector3.new(v.Position.X, -150, v.Position.Z)      
        end
    end
}
slider.Actives["Green Zone"] = {
    Stop = function() 
        if not game.Workspace.Disaster:FindFirstChild("Green Zone") and not pcall(function()game.Workspace.Disaster["Green Zone"].Zone:FindFirstChild("Part")end) then return end
        for i,v in pairs(_G.tracers) do
            if v.Tracking == game.Workspace.Disaster["Green Zone"].Zone.Part then v.Tracer:Destroy() v.Billboard:Destroy() table.remove(_G.tracers, i) end
        end 
    end, 
    Start = function()
        if game.Workspace.Disaster:FindFirstChild("Green Zone") then
            if not pcall(function()game.Workspace.Disaster["Green Zone"].Zone:FindFirstChild("Part")end) then return end
            for i,v in pairs(_G.tracers) do
                if v.Tracking == game.Workspace.Disaster["Green Zone"].Zone.Part then return end
            end
            newtracer(game.Workspace.Disaster["Green Zone"].Zone.Part, "Zone")
        end
    end
}
slider.Actives["Press The Button"] = {
    Trigger = nil, --maybe i shouldve used this for all tracers
    Stop = function(self)
        if self.Trigger then
            for i,v in pairs(_G.tracers) do
                if v.Tracking == self.Trigger then v.Tracer:Destroy() v.Billboard:Destroy() print('no') table.remove(_G.tracers, i) self.Trigger = nil break end
            end
        end
    end,
    Start = function(self)
        if game.Workspace.Disaster:FindFirstChild("Press The Button") and not self.Trigger then
            for i,v in pairs(game.Workspace.Disaster["Press The Button"]:GetDescendants()) do
                if v.Name == "Trigger" and v:IsA("MeshPart") then self.Trigger = v newtracer(v, "Button") end
            end
        else if not game.Workspace.Disaster:FindFirstChild("Press The Button") then
            self.Trigger = nil
        end
        end
    end
}
slider.Actives.Volcano = {
    Stop = function()
        if not game.Workspace.Disaster:FindFirstChild("Volcano") and not pcall(function() game.Workspace.Disaster.Volcano.Volcano:FindFirstChild("Or") end) then return end
        for i,v in pairs(_G.tracers) do
            if v.Tracking == game.Workspace.Disaster.Volcano.Volcano.Or then v.Tracer:Destroy() v.Billboard:Destroy() table.remove(_G.tracers, i) end
        end 
    end,
    Start = function()
        if game.Workspace.Disaster:FindFirstChild("Volcano") then
            if not pcall(function()game.Workspace.Disaster.Volcano.Volcano:FindFirstChild("Or") end) then return end
            for i,v in pairs(_G.tracers) do
                if v.Tracking == game.Workspace.Disaster.Volcano.Volcano.Or then return end
            end
            newtracer(game.Workspace.Disaster.Volcano.Volcano.Or, "Volcano")
        end
    end
}
slider.Actives["Caterdriller"] = {
    Stop = function()
        if game.Workspace.Disaster:FindFirstChild("Caterdriller") then
            if not pcall(function() game.Workspace.Disaster.Caterdriller.Nodes:FindFirstChild("Part") end) then return end
            pcall(function()
                for i,v in pairs(game.Workspace.Disaster.Caterdriller.Nodes:GetChildren()) do
                    if v.Transparency ~= 1 then v.Transparency = 1 end
                end
            end)
        end
    end,
    Start = function()
        if game.Workspace.Disaster:FindFirstChild("Caterdriller") then
            while not pcall(function() game.Workspace.Disaster.Caterdriller.Nodes:FindFirstChild("Part") end) or not game.Workspace.Disaster:FindFirstChild("Caterdriller") do wait() end
            pcall(function()
                for i,v in pairs(game.Workspace.Disaster.Caterdriller.Nodes:GetChildren()) do
                    if v.Transparency ~= 0.75 then
                        v.Size = v.Parent.Parent.Head.Size
                        v.Material = "ForceField"
                        v.Shape = "Ball"
                        v.Transparency = 0.75
                    end
                end
            end)
        end
    end
}
slider.Actives["Barrel Boy"] = {
    Stop = function()
        if not game.Workspace.Disaster:FindFirstChild("Barrel Boy") then return end
        if pcall(function() return game.Workspace.Disaster["Barrel Boy"].Points  end) and game.Workspace.Disaster["Barrel Boy"].Points[1].Transparency ~= 1 then
            for i,v in pairs(game.Workspace.Disaster["Barrel Boy"].Points:GetChildren()) do
                v.Transparency = 1
            end
        end
    end,
    Start = function()
        if not game.Workspace.Disaster:FindFirstChild("Barrel Boy") then return end
        if pcall(function() game.Workspace.Disaster["Barrel Boy"]:FindFirstChild("Points") end) and game.Workspace.Disaster["Barrel Boy"].Points[1].Transparency == 1 then
            for i,v in pairs(game.Workspace.Disaster["Barrel Boy"].Points:GetChildren()) do
                v.Color = Color3.new(1,1,1)
                v.CanCollide = false
                v.Size = Vector3.new(50,50,396)
                v.Material = "ForceField"
                v.Position = Vector3.new(v.Position.X,v.Position.Y,0)
                v.CastShadow = false
                v.Transparency = 0.9
            end
        end
    end
}
slider.Actives["Nuclear Bomb"] = {
    Stop = function()
        if not game.Workspace.Disaster:FindFirstChild("Nuclear Bomb") and not pcall(function() game.Workspace.Disaster["Nuclear Bomb"]:FindFirstChild("Point") end) then return end
        for i,v in pairs(_G.tracers) do
            if v.Tracking == game.Workspace.Disaster["Nuclear Bomb"].Point then v.Tracer:Destroy() v.Billboard:Destroy() table.remove(_G.tracers, i) end
        end
    end,
    Start = function()
        if not pcall(function() game.Workspace.Disaster["Nuclear Bomb"]:FindFirstChild("Point") end) then return end
        for i,v in pairs(_G.tracers) do
            if v.Tracking == game.Workspace.Disaster["Nuclear Bomb"].Point then return end
        end
        newtracer(game.Workspace.Disaster["Nuclear Bomb"].Point, "Nuke")
    end
}
slider.Actives["Button Remote (PATCHED)"] = {
    Object = remotePress:Clone(),
    LookFor = function()
        if game.Workspace.Disaster:FindFirstChild("Press The Button") then
            for i,v in pairs(game.Workspace.Disaster["Press The Button"]:GetDescendants()) do
                if v.Name == "Trigger" and v:IsA("MeshPart") then return true, v end
            end
        end
        return false
    end,
    Stop = function(self) if self.Object.Parent then self.Object.Text = "Press Button" self.Object.Parent = nil end end,
    Start = function(self)
        if not self.Object.Parent and self:LookFor() then
            self.Object.Parent = ons
            self.Object.Text = "Press Button"
        end
        if self.Object.Parent and not game.Workspace.Disaster:FindFirstChild("Press The Button") then
            self.Object.Parent = nil
            self.Object.Text = "Press Button"
        end
    end
}
slider.Actives["Illumina Remote"] = {
    Object = remotePress:Clone(),
    LookFor = function()
        if game.Workspace.Disaster:FindFirstChild("Illumina") then
            for i,v in pairs(game.Workspace.Disaster["Illumina"]:GetDescendants()) do
                if v:IsA("TouchTransmitter") then
                    return true, v.Parent
                end
            end
        end
        return false
    end,
    Stop = function(self) if self.Object.Parent then self.Object.Parent = nil end end,
    Start = function(self)
        if not self.Object.Parent and self:LookFor() then
            self.Object.Parent = ons
            self.Object.Text = "Explode Sword"
            self.Object.Position = remotePress.Position - UDim2.new(0,0,0,25)
        end
        if self.Object.Parent and not game.Workspace.Disaster:FindFirstChild("Illumina") then
            self.Object.Parent = nil
        end
    end
}
 
local updateactives = function()
    for i,v in pairs(slider.Actives) do
        if slider.Options[i].Value then v:Start() else do v:Stop() end end
    end
end
--calls and connections
draggable(dragbar, mm)
mm.ChildAdded:Connect(function(self)
    mm.Size = mm.Size + UDim2.new(0,0,0,25)
end)
_G.connections.toggle = uis.InputBegan:Connect(function(key,chatting)
    local waspanicked = panic
    if key.KeyCode == Enum.KeyCode.RightControl and not chatting then panic = not panic end
    if panic then
        wait(0.1)
        for i,v in pairs(_G.tracers) do v.Tracer.Transparency = 1 v.Billboard.Enabled = false end
        for i,v in pairs(slider.Actives) do v:Stop() end
        ons.Visible = false
        mm.Visible = false
        return
    else if waspanicked then
        for i,v in pairs(_G.tracers) do v.Tracer.Transparency = 0 v.Billboard.Enabled = true end
        ons.Visible = true
        mm.Visible = true
    end
    end
    if key.KeyCode == Enum.KeyCode.Semicolon and not chatting then togglemenu() return end
end)
local infoclosing = false
questionbox.MouseButton1Down:Connect(function()
    if not infoclosing then
        infoclosing = true
        local whichway = 1
        if extrainfo.Position.X.Scale == 1 then whichway = 0 end
        newtween(extrainfo, 0.5, {Position = UDim2.new(whichway,0,0,0)}):Play()
        repeat wait() until (extrainfo.Position.X.Scale == 0) or (extrainfo.Position.X.Scale == 1)
        infoclosing = false
    end
end)
slider.Actives["Button Remote (PATCHED)"].Object.MouseButton1Down:Connect(function()
    self = slider.Actives["Button Remote (PATCHED)"]
    local found, inst = self:LookFor()
    if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") or not found then return end
    self.Object.Text = "Pressed!"
    --plr.Character.HumanoidRootPart.CFrame = inst.CFrame
    firetouchinterest(plr.Character.HumanoidRootPart, inst, 0)
    firetouchinterest(plr.Character.HumanoidRootPart, inst, 1)
end)
slider.Actives["Illumina Remote"].Object.MouseButton1Down:Connect(function()
    self = slider.Actives["Illumina Remote"]
    local found, inst = self:LookFor()
    if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") or not found then return end
    firetouchinterest(plr.Character.HumanoidRootPart, inst, 0)
    firetouchinterest(plr.Character.HumanoidRootPart, inst, 1)
end)
for i,v in pairs(game.Players:GetPlayers()) do
    if not opttrackplr or not typeof(opttrackplr) == "string" or opttrackplr == "" then opttrackplr = false break end
    if v ~= plr and string.lower(v.Name):find(string.lower(opttrackplr)) == 1 then opttrackplr = v.Name plrfound = true break end
end
if opttrackplr and not plrfound then notify("Tracker Error", string.format("%s is not in the game", opttrackplr)) else if opttrackplr then notify("Tracker Success", string.format("Tracking %s", opttrackplr)) end end
--ui
local trackdisaster = slider.new("Track Disasters", false, false)
btnupdate(trackdisaster)
local removefog = slider.new("Remove Fog", false, false)
btnupdate(removefog)
local remborders = slider.new("Unlock Border View", false, false)
btnupdate(remborders)
local trackers = slider.new("   Trackers", true) 
local trackptb = slider.new("Press The Button", false, false)
btnupdate(trackptb)
local trackgz = slider.new("Green Zone", false, false)
btnupdate(trackgz)
local trackvc = slider.new("Volcano", false, false)
btnupdate(trackvc)
local trackctdr = slider.new("Caterdriller", false, false)
btnupdate(trackctdr)
local trackbb = slider.new("Barrel Boy", false, false)
btnupdate(trackbb)
local tracknuke = slider.new("Nuclear Bomb", false, false)
btnupdate(tracknuke)
local extras = slider.new("   Extras (DETECTABLE)", true)
local remoteptb = slider.new("Button Remote (PATCHED)", false, false)
btnupdate(remoteptb)
local remoteillumina = slider.new("Illumina Remote", false, false)
btnupdate(remoteillumina)
--update
_G.connections.tracers = game.RunService.RenderStepped:Connect(function()
    if not game.Workspace:FindFirstChild("Disaster") then return end
    if not panic and _G.update then updateactives() updatetracers() end
end)
notify("hey", "made with love by bell and your hot mother")
if reloaded then notify("Success", "Script reloaded!") end
mm.Visible = true