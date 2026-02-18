--!strict
-- Scenes are only to be used to update camera positioning
-- Therefore, the game scripts will interact with a Scene
-- to coordinate UI changes and such
local scene = {}

--these are locals and not types because 'type sceneSetParams' isnt descriptive, vs '{ Subscene: string...'
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
local sceneInitParams: {
	PlayStart: boolean?,
	OnlyPlayLatter: boolean?
}

local sceneMT : {
	__index: any,
	GetFadeFrame: (self: Scene)-> Frame,
	__tostring: (self: Scene)->string,
	ToggleFade: (self: Scene, on: boolean, time: number, data:typeof(sceneSetParams))->Tween,
	MoveTo: (self: Scene, pos: CFrame, time: number, data: typeof(sceneSetParams))->Tween,
	Set: (self: Scene, data: typeof(sceneSetParams))-> nil,
	Init: (self: Scene, data: typeof(sceneInitParams)?)-> nil 
} = {
	GetFadeFrame = nil :: any,
	__tostring = nil :: any,
	ToggleFade = nil :: any,
	MoveTo = nil :: any,
	Set = nil :: any,
	Init = nil :: any
}
sceneMT.__index = sceneMT

type sceneData = {
	Name: string,
	Start: string,
	Subscene: string,
	Origin: BasePart,
}
export type Scene = typeof( setmetatable({} :: sceneData, {__index = sceneMT }) )

--
local clone = table.clone
local modules = script.Parent
local camera = require(modules:WaitForChild("Camera"))
camera.Init()
camera.Reset()
--
local lp = game:GetService("Players").LocalPlayer
local gameLighting = game:GetService("Lighting")

local scenes = workspace:WaitForChild("Scenes")
local ts = game:GetService("TweenService")
local defaultTweenInfo = {
	EasingStyle = Enum.EasingStyle.Linear,
	EasingDirection = Enum.EasingDirection.Out
}
local spawn = task.spawn


--make fade
scene.SetFadeFrame = function(f: Frame): nil
	scene.FadeFrame = f
	return
end
scene.GetFadeFrame = function(self: any): Frame
	return scene.FadeFrame
end
sceneMT.GetFadeFrame = scene.GetFadeFrame
--Scene methods

sceneMT.__tostring = function(self: Scene): string
	return "Scene " .. self.Name
end
--

--types of scene/subscene changes
local lastTween: Tween? = nil

sceneMT.ToggleFade = function(self: Scene, on: boolean, time: number, data:typeof(sceneSetParams)): Tween
	if lastTween then
		lastTween:Cancel()
	end
	local trans = on and 0 or 1
	local fadeFrame = self:GetFadeFrame()
	fadeFrame.BackgroundTransparency = 1 - trans --start as oppposite (just in case)
	--
	local tweenData = (data.TweenInfo or {}) :: any
	local newTween = ts:Create(
		fadeFrame,
		TweenInfo.new(
			time,
			tweenData.EasingStyle or defaultTweenInfo.EasingStyle,
			tweenData.EasingDirection or defaultTweenInfo.EasingDirection
		), --overridden time, else fadeIn/out of current scene.
		{ BackgroundTransparency = trans }
	)
	
	newTween:Play()
	lastTween = newTween
	return newTween
end
sceneMT.MoveTo = function(self: Scene, pos: CFrame, time: number, data: typeof(sceneSetParams)): Tween
	if lastTween then
		lastTween:Cancel()
	end
	
	local subSceneData = self.Origin:FindFirstChild(self.Subscene) :: Attachment
	local tweenData = (data.TweenInfo or {}) :: any
	local newTween = ts:Create(
		camera.Object,
		TweenInfo.new(
			time,
			tweenData.EasingStyle or defaultTweenInfo.EasingStyle,
			tweenData.EasingDirection or defaultTweenInfo.EasingDirection
		),
		{ CFrame = pos }
	)

	newTween:Play()
	lastTween = newTween
	return newTween
end



