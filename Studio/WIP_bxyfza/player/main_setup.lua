--!strict
--waits for Init in ReplicatedFirst
local fadeGui = script.Init.Event:Wait()
 game:GetService("ReplicatedFirst").Init.Enabled = false
--disables it to stop the Fire() loop
--
local loadStatus : (msg: string?) -> nil = nil
do
	local s = fadeGui.Frame.Status
	loadStatus = function(msg: string?): nil
		if not msg then
			s.Visible = false
			return
		end
		s.Visible = true
		s.Text = msg
		return
	end
end

local lp = game:GetService("Players").LocalPlayer

local rs = game:GetService("ReplicatedStorage")
local ts = game:GetService("TweenService")
local modules = rs:WaitForChild("Modules")
local events = rs:WaitForChild("Events")
loadStatus"Waiting for World Scenes..."
local worldScenes = workspace:WaitForChild("Scenes")
-- refs
-- modules
local ClientData = require(modules:WaitForChild("ClientData"))
local SceneLoader = require(modules:WaitForChild("Scene"))
type Scene = SceneLoader.Scene

SceneLoader.SetFadeFrame(fadeGui.Frame)
-- remote events
loadStatus"Waiting for Remotes..."
local ready: RemoteEvent = events:WaitForChild("Ready")
local isServerDataLoaded: RemoteFunction = events:WaitForChild("IsDataLoaded")
local GetScenes: RemoteFunction = events:WaitForChild("GetScenes")
local SetScene: RemoteFunction = events:WaitForChild("SetScene")


local startScreen = fadeGui.Parent:WaitForChild("HomeScreen")

local dayCutscene = startScreen:WaitForChild"DayCutscene" :: Frame
local dayText1 = dayCutscene:WaitForChild("Inner"):WaitForChild("Shadow")::TextLabel
local dayText2 = dayText1:WaitForChild("Main") :: TextLabel

local playButtonScreen = startScreen:WaitForChild"Play" :: Frame

-- setup scenes (shared table)
local Scenes : { [string]: Scene } = require(modules.Scene:WaitForChild("Loaded"))

local function commsPrint(msg: string): nil
	print("[Server]", msg)
	return
end

local onServerSceneSetCallbacks = {}
--scene setup
do
	local function serverSetScene(name: string, subscene: string): any
		local scene = Scenes[name]
		commsPrint(("Set Scene to %s%s"):format(name, subscene and ", "..subscene or ""))
		assert(scene, "Server attempts to set missing scene "..name)
		--
		if onServerSceneSetCallbacks[name] then
			onServerSceneSetCallbacks[name](subscene) --use this to trigger playscreen guis and such
		end
		--
		if not subscene then
			scene:Init({
				PlayStart = true
			})
		else
			scene:Init()
			scene:Set({
				Subscene = subscene
			})--this is a yielding function
		end
		return
	end
	SetScene.OnClientInvoke = serverSetScene
	
	loadStatus"Fetching Scenes..."
	local scenesToLoad = GetScenes:InvokeServer("FetchScenes")
	for _, name in next, scenesToLoad do
		loadStatus("Waiting for '"..name.."'")
		Scenes[name] = SceneLoader.new(worldScenes:WaitForChild(name, 5)) or error("Server asks for nonexistent scene: " .. name)
	end
end

--gameplay
local gameDataLoaded = false
--
local function syncNextGameData()
	return ClientData:ServerFetch("Game")
end
local function animateUI(animTime: number, data) --no yield
	dayText1.Text = data.Day
	dayText2.Text = data.Day
	
	dayCutscene.Position = UDim2.fromScale(0.5, 1.5)
	ts:Create(
		dayCutscene,
		TweenInfo.new(animTime, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.5,1) }
	):Play()
	
	dayCutscene.Visible = true
	playButtonScreen.Visible = false
end
local function animateUIOut(animTime: number)
	ts:Create(
		dayCutscene,
		TweenInfo.new(animTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
		{ Position = UDim2.fromScale(0.5,1.5) }
	):Play()
end
local function animateCharacters(animTime: number, data) --yields
	--pick 3 random characters 1. walks up & cheers, 2. peeks around surf shop, 3. walking down the boardwalk
	task.wait(animTime)
end
local function prepNextLevel()
	local gameData
	local fadeInTime = Scenes.Outside.Origin:FindFirstChild("Level"):GetAttribute("Time")
	do
		local t = tick()
		gameData = syncNextGameData()
		task.wait(fadeInTime - (tick()-t)) --the first half (scene is fading out) + account for gamesync time
	end

	
	local levelScene = Scenes.Order
	--day cutscene
	do
		animateUI(fadeInTime, gameData)--doesnt yield
		--
		animateCharacters(fadeInTime*3, gameData)--yields
		animateUIOut(levelScene.Origin:FindFirstChild(levelScene.Start):GetAttribute("Time"))--no yield
	end
	
	--begin playscreen
	do
		levelScene:Set({
			Subscene = levelScene.Start,
			MidpointCallback = function()
				startScreen.Enabled = false
				script:FindFirstChild("GameController").Enabled = true --start game
				print"Game time"
			end
		})
		
	end

end
onServerSceneSetCallbacks["Outside"] = function(subscene: string): nil
	if subscene == "HomeScreen" then
		gameDataLoaded = false
	elseif subscene == "Level" then --load game data
		spawn(prepNextLevel)
		--
		gameDataLoaded = true
	end
	return
end
--end setup----------------------------------------------------------------------------

--start Starting screen----------------------------------------------------------------
local i = 1
repeat
	loadStatus(("Waiting for DataStore... (%d)"):format(i))
	i+=1
	if isServerDataLoaded:InvokeServer() then
		break
	end
	task.wait(3)
until i > 10
if i > 10 then
	warn("Datastore failed to load")
	loadStatus("Could not fetch player data... try rejoining?")
	return
end
--
local function doHomescreen()

	startScreen.Enabled = true
	dayCutscene.Visible = false
	playButtonScreen.Visible = true
	lp.Character:FindFirstChild("HumanoidRootPart").CFrame = (Scenes.Outside.Origin:FindFirstChild("Level"):FindFirstChild("CharEnd")::Attachment).WorldCFrame
	loadStatus()


	--goes to homescreen \/
	Scenes.Outside:Init({
		OnlyPlayLatter = true,
		PlayStart = true
	})
	startScreen.LocalScript.Ready.Event:Wait() --wait for user to press play

	--end Starting screen------------------------------------------------------------------


	--Start game
	--Scenes.Order:Init(true, true)


	ready:FireServer() --the server fires a setscene to begin the level
	--this lets us animate the day cutscene thing in a new thread
	
end
--
doHomescreen()