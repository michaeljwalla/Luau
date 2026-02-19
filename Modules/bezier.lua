local require = loadfile"bell/new/require.lua"""
local shared = require"bell/new/shared"
local module = shared:Get("Bezier", {})

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
local function gettotalweight(curveweights: { number }): number
	local totalweight = 0
	for i,v in ipairs(curveweights) do totalweight = totalweight + v end --find the total weight so you can readjust values later to be from 0-1
	return totalweight
end
module.SumCurveWeights = gettotalweight
module.GetPointOnCurve = lerpbezier
local function internalpercfromcurvelist(curves: { {Vector3 | CFrame} }, percent: number, curveweights: { number }?, weightsumcache: number?) : Vector3 |  CFrame
	--assert(percent <= 1 and percent >= 0, "Bezier curves may only be plotted from 0-100%")
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
		local totalweight = weightsumcache or gettotalweight(curveweights)

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
module.GetInternalPercentOnCurves = internalpercfromcurvelist

--improvement of FindPointOnCurve that allows for the combination of bezier curves and 'weight distribution' of those curves (layman's terms: drawing some curves 'quicker' than others)
module.GetPointOnCurves = function(curves: { {Vector3 | CFrame} }, percent: number, curveweights: { number }?, internalpercent: number?, quickindex: number?, weightsumcache: number?) : Vector3 |  CFrame
	if not (internalpercent and quickindex) then
		internalpercent, quickindex = internalpercfromcurvelist(curves, percent, curveweights, weightsumcache)
	end
	return lerpbezier(curves[quickindex], internalpercent)
end

return module