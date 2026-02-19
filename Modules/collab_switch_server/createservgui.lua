pcall(game.Destroy, game.Players.LocalPlayer.PlayerGui:FindFirstChild"ServersGui")

local http, tweens, tps, rs, uis = game:GetService"HttpService", game:GetService"TweenService", game:GetService"TeleportService", game:GetService"ReplicatedStorage", game:GetService"UserInputService"
local sort, insert = table.sort, table.insert
local wait, delay = task.wait, task.delay
local char, random = string.char, math.random

local gamemode = "Normal" or rs.Info.Gamemode.Value
local theme = Color3.fromRGB(220, 50, 50) or rs.Info.Theme.Value
local themedark = Color3.new(theme.R * .75, theme.G * .75, theme.B * .75)

local serversgui = Instance.new"ScreenGui"
serversgui.Name = "ServersGui"

Instance.new"UIScale".Parent = serversgui

local menu = Instance.new("Frame", serversgui)
menu.BackgroundTransparency = 1
menu.Size = UDim2.fromOffset(800,420)
menu.Position = UDim2.new(-0.5,-400,0.5,-210)
menu.Name = "Menu"


local graphic = Instance.new("ImageLabel", menu)
graphic.Size = UDim2.fromScale(1,1)
graphic.BackgroundTransparency = 1
graphic.Image = 'rbxassetid://5086778598'
graphic.ImageColor3 = theme
graphic.ImageRectOffset = Vector2.new(1,1)
graphic.ImageRectSize = Vector2.new(800,420)
graphic.Name = "Graphic"

local closebutton = Instance.new("ImageButton", menu)
closebutton.Size = UDim2.fromScale(0.16,0.152)
closebutton.Position = UDim2.fromScale(0.85,0.02)
closebutton.BackgroundTransparency = 1
closebutton.Image = 'rbxassetid://5086778598'
closebutton.ImageRectOffset = Vector2.new(802,451)
closebutton.ImageRectSize = Vector2.new(128,64)
closebutton.Name = "CloseButton"

local title = Instance.new("ImageLabel", menu)
title.Size = UDim2.fromScale(0.64,0.19)
title.Position = UDim2.fromScale(-0.05, -0.015)
title.BackgroundTransparency = 1
title.Image = 'rbxassetid://14010365969'
title.ImageRectOffset = gamemode == 'Hardcore' and Vector2.new(0,205) or Vector2.new(0,85)
title.ImageRectSize = Vector2.new(1081, 160)
title.Name = "Title"


local serverlist = Instance.new("ScrollingFrame", menu)
serverlist.Size = UDim2.fromOffset(470,300)
serverlist.Position = UDim2.new(0.49,-235,0.47,-125)
serverlist.BorderSizePixel = 2
serverlist.BorderColor3 = themedark
serverlist.ScrollBarThickness = 5
serverlist.BackgroundColor3 = themedark
serverlist.CanvasSize = UDim2.new()
serverlist.AutomaticCanvasSize = "Y"
serverlist.Name = "Servers"
Instance.new("UIListLayout", serverlist).SortOrder = "LayoutOrder"

local confirmteleport = Instance.new("Frame")
confirmteleport.Size = UDim2.fromOffset(400,200)
confirmteleport.BackgroundTransparency = 1
confirmteleport.AnchorPoint = Vector2.new(0.5,0.5)

