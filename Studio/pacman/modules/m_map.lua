--!strict
local module = {}

local scale: number = 3

local maze = script:WaitForChild("Maze")
local wall = script:WaitForChild("Wall")
local ghostWall = script:WaitForChild("GhostWall")
local dot = script:WaitForChild("Dot")
local powerPellet = script:WaitForChild("PowerPellet")
local portal = script:WaitForChild("Portal")


--now if we change ids it updates every other table using the ids too
module.mapIds = {
	Unknown = -2,
	Wall = -1,
	Dot = 0,
	PowerPellet = 1,
	PortalHBiased = 2,
	PortalVBiased = 3,
	GhostWall = 4,
	Air = 5
}

module.mapParts = {
	[module.mapIds.Wall] = wall,
	[module.mapIds.Dot] = dot,
	[module.mapIds.PowerPellet] = powerPellet,
	[module.mapIds.PortalHBiased] = portal, --for side portals
	[module.mapIds.PortalVBiased] = portal, --for side portals
	[module.mapIds.GhostWall] = ghostWall,
}
module.mapParents = {
	[module.mapIds.Wall] = "Walls",
	[module.mapIds.Dot] = "Dots",
	[module.mapIds.PowerPellet] = "Dots",
	[module.mapIds.PortalHBiased] = "Portals",
	[module.mapIds.PortalVBiased] = "Portals",
	[module.mapIds.GhostWall] = "Walls", --for ghost wall
}

