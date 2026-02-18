--!strict

--gamecontroller is used mostly to setup the proper interactions based on unlocks/natural playthru of game
--helper_interaction handles the actual player interactions and reports back to gamecontroller
local sceneSetParams: {
	Subscene: string,
	Mode: ("Fade" | "Move") | string?,
	SetTime: number?,
	OnlyPlayLatter: boolean?,
	MidpointCallback: (scene: Scene)->(...any)?,
	TweenInfo : {
		EasingStyle: Enum.EasingStyle?,
		EasingDirection: Enum.EasingDirection?
	}?
}

local rs = game:GetService("ReplicatedStorage")
local modules = rs:WaitForChild("Modules")

local runs = game:GetService("RunService")

local lpModule = require(modules:WaitForChild("Player"))
lpModule:SurrenderMovement()
local clientData = require(modules:WaitForChild("ClientData"))

local random = math.random

local s = require(modules:WaitForChild("Scene"))
type Scene = s.Scene
local Scenes = require( modules.Scene:WaitForChild("Loaded") )

local ts = game:GetService("TweenService")
local debris = game:GetService("Debris")

local lp : Player = game:GetService("Players").LocalPlayer
local levelGui = lp:FindFirstChild("PlayerGui"):FindFirstChild("LevelScreen") :: ScreenGui
local PlayScreen = levelGui:FindFirstChild("Play") :: Frame
local PauseScreen  = levelGui:FindFirstChild("Pause") :: Frame
local worldGuis = lp.PlayerGui:WaitForChild("WorldGuis")

local spawn = task.spawn
local delay = task.delay
local insert = table.insert
local abs = math.abs
local sign = math.sign
local clone = table.clone

local rs = game:GetService("ReplicatedStorage")
local rsEvents = rs:WaitForChild("Events")
local evalToppingRequest = rsEvents:WaitForChild("EvalTopping")
local scoreToppingRequest = rsEvents:WaitForChild("ScoreTopping")
local addToDrinkRequest = rsEvents:WaitForChild("AddToDrink")
local getCurrentDrinkId = rsEvents:WaitForChild("GetCurrentDrinkId")
local trashCurrentDrink = rsEvents:WaitForChild("TrashDrink")

local audioHelper = require(script:WaitForChild("Helper_Audios"))

local interactionHelper = require(script:WaitForChild("Helper_Interaction"))
local PlayscreenForeground = PlayScreen:FindFirstChild"Foreground" :: Frame
local GameClockFiller = PlayscreenForeground:FindFirstChild"ClockSigns":FindFirstChild"Fill" :: NumberValue
local CancelButtons = PlayscreenForeground:FindFirstChild("CancelButtons") :: Frame
--
local levelScript = levelGui:FindFirstChildOfClass("LocalScript") :: LocalScript
local levelConfig = levelScript:WaitForChild("Config") :: Configuration

local gameAction : BindableEvent = levelScript:FindFirstChild"Action" :: BindableEvent --sends to game contoller
local setData : BindableEvent = levelScript:FindFirstChild"SetData" :: BindableEvent   --sends to

local worldDrinkModels = workspace:WaitForChild("DrinkModels")
--server data
local gameData = clientData:Fetch("Game")
local unlockedTools = gameData.Unlocks--:ServerFetch("Unlocks")

--random functions
--combine tables
local function addToTable(t: {}, toAdd: {}, override: boolean)
	local new = clone(t)
	for i,v in next, toAdd do
		insert(new, v)
	end
	return new
end
--toggle spinner indicating 'waiting for server...'
local serverSpinnerEnabler = PlayScreen:WaitForChild("Foreground"):WaitForChild("ServerSpinner"):WaitForChild("Enabled") :: BoolValue
local function toggleServerWaitSpinner(enabled: boolean)
	serverSpinnerEnabler.Value = enabled
end

--some of the scenes have designated cancel buttons
local onCancelButtonVisibilityFuncs: {[string]: (enabled: boolean, designation: number)->(...any)} = {}
local function onCancelButtonVisibility(station: string, enabled: boolean, designation: number)
	local f = onCancelButtonVisibilityFuncs[station]
	if f then
		f(enabled, designation)
	end
	return
end
do
	local buildCanceler = CancelButtons:FindFirstChild("Build") :: Frame
	onCancelButtonVisibilityFuncs.Build = function(isEnabled: boolean, designation: number)
		if not isEnabled then task.wait(designation) end --f is already delayed. may be extra but its for continuity
		buildCanceler.Visible = isEnabled
	end
end
--for interactable surface guis, have the ability to re/deparent them to/from playergui
local function defocusWorldGuis(): nil
	for i,v : ObjectValue in next, worldGuis:GetChildren() do
		v.Parent = v.Value
	end
	return
end
local function avgPos(t: { Vector3 })
	local sum = Vector3.zero
	for i,v in next, t do sum += v end
	return sum/#t
end
local function getSubsceneChangeTime(s: Scene, subName: string?)
	local subscene = s.Origin:FindFirstChild(subName or s.Start)
	return subscene and subscene:GetAttribute("Time") or -1
end
--connections
local onGameActionCallbacks--[[: {[string]: (...any)->(...any)}]] = {}
local onSubsceneCallbacks: {
	[string]: {
		[string]: {
			Enter: (scene: Scene, subscene: string, designation: number)->(...any),
			Exit: (scene: Scene, subscene: string, designation: number)->(...any),
			OnCanceled: (scene: Scene, subscene: string, designation: number)->(...any)?
		}
	}
} = {}
local enterExitCoroutines: {[(...any)->(...any)]: thread} = {}
local function tryCoClose(f: (...any)->(...any)): nil
	if enterExitCoroutines[f] then
		coroutine.close(enterExitCoroutines[f])
		enterExitCoroutines[f] = nil
	end
	return
