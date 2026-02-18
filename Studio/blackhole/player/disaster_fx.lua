local lp = game.Players.LocalPlayer
local insert = table.insert
local clamp = math.clamp
local random = math.random 
local defaultFOV = 70
local maxFOV = 120

local gravityRemovePercent = 75
local scaleMethod = "Linear" --"Linear"

local pullStrength = 30
local cameraPullStrength = 10

local maxFOVWarpDistance = 100
local minFOVWarpDistance = 10 --point of no return

local sitNoJumpTime = 1.5
local sitMinWait = 3.5
local sitMaxWait = 6.5

local growOverTime = 25

--this is just code to implement disaster-specific functions it isn't the "actual" code so u can skip it
local function lerp(a,b,p) 
	return a + (b-a) * p
end
local function getDisasterFolder(): Folder?
	return workspace:FindFirstChild("/Path/Disasters/")
end
local function getChar(): Model?
	return lp.Character
end
local function getRoot(): BasePart?
	return lp.Character and lp.Character:FindFirstChild"HumanoidRootPart"
end

local function tugCamera(cam, tugCF, strength)
	cam.CFrame = cam.CFrame:Lerp(
		CFrame.new(cam.CFrame.p, tugCF.Position),
		strength
	)
	return
end
local onDisasterFunctions = {}
local disasterRanCheck = {}
local function getTotalMass(p, counted)
	counted = counted or {}
	if counted[p] then return 0 else counted[p] = true end
	local sum = p:GetMass()
	for i,v in next, p:GetConnectedParts() do
		if not v:IsA"BasePart" then continue end
		sum += getTotalMass(v, counted)
	end
	return sum
end
--creates entry in table
local function createIfNot(t, index, data): data
	if not t[index] then t[index] = data end
	return t[index]
end
local function addDisasterFunc(disName: string, loopData: {Looped: boolean, Step: string}, func): nil
	local newEntry = {
		Loop = loopData.Looped,
		Step = loopData.Step,
		Execute = func
	}
	
	insert(
		createIfNot(onDisasterFunctions, disName, {}), --returns table[disName] or sets table[disName] = {}
		newEntry
	)
	
	createIfNot(disasterRanCheck, disName, {})
	return
end

game:GetService("RunService").RenderStepped:Connect(function(dt)
	local disasters = getDisasterFolder()
	if not disasters then return end
	--
	for _, disaster in disasters:GetChildren() do
		local disName = disaster.Name
		local funcs = onDisasterFunctions[disName]
		if not funcs then continue end
		
		local funcRanCheck = disasterRanCheck[disName]
		--
		for i, entry in funcs do
			if not entry.Loop and funcRanCheck[i] then continue end
			funcRanCheck[i] = true
			entry.Execute(disaster, dt)
		end 
		continue
	end
end)

local growthVector = Vector3.one * growOverTime
local scaleMethods = {
	Linear = function(a) return a end,
	Quadratic = function(a) return a^2 end
}
local countdown = 0
local noJumpTimer = 0
--the acutal black hole code
addDisasterFunc("BlackHole", {Looped = true, Step = "RenderStepped"}, function(disaster, dt)
	local focalPoint = disaster:FindFirstChild("FocalPoint")
	local root = focalPoint and getRoot()
	if not root then return end
	--
	local cc = workspace.CurrentCamera
	local looking = cc.CFrame.LookVector
	local fpDir = (focalPoint.Position - cc.CFrame.Position).Unit
	--
	
	--[0, 2] max is 2 (if fpDir == -looking, Magnitude is 1 - (-1) = 1+1 = 2)
	local lookingFactor = scaleMethods[scaleMethod](
		1 - (looking - fpDir).Magnitude / 2
	) --make range [0,1] for easy lerping
	local distanceFactor = scaleMethods[scaleMethod](
		1 - ((root.Position - focalPoint.Position).Magnitude - minFOVWarpDistance) / (maxFOVWarpDistance - minFOVWarpDistance)
	)--already should be [0,1]
	distanceFactor = clamp(distanceFactor, 0, 1.001)
	
	local currentMaxFOV = lerp(defaultFOV, maxFOV, distanceFactor)
	local actualFOV= lerp(defaultFOV, currentMaxFOV, lookingFactor)
	
	cc.FieldOfView = actualFOV
	tugCamera(cc, focalPoint.CFrame, cameraPullStrength*(distanceFactor) * dt)
	
	local mass = getTotalMass((root))
	root:ApplyImpulse(mass * fpDir * pullStrength * dt * distanceFactor) --pull
	if distanceFactor ~= 0 then root:ApplyImpulse(Vector3.new(0,gravityRemovePercent*1e-2 * mass * dt * workspace.Gravity,0)) end
	--visualize
	local min, max = focalPoint:FindFirstChild"Min", focalPoint:FindFirstChild("Max")
	if not (min and max) then return end
	maxFOVWarpDistance += growOverTime *dt
	minFOVWarpDistance += growOverTime * dt
	focalPoint.Size = Vector3.one * 0.2 * minFOVWarpDistance * 2
	min.Size = Vector3.one * minFOVWarpDistance * 2
	max.Size = Vector3.one * maxFOVWarpDistance * 2
	
	if distanceFactor > 0 and countdown <= 0 then
		root.Parent.Humanoid.PlatformStand = true
		root:ApplyAngularImpulse(Vector3.new(random(-15,15), random(-15,15), random(-15,15)) * mass)
		noJumpTimer = sitNoJumpTime
		countdown = random(sitMinWait, sitMaxWait)
	else countdown -= dt end
	noJumpTimer -= dt
	if noJumpTimer <= 0 then root.parent.Humanoid.PlatformStand = false end
end)