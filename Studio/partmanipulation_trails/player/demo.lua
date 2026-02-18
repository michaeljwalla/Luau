local function isnetworkowner() return true end
local lp = game.Players.LocalPlayer
local function getroot() return lp.Character and lp.Character:FindFirstChild"HumanoidRootPart" end
local sync, desync = task.synchronize, task.desynchronize
local clr = table.clear
local floor = math.floor







local balls = require(game.ReplicatedStorage.partmanipulation_register)
local defaultpartshapes = {}
defaultpartshapes.Circle = function(self, degree, ...) --globals defined in (obj):update()
	local args = {...}
	local offsetperc = args[1]/args[2]
	degree = degree * torad + (offsetperc * tau)
	return Vector3.new(sin(degree), cos(args[3].degrps(0.1)*torad + offsetperc*tau)/15, cos(degree)) * self.Radius
end
defaultpartshapes.Heart = function(self, degree, ...) 
	local args = {...}
	local offsetperc = args[1]/args[2]
	degree = degree * torad + (offsetperc * tau)
	return Vector3.new(
		sin(degree)^3,
		0,
		( 13*cos( degree ) - 5*cos( 2*degree ) - 2*cos( 3*degree ) - cos( 4*degree ) )/16
	) * self.Radius
end
defaultpartshapes.Figure8 = function(self, degree, ...)
	local args = {...}
	local cache = args[3]
	local offsetperc = args[1]/args[2]
	degree = degree * torad + (offsetperc * tau)
	
	local x, y = sin(degree), 0.5 * sin(2 * degree)
	local rot2 = cache.degrps(0.0167) * torad
	local offs, offc = sin(rot2), cos(rot2)
	return Vector3.new(x*offc - y*offs, 0, x*offs + y*offc) * self.Radius
end
defaultpartshapes.Flower = function(self, degree, ...) --overrides rps to a fifth of the speed
	local args = {...}
	local cache = args[3]
	local chooseshape = floor(cache.degrps(0.05)*4/360)+2 --1/(4shapes * 5s each)
	local offsetperc = args[1]/args[2]
	degree = cache.degrps(self.RPS * 0.2) * torad + (offsetperc * tau)
	
	local x, y = sin(chooseshape * degree) * cos(degree), sin(chooseshape * degree) * sin(degree)
	local rot2 = cache.degrps(0.0167) * torad
	local offs, offc = sin(rot2), cos(rot2)
	return Vector3.new(x*offc - y*offs,0,y*offc + x*offs) * self.Radius
end
defaultpartshapes.Lightning = function(self, degree, ...) --125d
	local args = {...}
	local cache = args[3]
	local offsetperc = args[1]/args[2]
	degree = degree * torad + (offsetperc * tau)
	
	local x,y = cos(degree), sin(degree)
	local rot2 = cache.degrps(random()*5) * torad
	local offs, offc = sin(rot2), cos(rot2)
	return Vector3.new(
		x*offc - y*offs,
		0,
		y*offc + x*offs
	) * self.Radius + Vector3.new(0,75 * cos(cache.degrps(3*random())) + 40)
end
defaultpartshapes.Nova = function(self, degree, ...) --125d
	local args = {...}
	local cache = args[3]
	local offsetperc = args[1]/args[2]
	degree = degree * torad + (offsetperc * tau)

	local x,y = cos(2*degree)*cos(degree), cos(2*degree) * sin(degree)
	local rot2 = cache.degrps(5) * torad
	local offs, offc = sin(rot2), cos(rot2)

	local x = Vector3.new(
		x*offc - y*offs,
		cos(3*degree * random())*cos(5*degree * random()) + x*offs,
		y*offc + x*offs
	).Unit * self.Radius + Vector3.new(0,self.Radius/2)
	return x
end
defaultpartshapes.Cube = function(self, degree, ...) --tween
	local args = {...}
	local power = args[3].cube
	local spot = args[1]-1
	local x, y, z = (spot % power), floor(spot/power^2), floor(spot / power) % power
	return Vector3.new(x - power/2,y,z - power/2) * self.Radius + Vector3.new(0,5) --Vector3.new(x*2, 3 + 0.5 * y, z*2)