end
local function coroutinize(f: (...any)->(...any), ...: any): nil
	tryCoClose(f)
	--
	local co = coroutine.create(f)
	enterExitCoroutines[f] = co
	coroutine.resume(co, ...)
	--
	return
end

local function allowPlayerSceneInput(toggle: boolean)
	levelConfig:SetAttribute("ScenesLocked", not toggle)
	return
end

local function trySceneEnter(scene: Scene, subscene: string, designatedTime: number, wait: number?): boolean
	local f = onSubsceneCallbacks[scene.Name] and onSubsceneCallbacks[scene.Name][subscene]
	if f and f.Enter then
		if wait then
			delay(wait, coroutinize, onCancelButtonVisibility, scene.Name, true, designatedTime)
			delay(wait, coroutinize, f.Enter :: any, scene, subscene, designatedTime)
		else
			coroutinize(f.Enter :: any, scene, subscene, designatedTime)
		end
	end

	return f and true
end

local function trySceneExit(scene: Scene, subscene: string, designatedTime: number, wait: number?): boolean
	local f = onSubsceneCallbacks[scene.Name] and onSubsceneCallbacks[scene.Name][subscene]
	if f and f.Exit then
		if wait then
			delay(wait, coroutinize, onCancelButtonVisibility, scene.Name, false, designatedTime)
			delay(wait, coroutinize, f.Exit :: any, scene, subscene, designatedTime)
		else
			coroutinize(onCancelButtonVisibility, scene.Name, false, designatedTime)
			coroutinize(f.Exit :: any, scene, subscene, designatedTime)
		end
	end

	return f and true
end
--
local function onGameActionFired(action: string, ...: any): nil
	local cb = onGameActionCallbacks[action]
	if cb then
		cb(...)
	end
	return
end
gameAction.Event:Connect(onGameActionFired)

local currentScene = Scenes.Order
local function nothing():() return end
--demo
Scenes.Top = Scenes.test
--game setup
onGameActionCallbacks.PlayAudio = function(name: string, dat: audioHelper.__playAudioData?)
	audioHelper.PlayAudio(name, dat)
	return
end
onGameActionCallbacks.SetScene = function(scene: string, data: typeof(sceneSetParams)?): nil
	--
	local nextScene = Scenes[scene] or error("Invalid scene given: "..tostring(scene))
	local subscene : string = data and data.Subscene or nextScene.Start

	local sameScene = currentScene == nextScene

	if sameScene then
		--same subscene
		if subscene == nextScene.Subscene then
			return
		end

	end
	--scene exit anims
	local waitTime: number = getSubsceneChangeTime(nextScene, subscene)
	if currentScene then
		local curSubscene = currentScene.Subscene
		trySceneExit(currentScene, curSubscene, waitTime, nil) -- 'waitTime' is the time it takes for the current scene to finish
	end
	--
	currentScene = nextScene
	--scene enter anims
	do
		trySceneEnter(currentScene, subscene, waitTime, waitTime) --waitTime used here to let exit anim finish
	end

	nextScene:Set({
		Subscene = subscene,
		Mode = not sameScene and "Fade" or nil
	})

	--
	return
end
onGameActionCallbacks.Cancel = function(station: string)
	local scene = Scenes[station]
	local subscene = scene.Subscene
	--
	local sceneFuncs = onSubsceneCallbacks[station][subscene]
	--
	tryCoClose(sceneFuncs.Enter)
	tryCoClose(sceneFuncs.Exit)
	if sceneFuncs.OnCanceled then
		sceneFuncs.OnCanceled(scene, subscene, scene.Origin:FindFirstChild(subscene):GetAttribute("Time"))
	else
		warn("Canceled "..station..", "..subscene..", but it has no OnCanceled() callback")
	end
	return
