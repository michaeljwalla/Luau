local module = {}

local plane = workspace:WaitForChild("Plane")
local origin = plane:WaitForChild("Origin")
local nodes = plane:WaitForChild("Nodes")
local connectors = plane:WaitForChild("Connectors")
local insert = table.insert
local abs = math.abs
local v3 = Vector3.new
local cf = CFrame.new

local inf = 1/0
local function isundef(n)
	return not tonumber(n) or n ~= n --nan check
	or abs(n) == inf
end
function module.clearPlane()
	nodes:ClearAllChildren()
	return
end
module.PlotStep = 0.025
module.BoundsWorldScale = { X = 1, Y = 1, Z = 1 }
module.Bounds = {
	X = {0, 100},  	--x
	Y = {0, 100}, 	--y
	Z = {0, 100}  	--z
}
module.Steps = 16
local boundsScale = module.BoundsWorldScale
local bounds = module.Bounds
function module.SetBoundsWorldScale(dim, value)
	boundsScale[dim] = (not boundsScale[dim] or isundef(value) or value <= 0) and error"Invalid number given." or value
end
function module.setBoundMin(dim, value)
	local dimension = bounds[dim]
	assert( dimension and (isundef(value) and error"Invalid number given.") or value < dimension[2], ("Minimum cannot be >= maximum (%s)."):format(dim) )
	dimension[1] = value
	return
end
function module.setBoundMax(dim, value)
	local dimension = bounds[dim]
	assert( dimension and (isundef(value) and error"Invalid number given.") or value > dimension[1], ("Maximum cannot be <= minimum (%s)."):format(dim) )
	dimension[2] = value
	return
end
local baseNode = Instance.new("Part")
baseNode.Anchored = true
baseNode.Size = Vector3.one * 0.5

local baseLine = baseNode:Clone()
baseLine.Size = Vector3.one

local function plotinternal(x, yz)
	local newNode = baseNode:Clone()
	newNode.Position = origin.Position + v3(
		-x * boundsScale.X,				--NEGATIVE BC THE AXIS IS FLIPPED IN 3d WORLD
		yz.Real* boundsScale.Y,
		yz.Imaginary* boundsScale.Z
	)
	newNode.Parent = nodes
	return newNode
end
local function lerp(a, b, p)
	return a + (b-a) * p
end
local function getPercentFromLerp(a,b, lerped)
	return lerped / (b - a)
end
--[[

(lerped - a) / (b - a) = p
p(b-a) = lerped - a
lerped = a + p(b-a)
]]
local function connectPoints(a, b)
	local newLine = baseLine:Clone()
	newLine.Size = v3(1,1, (a-b).Magnitude)
	newLine.CFrame = cf( lerp(a,b,0.5), b )
	newLine.Parent = connectors
	return newLine
end
local function drawLinesForPoints()
	connectors:ClearAllChildren()
	local nodes = nodes:GetChildren()
	if not next(nodes) then return end
	connectPoints(origin.Position, nodes[1].Position)
	task.wait(0.025)
	for i = 1, #nodes-1 do
		connectPoints(nodes[i].Position, nodes[i+1].Position)
		task.wait(0.05)
	end
	return
end
module.CachedFunc = nil
function module.plotFunction(f)
	nodes:ClearAllChildren()
	connectors:ClearAllChildren()
	module.CachedFunc = f
	local maxSteps = module.Steps
	local nodesCache = {}
	
	local minX, maxX = bounds.X[1], bounds.X[2]
	for i = 1, maxSteps do
		task.wait(module.PlotStep)
		local valuePlotting = lerp(minX, maxX, i/maxSteps)
		
		local nextPoint = f(valuePlotting)
		insert(nodesCache, nextPoint)
		plotinternal(valuePlotting, nextPoint).Name = i
	end
	drawLinesForPoints()
	return nodesCache
end
local function plotBetweenPoints(a, b, f)
	local newPos = lerp(a, b, 0.5)

	local minX, maxX = bounds.X[1], bounds.X[2]
	local valuePlotting = lerp(
		minX, maxX,
		getPercentFromLerp(minX,maxX, -(newPos.X - origin.Position.X)) --gets the percent that wouldve placed it at that world position
	)
	
	local nextPoint = f(valuePlotting)
	return plotinternal(valuePlotting, nextPoint), nextPoint
end

return module