do
	local reusebackdrop = Instance.new("ImageLabel", confirmteleport)
	reusebackdrop.Image = 'rbxassetid://5086778598'
	reusebackdrop.ImageRectOffset = Vector2.new(1,1)
	reusebackdrop.ImageRectSize = Vector2.new(800,420)
	reusebackdrop.BackgroundTransparency = 1
	reusebackdrop.Size = UDim2.fromScale(1,1)
	reusebackdrop.Name = "Background"
	reusebackdrop.ImageColor3 = theme
	
	local reuseno = Instance.new("ImageButton")
	reuseno.ImageRectOffset = Vector2.new(640,486)
	reuseno.ImageRectSize = Vector2.new(128,64)
	reuseno.Image = 'rbxassetid://5086778598'
	reuseno.BackgroundTransparency = 1
	reuseno.Name = "No"
	reuseno.ZIndex = 3
	reuseno.Size = UDim2.fromScale(0.319,0.318)
	reuseno.Position = UDim2.fromScale(0.45,0.65)
	reuseno.Parent = confirmteleport
	
	local reuseyes = reuseno:Clone()
	reuseyes.ImageRectOffset = Vector2.new(514, 422)
	reuseyes.Position = UDim2.fromScale(0.15,0.65)
	reuseyes.Name = "Yes"
	reuseyes.ImageColor3 = Color3.new(0.25,0.25,0.25)
	reuseyes.Parent = confirmteleport
	
	local reusedesc = Instance.new("TextLabel")
	reusedesc.Font = "Highway"
	reusedesc.BackgroundTransparency = 1
	reusedesc.Size = UDim2.fromOffset(350,20)
	reusedesc.Position = UDim2.new(0.4,-165,1)
	reusedesc.TextColor3 = Color3.new(1,1,1)
	reusedesc.RichText = true
	reusedesc.Text = "Joining: <font color=\"rgb(245,201,81)\"></font>"
	reusedesc.Parent = confirmteleport
	reusedesc.Name = "Joining"
	reusedesc.TextSize = 16
	reusedesc.TextScaled = false
	reusedesc.TextStrokeTransparency = 0.76
	reusedesc.TextWrapped = true
	local reusequestion = reusedesc:Clone()
	
	reusequestion.AnchorPoint = Vector2.new(0.5,0)
	reusequestion.TextColor3 = Color3.fromRGB(170,170,150)
	reusequestion.TextSize = 18
	reusequestion.Name = "Question"
	reusequestion.Position = UDim2.fromScale(0.5,0.36)
	reusequestion.Size = UDim2.fromScale(0.6,0.12)
	reusequestion.Parent = confirmteleport
	
	local reusedescript = reusedesc:Clone()
	reusedescript.Name = "Description"
	reusedescript.Parent = confirmteleport
	
	local reusetb = Instance.new("TextBox")
	reusetb.BackgroundTransparency = 0.75
	reusetb.Size = UDim2.fromOffset(240,24)
	reusetb.AnchorPoint = Vector2.new(0.5,0.5)
	reusetb.Font = "Highway"
	reusetb.Name = "TextBox"
	reusetb.TextStrokeTransparency = 0.75
	reusetb.TextSize = 18
	reusetb.Position = UDim2.fromScale(0.5,0.55)
	reusetb.TextColor3 = Color3.new(1,1,1)
	reusetb.BackgroundColor3 = Color3.new()
	reusetb.Parent = confirmteleport
	
	
end
confirmteleport.Position = UDim2.fromScale(-0.5,0.5)
confirmteleport.Description.Text = "Please enter the code that appears inside the quotes before attempting to switch servers."
confirmteleport.Description.Size = UDim2.fromOffset(220,50)
confirmteleport.Description.Position = UDim2.new(0.5,-110,0.5,-80)
confirmteleport.Question.Text = "\"\""
confirmteleport.TextBox.PlaceholderText = "Enter the code here."
confirmteleport.TextBox.Text = ""
confirmteleport.Parent = serversgui

local filterbar = confirmteleport.TextBox:Clone()
filterbar.Name = "Filter"
filterbar.Position = UDim2.new(0.5,0,0.9,17)
filterbar.PlaceholderText = "Search by ID"
filterbar.TextTruncate = "AtEnd"
filterbar.Parent = menu

local sortsize = Instance.new("TextButton", menu)
sortsize.Size = UDim2.new(0,45,0,20)
sortsize.Position = UDim2.new(0.49,125,0.47,-150)
sortsize.TextSize = 18
sortsize.Text = "Size"
sortsize.BorderSizePixel = 2
sortsize.TextColor3 = Color3.new(1,1,1)
sortsize.Font = "Highway"
sortsize.BorderColor3 = themedark
sortsize.BackgroundColor3 = themedark
sortsize.Name = "Size"

local sortping = sortsize:Clone()
sortping.Position = UDim2.new(0.49,170,0.47,-150)
sortping.Text = "Ping"
sortping.BackgroundColor3 = theme
sortping.Parent = menu
sortping.Name = "Ping"

local refreshmenu = sortsize:Clone()
refreshmenu.Position = filterbar.Position - UDim2.fromOffset(220,10)
refreshmenu.Text = "Refresh"
refreshmenu.Name = "Refresh"
refreshmenu.Size = UDim2.new(0,70,0,20)
refreshmenu.BackgroundColor3 = theme
refreshmenu.Parent = menu

