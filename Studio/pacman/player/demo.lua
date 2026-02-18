--!strict
--[[




	honestly, just scroll to the bottom and read the intialize() function first. it will make sense quicker that way




]]


local tps: number = 8 --game updates(ticks) per sec
--so like you dont have to define type for EVERY var (none really) but
--i still did it for funcs/tables since theyre big and for vars I thought may be changed often (such as TPS)
local function settps(n: number): nil
	tps = n
	return
end
repeat task.wait() until game:IsLoaded() --idrk how to optimize client-server communication bc exploits are localscript-only😅😅

--references used
local uis: UserInputService = game:GetService("UserInputService")
local lp: Player = game:GetService("Players").LocalPlayer
local rs: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ts: TweenService = game:GetService("TweenService")
local startGame: RemoteEvent = rs:WaitForChild("StartGame") :: RemoteEvent
local changeTPS: BindableEvent = rs:WaitForChild("ChangeTPS") :: BindableEvent
local linearTween: Enum.EasingStyle = Enum.EasingStyle.Linear
local cc: Camera = workspace.CurrentCamera
--modules
local mapMaker = require(rs:WaitForChild("Modules"):WaitForChild("Map"))
local mapIds: {[string]: number} = mapMaker.mapIds
local entityMaker = require(rs:FindFirstChild("Modules"):WaitForChild("Entity"))
--
type Entity = entityMaker.Entity --⭐⭐⭐"export" keyword allows us to reference a module's types as a key-value
--more vars
local playerEntity: Entity = nil
local mazeLayout: {{number}} = nil
local maze: Model = nil
local playerId: number = nil

local score: number = 0
--tables
local directions = setmetatable({ --converts WASD into arrow keycodes
	W = "Up",
	S = "Down",
	A = "Left",
	D = "Right"
}, {__index = function(self, index) return index end}) --returns the original keycode if not in list (W = Up, Up = Up(__index))

local entities: {[Model]: Entity} = {} --idk good practice to hold onto active objects right...
local onMovementFuncs: {number: (Entity) -> boolean} = nil --defined after some functions



--BEGIN DEFINING FUNCTIONS



--duh
local function entityIsPlayer(entity: Entity): boolean
	return entity.Id == playerId
end



--moves entity
local function updateEntityPosition(entity: Entity): nil
	if not (entity.Model3D and entity.Model3D.PrimaryPart) then return end
	entity.Model3D.PrimaryPart.CFrame = CFrame.new(entity:Get3DWorldPosition())
	return
end



--tweens entity and returns it
local function tweenEntityPosition(entity: Entity): Tween?
	if not (entity.Model3D and entity.Model3D.PrimaryPart) then return end
	local tween = ts:Create(entity.Model3D.PrimaryPart, TweenInfo.new(1/tps, linearTween), {CFrame = CFrame.new(entity:Get3DWorldPosition())})
	tween:Play()
	return tween	
end



--turns a tile into air (yes, it edits the layout matrix) and deletes 3D component
--pcall(game.Destroy, object) in case the tile was already air (resulting in nil:Destroy() error)
local function clearTile(pos: Vector2): nil
	local oldId = mazeLayout[pos.X][pos.Y]
	mazeLayout[pos.X][pos.Y] = mapMaker.mapIds.Air --update layout
	pcall(game.Destroy, maze:FindFirstChild(mapMaker.mapParents[oldId]):FindFirstChild(tostring(pos))) 
	return
end



--these are the "eating" functions, some are directly tied to moving tiles while others are entity-entity interactions
--i didnt code entity-entity interactions lol
local function eatDot(entity: Entity): boolean
	score += 10
	clearTile(entity.Position)
	print("Score: " .. score)
	return true --still needs to tween
end
local function eatPowerPellet(entity: Entity): boolean
	score += 50
	clearTile(entity.Position)
	print("Score: " .. score)
	return true --still needs to tween
