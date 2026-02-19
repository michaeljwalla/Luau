local require = loadfile"bell/new/require.lua"""

local shared = require"bell/new/shared"
local stepper = require"bell/new/stepper"
local bezier = require("bell/new/bezier")
local keybinder = require("bell/new/keybinder")

local runservice = game:GetService"RunService"

local function lerp(a, b, p) 
	return a + (b - a) * p 
end

local clear, clone = table.clear, table.clone
local clamp = math.clamp
local blankvec = Vector3.zero
local blankcf = CFrame.new()
local cflerp = blankcf.Lerp --default

local defaultargs = { QuitOnDeath = true, Mode = "Speed", Value = 100, Method = cflerp }
local module = shared:Get("PlayerAPI", {
	Connections = {},
	WalkSpeed = {Enabled = false, Value = 16, Cached = 16},
	JumpPower = {Enabled = false, Value = 75, Cached = 16},
	BHopping = {Enabled = false},
	InfiniteJumping = {Enabled = false},
	NoRagdolling = {Enabled = false},
	NoClipping = {Enabled = false},
	Fly = require("bell/new/fly"),
	TweenArgs = defaultargs,
	TweenPositions = {},
	TweenStatus = {
		Died = false,
		CurrentPercent = 1,
		CurrentTime = 0,
		CurrentIndex = 1/0,
		InitialCF = blankcf,
		LastRoot = nil,
		Active = false
	}
})
local connections = module.Connections
for i,v in next, connections do stepper:Remove( unpack(v) ) end
clear(connections)

local lp = game.Players.LocalPlayer
module.LocalPlayer = lp
local function gethum(char): (Instance?, Instance?)
	char = char or lp.Character
	return char and char:FindFirstChildWhichIsA"Humanoid", char
end
local function getroot(char): (Instance?, Instance?, Instance?)
	local hum, char = gethum(char)
	return hum and hum.RootPart, hum, char
end
module.GetHumanoid = gethum
module.GetRoot = getroot


local function distancevec3(start, finish)
	return (start - finish).Magnitude
end
local function timebetweenpointswithspeed(start, finish, speed)
	return distancevec3(start,finish) / speed
end

local function noclip15(char: Instance, toggle: boolean): nil --noclip for r15
	toggle = not toggle -- true = noclip = opposite

	local parts = {
		char:FindFirstChild"Head",
		char:FindFirstChild"HumanoidRootPart",
		char:FindFirstChild"UpperTorso",
		char:FindFirstChild"LowerTorso",
	}
	for i,v in next, parts do v.CanCollide, v.CanTouch = toggle, toggle end -- implementation without using 4 ifs
	return
end
local function noclip6(char: Instance, toggle: boolean): nil --noclip for r6
	toggle = not toggle -- true = noclip = opposite

	local parts = {
		char:FindFirstChild"Head",
		char:FindFirstChild"HumanoidRootPart",
		char:FindFirstChild"Torso"
	}
	for i,v in next, parts do v.CanCollide, v.CanTouch = toggle, toggle end -- imp w/o using 3 ifs
	return
end
local rigR15 = Enum.HumanoidRigType.R15
function module:NoClip(toggle: boolean, char: Instance?)
	self.NoClipping.Enabled = (toggle == nil and not self.NoClipping.Enabled) or toggle
	local hum, char = gethum(char)
	if hum.RigType == rigR15 then
		noclip15(char, self.NoClipping.Enabled)
	else
		noclip6(char, self.NoClipping.Enabled)
	end
end
--set to -1 to cancel
function module:SetWalkSpeed(number)
	number = tonumber(number)
	local toggle = number and number ~= -1 

	self.WalkSpeed.Enabled = toggle or false --(nil or false)
	self.WalkSpeed.Value = number
	local hum = not toggle and gethum()
	if hum then
		hum.WalkSpeed = self.WalkSpeed.Cached
	end
end
function module:SetJumpPower(number)
	number = tonumber(number)
	local toggle = number and number ~= -1 

	self.JumpPower.Enabled = toggle or false --(nil or false)
	self.JumpPower.Value = number
end
function module:InfiniteJump(toggle)
	self.InfiniteJumping.Enabled = (toggle == nil and not self.InfiniteJumping.Enabled) or toggle
end
function module:BHop(toggle)
	self.BHopping.Enabled = (toggle == nil and not self.BHopping.Enabled) or toggle