local function tweenin(m)
	local t
	if m == menu then
		m.Position = UDim2.new(-0.5,-400,0.5,-210)
		t = tweens:Create(m, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {Position = UDim2.new(0.5,-400,0.5,-210)})
	else
		m.Position = UDim2.fromScale(-0.5,0.5)
		t = tweens:Create(m, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {Position = UDim2.fromScale(0.5,0.5)})
	end
	
	t:Play()
	return t
end
local function tweenout(m)
	local t
	if m == menu then
		m.Position = UDim2.new(0.5,-400,0.5,-210)
		t = tweens:Create(m, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {Position = UDim2.new(1.5,-400,0.5,-210)})
	else
		m.Position = UDim2.fromScale(0.5,0.5)
		t = tweens:Create(m, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {Position = UDim2.fromScale(1.5,0.5)})
	end
	
	t:Play()
	return t
end

serversgui.Parent = game.Players.LocalPlayer.PlayerGui
delay(0, tweenin, menu) --1 frame

local sortingfunc
local function getServersAsync(maxdepth)
	maxdepth = maxdepth or 1
	
	local servlist, nextpage = {}
	local reps = 0
    repeat
    	reps = reps + 1
    	
        local servers = nextpage
        	and http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/571353271/servers/Public?sortOrder=Desc&limit=50&cursor="..nextpage))
        	or http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/571353271/servers/Public?sortOrder=Desc&limit=50"))
        if not servers then continue end
        
    	nextpage = servers.nextPageCursor or nil
        for i,v in next, servers.data do
        	insert(servlist, v)
        end
        
        wait()
    until reps >= maxdepth or not nextpage
    
    if sortingfunc then sort(servlist, sortingfunc) end
    return servlist
end

local connections = {}

connections.OnClose = closebutton.MouseButton1Down--[[Click]]:Connect(function()
	for i,v in next, connections do v:Disconnect() end --cleanup
	tweens:Create(menu, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {Position = UDim2.new(1.5,-400,0.5,-210)}):Play()
	delay(0.25, game.Destroy, serversgui)
end)
local defaultentry = Instance.new("Frame")
defaultentry.Size = UDim2.new(1,0,0,50)
defaultentry.BorderSizePixel = 0

local richcolors = {
	red = "\"rgb(245,66,66)\"",
	orange = "\"rgb(240,120,46)\"",
	yellow = "\"rgb(245,201,81)\"",
	green = "\"rgb(50,168,82)\"",
	white = "\"rgb(255,255,255)\""--"\"0xffffff\""
}
do
	local deftxtlbl = Instance.new("TextLabel")
	deftxtlbl.TextColor3 = Color3.new(1,1,1)
	deftxtlbl.BackgroundTransparency = 1
	deftxtlbl.TextSize = 18
	deftxtlbl.Font = "Highway"
	deftxtlbl.RichText = true
	deftxtlbl.TextXAlignment = "Left"
	
	local jobholder = deftxtlbl:Clone()
	jobholder.Size = UDim2.new(1,-50,0.5)
	jobholder.Name = "JobId"
	jobholder.Text = ("    ID: <font color="..richcolors.yellow..">%s</font>")
	jobholder.Parent = defaultentry
	
	local plrholder = deftxtlbl:Clone()
	plrholder.Size = UDim2.fromScale(0.25,0.5)
	plrholder.Position = UDim2.fromScale(0,0.5)
	plrholder.Text = ("    Playing: <stroke thickness=\"1\"><font color=%s>%d/%d</font></stroke>")
	plrholder.Name = "Playing"
	plrholder.Parent = defaultentry
	
	local pingholder = deftxtlbl:Clone()
	pingholder.Size = UDim2.fromScale(0.25,0.5)
	pingholder.Position = pingholder.Size
	pingholder.Text = ("    Ping: <stroke thickness=\"1\"><font color=%s>%dms</font></stroke>")
	pingholder.Name = "Ping"
	pingholder.Parent = defaultentry
	
	local joinbtn = Instance.new("ImageButton", defaultentry)
	joinbtn.Name = "Join"
	joinbtn.BackgroundTransparency = 1
	joinbtn.Size = UDim2.fromOffset(70,50)
	joinbtn.Position = UDim2.new(1,-75)
	
	--PLACEHOLDER
	joinbtn.Image = 'rbxassetid://5086778598'
	joinbtn.ScaleType = "Fit"
	joinbtn.ImageRectOffset = Vector2.new(514,422)
	joinbtn.ImageRectSize = Vector2.new(128,64)
	
	--PLACEHOLDER
