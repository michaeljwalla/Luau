math.randomseed(tick())

local mult = 1

script.Parent.Size *= mult
local cottonPlant = require(script.Parent.CottonPlant)
local plants = {}
for i = 1, 10 do
	table.insert(plants, cottonPlant.new(script.Parent, 4))
end

local t = task.wait(1)
local x = 0
while t do
	for i,CottonPlant in next, plants do
		CottonPlant:grow(t)
		if CottonPlant:FullyGrown() then print(CottonPlant.Attributes.Name, CottonPlant.Cotton.Amount) x += CottonPlant.Cotton.Amount table.remove(plants, i) break end
	end
	t = task.wait()
	if #plants == 0 then break end
end
print("Done", x)