local x = module.mapIds.Wall
local o = module.mapIds.Air
module.Layout = {
	{o, o, o, x, x, x, x, x, x, x, x, x, x, x, x, 3, x, x, 3, x, x, x, x, x, x, x, x, x, x, x, x, o, o, o};
	{o, o, o, x, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, x, x, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, x, o, o, o};
	{o, o, o, x, 0, x, x, x, x, 0, x, x, x, x, x, 0, x, x, 0, x, x, x, x, x, 0, x, x, x, x, 0, x, o, o, o};
	{o, o, o, x, 0, x, x, x, x, 0, x, x, x, x, x, 0, x, x, 0, x, x, x, x, x, 0, x, x, x, x, 0, x, o, o, o};
	{o, o, o, x, 0, x, x, x, x, 0, x, x, x, x, x, 0, x, x, 0, x, x, x, x, x, 0, x, x, x, x, 0, x, o, o, o};
	{o, o, o, x, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, x, o, o, o};
	{o, o, o, x, 0, x, x, x, x, 0, x, x, 0, x, x, x, x, x, x, x, x, 0, x, x, 0, x, x, x, x, 0, x, o, o, o};
	{o, o, o, x, 0, x, x, x, x, 0, x, x, 0, x, x, x, x, x, x, x, x, 0, x, x, 0, x, x, x, x, 0, x, o, o, o};
	{o, o, o, x, 0, 0, 0, 0, 0, 0, x, x, 0, 0, 0, 0, x, x, 0, 0, 0, 0, x, x, 0, 0, 0, 0, 0, 0, x, o, o, o};
	{o, o, o, x, x, x, x, x, x, 0, x, x, x, x, x, 0, x, x, 0, x, x, x, x, x, 0, x, x, x, x, x, x, o, o, o};
	{o, o, o, o, o, o, o, o, x, 0, x, x, x, x, x, 0, x, x, 0, x, x, x, x, x, 0, x, o, o, o, o, o, o, o, o};
	{o, o, o, o, o, o, o, o, x, 0, x, x, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, x, x, 0, x, o, o, o, o, o, o, o, o};
	{o, o, o, o, o, o, o, o, x, 0, x, x, 0, x, x, x, 4, 4, x, x, x, 0, x, x, 0, x, o, o, o, o, o, o, o, o};
	{x, x, x, x, x, x, x, x, x, 0, x, x, 0, x, o, o, o, o, o, o, x, 0, x, x, 0, x, x, x, x, x, x, x, x, x};
	{2, o, o, o, o, o, o, o, o, 0, 0, 0, 0, x, o, o, o, o, o, o, x, 0, 0, 0, 0, o, o, o, o, o, o, o, o, 2};
	{x, x, x, x, x, x, x, x, x, 0, x, x, 0, x, o, o, o, o, o, o, x, 0, x, x, 0, x, x, x, x, x, x, x, x, x};
	{o, o, o, o, o, o, o, o, x, 0, x, x, 0, x, x, x, x, x, x, x, x, 0, x, x, 0, x, o, o, o, o, o, o, o, o};
	{o, o, o, o, o, o, o, o, x, 0, x, x, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, x, x, 0, x, o, o, o, o, o, o, o, o};
	{o, o, o, o, o, o, o, o, x, 0, x, x, 0, x, x, x, x, x, x, x, x, 0, x, x, 0, x, o, o, o, o, o, o, o, o};
	{o, o, o, x, x, x, x, x, x, 0, x, x, 0, x, x, x, x, x, x, x, x, 0, x, x, 0, x, x, x, x, x, x, o, o, o};
	{o, o, o, x, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, x, x, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, x, o, o, o};
	{o, o, o, x, 0, x, x, x, x, 0, x, x, x, x, x, 0, x, x, 0, x, x, x, x, x, 0, x, x, x, x, 0, x, o, o, o};
	{o, o, o, x, 0, x, x, x, x, 0, x, x, x, x, x, 0, x, x, 0, x, x, x, x, x, 0, x, x, x, x, 0, x, o, o, o};
	{o, o, o, x, 0, 0, 0, x, x, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, x, x, 0, 0, 0, x, o, o, o};
	{o, o, o, x, x, x, 0, x, x, 0, x, x, 0, x, x, x, x, x, x, x, x, 0, x, x, 0, x, x, 0, x, x, x, o, o, o};
	{o, o, o, x, x, x, 0, x, x, 0, x, x, 0, x, x, x, x, x, x, x, x, 0, x, x, 0, x, x, 0, x, x, x, o, o, o};
	{o, o, o, x, 0, 0, 0, 0, 0, 0, x, x, 0, 0, 0, 0, x, x, 0, 0, 0, 0, x, x, 0, 0, 0, 0, 0, 0, x, o, o, o};
	{o, o, o, x, 0, x, x, x, x, x, x, x, x, x, x, 0, x, x, 0, x, x, x, x, x, x, x, x, x, x, 0, x, o, o, o};
	{o, o, o, x, 0, x, x, x, x, x, x, x, x, x, x, 0, x, x, 0, x, x, x, x, x, x, x, x, x, x, 0, x, o, o, o};
	{o, o, o, x, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, x, o, o, o};
	{o, o, o, x, x, x, x, x, x, x, x, x, x, x, x, 3, x, x, 3, x, x, x, x, x, x, x, x, x, x, x, x, o, o, o};
}

--builds the maze from layout
function module.ConstructMaze(layout: {{number}}): Model?
	if type(layout) ~= "table" then return nil end
	--
	local maze = maze:Clone() --copy empty template
	local origin = maze.PrimaryPart.Position
	--
	maze:FindFirstChild("Scale").Value = scale
	for rNum,row in ipairs(layout) do --ipairs because it always counts numerically
		for cNum, colID in ipairs(row) do
			local mapPart = module.mapParts[colID]
			if not mapPart then continue end --represents air, nothing to place
			--
			mapPart = mapPart:Clone()
			mapPart.Name = ("%d, %d"):format(rNum, cNum) --so you can look it up via Vector2 position
			mapPart.Size *= scale
			
			--was gonna make it build AROUND the origin but Entity is easier to work with when not...
			mapPart.Position = origin + scale * Vector3.new( 
				rNum,
				0,
				cNum
			)
			mapPart.Parent = maze[module.mapParents[colID]] --find the correct subchild in maze
		end  
	end
	return maze
end

return module
