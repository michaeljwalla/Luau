local ray = game:WaitForChild"ServerStorage":WaitForChild"Ray"
local rayFolder = workspace:WaitForChild"Rays"
local drawnRays = {}

local debris = game:GetService("Debris")
local insert, random = table.insert, math.random
local randomseed = math.randomseed
local round = math.round

local handle = script.Parent.Parent
local tool = handle.Parent
local selfPrism = handle:WaitForChild("Prism")
local shooter: BasePart = script.Parent --assuming :isA("BasePart")
local maxRaycastDistance = 150

local numBounces = 2
local phaseInitialPass = true
local defaultColor = BrickColor.new("Really red").Color


local numScatterMin = 8
local numScatterMax = 8
local white = Color3.new(1,1,1)
local scatterPresets = { --represents the scatters possible. scatter[1] means the light is passing fully (1 beam).
	[1] = {},
	[2] = {white},
	[3] = {Color3.new(1,0,0), Color3.new(0,0,1)},
	[4] = {Color3.new(1,0,0), Color3.new(0,0,1), Color3.new(0,1,0)},
	[5] = {Color3.new(1,0,0), Color3.new(0,0,1), Color3.new(0,1,0), Color3.new(1,1,0)},
	[6] = {Color3.new(1,0,0), Color3.new(0,0,1), Color3.new(0,1,0), Color3.new(1,1,0), Color3.new(1,0,1)},
	[7] = {Color3.new(1,0,0), Color3.new(0,0,1), Color3.new(0,1,0), Color3.new(1,1,0), Color3.new(1,0,1), Color3.new(0,1,1)},
	[8] = {Color3.new(1,0,0), Color3.new(0,0,1), Color3.new(0,1,0), Color3.new(1,1,0), Color3.new(1,0,1), Color3.new(0,1,1), Color3.new(1,0.5,0)},
}
local maxScatterRotOffsets = {
	x = math.rad(35),
	y = math.rad(35),
	z = math.rad(35)
}
local scatterMultiplierAdd = 15 -- every scatter adds x% to the sum of ALL ray damage.
-- no scatter = [1] = 0
-- 1 split    = [2] = 15%
--[[
m = totalMultiplier
n = numSplits
x = damageAmplifier

1 + m*n = n*x
x = (1 + m*n)/n

ex: 1 split @ 15% mult
expected: 1.15x

x = (1 + (0.15)(2))/2
  = 0.575
  
0.575 * (2) = 1.15x
n*x = 1.15x
]]
local scatterDamageAmps = setmetatable({}, {__index = function(self, indx)
	return (1 + 1e-2 * (indx-1) * scatterMultiplierAdd)/indx
end,})

local function floorVec(v3)
	return Vector3.new(round(v3.x), round(v3.y), round(v3.z))
end

local function rand(n)
	return (random() < 0.5 and -1 or 1) * random()*n
end
--draw ray from point A to point B p simple stuff
local function part(p)
	local newPart = ray:Clone()
	newPart.Size = Vector3.one
	newPart.Position = p
	newPart.Parent = rayFolder
	insert(drawnRays, newPart)
end
local function drawRay(pA: Vector3, pB: Vector3, color: Color3, length: number): BasePart
	local newRay = ray:Clone()
	newRay.Size *= Vector3.new(1,1, length or (pA-pB).Magnitude)
	newRay.Color = color or defaultColor
	newRay.CFrame = CFrame.new(pA:Lerp(pB, 0.5), pB)
	newRay.Parent = rayFolder

	--part(pA) --hit contact debug
	return newRay
end
local rParams = RaycastParams.new()
rParams.CollisionGroup = "Raycast"
local scatterParams = RaycastParams.new()
scatterParams.CollisionGroup = "Scatter"

local function makeCast(origin: position, ending: Vector3, color: Color3, rp: RaycastParams): RaycastResult
	rp = rp or rParams
	local raycast = workspace:Raycast(origin, ending, rp)
	local newBeam = drawRay(
		origin,
		raycast and raycast.Position or ending,
		color
	)
	newBeam.CollisionGroup = rp.CollisionGroup
	insert(drawnRays, newBeam)
	--[[insert(drawnRays, 
		drawRay(
			raycast and raycast.Position or ending,
			raycast and raycast.Position + raycast.Normal*15 or ending,
			Color3.new(0,1,0),
			15
		)
	)]]-- show normal vector


	return raycast
end
local function getReflection(incidentVector, curNormal)
	return (incidentVector - (2 * incidentVector:Dot(curNormal) * curNormal)).Unit --idk bro https://devforum.roblox.com/t/how-to-reflect-rays-on-hit/18143
end
local function ricochetCast(originCF: CFrame, direction: Vector3, distance: number, color: Color)
	distance = distance or maxRaycastDistance
	local cast = makeCast(originCF.Position, direction.Unit * distance, color)
	if not cast then return end

	local incidentVector = originCF.LookVector
	for i = 1, numBounces do

		local reflection = getReflection(incidentVector, cast.Normal)
		local nextCast = makeCast(cast.Position, reflection*distance , color)

		if not nextCast then break end

		incidentVector = (nextCast.Position - cast.Position).Unit
		cast = nextCast
	end

	return
end

local function lightRayPrismCast(originCF, direction: Vector3, distance: number)
	distance = distance or maxRaycastDistance
	local cast = makeCast(originCF.Position, direction.Unit * distance, white)
	if not cast then return end

	--dmg humanoid?
	if cast.Instance.CollisionGroup ~= "Prism" then return end

	--we will reconstruct it in a sec
	drawnRays[#drawnRays]:Destroy()
	rawset(drawnRays, #drawnRays, nil)

	local insideCast = workspace:Raycast(cast.Position + 0.1*originCF.LookVector, direction.Unit * distance, rParams) --always phase prism on first try
	insert(drawnRays, 
		drawRay(
			originCF.Position,
			insideCast and insideCast.Position or cast.Position + direction.Unit * distance, --draw it manually to account for prism phase
			white
		)
	)
	if not insideCast then return end 
	--how...? unclosed shape?
	--just in case ig
	if insideCast.Instance.CollisionGroup ~= "Prism" then return end

	--scatter time
	local reflection = 	getReflection(originCF.LookVector, insideCast.Normal)
	
	
	randomseed(tick() * random()) --num beams produced is random
	local numBeams = random(numScatterMin, numScatterMax)
	print(numBeams)
	--direction of beams is seeded (random but predictable)
	local localRotation = Vector3.new((selfPrism.PrimaryPart.CFrame * handle.CFrame:Inverse()):ToEulerAngles())
	local seed = floorVec(1e3*localRotation)
	randomseed(
		seed.x + seed.y + seed.z
	)
	for i,color in next, scatterPresets[numBeams] do
		local dir = (CFrame.new(insideCast.Position, insideCast.Position + reflection) * CFrame.Angles(
			rand(maxScatterRotOffsets.x),
			rand(maxScatterRotOffsets.y),
			rand(maxScatterRotOffsets.z)
			)).LookVector
		makeCast(insideCast.Position, dir * distance, color, scatterParams)
		--drawnRays[#drawnRays].Transparency = 0.5
	end
end
local function main()
	lightRayPrismCast(shooter.CFrame, shooter.CFrame.LookVector)
	for i,v in next, drawnRays do debris:AddItem(v, 0.1) rawset(drawnRays, i, nil) end
end

tool.Activated:Connect(main)