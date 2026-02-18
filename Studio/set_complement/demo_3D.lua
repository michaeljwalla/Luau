local demosamples = 150
local demoyields = false

local demoShouldFaceCenter = true --just makes the demo look nicer
local demotransparency = 0
--


local squarelength = 12
local circleradius = 5
--change me^

local epsilon = 1e-7
--set me to 0 if you want to include circle's perimeter as valid position


local startingpos = Vector3.new(-squarelength, 0, squarelength) * 0.5

--
local random = math.random
local abs = math.abs

local function lerp(a: any, b: any, p: number): any
	return a + (b - a) * p
end
--[[

circle equation
x^2 + y^2 = r^2

y^2 = r^2 - x^2

y = +- sqrt(r^2 - x^2)

]]
local function solveOtherThanRadius(x: number, radius: number): { number & number }
	return {
		-(radius^2 - x^2)^0.5, -- x^0.5 is actually ~3x faster than sqrt(x) (not that it matters since the difference is a couple millionths of a millisecond)
		(radius^2 - x^2)^0.5
	}
end

local function getRandomQuadPosExcludingCircleXZ(min: Vector3, squarelen: number, radius: number): Vector3
	assert(radius * 2 < squarelen, "Chance of failure at midpoint along any axis (lower the radius)") --since the circle might be tangent with the squares sides if this were the case

	local diff = Vector3.new(squarelen, 0, squarelen)
	local max = min + diff
	
	local midpoint = lerp(min, max, 0.5) --assume circle is centered in the given bounds
	
	local randomX = lerp(min.X, max.X, random())
	local distanceFromMidX = abs(randomX - midpoint.X) --pretend theres a line drawn along the Z axis at X = distanceFromMidX
	
	if distanceFromMidX > radius then --circle radius not large enough for any intersection along line, every point is 'safe'
		local randomZ = lerp(min.Z, max.Z, random())
		return Vector3.new(
			randomX,
			min.Y,
			randomZ
		)
	elseif distanceFromMidX <= radius then --randomX gave a tangent line/intersection to the midpoint circle, at least one point is 'unsafe'
		local rangeInsideCircle = solveOtherThanRadius( distanceFromMidX, radius)
		
		-- i think a more mathematical notation would be [min, pt1) U (pt2, max]
		-- when the line was tangent to the circle, solveOtherThanRadius returns { n, n } since theres only one intersection (kind of how like 1 = sin(90) but 0.5 = sin(30), sin(150))
		local validranges = {		
			{min.Z, midpoint.Z + rangeInsideCircle[1] - epsilon}, 
			{midpoint.Z + rangeInsideCircle[2] + epsilon, max.Z}  -- +-epsilon to exclude the perimeter of the circle as a valid pos (remove it to include the circles edge)
		}
		--since we assumed the circle is at the midpoint of the square, we KNOW that either sub-range has an equal chance of being picked
		if random() < 0.5 then
			local randomZ = lerp(validranges[1][1], validranges[1][2], random())
			return Vector3.new(
				randomX,
				min.Y,
				randomZ
			)
		else
			local randomZ = lerp(validranges[2][1], validranges[2][2], random())
			return Vector3.new(
				randomX,
				min.Y,
				randomZ
			)
		end
	end
end
local demofolder = Instance.new("Folder", workspace)
demofolder.Name = "DemoPieces"
local part = Instance.new("Part")
part.Anchored = true
part.Size = Vector3.new(1,1,1)
part.Transparency = demotransparency

local function rundemo(y, radius, lookoffset)
	startingpos = Vector3.new(startingpos.X, y, startingpos.Z)
	local midpoint = lerp(startingpos, startingpos + Vector3.new(squarelength, 0, squarelength), 0.5)
	for i = 1, demosamples do
		if demoyields then task.wait() end

		local new = part:Clone()

		--startingpos = startingpos * Vector3.new(1,0,1) + Vector3.new(0,math.random() * 2.5 - 2) --just randomizes y val a little

		new.CFrame = CFrame.new(
			getRandomQuadPosExcludingCircleXZ(startingpos, squarelength, radius),
			Vector3.new(midpoint.X, lookoffset or startingpos.Y, midpoint.Z)
		)
		new.Parent = demofolder
	end
end
--rundemo(0, circleradius)

local function demo3dsphere(centerpoint, radius, precision)
	local lowestpoint = centerpoint.Y - radius
	for i = -radius, radius, precision do
		rundemo(centerpoint.Y + i, radius * math.cos(math.pi/2 * abs(i)/radius), centerpoint.Y)
	end
end
demo3dsphere(Vector3.new(0,25,0), 5, 0.1)