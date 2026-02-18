local module = {}
module.__index = module

local cottonsettings = require(script:WaitForChild("SettingsHelper"))
local cottonsettingsinfo = cottonsettings.LevelData
module.SettingsHelper = cottonsettings

local defaultify = cottonsettings.Defaultify
local blankColor = BrickColor.new("Medium stone grey")
local cotton = script:WaitForChild("Cotton")
local root = script:WaitForChild('Root') -- (only .Anchored, BrickColor/Color, and Material matters)
local maxsizeXZ = root.Size

local attachment = Instance.new("Attachment") --the base from where any plant could grow
attachment.Name = "Plant"

local random = math.random
local max, min = math.max, math.min
local insert = table.insert
local clear = table.clear

local function randDouble(rangemin, rangemax)	--duh
	return random() * (rangemax - rangemin) + rangemin
end
local function randRangeAroundZero(n)			--ex f(30) = [-15, 15] 30 degree cone
	n = n * 0.5
	return randDouble(-n, n)
end


--relative top/bottom of part
local function getTopCenter(part: BasePart, flip: number?): CFrame
	return part:IsA"Attachment" and part.WorldCFrame or part.CFrame * CFrame.new(0,part.Size.Y * 0.5 * (flip or 1), 0)
end
local vone = Vector3.one
function module:_forceSprout(node: Attachment | BasePart, ctr: number): { BasePart }?
	local settings = self.Settings
	local newBranches
	if ctr >= random(settings.MinBranchDepth, settings.MaxBranchDepth) then --branching/sprouting can stop at any time (base case)
		local newCotton = cotton:Clone()
		newCotton.Size = vone * randDouble(settings.CottonBallMinWidth, settings.CottonBallMaxWidth)
		newCotton.CFrame = node.CFrame *  CFrame.new(0,node.Size.Y/2,0)
		
		local mag = newCotton.Size.Magnitude
		newCotton.Light.Range = max(3, mag*2)
		
		local cottoninfo = self.Cotton
		cottoninfo.Amount += mag
		insert(cottoninfo, newCotton)
		
		newCotton.Parent = node
		return
	elseif ctr == 0 then --when ctr == 0, node is an Attachment; otherwise, its a Part
		local width, turnxz, turny = settings.StartingBranchWidth, settings.StartingBranchMaxTurnRadiusXZ, settings.StartingBranchMaxTurnRadiusY
		
		local new = root:Clone()
		new.Name = ctr
		new.Color = self.Attributes.Color
		new.Size = Vector3.new(width, 0, width)
		new.CFrame = node.WorldCFrame * CFrame.new(0,new.Size.Y/2, 0) * CFrame.Angles(																		--rotate it
			randRangeAroundZero(turnxz),
			randRangeAroundZero(turny),
			randRangeAroundZero(turnxz)
		)
		new.CFrame = new.CFrame + (node.WorldCFrame.Position - getTopCenter(new, -1).Position)	
		new.Parent = node

		newBranches = { new }
		self.GrowingBranches[new] = randDouble(settings.MinBranchLength, settings.MaxBranchLength)
		return node
	else
		--calculate decayed values
		local minlen = settings.MinBranchLength
		local minbranches = settings.MinBranches
		
		local turnxz, turny = settings.BranchMaxTurnRadiusXZ, settings.BranchMaxTurnRadiusY
		
		local decayedsize = settings.StartingBranchWidth - settings.BranchDepthSizeDecayLinear * ctr
		local decayedlength = max(minlen,	settings.MaxBranchLength - settings.BranchDepthLengthDecayLinear * ctr)
		local decayedbranches = max(minbranches, settings.MaxBranches - settings.BranchDepthBranchDecayLinear * ctr)

		--create new sprouts which get immediately used in the recursive part
		newBranches = {}

		local attributes = self.Attributes
		local myBranches = self.GrowingBranches
		for i = 1, random(minbranches, decayedbranches) do
			local new = root:Clone()
			new.Name = ctr
			new.Color = attributes.Color
			new.Size = Vector3.new(decayedsize,0,decayedsize)
			new.CFrame = node.CFrame * CFrame.new(0, 0.5 * (node.Size.Y + new.Size.Y), 0)				--adjust for vertical len of node and new
				* CFrame.Angles(																		--rotate it
					randRangeAroundZero(turnxz),
					randRangeAroundZero(turny),
					randRangeAroundZero(turnxz)
				)
			--newly rotated piece will no longer be directly connected on the bottom so move it back
			--finds displacement from bottom of 'new' to top of 'node' \/
			new.Parent = node

			insert(newBranches, new)
			myBranches[new] = randDouble(minlen, decayedlength)
		end
	end

	return newBranches
end

--grows each branch fully before sprouting
function module:_checkValidSprout(node: Attachment | BasePart): { BasePart }?
	local cottons = {}
	if self.GrowingBranches[node] then return { node } end --not done growing

	return self:_forceSprout(node, tonumber(tostring(node.Name))+1)
end

function module:grow(delta: number): nil
	local branches = self.GrowingBranches
	local settings = self.Settings
	local minGrow, maxGrow = settings.MinGrowthPercent, settings.MaxGrowthPercent
	
	for branch,height in next, branches do
		if not branch.Parent then rawset(branches, branch, nil) continue end
		local newgrowth = randDouble(minGrow, maxGrow) * delta

		local curSize = branch.Size
		local newHeight = min(height, curSize.Y + newgrowth*height)
		branch.Size = Vector3.new(curSize.X, newHeight, curSize.Z)
		branch.CFrame = branch.CFrame + (getTopCenter(branch.Parent).Position - getTopCenter(branch, -1).Position)	
		if newHeight == height then
			rawset(branches, branch, nil)
			self:_checkValidSprout(branch)
		end
	end
	return
end


function module:FullyGrown()
	return not next(self.GrowingBranches) --nil only when nothing is present in table
end
function module:Destroy(clearSettings)
	if clearSettings then clear(self.Settings) end
	self.Root:Destroy()
	clear(self)
	return
end

--nodefaultify when some func externally .Defaultify()s a settings table which will (purportedly) be used multiple times to save memory (r/t cloning the same table 20 times)
function module.new(base: BasePart, settings: (table | number)?, nodefaultify: boolean?): CottonPlant
	local size = base.Size - maxsizeXZ
	local plantRoot = attachment:Clone()

	--randomly picks a point on the part to grow from
	--since new is an Attachment the .CFrame is relative and will adjust itself for rotated pieces
	plantRoot.CFrame = CFrame.new(
		randRangeAroundZero(size.X), --offsets anywhere around the part's XZ face
		base.Size.Y/2,
		randRangeAroundZero(size.Z)
	)
	
	--
	local newPlantObject = setmetatable({
		GrowingBranches = {},
		Root = plantRoot,
		Cotton = {
			Amount = 0,
			Pieces = {}	
		}, -- "Mass" by summed size.Magnitude
	}, module)
	if type(settings) == 'number' then
		newPlantObject.Settings = cottonsettings[settings]
		newPlantObject.Attributes = cottonsettingsinfo[settings]
	else
		newPlantObject.Settings = nodefaultify and settings or cottonsettings.Defaultify(settings)
		newPlantObject.Attributes = newPlantObject.Settings
	end
	--
	
	newPlantObject:_forceSprout(plantRoot, 0)
	plantRoot.Parent = base
	
	return newPlantObject
end

return module