end
defaultpartshapes.Smiley = function(self, degree, ...)
	local args = {...}
	local place = args[1]
	local cache = args[3]
	local x,y
	if place <= 2 then
		degree = degree * torad + (place/args[2] * tau)
		x = (2*place - 3) * 0.25 --x/2 - 3/4
		y = 0.25 + sin(cache.degrps(5)) * 0.25
	elseif place <= 5 then
		degree = degree * torad + ((place-2) * 0.25 * tau)
		x = cos(degree) * 0.5
		y = -abs(sin(degree)) * 0.25 - 0.25
	else
		degree = degree * torad + ((place-5)/(args[2]-5) * tau)
		x = cos(degree)
		y = sin(degree)
	end
	local degree2 = cache.root and -cache.root.Orientation.Y*torad or 0
	return Vector3.new(x * cos(degree2), y, x * sin(degree2)) * self.Radius
end
defaultpartshapes.Orbit = function(self, degree, ...) 
	local args = {...}
	local cache = args[3]
	local offsetperc = args[1]/args[2]
	
	randomseed(args[1]*12345) --to make predictable orbit patterns
	degree = (cache.degrps(self.RPS * (random() + 0.1)) * torad +((offsetperc + random()) * tau)) % tau
	
	return Vector3.new(
		cos(degree),
		0,
		sin(degree)
	) * (args[1]/args[2] + 5/self.Radius) * self.Radius
end
defaultpartshapes.Wings = function(self, degree, ...)
	local args = {...}
	local cache = args[3]
	local offsetperc = args[1]/args[2]
	degree = degree * torad + (offsetperc * tau)
	
	local x,y = sin(2*degree)
	y = 2*x*cos(degree)
	local degree2 = -cache.root.Orientation.Y*torad
	return -cache.root.CFrame.LookVector + Vector3.new(
		x*cos(degree2),
		y,
		x*sin(degree2)
	) * self.Radius
end


--
for i,v in next, defaultpartshapes do balls.updatefenv(v) end

local connectedparts = {}
local plen = 0
local function removepart(obj)
	if not connectedparts[obj] then return end
	rawset(connectedparts, obj, nil)
end
local zero, czero = Vector3.zero, CFrame.identity
local defdata = {
	rps = 1,
	radius = 15,
	P = nil,
	D = 500, --125 for lightning rememebr this
	mode = "tp", --tween better for debug but doesnt actually replicate soo dont use
	offset = Vector3.new(0,0,0),
	method = defaultpartshapes.Wings,
	setup = function(self)
		local part = self.Part
		part.CanTouch = false
		while not isnetworkowner(part) do wait() end
		local bvel = part:WaitForChild("BodyVelocity", 5)
		if not bvel then self:unregister() return end
		bvel:Destroy()
		local con
		con = part.AncestryChanged:Connect(function()
			con:Disconnect()
			self:unregister()
		end)
		if self.Mode == 'tweening' then
			self.Part.Position = (getroot() or czero).Position
		end
		self.Part.RotVelocity = zero
		connectedparts[self] = true
	end,
	unregister = removepart
}
workspace.ChildAdded:Connect(function(p)
	if not p:IsA"BasePart" then return end
	balls.register(p, defdata)
end)
local function newdegcache(n)
	local next = self.degs[n]
	if not next then
		next = getfenv(2).degreeAtRPS(n)
		self.degs[n] = next
	end
	return next
end
local plen = 1
local cachefuncs = {
	cube = function(self)
		local pow = plen^(1/3)
		local pcheck = floor(pow)
		pow = (pow == pcheck and pow) or pcheck + 1
		rawset(self, 'cube', pow)
		return pow
	end,
	root = function(self)
		local root = getroot()
		if root then
			rawset(self, 'root', root)
			return root
		end
	end,
	degrps = function(self)
		if not self.degs then
			self.degs = {}
			getfenv(newdegcache)['self'] = self
		end
		return newdegcache
	end,
}
local cachemt = {}
local cache = setmetatable({}, cachemt)
cachemt.__index = function(self, index)
	local x = cachefuncs[index]
	return x and x(self)
end
game["Run Service"].Heartbeat:Connect(function()
	desync()
	local root = getroot()
	if not root then return end
	root = root.Position
	
	local ctr = 0
	local tbl = {}
	for i,v in next, connectedparts do
		if not isnetworkowner(i.Part) then i:unregister() continue end
		ctr = ctr + 1
		tbl[i] = i:nextupdate(root, ctr, plen, cache)
	end
	plen = ctr > 0 and ctr or 1
	
	sync()
	for i,v in next, tbl do
		i:update(v, true)
	end
	clr(cache)
	clr(tbl)
end)