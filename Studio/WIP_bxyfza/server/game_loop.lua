--!strict
local serverTPS = 1/script:GetAttribute("TPS")

local dataCreator = require("./Modules/DataCreator")
local serverStartGame : BindableFunction = script:WaitForChild("Start")

local runs = game:GetService("RunService")
local ss = game:GetService("ServerStorage")
local rs = game:GetService("ReplicatedStorage")
local rsModules = rs:WaitForChild("Modules")
local SetScene = rs:WaitForChild("Events"):WaitForChild("SetScene")
local internalServerGet : BindableFunction = ss:WaitForChild("InternalServerGet")
local internalServerSet : BindableEvent = ss:WaitForChild("InternalServerSet")
local internalReplicateRequest : BindableEvent = ss:WaitForChild("ClientReplicate")


local addToDrink = rs.Events:WaitForChild("AddToDrink")
local clientEvalTopping = rs.Events:WaitForChild("EvalTopping")
local clientScoreTopping = rs.Events:WaitForChild("ScoreTopping")
local clientTrashDrink = rs.Events:WaitForChild("TrashDrink")

local customerModule = require(rsModules:WaitForChild("Game"):WaitForChild("Customers"))
local orderModule = require(rsModules.Game:WaitForChild("Order"))
local worldDrinkModule = require("./Modules/WorldDrinkEditor")

local readyEvent = rs.Events:WaitForChild("Ready")
local playerGetDrinkIdRequest = rs.Events:WaitForChild("GetCurrentDrinkId")

local playerData = dataCreator.Shared
local levelData = require("./Modules/Levels")

local queueModule = require("./Modules/Queue")
type Queue = queueModule.Queue
type Order = orderModule.Order


--
local delay = task.delay
local remove = table.remove

local dummyKey: never
type activeGameData = {
	Player: Player,
	Data: typeof(playerData[dummyKey]),
	LevelData: typeof(levelData.Levels[dummyKey]),
	TimeElapsed: number,
	Paused: boolean
}
local activeGames: {
	[Player]: activeGameData
} = {}

local insert = table.insert

local gameFunctions = {
	Heartbeat = function(dt: number, gameData: activeGameData)
		
	end,
}
local getCurrentOrder: (pData: typeof(dataCreator.Game), Station: string)-> Order?

--misc client eval requests/commands for most toppings
local clientEvalCommands: {
	[string]: (p: Player, ...any) -> ...any
} = {}
clientEvalTopping.OnServerInvoke = function(p: Player, command: string, ...:any): ...any
	local f = clientEvalCommands[command]
	if not f then return end
	return f(p, ...)
end

--some of the scores need the client to self-report them
local clientScoreCommands: {
	[string]: (p: Player, ...any) -> ...any
} = {}
clientScoreTopping.OnServerEvent:Connect(function(p: Player, command: string, ...:any): ...any
	local f = clientScoreCommands[command]
	if not f then return end
	return f(p, ...)
end)
--
clientScoreCommands.CupSize = function(p: Player, score: number): nil
	local pData = activeGames[p]
	assert(pData and pData.Data.Game, "No game data for "..p.Name)
	local currentOrder = getCurrentOrder(pData.Data.Game, "Build")
	if not currentOrder or currentOrder:GetIngredientScore("CupSize") ~= -1 then return end --already scored/DNE
	currentOrder:ScoreIngredient("CupSize", score, nil)
	worldDrinkModule.Funcs.FillCup(pData.Data.Game, currentOrder)
	return
end
clientScoreCommands.MixIn = function(p: Player, score: number): nil
	local pData = activeGames[p]
	assert(pData and pData.Data.Game, "No game data for "..p.Name)
	local currentOrder = getCurrentOrder(pData.Data.Game, "Build")
	if not currentOrder or currentOrder:GetIngredientScore("MixIn") ~= -1 then return end --already scored/DNE
	currentOrder:ScoreIngredient("MixIn", score, nil)
	return
end
clientScoreCommands.Syrup = function(p: Player, score: number): nil
	local pData = activeGames[p]
	assert(pData and pData.Data.Game, "No game data for "..p.Name)
	local currentOrder = getCurrentOrder(pData.Data.Game, "Build")
	if not currentOrder or currentOrder:GetIngredientScore("Syrup") ~= -1 then return end --already scored/DNE
	currentOrder:ScoreIngredient("Syrup", score, nil)
	return
end
--

--starting new games
local function initGame(plr: Player): (...any)
	local pData = playerData[plr]
	local lData = levelData.GetLevel(pData.Base.Day)
	activeGames[plr] = {
		Player = plr,
		Data = pData,
		LevelData = lData,
		TimeElapsed = 0,
		Paused = true
	}
	local newGame = internalServerGet:Invoke("NewMinigame", plr)
	SetScene:InvokeClient(plr, "Outside", "Level")
	return
end