end
function module:NoRagdoll(toggle)
	self.NoRagdolling.Enabled = (toggle == nil and not self.NoRagdolling.Enabled) or toggle
end
local humjumpstate = Enum.HumanoidStateType.Jumping
keybinder.RegisterKeybind({
	Info = "PlayerAPI >> InfiniteJump",		-- string
	Key = "Space", 					-- EnumItem | string
	Ctrl = false, 				-- boolean
	Alt = false,				-- boolean
	Repetitions = 1		-- number?
}, function(unix)
	local hum = module.InfiniteJumping.Enabled and gethum()
	if hum then hum:ChangeState(humjumpstate) end
end, true)
local spawn, defer = task.spawn, task.defer
local toradian = 180 / math.pi
connections.PlayerAPICharacterController = { stepper:Add(runservice, "Stepped", "PlayerAPICharacterController", function(delta)
	local root, hum, char = getroot()
	if not root then return end

	if module.WalkSpeed.Enabled then
		local ws, oldws = module.WalkSpeed.Value, hum.WalkSpeed
		if ws ~= oldws then module.WalkSpeed.Cached = oldws end
		hum.WalkSpeed = ws
	end
	if module.JumpPower.Enabled then
		local jp, oldjp = module.JumpPower.Value, hum.JumpPower
		if jp ~= oldjp then module.JumpPower.Cached = oldjp end
		hum.JumpPower = ws
	end
	if module.BHopping.Enabled then
		local forcevel = hum.MoveDirection * hum.WalkSpeed
    	root.Velocity = root.Velocity * Vector3.new(0,1,0) + forcevel
	end

	if module.NoClipping.Enabled then --wrap in an if even tho its not needed in case something else ever makes char noclip
		module:NoClip(module.NoClipping.Enabled, character)
	end
end) }

do
	local cachedhum
	local illegalstates = {
        [Enum.HumanoidStateType.FallingDown] = true,
        [Enum.HumanoidStateType.Ragdoll] = true,
        [Enum.HumanoidStateType.PlatformStanding] = true
    }

	local db
	local function onstatechanged(oldstate, newstate)
		local localhum = cachedhum
		if db or module.Fly:IsFlying() or not module.NoRagdolling.Enabled then return else db = true end

		local root = getroot()
		if root and (illegalstates[newstate] or (newstate.Name == 'Seated' and not (root.Anchored or root:IsGrounded()))) then
			localhum:ChangeState(oldstate)
		end
		db = false
	end
	local function oncharacteradded(char)
		cachedhum = char:WaitForChild("Humanoid", 60)
		if not cachedhum then return end

		if connections.NoRagdollOnStateChanged then
			stepper:Remove(unpack(connections.NoRagdollOnStateChanged))
		end
		connections.NoRagdollOnStateChanged = { stepper:Add(cachedhum, "StateChanged", "PlayerAPINoRagdollOnStateChanged", onstatechanged) }
	end
	connections.NoRagdollOnCharacterAdded = { stepper:Add(lp, "CharacterAdded", "PlayerAPINoRagdollOnCharacterAdded", oncharacteradded) }
	if lp.Character then spawn(oncharacteradded, lp.Character) end
end

local tweenargs = module.TweenArgs
local tweenstatus = module.TweenStatus
local tweenpositions = module.TweenPositions

local tweeninternaldata = {
	PositioningTimes = {},
	StartTime = 0,
	TotalPercent = 0,
	TotalRuntime = 0,
	BezierSumWeight = 0
}
local timeforposition = tweeninternaldata.PositioningTimes
local function disabletweener(skipnc)
	tweenstatus.Active = false
	tweenstatus.CurrentTime = 0
	tweenstatus.CurrentIndex = 1/0
	tweenstatus.LastRoot = nil
	tweenstatus.InitialCF = blankcf

	clear(timeforposition)
	if not skipnc then module:NoClip(false) end
	stepper:Disable(runservice, "Heartbeat", "PlayerAPITweener")
	return
end
local function enabletweener(root)
	tweenstatus.Died = false
	tweenstatus.Active = true
	tweenstatus.CurrentPercent = 0
	tweenstatus.CurrentTime = tick()
	tweenstatus.CurrentIndex = 1
	tweenstatus.LastRoot = root
	tweenstatus.InitialCF = root.CFrame

	module:NoClip(true)
	stepper:Enable(runservice, "Heartbeat", "PlayerAPITweener")
