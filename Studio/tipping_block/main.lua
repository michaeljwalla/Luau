local turnspeed = 0.7

--delays

local waitBeforeMovingDelay = 0.25
local waitAfterMovingDelay = 0.25

local waitUntilShowingIndicatorDelay = 0

--

local part = script.Parent
local fake = part:Clone() --do not touch
fake:ClearAllChildren()

local sound = script:WaitForChild('Slam') --needs the SoundId


local wait = task.wait
local random = math.random
local insert, clone = table.insert, table.clone

local min = math.min
local signof = math.sign
local abs = math.abs
local sin, cos = math.sin, math.cos
local torad = math.pi/180
local pi = math.pi
local Vertices = {
	Vector3.new(1, 1, -1),  --v1 - top front right
	Vector3.new(1, -1, -1), --v2 - bottom front right
	Vector3.new(-1, -1, -1),--v3 - bottom front left
	Vector3.new(-1, 1, -1), --v4 - top front left

	Vector3.new(1, 1, 1),  --v5 - top back right
	Vector3.new(1, -1, 1), --v6 - bottom back right
	Vector3.new(-1, -1, 1),--v7 - bottom back left
	Vector3.new(-1, 1, 1)  --v8 - top back left
}
local dirhelp = {
	Vector3.new(1,0,0),
	Vector3.new(-1,0,0),
	Vector3.new(0,0,1),
	Vector3.new(0,0,-1)
}


local function absvec(vec3)
	return Vector3.new(abs(vec3.X), abs(vec3.Y), abs(vec3.Z))
end
local function lerp(a,b,p)
	return a + (b - a) * p
end
local function rougheq(a, b, epsilon)
	return abs(a - b) < epsilon
end
local function rougheqv3(a, b, epsilon)
	return absvec(a - b).Magnitude < epsilon
end

local function GetCorners(cf, size)
	size = size/2
	
	local corners = {}
	for _, Vector in pairs(Vertices) do
		table.insert(corners, ( cf * CFrame.new( size * Vector )).Position)
	end
	return corners
end



local baseRightVectors = setmetatable({ --unused but keep anyways
	[Vector3.new(1,0,0)] = 'Identity',
	[Vector3.new(0,0,1)] = 'Y',
	[Vector3.new(0,1,0)] = 'Z'
}, {
	__index = function(self, index: CFrame | Vector3)
		if typeof(index) == 'CFrame' then index = index.RightVector end

		if 1 - abs(index.X) < 0.001 then
			return 'Identity'
		elseif 1 - abs(index.Z) < 0.001 then
			return 'Y'
		elseif 1 - abs(index.Y) < 0.001 then
			return 'Z'
		end
		return '?'
	end,
})

