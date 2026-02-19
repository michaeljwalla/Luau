local getthread, rethread
if syn then
    getthread, rethread = syn.get_thread_identity, syn.set_thread_identity
else
    getthread, rethread = getthreadidentity, setthreadidentity
end

local function require(d, recache)
    shared.requirecache = shared.requirecache or {}
    if (typeof(d) ~= 'string') then
        local pre = getthread()
        rethread(2)
        local a = getfenv().require(d)
        rethread(pre)
        return a
    elseif d:find"^http" then return loadstring(game:HttpGet(d), d:sub(1,12))()
    else
        if not recache and shared.requirecache[d] then return shared.requirecache[d] end
        local n, a = pcall(readfile, d..".lua") --loadfile lol
        --print(({a:gsub("\n","\n")})[2] + 1)
        assert(n, "No local module '"..d.."'")
        local chunk = loadstring(a, d)
        assert(chunk, "Error in local: "..d)
        shared.requirecache[d] = chunk()
        return shared.requirecache[d]
    end
end

local function hasprop(inst, prop, pcd)
    return pcd and inst[prop] or pcall(hasprop, inst, prop, true)
end
local function apply(inst, props)
    local parent = props.Parent
    props.Parent = nil
    for i,v in next, props do
        if hasprop(inst, i) then
            inst[i] = v
        end
    end
    if parent then inst.Parent = parent end
    return inst
end

if shared.tpgui then
	shared.tpgui.Gui:cleanup()
	for i,v in next, shared.tpgui.Connections or {} do
		v:Disconnect()
		rawset(shared.tpgui.Connections or {}, i, nil)
	end
end
local delay, wait = task.delay, task.wait
local clamp, floor = math.clamp, math.floor
local insert, sort = table.insert, table.sort
local http, tps = game:GetService"HttpService", game:GetService"TeleportService"
local gui = require("bell/gui", true)
shared.tpgui = {
	Gui = gui,
	RoproCache = shared.tpgui and shared.tpgui.RoproCache or {},
	Connections = {},
	ServerCache = {}
}
local menu = gui:AddMenu"Teleport"
local cons = shared.tpgui.Connections

local cache = shared.tpgui.RoproCache
local function fetchroproasync(jobid)
	cache[jobid] = cache[jobid] or game:HttpGet("https://api.ropro.io/createInvite.php?universeid="..game.GameId.."&serverid="..jobid)
	return cache[jobid]
end

local sortingfunc
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
    shared.tpgui.ServerCache = servers
    if sortingfunc then sort(servers, sortingfunc) end
    return servers
end

local servcontainer = gui:AddBasic("ScrollingFrame", UDim2.new(0.8,0,0.8), UDim2.new(0.1,0,0.1), menu.Frame)
Instance.new("UIListLayout", servcontainer).SortOrder = "LayoutOrder"
local defaultserverentry = apply(gui:AddBasic("Frame", UDim2.new(1,0,0,35)), {
	BackgroundColor3 = gui:GetThemeColor"Medium"
})
apply(gui:AddBasic("TextLabel", UDim2.new(1,-35,0,20), nil, defaultserverentry), {
	BorderSizePixel = 0,
	Name = "JobId",
	BackgroundColor3 = gui:GetThemeColor"Medium",
	TextSize = 10
})
apply(gui:AddBasic("TextLabel", UDim2.new(1,-35,0,15), UDim2.new(0,0,0,20), defaultserverentry), {
	BorderSizePixel = 0,
	Name = "PlrRopro",
	BackgroundColor3 = gui:GetThemeColor"Medium",
	TextSize = 10
})
apply(gui:AddBasic("TextButton", UDim2.new(0,35,0,35), UDim2.new(1,-37), defaultserverentry), {
	BackgroundColor3 = gui:GetThemeColor"Dark",
	Name = "Join",
	Text = "<font color=%s>Join</font>",
	TextSize = 12
})
local function torichcolor(c3, offset)
    offset = tonumber(offset) or 0
    return ('"rgb(%d,%d,%d)"'):format(clamp(floor(c3.R*255)+offset,0,255), clamp(floor(c3.G*255)+offset,0,255), clamp(floor(c3.B*255)+offset,0,255))
end

local blue = torichcolor(gui:GetThemeColor"Accent", 40)
local red = torichcolor(Color3.fromRGB(245, 66, 66))
local green = torichcolor(Color3.fromRGB(50, 168, 82))
local white = torichcolor(Color3.new(1,1,1))
local yellow = torichcolor(Color3.fromRGB(245, 201, 81))

local queued = false
local function setstatus(joining, which)
	queued = joining
	if joining then
		for i,v in next, servcontainer:GetChildren() do
			if v:IsA"UIListLayout" or v == which then continue end
			v.Join.Text = v.Join.Text:gsub("[Rej]*J?oin", "...")
		end
	else
		for i,v in next, servcontainer:GetChildren() do
			if v:IsA"UIListLayout" then continue end
			if v.JobId.Text:find(game.JobId) then
				v.Join.Text = v.Join.Text:gsub("%.%.%.", "Rejoin")
			else
				v.Join.Text = v.Join.Text:gsub("%.%.%.", "Join")
			end
		end
	end
	return
end
local function reset(ui)
	ui.Text = ui.Text:gsub("%?", "")