end



--not written yet but placeholders
local function eatGhost(): unknown
	return
end
local function eatFruit(): unknown
	return
end

		
		
--check if tile is either a vert/horiz portal (there are 2 types of portals bc its easier to code lol)
local function isPortalTile(id: number): boolean
	return id == mapMaker.mapIds.PortalHBiased or id == mapMaker.mapIds.PortalVBiased
end



--returns the portal along the same row or column (depending on portal bias)
local function findComplementaryPortal(entity: Entity): Vector2?
	local pos = entity.Position
	local portalExit
	
	if entity:GetTileId() == mapMaker.mapIds.PortalHBiased then
		--search horizontally
		for i,colId in next, entity.Layout[pos.X] do
			if i == pos.Y or not isPortalTile(colId) then continue end --if column=current or tile is not portal
			print("Found portal horizontally")
			return Vector2.new(pos.X, i)
		end
	else
		--search vertically
		for i,row in next, entity.Layout do
			if i == pos.X or not isPortalTile(row[pos.Y]) then continue end --if row=current or tile is not portal
			print("Found portal vertically")
			return Vector2.new(i, pos.Y)
		end
	end
	return nil
end



--[[
technically this is how the portal works
1. player input (moves into portal)
2. teleports to other portal
3. moves player in same direction (kicks out of portal)
4. tween animation
]]
local function usePortal(entity: Entity): boolean
	local portalPos = findComplementaryPortal(entity)
	assert(portalPos, "No matching portal found on either axis (dumbass)")
	--teleport woooo
	entity.Position = portalPos --tp to other portal
	updateEntityPosition(entity)
	entity:Move(entity.LastDirection) --"walk out" of it now
	tweenEntityPosition(entity)
	--
	return false
end



--this is the function for air😭
local function doNothing(): boolean return true end
--type check FORCES all new entries to be [number] = function
local onMovementFuncs: {[number]: (Entity) -> boolean} ={
	[mapIds.Dot] = eatDot,
	[mapIds.PowerPellet] = eatPowerPellet,
	[mapIds.PortalVBiased] = usePortal,
	[mapIds.PortalHBiased] = usePortal,
	[mapIds.Air] = doNothing
}
--try it: uncomment these lines
--onMovementFuncs.Hello = 5
--onMovementFuncs[999] = 5
--onMovementFuncs[999] = doNothing



--connects all the movement functions below
--onEntityMovement is our fake "event" that gets fired every time Entity:Move() is called
local function onEntityMovement(entity: Entity): nil
	local move = entity.LastDirection
	local moveFunc = onMovementFuncs[entity:GetTileId()]
	
	local doTween = false
	if moveFunc then
		doTween = moveFunc(entity) --some code (ex portal) will tween it themselves bc it does extra stuff
	end
	--if other entity-entity interaction then dieFunc()/eatFunc() end (didnt implement)
	
	if doTween then tweenEntityPosition(playerEntity) end
	return
end



--whenever the server spawns new entities this is the initial setup (positioning and registering as Entity type)
local function initEntity(entityModel: Instance): Entity?
	if not entityModel:IsA"Model" then return end
	if  entities[entityModel] then return entities[entityModel] end --if already initialized
	
	--Entity init
	local entityObj = entityMaker.new(mazeLayout, maze) 
	local spawnLoc = (entityModel:WaitForChild("SpawnLocation")::Vector3Value).Value
	--
	entityObj.Model3D = entityModel
	entityObj.Position = Vector2.new(spawnLoc.X, spawnLoc.Y)
	entityObj.Id = (entityModel:WaitForChild"Id"::IntValue).Value
	entityObj.OnMove = onEntityMovement 
	--end entity init
	
	--3D world updates
	updateEntityPosition(entityObj)
	entityModel:ScaleTo((maze:FindFirstChild("Scale")::NumberValue).Value)
	--end 3D world updates
	
	entities[entityModel] = entityObj
	return entityObj