end
local function pingascending(a,b) return a.ping < b.ping end
local function sizedescending(a,b) return a.playing > b.playing end
local sortingfunc, cachedservers = sizedescending, {}
local function getserversasync(maxdepth)
	maxdepth = maxdepth or 1
	
	local servers, nextCursor = {}
	local reps = 0
    repeat
    	reps = reps + 1
        local Servers;
        if not nextCursor then
            Servers = http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=50"))
        else
            Servers = http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=50&cursor="..nextCursor))
        end
        if (Servers) then
        	nextCursor = Servers.nextPageCursor or nil
            for i,v in next, Servers.data do
            	insert(servers, v)
            end
        end
        wait()
    until reps >= maxdepth or not nextCursor
    
    cachedservers = servers
    if sortingfunc then sort(servers, sortingfunc) end
    return servers
end
local lastgenned, teleporting = "!", false
local function generateCode(len, withletters) --might make curse words (lol?) if
	local str = ''
	if withletters then
		for i = 1, len do str = str..(random() < 0.33 and char(random(48,57)) or char(random(97,122))) end -- 0-9, a-z
	else
		for i = 1, len do str = str..char(random(48,57)) end
	end
	lastgenned = str
	return str
end
local processing, togglebuttons, chosenjob 
local currentgame, currentjob = game.PlaceId, game.JobId
local function addServerEntry(data, index)
	local id, ping, pcur, pmax = data.id, data.ping, data.playing, data.maxPlayers
	
	local new = defaultentry:Clone()
	new.BackgroundColor3 = index % 2 == 0 and themedark or theme
	new.JobId.Text = new.JobId.Text:format(id)
	new.Name = id
	
	if pcur < pmax or id == currentjob then
		new.Playing.Text = new.Playing.Text:format(pcur < pmax and richcolors.white or richcolors.red, pcur, pmax)
		connections[new] = new.Join.MouseButton1Down:Connect(function()
			if processing then
				return
			end
			togglebuttons(false)
			tweenout(menu)
			delay(0.25, tweenin, confirmteleport)
			
			chosenjob = id
			local genned = generateCode(7)
			confirmteleport.Question.Text = ("\"%s - %s\""):format(genned:sub(1,3), genned:sub(4))
			confirmteleport.TextBox.Text = ""
			confirmteleport.Joining.Text = confirmteleport.Joining.Text:gsub(">(.*)<", ">"..id.."<")
		end) --why not mb1click?
	else
		new.Playing.Text = new.Playing.Text:format(richcolors.red, pcur, pmax)
		new.Join.ImageColor3 = Color3.new(0.5,0.5,0.5)
	end
	
	local pingformat
	if ping <= 65 then
		pingformat = new.Ping.Text:format(richcolors.green, ping)
	elseif ping <= 95 then
		pingformat = new.Ping.Text:format(richcolors.yellow, ping)
	elseif ping <= 140 then
		pingformat = new.Ping.Text:format(richcolors.orange, ping)
	else
		pingformat = new.Ping.Text:format(richcolors.red, ping)
	end
	new.Ping.Text = pingformat..(id == currentjob and "<b>  |  </b> <stroke thickness=\"1\"><font color=\"rgb(245,201,81)\">CURRENT SERVER</font></stroke>" or "")
	
	new.Parent = serverlist
	return new
end
local function cleanServerEntries()
	for i,v in next, serverlist:GetChildren() do
		if v:IsA"UIListLayout" then continue end
		
		v:Destroy()
		connections[v]:Disconnect()
		rawset(connections, v, nil)
	end
	return
end
local function populate(servs)
	processing = true
	cleanServerEntries()
	servs = servs or getserversasync()
	for i,v in next, servs do
		addServerEntry(v, i)
		--wait()
	end
	processing = false
	return
end
togglebuttons = function(toggle)
	processing = not toggle
	local col = processing and Color3.new(0.25,0.25,0.25) or Color3.new(1,1,1)
	for i,v in next, serverlist:GetChildren() do
		local joinbtn = v:FindFirstChild"Join"
		if joinbtn and connections[joinbtn] then v.Join.ImageColor3 = col end --connection check to ignore disabled buttons (players 18/18)
	end
	return
end


