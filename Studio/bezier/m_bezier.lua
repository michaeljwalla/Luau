--WARNING includes demo code at bottom
local parent = workspace:WaitForChild("hi")
local module = {}

local insert = table.insert
local function lerpbezier(points: {Vector3 | CFrame}, percent: number): Vector3 | CFrame
	assert(percent <= 1 and percent >= 0, "Bezier curves may only be plotted from 0-100%")
	if #points == 1 then -- base case
		return points[1]
	end
	assert(#points < 11, "It's very performance-intensive to spam points... (try joining curves together instead)") --spamming points doesnt even give better shapes after like 5 or 6
	local newpoints = {}
	for i = 1, #points - 1 do
		insert(newpoints, points[i]:Lerp(points[i+1], percent))
	end
	points = nil
	return lerpbezier(newpoints, percent)
end
module.FindPointOnCurve = lerpbezier
module.GetInternalPercentOnCurves = function(curves: { {Vector3 | CFrame} }, percent: number, curveweights: { number }?) : Vector3 |  CFrame
	assert(percent <= 1 and percent >= 0, "Bezier curves may only be plotted from 0-100%")
	assert(#curves > 0, "Need at least one bezier curve to plot retard")


	if not curveweights then --assume equal weighting
		local weight = (#curves)^-1
		local minpercent = 0 --always tracks the lower value of the range that curve n holds from 0-1

		for i, curve in ipairs(curves) do
			if percent <= minpercent + weight then --add weight to min to get upper value of range (equivalent to "if min < percent < max")
				local internalpercent = (percent - minpercent) / weight --get the % of the local curve that the total % landed on (ex 40% with 2 50% curves -> curve 1, 80%) ( 0 < 0.4 < 0.5 -> (0 + 0.4) / 0.5)
				return internalpercent, i
			else
				minpercent = minpercent + weight --update lower %
			end
		end
	else
		assert(#curveweights == #curves, "Unequal amount of curves and curve weights given")
		local totalweight = 0
		for i,v in ipairs(curveweights) do totalweight = totalweight + v end --find the total weight so you can readjust values later to be from 0-1

		local minpercent = 0
		for i, curve in ipairs(curves) do
			local weight = curveweights[i] / totalweight --weight [0, 1] readjustment happens here
			if percent <= minpercent + weight then
				local internalpercent = (percent - minpercent) / weight --other than that, same code as equal weighting
				return internalpercent, i
			else
				minpercent = minpercent + weight
			end
		end
	end

end

--improvement of FindPointOnCurve that allows for the combination of bezier curves and 'weight distribution' of those curves (layman's terms: drawing some curves 'quicker' than others)
module.FindPointOnCurves = function(curves: { {Vector3 | CFrame} }, percent: number, curveweights: { number }?, internalpercent: number?, quickindex: number?) : Vector3 |  CFrame
	if not (internalpercent and quickindex) then
		internalpercent, quickindex = module.GetInternalPercentOnCurves(curves, percent, curveweights)
	end
	return module.FindPointOnCurve(curves[quickindex], internalpercent)
end


local part = Instance.new("Part")
part.Size = Vector3.one
part.Anchored = true

local point = part:Clone()
point.Material = "Neon"

local points = {Vector3.new(0,0,0), Vector3.new(30,50,30), Vector3.new(0,50,0), Vector3.new(30,0,10)}
local function transform(vecs, vec, mulvec)
	local new = {}
	for i,v in next, vecs do new[i] = mulvec * v + vec end
	return new
end
local lol = {points, transform(points, Vector3.new(30,0,10), Vector3.new(1,-1,1))}
for i,v in next, points do local new = point:Clone() new.Parent = workspace new.Position = v end
wait(2)
for i = 1, 1000 do
	task.wait()
	local new = part:Clone()
	new.Parent = workspace
	new.Position = module.FindPointOnCurves(lol, i*1e-3, {0.1, 0.9})--(points, i * 1e-2)
end