local cframeequalangles = { --unused but keep anyways
	Identity = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	Y =	CFrame.new(0, 0, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
	Z = CFrame.new(0, 0, 0, 0, -1, 0, 1, 0, 0, 0, 0, 1)
}

local function outofbounds(cframe, size, min, max, errbounds)
	min -= Vector3.new(errbounds, 0, errbounds)
	max += Vector3.new(errbounds, 0, errbounds)
	for i,v in next, GetCorners(cframe, size) do
		local x, z = v.X, v.Z
		if not ((x >= min.X and x <= max.X) and (z >= min.Z and z <= max.Z)) then
			return true
		end
	end
	return false	
end



local function getpartbottomrel(part)
	local cf = part.CFrame
	local size = part.Size/2
	
	local identitytransform = cf.Rotation:Inverse()
	if rougheq(1, abs(cf.LookVector.Y), 0.001) then
		return (identitytransform * CFrame.new(0,-size.Z,0)).Position
	elseif rougheq(1, abs(cf.RightVector.Y), 0.001) then
		return (identitytransform * CFrame.new(0,-size.X,0)).Position
	end
	return (identitytransform * CFrame.new(0,-size.Y,0)).Position
end

local function getborderwithpos(part, pos)
	local cf1, size = part.CFrame, part.Size/2
	local direction = ((pos - cf1.Position) * Vector3.new(1,0,1)).Unit
	local absdir = absvec(direction)
	
	local identitytransform = cf1.Rotation:Inverse()
	if rougheqv3(absvec(cf1.LookVector), absdir, 0.001)  then
		return (identitytransform * CFrame.new(direction * size.Z)).Position
	elseif rougheqv3(absvec(cf1.RightVector), absdir, 0.001)  then
		return (identitytransform * CFrame.new(direction * size.X)).Position
	end
	return (identitytransform * CFrame.new(direction * size.Y)).Position
end
local function reachbottomofborder(part, pos)
	return CFrame.new(getborderwithpos(part, pos) + getpartbottomrel(part))
end




local nextmove, lastpos = nil, part.Position
local boundsmin, boundsmax = Vector3.new(-200,0,-200), Vector3.new(200,0,200)



local function isneighborx_XOR_z(pos, checkpos)
	local checkx, checkz = rougheq(pos.X, checkpos.X, 0.001), rougheq(pos.Z, checkpos.Z, 0.001)
	return (checkx or checkz) and not (checkx and checkz)
end
local function isneighborY(checkpos, cangoup)
	return rougheq(25, checkpos.Y, 0.001) or (cangoup and (rougheq(50, checkpos.Y, 0.001)))
end
local function isvalidpos(checkpart, cangoup)
	local checkpos = checkpart.CFrame
	local curpos = part.Position
	
	
	return not rougheqv3(checkpos, lastpos, 0.001) and isneighborx_XOR_z(curpos, checkpos) and isneighborY(checkpos, cangoup) and not outofbounds(fake.CFrame, fake.Size, boundsmin, boundsmax, 5)
end


local function pivotpart(part, pivotdata)
	local t = tick()
	local alpha = 0

	local startangle = Vector3.zero
	local finalangle = Vector3.new(unpack(pivotdata.Axis))
	part.PivotOffset = pivotdata.Pivot

	local lastpivot = part:GetPivot()
	while alpha < 1 do
		wait()
		alpha = min(1, (tick() - t)/turnspeed)

		local nextangle = lerp(startangle, finalangle, alpha)
		part:PivotTo(lastpivot * CFrame.Angles(nextangle.X, nextangle.Y, nextangle.Z))
	end
	part.CFrame = pivotdata.CFrame
	part.PivotOffset = CFrame.new()
end

while true do
	--[[local currentorient = baseRightVectors[part.CFrame]
	part.CFrame = CFrame.new(part.Position) * cframeequalangles[currentorient]]

	if not nextmove then
		local possiblerotations = {}
		do
			local ogcf = part.CFrame
			
			fake.CFrame = ogcf
			local validy = rougheq(fake.Position.Y, 50, 0.001) and 25 or 50
			local washorizontal = rougheq(25, fake.Position.Y, 0.001)
			
			
			
			local offset = 0
			for i = 1, 4 do
				fake.CFrame = ogcf
				fake.PivotOffset = reachbottomofborder(fake, fake.Position + dirhelp[i])
				
				local tbl = {0, 0, 0}
				local found
				
				local ctr = 0
				
				for i = 1, 3 do
					for a = -1, 1, 2 do
						fake.CFrame = ogcf
						tbl[i] = a * pi/2
						local axis = CFrame.Angles(unpack(tbl))
						fake:PivotTo(fake:GetPivot() * axis)

						
						
						--[[local new = fake:Clone()
						new.Transparency = 0.5
						new.CFrame = part.CFrame
						new.Parent = workspace.Preview
						task.spawn(pivotpart, new, {CFrame = fake.CFrame, Axis = clone(tbl), Pivot = fake.PivotOffset})]]
						local case = isvalidpos(fake, washorizontal)
						if not case then --[[task.delay(1, function() new.BrickColor = BrickColor.new("Crimson") task.wait(1) new:Destroy() end) Instance.new"Model".Parent = new]]  continue end

						insert(possiblerotations, { CFrame = fake.CFrame, Axis = clone(tbl), Pivot = fake.PivotOffset })
						found = true
						break
					end
					if found then break end
					insert(tbl, 1, 0) --push over value
					rawset(tbl, 4, nil) --remove old
				end
			end
		end
		
		

		lastpos = part.Position
		nextmove = possiblerotations[random(1,#possiblerotations)]
		
		
		wait(waitUntilShowingIndicatorDelay)
		
		local new = fake:Clone()
		new.Transparency = 0.5
		new.CFrame = nextmove.CFrame
		new.Parent = workspace.Preview
	else
		wait(waitBeforeMovingDelay)
		--if abs(nextmove.Position.Y - lastpos.Y) > 1 then
		pivotpart(part, nextmove)
		sound:Play()
		--end
		nextmove = nil
		workspace.Preview:ClearAllChildren()
		
		wait(waitAfterMovingDelay)
	end
end