--anything that may need live updates on the game
local t = 0
local function onServerHeartbeat(dt: number)
	t += dt
	if t < serverTPS then
		return
	end
	--
	for plr, game in activeGames do
		gameFunctions.Heartbeat(dt, game)
	end
	--
	t %= serverTPS
end

local queueTableSorter = {
	CupSize = "Build",
	MixIn = "Build",
	Syrup = "Build",
	BlendLevel = "Mix",
	WhippedCream = "Top",
	Sauce = "Top",
	Sprinkles = "Top",
	Placeables = "Top"
}
getCurrentOrder = function(pData: typeof(dataCreator.Game), Station: string): Order?
	local q = pData.Live.Queues[Station]
	return q:Peek()
end

local function onAddToDrink(p: Player, addType: string, addWhat: string, isNewOrder: boolean)
	local activeGame = activeGames[p]
	local gameData = activeGame and activeGame.Data.Game
	if not gameData then return end
	local liveCreations = gameData.Live.Creations
	local liveQueues = gameData.Live.Queues
	local unlocks = gameData.Unlocks
	
	--make new order
	if isNewOrder then
		if #liveQueues.Build > 0 then warn"Cannot start new order while another cup is in Build" return end 
		local newOrder = orderModule.new()
		insert(liveCreations, newOrder)
		gameData.NumCreations += 1
		--
		local id = gameData.NumCreations
		newOrder:SetId(id)
		liveQueues.Build:Add(newOrder) --newOrder needs a CupSize first so it starts in the Build queue
	end
	
	--get earliest order to add to, given the queue
	local currentOrder = getCurrentOrder(gameData, queueTableSorter[addType])
	if not currentOrder then warn("Could not find order to add to") return end
	

	
	--must be unlocked
	local nextIngUnlocks = unlocks[addType] 
	if not (nextIngUnlocks and nextIngUnlocks[addWhat]) then
		warn("Tried to add ingredient not unlocked yet")
		return
	end
	
	currentOrder:SetIngredient(addType, addWhat)
	worldDrinkModule.worldAddIngredient(gameData, currentOrder, addType, addWhat)
	
	--update the queues now
	do
		local nextIngred = currentOrder:GetIngredient(1) --get next ingredient
	--[[if nextIngredient == "None" then
		nothing :p
	else]]if typeof(nextIngred) == "table" then --only the top station has variant ingredients
			nextIngred = nextIngred[1]
		end
		--curIngredient : string
		if nextIngred ~= "None" and queueTableSorter[addType] ~= queueTableSorter[nextIngred] then
			local prevQ : Queue = liveQueues[queueTableSorter[addType]]
			local nextQ : Queue = liveQueues[queueTableSorter[nextIngred]]
			--
			prevQ:Remove()
			nextQ:Add(currentOrder)
			
			print("Shifted order " ..currentOrder.Id.." from "..queueTableSorter[addType].." to "..queueTableSorter[nextIngred])
		end
	end
	
	--the Build starting scene changes based on progression of drink
	return
end


local function getCurrentDrinkId(p: Player, station: string): number
	local activeGame = activeGames[p]
	local gameData = activeGame and activeGame.Data.Game
	if not gameData then return -1 end
	--
	local curOrder = getCurrentOrder(gameData, station)
	return curOrder and curOrder.Id or -1
end

local function trashWorldDrink(order: Order, designation: number)
	local worldDrink = worldDrinkModule.GetDrinkModel(order.Id)
	if not worldDrink then warn("no world model to trash...") return end
	--
	delay(designation, game.Destroy, worldDrink)
	return
end
local function onTrashDrink(p: Player, station: string, designation: number)
	local activeGame = activeGames[p]
	local gameData = activeGame and activeGame.Data.Game
	if not gameData then warn("no game active, cannot trash") return end
	local queues = gameData.Live.Queues
	--
	local curOrder: Order?
	if station == "Build" and #queues.Build == 0 then
		curOrder = queues.Mix[#queues.Mix] --the Syrup cancel happens after it moves into the Mix queue... so grab the last-added item
		station = "Mix"
		
		if curOrder then
			warn("crosstrashed order "..curOrder.Id.." from Mix on behalf of Build")
		end
	else
		curOrder = getCurrentOrder(gameData, station) --otherwise, grab the "oldest"/first item which
	end
	if not curOrder then return end
	
	--remove from queue +/ game internal data
	local q : Queue = queues[station]
	q:Remove()
	
	--try remove from world
	trashWorldDrink(curOrder, designation)
	
	
	return
end
--
clientTrashDrink.OnServerEvent:Connect(onTrashDrink)
playerGetDrinkIdRequest.OnServerInvoke = getCurrentDrinkId
addToDrink.OnServerInvoke = onAddToDrink
--
runs.Heartbeat:Connect(onServerHeartbeat)
serverStartGame.OnInvoke = initGame