end
module.CancelMoveTo = function() disabletweener() end --new closure bc it should have no args
local function move(part, cframe)
	part.Velocity = blankvec
	part.CFrame = cframe
end

connections.PlayerAPITweener = { stepper:Add(runservice, "Heartbeat", "PlayerAPITweener", function(delta)
	if not tweenstatus.Active or tweenstatus.CurrentIndex > #tweenpositions then disabletweener() return end
	local root, hum, char = getroot()
	if not root or hum.Health == 0 then
		return
	elseif tweenstatus.LastRoot ~= root then
		if tweenstatus.LastRoot and tweenargs.QuitOnDeath then tweenstatus.Died = true disabletweener() return end
		module:MoveTo(tweenpositions, tweenargs) --recalculate
		--[[tweenstatus.LastRoot = root
		tweenstatus.InitialCF = root.CFrame
		tweenstatus.CurrentPercent = 0]]
	end
	
	-- implement movement now!
	local time = tick()
	local totaldiff, localdiff = time - tweeninternaldata.StartTime, time - tweenstatus.CurrentTime
	local index = tweenstatus.CurrentIndex

	tweeninternaldata.TotalPercent = clamp(totaldiff / tweeninternaldata.TotalRuntime, 0, 1)
	local percentfinished
	
	if tweenargs.IsBezier then
		percentfinished = tweeninternaldata.TotalPercent
		local internalpercent, curveindex = bezier.GetInternalPercentOnCurves(tweenpositions, percentfinished, tweenargs.BezierData) --bezierdata can be nil and still work (will default to equal weighting)
		
		local nextpoint = bezier.GetPointOnCurves(tweenpositions, nil, nil, clamp(internalpercent, 0, 1), curveindex, tweeninternaldata.BezierSumWeight)
		
		if percentfinished == 1 then
			disabletweener()
			return
		end
		move(root, nextpoint)
	else
		percentfinished = clamp(localdiff / timeforposition[index], 0, 1)
		local cfgetter = tweenargs.Method
		move(root, cfgetter(
			tweenstatus.InitialCF,
			tweenpositions[index],
			cfgetter == cflerp and percentfinished or {Total = tweeninternaldata.TotalPercent, Local = percentfinished},
			{Total = totaldiff, Local = localdiff}
		))
	end

	
	module:NoClip(true, char)
	if percentfinished == 1 then
		tweenstatus.CurrentIndex = index + 1
		tweenstatus.CurrentTime = tick()
		tweenstatus.InitialCF = tweenpositions[index]
	end
end) }
--where Method is an (optional) function that adjusts the tweening cframe given the start, end, and %finished -- f(start: CFrame, end: CFrame, percents: {Local: number, Total: number}, times: {Local: number, Total: number}): CFrame
--Method is not used for bezier curves (use weighting instead: args.BezierData)
local function convertsingletomultibezier(points)
	for i,v in next, points do
		if typeof(v) == 'Vector3' then
			points[i] = CFrame.new(v)
		end
	end
	timeforposition[1] = timeinterval

	tweenpositions = { points }
	module.TweenPositions = tweenpositions
	tweeninternaldata.BezierSumWeight = 1
end
local function weighcurvesequally(points, timeinterval)
	timeinterval = timeinterval / #points
	for i,v in ipairs(points) do
		for a,x in next, v do
			if typeof(x) == 'Vector3' then
				points[i][a] = CFrame.new(x)
			end
		end
		timeforposition[i] = timeinterval
	end
end
local function weighcurvesindividually(points, weights, totalweight)
	for i,curve in ipairs(points) do
		for a, node in next, curve do
			if typeof(x) == 'Vector3' then
				points[i][a] = CFrame.new(v)
			end
		end
		timeforposition[i] = weights[i] / totalweight
	end
end
local function setupbeziertween(points, runtime, weights)
	assert(next(points), "Missing curves/points for bezier tween")
	
	if type(points[1]) == 'table' then --multiple bezier curves
		local totalweight = weights and bezier.SumCurveWeights(weights)
		tweeninternaldata.BezierSumWeight = totalweight

		if not totalweight or totalweight == 0 then --equal time distribution, no weight was given
			weighcurvesequally(points, runtime)
		else 
			weighcurvesindividually(points, weights, totalweight)
		end
	else --convert to multi-curve format anyways
		convertsingletomultibezier(points)
	end
	
	tweeninternaldata.TotalRuntime = runtime
