local module = {}

local random =  math.random
local newc3 = Color3.new

local torad = math.pi/180
local clone = table.clone
local default = {
	
	--number of times a branch can branch again
	MaxBranchDepth = 4,
	MinBranchDepth = 2,
	
	--number of branches that can sprout from one point
	MaxBranches = 4,
	MinBranches = 1,
	
	--physical length of branch
	MaxBranchLength = 2,
	MinBranchLength = 0.5,
	
	--% a single branch can grow in one second (averages to 20%)
	MaxGrowthPercent = 0.4,
	MinGrowthPercent = 0,
	
	--how thick the first branch is
	StartingBranchWidth = 0.25,
	
	--range of size of cotton
	CottonBallMinWidth = 0.25,
	CottonBallMaxWidth = 0.6,
	
	--how much each sprouting branch can turn by (relative to root)
	BranchMaxTurnRadiusY = 360 * torad,
	BranchMaxTurnRadiusXZ = 180 * torad,
	
	--same but for starting branch only
	StartingBranchMaxTurnRadiusY = 360 * torad,
	StartingBranchMaxTurnRadiusXZ = 60 * torad,
	
	--varying decays as depth increases 
	BranchDepthBranchDecayLinear = 1/3, --fractional branch decay means it loses a branch every (1/fraction) depths
	BranchDepthLengthDecayLinear = 0.25,
	BranchDepthSizeDecayLinear = 0.05,
}
module.Default = default
default.__index = default
function module.Defaultify(settingstbl: {}): {}
	return setmetatable(settingstbl, default)
end
module.LevelData = {
	{
		Name = "Wild Cotton",
		Description = "Basic, undomesticated cotton. Grows slowly with little yield.",
		Fertilizer = 1,
		Space = 1,
		Price = 0,
		Color = BrickColor.new("Dark orange").Color
	},
	{
		Name = "Egyptian Cotton",
		Description = "A durable, soft type of cotton. Slightly faster growth and average yield.",
		Fertilizer = 1,
		Space = 1,
		Price = 0,
		Color = BrickColor.new("Grime").Color
	},
	{
		Name = "Petit Gulf Cotton",
		Description = "A versatile, high-demand cotton credited with partially facilitating the (1st) American Industrial Revolution. Satisfactory growth rate and yield.",
		Fertilizer = 2,
		Space = 1,
		Price = 0,
		Color = BrickColor.new("Shamrock").Color
	},
	{
		Name = "Cotton Tree",
		Description = "A crossbreed of several cotton and tree species, genetically modified to survive in shallow soil. Exceptional yield with subpar growth speed.",
		Fertilizer = 3,
		Space = 3,
		Price = 0,
		Color = BrickColor.new("Pine Cone").Color
	},
	setmetatable({
		Name = "Magic Beans",
		Description = "You sold your family's only cow to a strange man for these.",
		Space = 5,
		Fertilizer = 5,
		Price = 0,
		
	}, {
		__index = function(self, index)
			return index == 'Color' and newc3(random(), random(), random()) or nil
		end,
	})
}



module[1] = module.Defaultify{
	MaxBranchLength = 1,
	MinBranchLength = 0.25,
	
	MaxBranchDepth = 3,
	MaxBranches = 2,

	MaxGrowthPercent = 0.2,
	StartingBranchWidth = 0.15,
	
	BranchDepthLengthDecayLinear = 0,
	BranchDepthBranchDecayLinear = 0,
	
	CottonBallMaxWidth = 0.25,
	CottonBallMinWidth = 0.15
}
module[2] = module.Defaultify{
	MaxBranchLength = 1.5,
	MinBranchLength = 0.5,

	MaxBranchDepth = 3,
	MaxBranches = 3,

	MaxGrowthPercent = 0.3,
	
	BranchDepthLengthDecayLinear = 0.2,
	BranchDepthBranchDecayLinear = 0,

	CottonBallMaxWidth = 0.4
}
module[3] = default
module[4] = module.Defaultify{
	MinBranchLength = 3,
	MaxBranchLength = 15,
	
	CottonBallMinWidth = 1.5,
	CottonBallMaxWidth = 2.5,
	
	StartingBranchWidth = 1,
	
	MinBranches = 2,
	MaxBranches = 3,
	MaxBranchDepth = 5,

	MaxGrowthPercent = 0.2,
	
	BranchDepthLengthDecayLinear = 4,
	BranchDepthSizeDecayLinear = 0.2,
	BranchDepthBranchDecayLinear = -1/3,
	
	BranchMaxTurnRadiusY = 360 * torad,
	BranchMaxTurnRadiusXZ = 90 * torad,

	--same but for starting branch only
	StartingBranchMaxTurnRadiusY = 360 * torad,
	StartingBranchMaxTurnRadiusXZ = 15 * torad,
}
module[5] = module.Defaultify{
	MaxBranchLength = 30,
	MinBranchLength = 17,
	
	MaxGrowthPercent = 1,
	MinGrowthPercent = 0,
	
	StartingBranchWidth = 5,
	BranchDepthSizeDecayLinear = 0.2,
	
	MaxBranches = 1,
	
	MaxBranchDepth = 18,
	MinBranchDepth = 15,
	
	BranchMaxTurnRadiusY = 360 * torad,
	BranchMaxTurnRadiusXZ = 40 * torad,

	--same but for starting branch only
	StartingBranchMaxTurnRadiusY = 360 * torad,
	StartingBranchMaxTurnRadiusXZ = 10 * torad,

	BranchDepthLengthDecayLinear = 0,
	BranchDepthBranchDecayLinear = -1/8.5,
	--range of size of cotton
	CottonBallMinWidth = 5,
	CottonBallMaxWidth = 15,
}
return module