local setModes: {
	[string]:(scene: Scene, data: typeof(sceneSetParams)) -> any
} = {}
setModes.Fade = function(scene: Scene, data: typeof(sceneSetParams)): nil
	--fade out
	if not data.OnlyPlayLatter then
		local oldAttachment = (scene.Origin :: BasePart):WaitForChild(data.Subscene, 5) :: Attachment
		assert(oldAttachment, "Unload Error for " .. tostring(scene) .. " on Subscene " .. data.Subscene)
		--
		scene:ToggleFade(
			true,
			data.SetTime or oldAttachment:GetAttribute("Time") :: number,
			data
		).Completed:Wait()
	end
	--lighting
	local lighting = scene.Origin:FindFirstChild("Lighting") :: Folder
	if lighting then
		for i,v : any in next, lighting:GetChildren() do
			gameLighting[v.Name] = v.Value
		end
	end
	--
	--setup for next scene
	scene.Subscene = data.Subscene
	local newAttachment = (scene.Origin :: BasePart):WaitForChild(data.Subscene, 5) :: Attachment
	assert(newAttachment, "Load Error for " .. tostring(scene) .. " on Subscene " .. data.Subscene)
	--
	camera.To(newAttachment.WorldCFrame)
	--fade in
	if data.MidpointCallback then spawn(data.MidpointCallback, scene) end
	scene:ToggleFade(
		false,
		data.SetTime or newAttachment:GetAttribute("Time"),
		data
	).Completed:Wait()
	return
end
setModes.Move = function(scene: Scene, data: typeof(sceneSetParams)): nil
	--setup for next scene
	scene.Subscene = data.Subscene
	local newAttachment = (scene.Origin :: BasePart):WaitForChild(data.Subscene, 5) :: Attachment
	assert(newAttachment, "Load Error for " .. tostring(scene) .. " on Subscene " .. data.Subscene)
	--
	--lighting
	local lighting = scene.Origin:FindFirstChild("Lighting") :: Folder
	if lighting then
		for i,v : any in next, lighting:GetChildren() do
			gameLighting[v.Name] = v.Value
		end
	end
	--
	if not data.OnlyPlayLatter then
		if data.MidpointCallback then spawn(data.MidpointCallback, scene) end
		scene:MoveTo(
			newAttachment.WorldCFrame,
			data.SetTime or newAttachment:GetAttribute("Time"),
			data
		).Completed:Wait()
	else
		camera.Object.CFrame = newAttachment.WorldCFrame
	end
	return
end
--for changing subscenes
--to open a new scene, do scene:Init(true)
sceneMT.Set = function(self: Scene, data: typeof(sceneSetParams)): nil
	local subscene = self.Origin:FindFirstChild(data.Subscene)
	assert(subscene and subscene:IsA"Attachment", "Subscene invalid/not found")
	local mode = data.Mode or subscene:GetAttribute("Mode")
	
	local fadeFrame = self:GetFadeFrame()
	local clickBlocker = fadeFrame:FindFirstChild"NoClick" :: GuiButton
	
	clickBlocker.Visible = true
	
	--do scene switch
	setModes[tostring(mode)](self, data)
	clickBlocker.Visible = false
	
	return
end
--
local function sceneInit(self: Scene, data: typeof(sceneInitParams)?): nil
	local data = data or {} :: typeof(sceneInitParams)
	--find the world model
	local worldModel = scenes:WaitForChild(self.Name)
	self.Origin = worldModel:WaitForChild("Origin", 10) :: BasePart
	assert(self.Origin, "Could not find Origin for " .. tostring(self))
	--
	self.Subscene = self.Start
	
	if data.PlayStart then
		self:Set({
			Subscene = self.Start,
			Mode = "Fade",
			OnlyPlayLatter = data.OnlyPlayLatter
		})
	end
	return 
end
sceneMT.Init = sceneInit
--

--new()
local proxymt = { __index = sceneMT}
scene.new = function(worldScene: Model) : Scene
	local origin = worldScene:WaitForChild("Origin", 10) :: BasePart or error"Scene is missing origin."
	local startAt = ((worldScene:WaitForChild("Start", 5) or error"Scene is missing Start value") :: StringValue).Value
	return setmetatable({
		Name = worldScene.Name,
		Start = startAt,
		Subscene = "",	--put in :Init()
		Origin = origin, 	--put in :Init()
	}, proxymt) :: Scene
end


return scene
