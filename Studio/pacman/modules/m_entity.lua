--!strict
--[[

README

it looks like some alien bs im ngl but uhh we can walk thru it real quick

]]
--since were using id system for game tiles, i only defined the IDs in Map module so mass-changing IDs is quick
local mapIds = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Map")).mapIds
--
--defining the type
local Entity = {}
Entity.__index = Entity --we want every Entity to have the same functions but dont want to have to redefine EVERYTHING
--						--using __index helps us reuse unchanging values (ex functions and the Directions table)
--
--					--\/ this line allows the type to use metatables, the '&' joins the "table" type with our "Entity" type
--					--no, theres not a better way to get table type 😭
--					--were just predefining all the name references & their types (ex an abstract class in Java)
export type Entity = typeof({}) & { 
	Id: number,
	WalkOn: {any},
	Map: Model,
	Layout: {{number}},
	Position: Vector2,
	LastDirection: string,
	Model3D: Model?,
	-- for metatable \/								-- the "(params) -> output" is the type checker for functions
	--these functions are referenced but not edited😀 so no need to redefine them in Entity.new
	Directions: {[string]: Vector2},
	OnMove: (Entity) -> nil, --this is gonna be treated like an event/connection
	GetTileId: (Entity, number?, number?) -> number,
	Get3DWorldPosition: (Entity) -> Vector3,
	CanMove: (Entity, string) -> Vector2?,
	GetPossibleMoves: (Entity) -> {[string]: Vector2?},
	Move: (Entity, string) -> {[string]: Vector2?}?
}
--
-- START DEFINING FUNCTIONS/VALUES
-- all these are gonna be used in the metatable of Entity's
Entity.Directions = setmetatable({
	Left = Vector2.new(0,1),
	Right = Vector2.new(0,-1),
	Up = Vector2.new(-1,0),
	Down = Vector2.new(1,0)
}, {__index = function() return Vector2.zero end}) --always returns a Vector2, if invalid key then returns 0,0



--pretty simple just looks up a 2d matrix value
function Entity:GetTileId(r: number?, c: number?): number
	self = self :: Entity --so the type checker knows self is an Entity
	
	if not r then 
		r,c  = self.Position.X, self.Position.Y --in case it was called to lookup CURRENT tile, no params needed!
	end
	return (self.Layout[r::number] and self.Layout[r::number][c::number]) or mapIds.Unknown
end



--also pretty simple it just finds the 3D position of Entity since we edit Entity thru tables and not the 3D world.
function Entity:Get3DWorldPosition(): Vector3
	-- \/have to use type casting here becauseFindFirstChild returns Instance not specific types
	local pos = (self.Map:FindFirstChild("Origin")::BasePart).Position
		+ (self.Map:FindFirstChild("Scale")::NumberValue).Value
		* Vector3.new(
			self.Position.X,
			0,
			self.Position.Y
		)
	
	return pos --basically, pos = 2D position * 3D map scale
end



--Check if the current pos + direction in the 2D map can be walked on, returns the new position if so
function Entity:CanMove(dir: string): Vector2?
	self = self :: Entity
	local newPos = self.Position + self.Directions[dir]
	local tileId = self:GetTileId(newPos.X, newPos.Y)
	
	return self.WalkOn[tileId] and newPos
end



--returns CanMove() for all directions
--will likely be useful when doing ghost movements
function Entity:GetPossibleMoves(): {[string]: Vector3}
	local possibleMoves = {}
	for dir, offset in pairs(self.Directions) do
		local checkMove = self:CanMove(dir)
		if not checkMove then continue end
		possibleMoves[dir] = checkMove --add to possibilities list
	end
	return possibleMoves
end



--updates the Entity values, you still need to update in 3D world yourself (dw its easy)
function Entity:Move(dir: string): {[string]: Vector2?}?
	self = self :: Entity
	local moves = self:GetPossibleMoves()
	if not moves[dir] then return moves end --return possible moves for ghost to use to change direction
	
	self.LastDirection = dir
	self.Position += self.Directions[dir]
	if self.OnMove then self.OnMove(self) end
	return nil
end
--END DEFINING FUNCTIONS/VALUES

--woohoo we made it
--takes the map's layout (Move()) as a parameter as well as the 3D model (Get3DWorldPosition())
function Entity.new(mapLayout: {{number}}, map: Model) : Entity
	local newEntity = {
		Id = 0,
		WalkOn = {
			[mapIds.Wall] = false,				--wall
			[mapIds.Dot] = true,				--dot
			[mapIds.PowerPellet] = true,		--power pellet
			[mapIds.PortalHBiased] = true, 		--portal
			[mapIds.PortalVBiased] = true, 		--portal
			[mapIds.GhostWall] = true,			--ghost wall
			[mapIds.Air] = true,				--air
		},
		Map = map,
		Layout = mapLayout,
		Position = Vector2.zero,
		LastDirection = "None",
		Model3D = nil, --make sure to add a model...
		OnMove = nil --optional function after moving
	}
	return setmetatable(newEntity :: any, Entity) --for some reason its gotta be 'any' type here
end

--using the types isnt necessary obviously, but it can help with debugging by preventing type errors before they can compile
--make sure to use --!strict at Line1 to activate checking tho...
return Entity