connections.Nevermind = confirmteleport.No.MouseButton1Click:Connect(function()
	if teleporting then return end
	lastgenned = "!" --so it doesnt get clicked while tweening out
	togglebuttons(true)
	
	tweenout(confirmteleport)
	delay(0.25, tweenin, menu)
end)
local lastvalidinput, txtdb
local tb = confirmteleport.TextBox
connections.ValidateCode = confirmteleport.TextBox:GetPropertyChangedSignal("Text"):Connect(function(txt)
	if txtdb then
		return
	elseif tb.Text:find("^%d%d%d %-$") then
		txtdb = true
		tb.Text = tb.Text:sub(1,2)
		txtdb = false
		return
	end
	local txt = tb.Text:gsub("[^0-9]+", ""):sub(1,7)--:gsub("[^%w]+", ""):lower()
	lastvalidinput = txt
	
	if #txt >= 3 then
		txtdb = true
		tb.Text = txt:sub(1,3).." - "..txt:sub(4)
		tb.ClearTextOnFocus = false
		txtdb = false
		tb:ReleaseFocus()
		tb:CaptureFocus() --pushes cursor to after the dash
		tb.ClearTextOnFocus = true
	else
		confirmteleport.TextBox.Text = txt
	end
	
	confirmteleport.Yes.ImageColor3 = lastvalidinput == lastgenned and Color3.new(1,1,1) or Color3.new(0.25,0.25,0.25)
	
end)

connections.JoinServer = confirmteleport.Yes.MouseButton1Down:Connect(function()
	if not (chosenjob and not teleporting and lastvalidinput == lastgenned) then return end
	teleporting = true
	confirmteleport.Yes.ImageColor3 = Color3.new(0.25,0.25,0.25)
	confirmteleport.No.ImageColor3 = Color3.new(0.25,0.25,0.25)
	
	if connections.TPFail then
		connections.TPFail:Disconnect()
	end
	connections.TPFail = tps.TeleportInitFailed:Connect(function()
		connections.TPFail:Disconnect()
		cleanServerEntries()
		togglebuttons(true)
		populate()
	end)
	tps:TeleportToPlaceInstance(currentgame, chosenjob)
end)
connections.FilterServers = filterbar:GetPropertyChangedSignal("Text"):Connect(function()
	if processing then return end
	
	local txt = filterbar.Text:gsub("[^a-f0-9%-]?", ""):gsub("^%-", ""):lower()
	txt = txt:gsub("(%-+)", "-")
	filterbar.Text = txt
	txt = txt:gsub("%-", "%%-") --magic character
	
	local colorcheck = false
	for i,v in next, cachedservers do
		local id = v.id
		
		local me = serverlist[id]
		local starting, ending = id:find(txt)
		if starting then
			colorcheck = not colorcheck --makes sure that color alternating doesnt double-up
			me.BackgroundColor3 = colorcheck and theme or themedark
			--broken + too inefficient
			--starting, ending = starting
			--local txt = me.JobId.Text
			--me.JobId.Text = txt:sub(1,starting-1).."|"..--[["<font color=\"rgb(50,168,82)\">"..]]txt:sub(starting, ending).."|"..--[["</font>"..]]txt:sub(ending+1)
			me.Visible = true
		else
			me.Visible = false
			--broken + too inefficient
			--me.JobId.Text = serverlist[id].JobId.Text:gsub("<font color=\"rgb%(50,168,82%)\">([a-z0-9%-]+)</font>", "%1")
		end
	end
end)
connections.SortBySize = sortsize.MouseButton1Down:Connect(function()
	if processing or sortingfunc == sizedescending then return end
	sortping.BackgroundColor3 = theme
	sortsize.BackgroundColor3 = themedark
	sortingfunc = sizedescending
	
	sort(cachedservers, sortingfunc)
	populate(cachedservers)
end)
connections.SortByPing = sortping.MouseButton1Down:Connect(function()
	if processing or sortingfunc == pingascending then return end
	sortsize.BackgroundColor3 = theme
	sortping.BackgroundColor3 = themedark
	sortingfunc = pingascending
	
	sort(cachedservers, sortingfunc)
	populate(cachedservers)
end)
do
	local function f()
		refreshmenu.Text = "Refresh"
	end
	local tref = tick()
	connections.Refresh = refreshmenu.MouseButton1Down:Connect(function()
		if processing or dbref or tick() - tref < 3 then return end
		refreshmenu.Text = "..."
		refreshmenu.BackgroundColor3 = themedark
		
		delay(3, f)
		populate()
		refreshmenu.Text = "Done"
		refreshmenu.BackgroundColor3 = theme
		tref = tick()
	end)
end

populate()