end
local populate


local function addserverentry(servdata)
	local id = servdata.id
	local canjoin = servdata.playing < servdata.maxPlayers
	local newentry = defaultserverentry:Clone()
	newentry.JobId.Text = ("<font color=%s>%s</font> - <font color=%s>%dms</font>"):format(blue, id, yellow, floor(servdata.ping))
	newentry.PlrRopro.Text = ("Players: <font color=%s>%d/%d</font> - RoPro: <font color=%s>%s</font>"):format(canjoin and green or red, servdata.playing, servdata.maxPlayers, yellow, cache[id] or "?")
	
	if id == game.JobId then
		newentry.Join.Text = newentry.Join.Text:format(green):gsub("Join", "Rejoin")
	elseif not canjoin then
		newentry.Join.Text = newentry.Join.Text:format(red)
	else
		newentry.Join.Text = newentry.Join.Text:format(white)
	end
	cons[newentry] = {}
	if canjoin or game.JobId == id then
		local timelastclick = 0
		cons[newentry].Left = newentry.Join.MouseButton1Click:Connect(function()
			if queued then
				return
			elseif not newentry.Join.Text:find"%?" and tick() - timelastclick > 5 then
				setstatus(false)
				timelastclick = tick()
				
				delay(5, reset, newentry.Join)
				newentry.Join.Text = newentry.Join.Text:gsub(">(%w+)<", ">%1?<")
				return
			end
			setstatus(true, newentry)
			
			if cons.TPSFail then cons.TPSFail:Disconnect() end
			cons.TPSFail = tps.TeleportInitFailed:Connect(populate)
			tps:TeleportToPlaceInstance(game.PlaceId, id)
		end)
	end
	
	local rp, db
	cons[newentry].Right = newentry.Join.MouseButton2Click:Connect(function()
		if db then return else db = true end
		
		if not rp then
			rp = fetchroproasync(id)
			newentry.PlrRopro.Text = newentry.PlrRopro.Text:gsub("%?", rp)
		end
		setclipboard(rp)
		db = false
	end)
	newentry.Parent = servcontainer
end

populate = function(ls)
	queued = true
	for i,v in next, servcontainer:GetChildren() do
		if not v:IsA"UIListLayout" then
			v:Destroy()
			for i,v in next, cons[v] do v:Disconnect() end
			rawset(cons, v, nil)
		end
	end
	for i,v in next, ls or getserversasync() do
		addserverentry(v)
		wait()
	end --i just like the loading process
	setstatus(false)
end
do
	local refresht = tick()
	local function refcd(ui)
		ui.Text = "Refresh"
	end
	local x = apply(gui:AddBasic("TextButton", UDim2.new(0,70,0,15), UDim2.new(0.1,0,0.1,-16), menu.Frame), {
		TextSize = 12,
		Text = "...",
		BackgroundColor3 = gui:GetThemeColor"Medium"
	})
	insert(cons, x.MouseButton1Click:Connect(function()
		if queued or tick() - refresht < 5 then return end
		refresht = tick()
		delay(5, refcd, x)
		x.Text = "..."
		
		populate()
	end))
	delay(5, refcd, x)
	
	local size, ping = apply(gui:AddBasic("TextButton", UDim2.new(0,45,0,15), UDim2.new(0.9,-90,0.1,-16), menu.Frame), {
		TextSize = 12,
		Text = "Size ⬆",
		BackgroundColor3 = gui:GetThemeColor"Medium"
	}), apply(gui:AddBasic("TextButton", UDim2.new(0,45,0,15), UDim2.new(0.9,-45,0.1,-16), menu.Frame), {
		TextSize = 12,
		Text = "Ping",
		BackgroundColor3 = gui:GetThemeColor"Medium"
	})
	
	local function sizedescending(a, b)
		return a.playing > b.playing
	end
	local function sizeascending(a, b)
		return a.playing < b.playing
	end
	local sizewasdesc, pingwasasc = true, true
	insert(cons, size.MouseButton1Click:Connect(function()
		if queued then return end
		ping.Text = "Ping"
		pingwasasc = true
		
		if sizewasdesc then
			sort(shared.tpgui.ServerCache, sizeascending)
			sortingfunc = sizeascending
			size.Text = "Size ⬇"
		else
			sort(shared.tpgui.ServerCache, sizedescending)
			sortingfunc = sizedescending
			size.Text = "Size ⬆"
		end
		sizewasdesc = not sizewasdesc
		populate(shared.tpgui.ServerCache)		
	end))
	
	local function pingdescending(a, b)
		return a.ping > b.ping
	end
	local function pingascending(a, b)
		return a.ping < b.ping
	end
	insert(cons, ping.MouseButton1Click:Connect(function()
		if queued then return end
		size.Text = "Size"
		sizewasdesc = false
		
		if pingwasasc then
			sort(shared.tpgui.ServerCache, pingascending)
			sortingfunc = pingascending
			ping.Text = "Ping ⬇"
		else
			sort(shared.tpgui.ServerCache, pingdescending)
			sortingfunc = pingdescending
			ping.Text = "Ping ⬆"
		end
		pingwasasc = not pingwasasc
		populate(shared.tpgui.ServerCache)		
	end))
end

populate()

gui:SwitchTo"Teleport"
gui:Enable()