end
--Order Scene setup
do
	onSubsceneCallbacks.Order = {}

	local lastTry: RBXScriptConnection? = nil
	local openSign = GameClockFiller.Parent :: Frame
	local counterEmotes = {
		"Wave",
		"Point",
		"Dance"
	}
	local function atCounterEmote()
		local emote = counterEmotes[random(1, #counterEmotes)]
		return lpModule:Emote(emote)
	end
	local function toggleOpenSign()
		openSign.Visible = not openSign.Visible
		return
	end
	onSubsceneCallbacks.Order.Station = {
		Enter = function(scene: Scene, subscene: string, designation: number)
			local ssAttach = scene.Origin:FindFirstChild(subscene)
			local charStart : CFrame, charEnd:CFrame = (ssAttach:FindFirstChild"CharStart" :: Attachment).WorldCFrame, (ssAttach:FindFirstChild("CharEnd") :: Attachment).WorldCFrame
			local humanoid = lpModule:Teleport(charStart)
			if not humanoid then return end
			--
			local walkTime = (charStart.Position-charEnd.Position).Magnitude / designation
			lpModule:WalkTo(charEnd, nil, walkTime)
			--cleanup and re-try wave @ end of walk
			if lastTry then lastTry:Disconnect() end
			lastTry = humanoid.MoveToFinished:Once(atCounterEmote)
			--clock ui
			toggleOpenSign()
		end,
		Exit = function(scene: Scene, subscene: string, designation: number)
			local ssAttach = scene.Origin:FindFirstChild(subscene)
			local charStart : CFrame, charEnd:CFrame = (ssAttach:FindFirstChild"CharStart" :: Attachment).WorldCFrame, (ssAttach:FindFirstChild("CharEnd") :: Attachment).WorldCFrame
			--lpModule:Teleport(charEnd)
			--
			lpModule:CancelEmotes()
			--
			local walkTime = (charStart.Position-charEnd.Position).Magnitude / designation
			lpModule:WalkTo(charStart, nil, walkTime)
			--clock ui
			delay(designation, toggleOpenSign)
		end
	}


end

--Build scene setup
do
	onSubsceneCallbacks.Build = {}

	local function getUnlockedCups(): { [string]: boolean }
		return unlockedTools.CupSize
	end

	local dispActiveAttach: Attachment
	local dispActiveOriginCFrame: CFrame
	local buildScene = (Scenes.Build.Origin.Parent :: Instance)
	local dispCenter = buildScene:WaitForChild("Stuff"):WaitForChild("Center") :: Attachment

	local buildCancelButton = CancelButtons:FindFirstChild("Build") :: Frame
	local bcbEnabled = buildCancelButton:FindFirstChildWhichIsA("BoolValue") :: BoolValue

	local function allowBuildCancels(b: boolean)
		bcbEnabled.Value = b
		return
	end

	local cupsFolder = buildScene:WaitForChild("Stuff"):WaitForChild("Cups")
	local cupsAttach = cupsFolder:WaitForChild("Attachments")
	local cupsCenter : Attachment = cupsAttach:WaitForChild("Center") :: Attachment
	--
	local travelDistance = Vector3.new(0,0,15)
	local endingTransparency = 0.65
	--
	local function assignBuildStartScreen(scene: string)
		if not scene then --reset to true default value
			Scenes.Build.Start = ((Scenes.Build.Origin.Parent :: Model):WaitForChild("Start") :: StringValue).Value
		end
		Scenes.Build.Start = scene
		return
	end
	--
	local function primPart(m: Model): BasePart
		return (m.PrimaryPart :: BasePart)
	end
	local function animateCupsEnter(tweenTime: number): { [Model]: Tween }
		local cups : { Model } = {}
		--get cups to show
		for size, unlocked in next, getUnlockedCups() do
			local cup : Model = cupsFolder:WaitForChild(size) :: Model
			local origin = (cupsAttach:WaitForChild(size) :: Attachment).WorldCFrame
			;primPart(cup).CFrame = origin - travelDistance --they start on the left

			;(cup.PrimaryPart :: BasePart).Transparency = 1
			if not unlocked then continue end
			insert(cups, cup)
		end
		if #cups == 0 then error("how... no cups unlocked......") end
		--even amount of cups split the middle
		local toTween = travelDistance
		if #cups % 2 == 0 then --even amount results in the whole thing shifted left, move by half of separation dist
			local sepDist = (primPart(cups[1]).Position - primPart(cups[2]).Position).Z
			toTween += Vector3.new(0,0, -abs(sepDist) / 2)
		end

		local cupTweenData: {[Model]: Tween} = {}
		for i,cup in next, cups do
			local part = primPart(cup)
			local t = ts:Create(
				part,
				TweenInfo.new(tweenTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{
					CFrame = part.CFrame + toTween
				}
			)
			t:Play()
			cupTweenData[cup] = t
			--transparency tween, i dont see a current need to track this since its not very problematic
			ts:Create(
				part,
				TweenInfo.new(tweenTime, Enum.EasingStyle.Exponential),
				{
					Transparency = endingTransparency
				}
			):Play()
		end
		return cupTweenData
	end

	local worldCupMovementMult = 3
	local worldCupTimeMult = 2
	local function worldCupExit(cup: Model, originalTime: number)
		local toTween = travelDistance * worldCupMovementMult
		local part = primPart(cup)
		return ts:Create(
			part,
			TweenInfo.new(originalTime * worldCupTimeMult, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{
				CFrame = part.CFrame + toTween
			}
		)
	end
	local function cupExit(cup: Model, tweenTime: number, dir: number, noTransparency: boolean?): Tween
		local toTween = travelDistance * dir
		local part = primPart(cup)
		return ts:Create(
			part,
			TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{
				CFrame = part.CFrame + toTween,
				Transparency = noTransparency and part.Transparency or 1
			}
		)
	end
	local function cupCenterOnConveyor(cup: Model, tweenTime: number): Tween
		local part = primPart(cup)
		local ZTweenAmount = (cupsCenter.WorldPosition - part.Position).Z
		return ts:Create(
			part,
			TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{
				CFrame = part.CFrame + Vector3.new(0,0,ZTweenAmount)
			}
		)
	end
	--allows me to pick which way the cups exit (-1 left, 0 none, 1 right)
	local function animateCupsExit(cups: { [Model]: number }, tweenTime: number): {[Model]: Tween}
		local cupTweenData: {[Model]: Tween} = {}
		for cup,dir in next, cups do
			if dir == 0 then continue end
			local t = cupExit(cup, tweenTime, dir)
			t:Play()
			cupTweenData[cup] = t
		end
		return cupTweenData
	end

	local function sendChosenCup(): (string, boolean)
		local unlockedCups = getUnlockedCups()
		local cup = interactionHelper.awaitInfo("Build", "CupSize", unlockedCups, cupsFolder)
		--auto pick (only one option)
		local autoPicked = cup:sub(1,1) == "!"
		if autoPicked then
			cup = cup:sub(2)
		end
		--
		interactionHelper.cleanInfo("Build", "CupSize", unlockedCups, cupsFolder)
		--

		toggleServerWaitSpinner(true)
		addToDrinkRequest:InvokeServer("CupSize", cup, true) --addType, addWhat, isNewOrder
		toggleServerWaitSpinner(false)
		return cup, autoPicked
	end
	local function cupExitIfNot(chosenCup: string, tweenTime: number)
		local unlockedCups = getUnlockedCups()
		local chosenCup: BasePart = primPart( cupsFolder:WaitForChild(chosenCup) :: Model)
		--
		local cupsToExit: {[Model]: number} = {}
		for size, unlocked in next, unlockedCups do
			if not unlocked then continue end
			--
			local cup = primPart(cupsFolder:WaitForChild(size) :: Model)
			if cup == chosenCup then
				continue
			end
			--
			local moveDir = cup.Position - chosenCup.Position
			cupsToExit[cup.Parent :: Model] = sign(moveDir.Z)
		end
		animateCupsExit(cupsToExit, tweenTime)
		--
	end
	local serverBuildDrink: Model?

	local function tryTrashServerBuildDrink(designation: number)
		if not (serverBuildDrink and serverBuildDrink.Parent) then return end

		--SERVER deletes part after designation (+latency)
		trashCurrentDrink:FireServer("Build", designation * worldCupTimeMult)

		--CLIENT visually "deletes" part
		local drinkCup = serverBuildDrink:FindFirstChild("Cup") :: Model
		if drinkCup then
			worldCupExit(drinkCup, designation):Play() --always exits from right
		end
		return
	end
	local function refreshServerBuildDrink() : Model?
		local serverDrinkId = getCurrentDrinkId:InvokeServer("Build")
		local serverDrink = serverDrinkId ~= -1 and worldDrinkModels:WaitForChild(tostring(serverDrinkId), 5) or nil

		serverBuildDrink = serverDrink

		return serverDrink
	end
	local function switchToServerCup(clientCup: string, tweenTime: number)
		toggleServerWaitSpinner(true)

		refreshServerBuildDrink()

		toggleServerWaitSpinner(false)
		if not serverBuildDrink then warn("No current drink!") return end
		--
		--
		local oldCup = primPart(cupsFolder:FindFirstChild(clientCup) :: Model)
		oldCup.Transparency = 1

		local serverCup = serverBuildDrink:FindFirstChild("Cup") ::  Model
		primPart(serverCup).CFrame = oldCup.CFrame
		cupCenterOnConveyor(serverCup, tweenTime):Play()
		return
	end

	local isCupsExited = false
	--Cups Picker
	onSubsceneCallbacks.Build.CupSize = {
		Enter = function(scene: Scene, subscene: string, designation: number)
			--setup
			isCupsExited = false
			assignBuildStartScreen("CupSize")
			audioHelper.PlayAudio("swoosh")
			delay(designation, allowBuildCancels, true)
			delay(designation, allowPlayerSceneInput, true)
			--dispenser positions reset
			dispActiveAttach.WorldCFrame = dispActiveOriginCFrame
			--
			animateCupsEnter(designation)
			task.wait(designation)
			--
			local cup, autoPicked = sendChosenCup() --yields here, so code after this line may not run
			--code after /\ means the player picked a cup
			allowPlayerSceneInput(false)
			allowBuildCancels(false)
			assignBuildStartScreen("FillCup") --save status if user exits station

			--code below will run in-sync with Build.FillCup.Enter
			local toFillCupTime = getSubsceneChangeTime(scene, "FillCup")
			--
			switchToServerCup(cup, toFillCupTime)
			cupExitIfNot(cup, toFillCupTime) --CupSize always precedes FillCup
			isCupsExited = true
			--

			onGameActionCallbacks.SetScene(scene.Name, {
				Subscene = "FillCup",
				TweenInfo = {
					EasingStyle = Enum.EasingStyle.Sine,
					EasingDirection = Enum.EasingDirection.InOut
				}
			})
		end,
		Exit = function(scene: Scene, subscene: string, designation: number)
			--the player didnt pick a cup, so they leave the scene by all sliding right (1).
			local cupsToAnim = getUnlockedCups()
			--
			if not isCupsExited then
				local dirs: {[Model]: number} = {}
				for cup, unlocked in next, cupsToAnim do
					dirs[cupsFolder:WaitForChild(cup) :: Model] = 1
				end
				animateCupsExit(dirs, designation)
			end

			--
			interactionHelper.cleanInfo("Build", "CupSize", cupsToAnim, cupsFolder)

		end,
		OnCanceled = function(scene: Scene, subscene: string, designation: number)
			allowBuildCancels(false)
			allowPlayerSceneInput(false)
			--
			--tryTrashServerBuildDrink(designation) --not needed here bc they havent even picked a cup yet!
			trySceneExit(scene, subscene, designation)
			trySceneEnter(scene, "CupSize", designation, designation)
		end
	}

	local dispensers = buildScene:FindFirstChild("Stuff"):WaitForChild("Dispensers")
	dispActiveAttach = dispCenter:WaitForChild("Dispenser") :: Attachment
	dispActiveOriginCFrame = dispActiveAttach.WorldCFrame
	--
	local dispAwaitAttach = dispCenter:WaitForChild("Await") :: Attachment

	--

	local function getDispenser(disp: string):Model
		return dispensers:WaitForChild(disp) :: Model
	end
	local dispPourAttachments = {
		FillCup = getDispenser("FillCup"):WaitForChild("Dispenser"):WaitForChild("Pipe"):WaitForChild("End"):WaitForChild("Pour") :: Attachment
	}

	local fillcupSuccessGui = getDispenser("FillCup"):WaitForChild("Gui"):WaitForChild("FillCup"):WaitForChild("SuccessNotif") :: SurfaceGui
	local function animateDispenser(disp: string, isActive: boolean, tweenTime: number): nil
		local dispenser = getDispenser(disp)
		--assert(disp, "Dispenser "..disp.." does not exist")

		local toAttachment : Attachment = isActive and dispActiveAttach or dispAwaitAttach
		local easingDir = (isActive and Enum.EasingDirection.Out) or Enum.EasingDirection.In
		local dispPart = primPart(dispenser)
		ts:Create(
			dispPart,
			TweenInfo.new(tweenTime, Enum.EasingStyle.Back, easingDir),
			{CFrame = toAttachment.WorldCFrame * dispPart.CFrame.Rotation }	
		):Play()
		return
	end
	local function focusWorldDispenserGui(disp: string): ObjectValue?
		local dispenser = getDispenser(disp)
		local gui = dispenser:WaitForChild("Gui"):WaitForChild(disp) :: ObjectValue
		gui.Parent = worldGuis
		--
		return gui
	end

	local animBonusData: {
		FadeInOut: number,
		PauseTime: number,
		RPS: number
	}
	local function spinBonusSign(i: ImageLabel, time: number, speed: number)
		local r = 0
		local endTime = tick()+time
		local con: RBXScriptConnection
		con =runs.Heartbeat:Connect(function(dt)
			if tick() >= endTime then
				con:Disconnect()
				i.Rotation = 0
			end
			r = (r + 360 * speed * dt) % 360
			i.Rotation = r
		end)
	end
	local function animateBonusMessage(successGui: SurfaceGui, msg: string, animData: typeof(animBonusData))
		local notif = successGui:WaitForChild("Scaled"):WaitForChild("Notification") :: Frame
		local caption = notif:WaitForChild("Decal"):WaitForChild("Caption") :: TextLabel
		local image = notif:FindFirstChild("Decal"):WaitForChild("Image") :: ImageLabel
		--
		caption.Text = msg
		notif.Size = UDim2.new()
		notif.Visible = true
		--
		local inOut = animData.FadeInOut
		local pause = animData.PauseTime
		local tweenIn = ts:Create(
			notif,
			TweenInfo.new(inOut, Enum.EasingStyle.Linear),
			{ Size = UDim2.fromScale(1,1)}
		)
		local tweenOut = ts:Create(
			notif,
			TweenInfo.new(inOut, Enum.EasingStyle.Linear),
			{ Size = UDim2.new()}
		)
		--
		tweenIn:Play()
		delay(inOut+pause, function()
			tweenOut:Play()
			tweenOut.Completed:Wait()
			notif.Visible = false
		end)
		spinBonusSign(image, 2*inOut+pause, animData.RPS)
		return
	end
	local function sendFillCupScore(dispGuis: ObjectValue): (number, boolean)
		local score, bonusMsg = interactionHelper.awaitInfo("Build", "FillCup", nil, dispGuis)
		if bonusMsg then
			animateBonusMessage(fillcupSuccessGui, bonusMsg, {
				FadeInOut = 0.25,
				PauseTime = 1,
				RPS = 1
			})
		end
		--
		scoreToppingRequest:FireServer("CupSize", score) --YES! FillCup is actually just the scorer for CupSize.
		return score, bonusMsg ~= nil
	end
	local function animateFillCupPour(serverCup: Model, dispAttach: Attachment)

		toggleServerWaitSpinner(true)
		allowBuildCancels(true) --so the user can cancel order during the bonus message & fill anim
		--
		interactionHelper.awaitDraw("Build", "FillCup", {
			Cup = serverCup:WaitForChild("Cup") :: Model,
			PourAttachment = dispAttach
		})
		--
		toggleServerWaitSpinner(false)
		allowBuildCancels(false)
	end
	--Cups Filler
	onSubsceneCallbacks.Build.FillCup = {
		Enter = function(scene: Scene, subscene: string, designation: number)
			delay(designation, allowPlayerSceneInput, true) --playersceneinput always starts false due to CupSize/SetScene
			delay(designation, allowBuildCancels, true)
			--
			local dispGuis = focusWorldDispenserGui("FillCup")
			assert(dispGuis, "Missing display gui(s) for "..scene.Name..", "..subscene)
			--animate machine dropdown
			animateDispenser("FillCup", true, designation) 
			--get player score & animate bonus
			local score, gotBonus = sendFillCupScore(dispGuis)

			--code underneath may not run if sceneswitch
			allowPlayerSceneInput(false)
			allowBuildCancels(false)
			assignBuildStartScreen("MixIn") --save status if user exits station

			--animate pouring
			if assert(serverBuildDrink, "No drink to animate at Build") then
				--YIELDING FUNCTION
				animateFillCupPour(serverBuildDrink, dispPourAttachments.FillCup)
				--YIELDING FUNCTION
			end

			--switch to MixIn subscene!
			onGameActionCallbacks.SetScene(scene.Name, {
				Subscene = "MixIn",
				TweenInfo = {
					EasingStyle = Enum.EasingStyle.Sine,
					EasingDirection = Enum.EasingDirection.InOut
				}
			})
		end,
		Exit = function(scene: Scene, subscene: string, designation: number)
			defocusWorldGuis()
			--
			animateDispenser("FillCup", false, designation)
			--
			interactionHelper.cleanInfo("Build", "FillCup")
			if serverBuildDrink then
				interactionHelper.cleanDraw("Build", "FillCup", serverBuildDrink)
			end
		end,
		OnCanceled = function(scene: Scene, subscene: string, designation: number)
			allowBuildCancels(false)
			allowPlayerSceneInput(false)
			--
			tryTrashServerBuildDrink(designation)

			toggleServerWaitSpinner(false) --it may stay 'stuck' on if the player cancels during the pour anim.
			--
			onGameActionCallbacks.SetScene(scene.Name, {
				Subscene = "CupSize",
				TweenInfo = {
					EasingStyle = Enum.EasingStyle.Sine,
					EasingDirection = Enum.EasingDirection.InOut
				}
			})
		end
	}

	--Mix-Ins

	local mixInDispenser = getDispenser("MixIn")

	local mixInDispenserAttach = (mixInDispenser:FindFirstChild("Body"):FindFirstChild("DispenserPiece"):FindFirstChild("Attachment") :: Attachment)
	local mixInGui = mixInDispenser:WaitForChild("Gui"):WaitForChild("MixIn") :: ObjectValue
	local migChooser = mixInGui:WaitForChild("FlavorChooser") :: Folder
	local migDispenser = mixInGui:WaitForChild("Dispenser") :: Folder

	local migDispBtn = migDispenser:WaitForChild("Button") :: SurfaceGui
	local mixInSuccessGui = migDispenser:WaitForChild("SuccessNotif") :: SurfaceGui

	local migChooserButtons: {[string]: Frame} = {}
	--collect buttons and add to table
	do
		local btns = addToTable(
			migChooser:FindFirstChild("ChoiceLeft"):FindFirstChild("Holder"):GetChildren(),
			migChooser:FindFirstChild("ChoiceRight"):FindFirstChild("Holder"):GetChildren(),
			false
		)
		for i,v : Frame in next, btns do
			migChooserButtons[v.Name] = v
		end
	end


	--
	local function getUnlockedMixIns(): {[string]: boolean}
		return unlockedTools.MixIn
	end
	local function toggleGuiTop(gui: SurfaceGui, enabled: boolean)
		gui.AlwaysOnTop = enabled
	end
	local function disableLockedMixIns()
		local unlocked = getUnlockedMixIns()
		for name,v : Frame in next, migChooserButtons do
			(v:FindFirstChildWhichIsA("ImageButton") :: ImageButton).Visible = unlocked[v.Name]
		end
		return
	end
	--used for after the player selects an flavor
	local function toggleMixInShadows(enabled: boolean, ignore: string?)
		for name,v : Frame in next, migChooserButtons do
			local shadow = v:FindFirstChild("Shadow") :: TextButton
			if name == ignore then
				shadow.Visible = not enabled
			else
				shadow.Visible = enabled
			end
		end
	end
	local function awaitMixInChoice(): string
		local unlocked = getUnlockedMixIns()
		local choice = interactionHelper.awaitInfo("Build", "MixIn_Chooser", unlocked, migChooserButtons)
		--
		return choice
	end
	local isDown = {
		Syrup = true,
		MixIn = true
	}
	local function getDispCoverTween(disp: Model, enabled: boolean, animateTime: number): (Tween?, Tween?)
		if isDown[disp.Name] == enabled then return end
		isDown[disp.Name] = enabled
		--
		local cover = disp:WaitForChild("Body"):WaitForChild("Cover")::Model
		local dir: Enum.EasingDirection, mul: number = Enum.EasingDirection.In, 1
		if enabled then
			dir = Enum.EasingDirection.Out
			mul = -1
		end

		local coverBack, coverSign = cover:WaitForChild("Cover")::BasePart, cover:WaitForChild("Sign")::BasePart
		local moveOffset =  Vector3.new(0, coverBack.Size.Y/2 * mul, 0)
		--
		return ts:Create(
			coverBack,
			TweenInfo.new(animateTime, Enum.EasingStyle.Sine, dir),
			{
				Position = coverBack.Position + moveOffset
			}
		), ts:Create(
			coverSign,
			TweenInfo.new(animateTime, Enum.EasingStyle.Sine, dir),
			{
				Position = coverSign.Position + moveOffset
			}
		)
	end
	local function sendMixInChoice(choice: string)
		toggleServerWaitSpinner(true)
		addToDrinkRequest:InvokeServer("MixIn", choice, false) --addType, addWhat, isNewOrder
		toggleServerWaitSpinner(false)
		return
	end
	local function sendMixInScore(dispGuis: Instance): (number, boolean)
		local score, bonusMsg = interactionHelper.awaitInfo("Build", "MixIn_Dispenser", nil, dispGuis)
		interactionHelper.cleanInfo("Build", "MixIn_Dispenser")

		toggleGuiTop(migDispBtn, false)
		if bonusMsg then
			animateBonusMessage(mixInSuccessGui, bonusMsg, {
				FadeInOut = 0.25,
				PauseTime = 1,
				RPS = 1
			})
		end
		--

		scoreToppingRequest:FireServer("MixIn", score) --YES! FillCup is actually just the scorer for CupSize.
		return score, bonusMsg ~= nil
	end

	local function animateMixInPour(choice: string, score: number)

		toggleServerWaitSpinner(true)
		allowBuildCancels(true) --so the user can cancel order during the bonus message
		--waitforchild on cup model, it will have the server parent a transparent fillPart to it
		--record the fillpart Y size and set it to 0, then opaque + tween size back to normal
		--this one should yield
		if serverBuildDrink then
			interactionHelper.awaitDraw("Build", "MixIn", {
				Cup = serverBuildDrink:WaitForChild("Cup") :: Model,
				PourAttachment = mixInDispenserAttach,
				Flavor = choice,
				Score = score
			})
		else
			warn("no drink")
		end

		task.wait()
		toggleServerWaitSpinner(false)
		allowBuildCancels(false)
	end

	onSubsceneCallbacks.Build.MixIn = {
		Enter = function(scene: Scene, subscene: string, designation: number)
			delay(designation, allowPlayerSceneInput, true) --playersceneinput always starts false due to CupSize/SetScene
			delay(designation, allowBuildCancels, true)
			--
			local dispGuis = focusWorldDispenserGui("MixIn")
			assert(dispGuis, "Missing display gui(s) for "..scene.Name..", "..subscene)

			--animate machine dropdown
			disableLockedMixIns()
			toggleMixInShadows(false)
			animateDispenser("MixIn", true, designation) 

			--get+send mixin choice
			local choice = awaitMixInChoice() --can end here via canceling
			do
				toggleMixInShadows(true, choice)

				allowBuildCancels(false)
				allowPlayerSceneInput(false)

				--sendMixInChoice(choice) --MOVED TO AFTER SCORING (because WorldDrinkEditor uses the score, which isnt assigned yet)
			end
			-- switch to dispenser gui now
			do

				local covert1, covert2 = getDispCoverTween(mixInDispenser, false, designation/2)
				if covert1 and covert2 then
					covert1:Play()
					covert2:Play()
				end
				delay(designation/2, function()
					toggleGuiTop(migDispBtn, true)

					allowBuildCancels(true)
					allowPlayerSceneInput(true)
				end)

			end

			--get+send mixin score 
			do 
				local score, gotBonus = sendMixInScore(dispGuis:FindFirstChild("Dispenser")) --yields here again
				sendMixInChoice(choice)
				--code underneath may not run if sceneswitch
				allowPlayerSceneInput(false)
				allowBuildCancels(false)
				assignBuildStartScreen("Syrup") --save status if user exits station
				--animate pouring
				animateMixInPour(choice, score)
				--switch to MixIn subscene!
				onGameActionCallbacks.SetScene(scene.Name, {
					Subscene = "Syrup",
					TweenInfo = {
						EasingStyle = Enum.EasingStyle.Sine,
						EasingDirection = Enum.EasingDirection.InOut
					}
				})
			end 
			return
		end,
		Exit = function(scene: Scene, subscene: string, designation: number)
			defocusWorldGuis()
			--

			--hide dispenser gui
			toggleGuiTop(migDispBtn, false)
			spawn(function()
				local covert1, covert2 = getDispCoverTween(mixInDispenser, true, designation/2)

				if covert1 and covert2 then
					covert1:Play()
					covert2:Play()
					covert1.Completed:Wait()
				end
				--

				animateDispenser("MixIn", false, covert1 and designation/2 or designation)
			end)
			--
			interactionHelper.cleanInfo("Build", "MixIn_Chooser")
			interactionHelper.cleanInfo("Build", "MixIn_Dispenser")

			if serverBuildDrink then
				interactionHelper.cleanDraw("Build", "MixIn")
			end
		end,
		OnCanceled = function(scene: Scene, subscene: string, designation: number)
			allowBuildCancels(false)
			allowPlayerSceneInput(false)
			--
			tryTrashServerBuildDrink(designation)
			toggleServerWaitSpinner(false) --it may stay 'stuck' on if the player cancels during the pour anim.
			--
			onGameActionCallbacks.SetScene(scene.Name, {
				Subscene = "CupSize",
				TweenInfo = {
					EasingStyle = Enum.EasingStyle.Sine,
					EasingDirection = Enum.EasingDirection.InOut
				}
			})
		end
	}


	--Syrups
	local syrupDispenser = getDispenser("Syrup")
	local syrupChooser = syrupDispenser:WaitForChild("Dispenser") :: Model
	--
	local syrupGui = syrupDispenser:WaitForChild("Gui"):WaitForChild("Syrup") :: ObjectValue
	local sgDispenser = syrupGui:WaitForChild("Dispenser") :: Folder
	local sgChooser = syrupGui:WaitForChild("FlavorChooser")
	--
	local sgDispBtn = sgDispenser:WaitForChild("Button") :: SurfaceGui
	local syrupSuccessGui = sgDispenser:WaitForChild("SuccessNotif") :: SurfaceGui

	local syrupChooserButtons: {[string]: BasePart} = {}
	local syrupChooserUIAttach : {[string]: BasePart} = {}
	--collect buttons and add to table
	do
		local btns = syrupChooser:GetChildren()
		for i,v in next, btns do
			if v.Name == "Button" then continue end
			--
			syrupChooserButtons[v.Name] = v:FindFirstChild"Flavor" :: BasePart
			syrupChooserUIAttach[v.Name] = syrupChooserButtons[v.Name]:FindFirstChild("Part") :: BasePart
		end
	end
	--

	local function getUnlockedSyrups(): {[string]: boolean}
		return unlockedTools.Syrup
	end
	local function disableLockedSyrups()
		local unlocked = getUnlockedSyrups()
		for name,v : BasePart in next, syrupChooserButtons do
			local isUnlocked = unlocked[name]
			local uiAttach = syrupChooserUIAttach[name]
			--
			if isUnlocked then
				v.Color = (v:FindFirstChildWhichIsA("Color3Value") :: Color3Value).Value
				--
				uiAttach.Position = (v:FindFirstChild("Label") :: Attachment).WorldPosition
			else
				v.Color = Color3.fromRGB(130,130,130)
				--
				syrupChooserUIAttach[name].Position = (v:FindFirstChild("Hidden") :: Attachment).WorldPosition
			end
		end
		return
	end

	local function toggleSyrupShadows(enabled: boolean, ignore: string?)
		local attachmentName = enabled and "Hidden" or "Label"
		local unlocked = getUnlockedSyrups()
		for name,v : BasePart in next, syrupChooserButtons do
			local attachment = v:FindFirstChild(unlocked[name] and attachmentName or "Hidden") :: Attachment
			if name == ignore then
				continue
			else
				local c = v.Color
				local mul = enabled and 0.25 or 1
				v.Color = Color3.new(mul*c.R, mul*c.G, mul*c.B) --50% darken
				--
				syrupChooserUIAttach[name].Position = attachment.WorldPosition
			end
		end
	end
	local function awaitSyrupChoice(): string
		local unlocked = getUnlockedSyrups()
		local choice = interactionHelper.awaitInfo("Build", "Syrup_Chooser", unlocked, syrupChooserButtons)
		interactionHelper.cleanInfo("Build", "Syrup_Chooser", syrupChooserButtons)
		--
		return choice
	end
	local function sendSyrupChoice(choice: string)
		toggleServerWaitSpinner(true)
		addToDrinkRequest:InvokeServer("Syrup", choice, false) --addType, addWhat, isNewOrder
		toggleServerWaitSpinner(false)
		return
	end


	local function sendSyrupScore(dispGuis: Instance): (number, boolean)
		local score, bonusMsg = interactionHelper.awaitInfo("Build", "Syrup_Dispenser", nil, dispGuis)
		interactionHelper.cleanInfo("Build", "Syrup_Dispenser")

		toggleGuiTop(sgDispBtn, false)
		if bonusMsg then
			animateBonusMessage(syrupSuccessGui, bonusMsg, {
				FadeInOut = 0.25,
				PauseTime = 1,
				RPS = 1
			})
		end
		--

		scoreToppingRequest:FireServer("Syrup", score)
		return score, bonusMsg ~= nil
	end

	local function animateSyrupPour(choice: string)

		toggleServerWaitSpinner(true)
		allowBuildCancels(true) --so the user can cancel order during the bonus message
		--waitforchild on cup model, it will have the server parent a transparent fillPart to it
		--record the fillpart Y size and set it to 0, then opaque + tween size back to normal
		--this one should yield
		task.wait()
		toggleServerWaitSpinner(false)
		allowBuildCancels(false)
	end

	onSubsceneCallbacks.Build.Syrup = {
		Enter = function(scene: Scene, subscene: string, designation: number)

			delay(designation, allowPlayerSceneInput, true) --playersceneinput always starts false due to CupSize/SetScene
			delay(designation, allowBuildCancels, true)
			--
			local dispGuis = focusWorldDispenserGui("Syrup")
			assert(dispGuis, "Missing display gui(s) for "..scene.Name..", "..subscene)


			--animate machine dropdown
			disableLockedSyrups()
			toggleSyrupShadows(false)
			animateDispenser("Syrup", true, designation) 

			--get+send mixin choice
			local choice = awaitSyrupChoice() --can end here via canceling
			do
				toggleSyrupShadows(true, choice)

				allowBuildCancels(false)
				allowPlayerSceneInput(false)

				--sendMixInChoice(choice) --MOVED TO AFTER SCORING (because WorldDrinkEditor uses the score, which isnt assigned yet)
			end

			-- switch to dispenser gui now
			do

				local covert1, covert2 = getDispCoverTween(syrupDispenser, false, designation/2)
				if covert1 and covert2 then
					covert1:Play()
					covert2:Play()
				end
				delay(designation/2, function()
					toggleGuiTop(sgDispBtn, true)

					allowBuildCancels(true)
					allowPlayerSceneInput(true)
				end)

			end

			--get+send mixin score 
			do 
				local score, gotBonus = sendSyrupScore(dispGuis:FindFirstChild("Dispenser")) --yields here again
				sendSyrupChoice(choice)
				--code underneath may not run if sceneswitch

				allowPlayerSceneInput(false)
				allowBuildCancels(false)
				assignBuildStartScreen("CupSize") -- the cup is now done, it can be "sent off"
				--animate pouring
				animateSyrupPour(choice)


				--this code specially runs here bc we are changing SCENES not subscenes from Build -> Top
				local exitDesignation = getSubsceneChangeTime(Scenes.Mix)
				delay(exitDesignation, allowBuildCancels, true)

				if serverBuildDrink then
					local drinkCup = serverBuildDrink:FindFirstChild("Cup") :: Model
					if drinkCup then
						--increases the cups speed and reduces its time to finish Tween by SceneExit()
						--because the speed matters here
						local _t, _m = worldCupTimeMult, worldCupMovementMult
						--
						worldCupMovementMult = worldCupTimeMult/designation
						--
						worldCupExit(drinkCup, designation):Play() --always exits from right
						--
						worldCupTimeMult, worldCupMovementMult = _t, _m --couldve done /= mul but dont want floating pt error
					end
				end

				--switch to MixIn subscene!
				--onGameActionCallbacks.SetScene("Mix") --it is now in the mix queue sooo
				levelConfig:SetAttribute("CurrentScene", "Mix") --this fires the above/\ and helps the script update the "current scene" for btn debounce.
			end 
			return

		end,
		Exit = function(scene: Scene, subscene: string, designation: number)
			defocusWorldGuis()
			--

			--hide dispenser gui
			toggleGuiTop(sgDispBtn, false)
			spawn(function()
				local covert1, covert2 = getDispCoverTween(syrupDispenser, true, designation/2)

				if covert1 and covert2 then
					covert1:Play()
					covert2:Play()
					covert1.Completed:Wait()
				end
				--

				animateDispenser("Syrup", false, covert1 and designation/2 or designation)
			end)
			--
			interactionHelper.cleanInfo("Build", "Syrup_Chooser")
			interactionHelper.cleanInfo("Build", "Syrup_Dispenser")
		end,
		OnCanceled = function(scene: Scene, subscene: string, designation: number)
			allowBuildCancels(false)
			allowPlayerSceneInput(false)
			--
			tryTrashServerBuildDrink(designation)
			--
			onGameActionCallbacks.SetScene(scene.Name, {
				Subscene = "CupSize",
				TweenInfo = {
					EasingStyle = Enum.EasingStyle.Sine,
					EasingDirection = Enum.EasingDirection.InOut
				}
			})
		end
	}
end

--Mix scene setup
--[[


--TODO: animate the syrup pour (try copy pasting

------------------------------
MIX
------------------------------
/*-
]]
do
	onSubsceneCallbacks.Mix = {}
	onSubsceneCallbacks.Mix.Station = {
		Enter = function(scene: Scene, subscene: string, designation: number)
			delay(designation, allowPlayerSceneInput, true) --playersceneinput always starts false due to CupSize/SetScene



			return
		end,
		Exit = function(scene: Scene, subscene: string, designation: number)
			return
		end,
		OnCanceled = function(scene: Scene, subscene: string, designation: number)
			return
		end
	}
end
--Top scene setup
do
	onSubsceneCallbacks.Top = {}
	onSubsceneCallbacks.Top.Test = {
		Enter = function(scene: Scene, subscene: string, designation: number)

			delay(designation, allowPlayerSceneInput, true) --playersceneinput always starts false due to CupSize/SetScene

			return
		end,
		Exit = function(scene: Scene, subscene: string, designation: number)
			return
		end,
		OnCanceled = function(scene: Scene, subscene: string, designation: number)
			return
		end
	}
	--
	onSubsceneCallbacks.test = {
		Test = onSubsceneCallbacks.Top.Test	
	}
end
--start game
setData:Fire("ResetTime") --start the daynight cycle
Scenes.Build.Start = "CupSize" --bc it can change its default starting scene.
onSubsceneCallbacks.Order.Station.Enter(Scenes.Order, "Station", 0.5) --the first scene of the game


--demo
PlayScreen.Visible = true
PauseScreen.Visible = false
game.TweenService:Create(GameClockFiller, TweenInfo.new(15, Enum.EasingStyle.Linear), { Value = 1 }):Play()
--