end
local function findtotallineardistance(points, startpos)
	local distance = 0
	local distances = {}
	for i,v in ipairs(points) do
		if typeof(v) == 'Vector3' then
			points[i] = CFrame.new(v)

			distances[i] = distancevec3(startpos, v)
			distance = distance + distances[i]
			startpos = v
			continue
		end
		distances[i] = distancevec3(startpos, v.Position)
		distance = distance + distances[i]

		curpos = v.Position
	end
	return distance, distances
end
local function setuptimedtween(points, runtime, startpos)
	local totaldistance, pointdists =  findtotallineardistance(points, startpos)--calculate the speed required to reach time limit
	for i = 1, #pointdists do
		timeforposition[i] = runtime * pointdists[i] / totaldistance
	end

	tweeninternaldata.TotalRuntime = runtime
end
local function findtotaltimegivenspeed(points, speed, curpos)
	local sum = 0
	local indivtimes = {}
	for i,v in ipairs(points) do
		if typeof(v) == 'Vector3' then
			v = CFrame.new(v)
			points[i] = v
		end
		local nxtpos = v.Position
		indivtimes[i] = timebetweenpointswithspeed(curpos, nxtpos, speed)
		sum = sum + indivtimes[i]
		curpos = nxtpos
	end
	return sum, indivtimes
end
local function setupspeedtween(points, speed, startpos)
	local totaltime, pointtimes = findtotaltimegivenspeed(points, speed, startpos)
	timeforposition = pointtimes
	tweeninternaldata.TotalRuntime = totaltime
end
--wrap points *even if its just one point* in  braces {} to activate tweening, else defaults to insta-tp
function module:MoveTo(points: CFrame | Vector3 | { CFrame | Vector3 } | { {CFrame | Vector3} }, args: { QuitOnDeath: boolean?, Mode: "Speed" | "Time", Value: number, Method: f?, IsBezier: boolean, BezierData: { number }? }?): (boolean, number)
	local root = getroot()
	if not root then
		return false
	elseif typeof(points) == 'CFrame' then
		move(root, points)
		return true
	elseif typeof(points) == 'Vector3' then
		move(root, CFrame.new(points))
		return true
	end

	assert(ipairs(points)(points, 0), "Expected ordered array for argument #1.")
	local len, args = #points, args or defaultargs
	
	assert(args.Mode ~= 'Speed' or args.Value ~= 0, "Tween speed cannot be 0.")
	self.TweenPositions, tweenpositions = points, points
	self.TweenArgs, tweenargs = args, args

	disabletweener(true)
	
	args.Method = type(args.Method) == 'function' and args.Method or cflerp --default to linear tweening

	if args.IsBezier then --traverse bezier curve(s) in given time
		--basically impossible to compute bezier arc length > 2nd degree curves w/o using numerical integration, which is then not worth the amount of processing power that could be used to do so
		assert(args.Mode == 'Time', "Bezier curves may only be tweened with a predetermined time, NOT speed.") 
		setupbeziertween(points, args.Value, args.BezierData)
	elseif args.Mode == 'Time' then --calculate speed to finish in given time
		setuptimedtween(points, args.Value, root.Position)
	else --calculate time to finish with given speed
		setupspeedtween(points, args.Value, root.Position)
	end

	tweeninternaldata.StartTime = tick()
	enabletweener(root)
	return true, tweeninternaldata.TotalRuntime
end

disabletweener(true)
--local lol, time = module:MoveTo({Vector3.new(0,0,0)}, {Mode = "Speed", Value = 80})

--task.wait(time)
--[[local points = {Vector3.new(0,0,0), Vector3.new(30,0,10), Vector3.new(30,50,30),Vector3.new(20,50,100), Vector3.new(0,50,0), Vector3.new(30,0,10)}
local function transform(vecs, vec, mulvec)
	local new = {}
	for i,v in next, vecs do new[i] = mulvec * v + vec end
	return new
end

local up = Vector3.new(0,50,0)
local lol = {points, points, points}
local points2 = {Vector3.new(100,50,100),Vector3.new(-100,50,100),Vector3.new(-100,50,-100),Vector3.new(100,50,-100),Vector3.new(100,50,100)}
module:MoveTo(points2, {Mode = "Time", IsBezier = true, Value = 10, QuitOnDeath = true}) --last bug: bezier curves are getting repeated in scale with how many curves they have: n curves = n^2 uses]]

return module