end



--lol yea
local function destroyCharacter(): nil
	local char = lp.Character or lp.CharacterAdded:Wait()
	char:Destroy() --😛
	return
end



--moves camera to top of map
local function positionCamera(map: Model): nil
	cc.CameraType = Enum.CameraType.Scriptable

	local mapScale = (map:WaitForChild("Scale")::NumberValue).Value
	local mapRot, mapSize = map:GetBoundingBox() --returns CFrame.Rotation and Vector3 size. does NOT contain actual pos.
	--
	cc.CFrame = (map:WaitForChild"Origin"::BasePart).CFrame * CFrame.new(mapSize/2) --center camera on the map (midpoint)
	cc.CFrame = CFrame.lookAt(
		(cc.CFrame * CFrame.new(0,mapSize.Y * 10 * mapScale,0)).Position,--raise the camera and orient downwards
		cc.CFrame.Position
	) * CFrame.Angles(0,0,math.pi) --rotate 180* because the maps upside down :p
	return
end



--helps find the player MODEL. not really used for much else as of now.
local function getEntityFromId(map:Model, id:number): Model?
	for i,v in next, map:WaitForChild("Entities"):GetChildren() do
		initEntity(v)											--isnt necessarily needed but just in case
		if (v:WaitForChild("Id")::IntValue).Value == id then return v::Model end
	end
		-- maybe it hasnt loaded from server yet...
	repeat
		local entity: Model = map:FindFirstChild("Entities").ChildAdded:Wait() :: Model --sometimes extra type casting (:: Model) is needed
		initEntity(entity) 												--isnt necessarily needed but just in case
		if (entity:WaitForChild("Id")::IntValue).Value == id then return entity end
	until false
	return
end



--setup the player woohoo
local function initPlayer()
	local plrModel = getEntityFromId(maze, playerId)
	assert(plrModel, "Player not found (dumbass)")
	playerEntity = entities[plrModel]
	playerEntity.WalkOn[mapMaker.mapIds.GhostWall] = false --no walk into ghost walls
	
end



--the function that runs every frame (only activates x times per second tho)
local tick: number = 0
local function tickCheck(dt: number): nil
	tick += dt
	if tick < 1/tps then return end --waits for next tick
	tick = 0
	
	--vars
	local keysdown = uis:GetKeysPressed()
	local possible = playerEntity:GetPossibleMoves()
	local move = playerEntity.LastDirection
	--[[
		checks:
		1. is key down?
		2. is valid direction?
		3. is ABLE to move in direction?
		4. if so, update move dir
		   if not, maintain current dir (bc every entity always tries to move 'forward'...)
	]]
	for i, key in keysdown do
		if not possible[directions[key.KeyCode.Name]] then continue end
		move = directions[key.KeyCode.Name]
		break
	end

	playerEntity:Move(move) --OnMove (event) will fire OnEntityMovement (function)
	return
end



--easy peasy lemon squeezy
local function initPlayerMovement()
	game:GetService("RunService").Heartbeat:Connect(tickCheck)
end



--its good to use heavy functional programming because it makes the finished product easy to understand
local function initialize(l: {{number}}, m:Model, pid: number)
	--define global vars
	maze = m
	mazeLayout = l
	playerId = pid
	
	--look at these lovely functions, so easy to read and understand!
	destroyCharacter()
	positionCamera(maze)
	
	--
	for i,v in next, maze:WaitForChild("Entities"):GetChildren() do
		initEntity(v::Model) --u better hope v is a model!
	end
	maze:FindFirstChild("Entities").ChildAdded:Connect(initEntity)
	--
	initPlayer()
	initPlayerMovement()
	
end
--END DEFINING FUNCTIONS

--woah, 300 lines of code condensed into 1! so lovely
startGame.OnClientEvent:Connect(initialize)
changeTPS.Event:Connect(settps)