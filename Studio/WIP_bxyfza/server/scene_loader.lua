--!strict
local demoSceneTest = false

local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local events = rs:WaitForChild("Events")
-- remote events
local GetScenes = events:WaitForChild("GetScenes")
local SetScene = events:WaitForChild("SetScene")
local Ready = events:WaitForChild("Ready")

local ServerStartGame = script.Parent:WaitForChild("ServerGameLoop"):WaitForChild("Start")
--data
local scenesToLoad : {string} = require("./Modules/ScenesToLoad")
--
local function commsPrint(who: Player, msg: string): nil
	--print("\t["..tostring(who).."]", msg)
	return
end
local function onPlayerAdded(plr: Player): nil
	commsPrint(plr, "Joined")
	plr:LoadCharacter()
	;(plr.Character::Model):ScaleTo(2)
	return
end
players.PlayerAdded:Connect(onPlayerAdded)
--
local function onReadyFired(plr: Player): nil
	commsPrint(plr, "Ready")
	
	ServerStartGame:Invoke(plr)
	--SetScene:InvokeClient(plr, "Order")
	return
end
Ready.OnServerEvent:Connect(onReadyFired)

local getRequests = {}
getRequests.FetchScenes = function(plr: Player)
	return scenesToLoad
end
local function onGetScenes(plr: Player, request: string, ...: any)
	commsPrint(plr, "Request " .. request)
	return getRequests[request] and getRequests[request](plr, ...)
end
GetScenes.OnServerInvoke = onGetScenes