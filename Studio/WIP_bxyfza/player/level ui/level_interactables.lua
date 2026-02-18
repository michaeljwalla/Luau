--!strict
local sceneSetParams: {
	Subscene: string,
	Mode: ("Fade" | "Move") | string?,
	SetTime: number?,
	OnlyPlayLatter: boolean?,
	MidpointCallback: (scene: any--[[Scene]])->(...any)?,
	TweenInfo : {
		EasingStyle: Enum.EasingStyle?,
		EasingDirection: Enum.EasingDirection?
	}?
}
--instances
local levelGui = script.Parent
local PlayScreen = levelGui.Play
local PauseScreen = levelGui.Pause
--
local max, min = math.max, math.min
-- services
local tweenservice = game:GetService("TweenService")
local runs = game:GetService('RunService')
local runsFuncs = {Heartbeat = {}, RenderStepped = {}, Stepped = {}}
--
local scrConfig = script.Config
--communication
local gameAction = script.Action --sends to game contoller
local setData = script.SetData   --sends to 
--misc functions
local insert = table.insert
local function filterchildren(i: Instance, type: string): { any }
	local t = {}
	for i, v in next, i:GetChildren() do
		if v:IsA(type) then
			insert(t, v)
		end
	end
	return t
end


--connections
local onSetDataCallbacks: {[string]: (...any)->(...any)} = {}
--for communicating with gamecontroller
do
	local function onSetDataFired(action: string, ...: any): nil
		local cb = onSetDataCallbacks[action]
		if cb then
			cb(...)
		end
		return
	end
	setData.Event:Connect(onSetDataFired)
end

--daynight fillbar and game counter
do
	--
	local signSpinSpeed = 1.5
	--
	local clocksigns = PlayScreen.Foreground.ClockSigns
	local clockSyncFill = clocksigns.Fill
	--
	local openSign = clocksigns.OpenSign
	local openSignFillBar = openSign.Outer.Inner.Time.FillBack.FillBar
	--
	local function syncClockToFill(): number
		local value = clockSyncFill.Value
		openSignFillBar.Size = UDim2.fromScale(0.5 * clockSyncFill.Value, 1) --0.5 bc the close time is halfway thru the "day"
		return value
	end
	
	local lastTween: Tween? = nil
	local function toClosedSign(tween: boolean, time: number?)
		if tween then
			clocksigns.Rotation = 0
			if lastTween then lastTween:Cancel() end
			lastTween = tweenservice:Create(
				clocksigns,
				TweenInfo.new(time, Enum.EasingStyle.Elastic),
				{ Rotation = 180 }
			)
			;(lastTween :: Tween):Play()
			return
		end
		--
		if lastTween then lastTween:Cancel() end
		clocksigns.Rotation = 180
		return
	end
	local function toOpenSign(tween: boolean, time: number?)
		if tween then
			clocksigns.Rotation = 180
			if lastTween then lastTween:Cancel() end
			lastTween = tweenservice:Create(
				clocksigns,
				TweenInfo.new(time, Enum.EasingStyle.Elastic),
				{ Rotation = 0 }
			)
			;(lastTween :: Tween):Play()
			return
		end
		--
		if lastTween then lastTween:Cancel() end
		clocksigns.Rotation = 0
		return
	end

	local isOpen = false
	local function checkSignSpin(n: number)
		if (n <= 0 or n >= 1) and isOpen then
			isOpen = false
			toClosedSign(true, signSpinSpeed)
		elseif n < 1 and not isOpen then
			isOpen = true
			toOpenSign(true, signSpinSpeed)
		end
	end
	local filldb = false
	local function setFill(n: number)
		filldb = true
		clockSyncFill.Value = n
		filldb = false
		return
	end
	
	
	onSetDataCallbacks.ResetTime = function()
		isOpen = false
		toClosedSign(false)
		setFill(0)
		return
	end
	onSetDataCallbacks.SetTime = setFill --probably wont be used but here just in case i make changes l8r
	
	--ok now finally doing the syncer
	clockSyncFill.Changed:Connect(function(currentNum)
		if filldb then return end
		filldb = true
		--
		syncClockToFill()
		checkSignSpin(currentNum)
		--
		filldb = false
		return
	end)
	--
	
end
local function onMouseOverAudio()
	gameAction:Fire("PlayAudio", "ui_blip_light")
end
local function onClickedAudio()
	gameAction:Fire("PlayAudio", "ui_blip_medium")
end
--game pausers
do
	local function playPauseSignal(): nil
		gameAction:Fire("PauseToggle")
		onClickedAudio()
		return
	end
	local pauseButtons : { GuiButton } = {
		PlayScreen.Bottom.Main.Options.Right.Pause,
		PlayScreen.Bottom.Main.Options.Menu,
		--
		PauseScreen.Bottom.Main.Resume
	}
	for i, v in next, pauseButtons do
		v.MouseButton1Click:Connect(playPauseSignal)
		v.MouseEnter:Connect(onMouseOverAudio)
	end
	
end
--music muters
do
	local function musicSignal(): nil
		gameAction:Fire("MusicToggle")
		onClickedAudio()
		return
	end
	local musicButtons : { GuiButton } = {
		PlayScreen.Bottom.Main.Options.Right.Music,
		PauseScreen.Top.Main.Options.Music
	}
	for i, v in next, musicButtons do
		v.MouseButton1Click:Connect(musicSignal)
		v.MouseEnter:Connect(onMouseOverAudio)
	end
end
--quit buttons
do
	local function quitGame(): nil
		gameAction:Fire("Quit")
		onClickedAudio()
		return
	end
	local quitButtons : { GuiButton } = {
		PauseScreen.Top.Main.Options.Quit
	}
	for i, v in next, quitButtons do
		v.MouseButton1Click:Connect(quitGame)
		v.MouseEnter:Connect(onMouseOverAudio)
	end
end
--pause screen sub-options
do
	local subOptions: { GuiButton } = filterchildren(PauseScreen.Bottom.Main.SubOptions, "GuiButton")
	for i, v in next, subOptions do
		v.MouseButton1Click:Connect(function()
			gameAction:Fire("SubOption", v.Name)
			onClickedAudio()
		end)
		v.MouseEnter:Connect(onMouseOverAudio)
	end
end
--cancelButtons
do
	local cancelOptions: { Frame } = filterchildren(PlayScreen.Foreground.CancelButtons, "Frame")
	for i,v in next, cancelOptions do
		local btn = v:FindFirstChildWhichIsA("GuiButton") :: GuiButton
		local enabled = v:FindFirstChildWhichIsA("BoolValue") :: BoolValue
		--
		btn.MouseButton1Click:Connect(function()
			if not enabled.Value then return end
			gameAction:Fire("Cancel", v.Name)
			gameAction:Fire("PlayAudio", "bass")
		end)
		btn.MouseEnter:Connect(onMouseOverAudio)
	end
end
--play screen subscene switchers
do
	local scenes: { GuiButton } = filterchildren(PlayScreen.Bottom.Main.Scenes, "GuiButton")
	
	local function dampenButton(btn: GuiButton, c: Color3, amount: number?)
		local dampen = amount or 1 - scrConfig:GetAttribute("SceneButtonDampen") :: number
		btn.BackgroundColor3 = Color3.new(c.R*dampen, c.G*dampen, c.B*dampen)
	end
	local function darkenButtons(ignore: string)
		local dampen = 1 - scrConfig:GetAttribute("SceneButtonDampen") :: number
		for i, btn in next, scenes do
			local c : any = btn:FindFirstChildWhichIsA("Color3Value")
			c = c and c.Value :: Color3
			assert(c)
			if btn.Name == ignore then
				btn.BackgroundColor3 = c
			else
				dampenButton(btn, c, dampen)
			end
		end
	end
	
	for i, v in next, scenes do
		v.MouseButton1Click:Connect(function()
			if scrConfig:GetAttribute("CurrentScene") == v.Name or scrConfig:GetAttribute("ScenesLocked") then
				onClickedAudio()
				return
			end --essentially a debounce
			gameAction:Fire("PlayAudio", "button")
			--
			scrConfig:SetAttribute("CurrentScene", v.Name)

			--darkenButtons(v.Name)
		end)
		local c : any = v:FindFirstChildWhichIsA("Color3Value")
		c = c and c.Value :: Color3
		assert(c)
		v.MouseEnter:Connect(function()
			--onMouseOverAudio() --it was annoying me
			v.BackgroundColor3 = c
		end)
		v.MouseLeave:Connect(function()
			if scrConfig:GetAttribute("CurrentScene") == v.Name then
				dampenButton(v,c,1)
				return
			end
			dampenButton(v, c)
		end)
		v.MouseButton1Down:Connect(function()
			dampenButton(v, c, 1.25) --lightens it
		end)
	end
	scrConfig:GetAttributeChangedSignal("CurrentScene"):Connect(function() --this is separated so other scripts can change the scene without messing w/ button debounce
		local curScene = scrConfig:GetAttribute("CurrentScene")
		gameAction:Fire("SetScene", curScene, nil)
		--
		darkenButtons(curScene)
	end)
	--
	darkenButtons("Order")
end

--heartbeat funcs

--loading spinner (always on)
do
	local serverSpinner = PlayScreen.Foreground.ServerSpinner
	local img = serverSpinner.Spinner
	
	local enabled : BoolValue = serverSpinner.Enabled
	local fadeinspeed : NumberValue = serverSpinner.FadeInSpeed
	local rps : NumberValue = serverSpinner.RPS
	--
	local function incremTransparency(dt: number, enabled: boolean)
		local amount = dt * 1/fadeinspeed.Value
		if enabled then
			img.ImageTransparency = max(0, img.ImageTransparency - amount) --slowly fade in
		else
			img.ImageTransparency = min(1, img.ImageTransparency + amount) --slowly fade out
		end
		return
	end
	runsFuncs.Heartbeat.ServerSpinner = function(dt: number)
		local dr = dt * rps.Value * 360
		img.Rotation = (img.Rotation + dr) % 360
		--
		incremTransparency(dt, enabled.Value)
		return
	end
	
end
--heartbeat con
runs.Heartbeat:Connect(function(dt: number)
	local fList = runsFuncs.Heartbeat
	for i,v : (dt: number)->(...any) in next, fList do
		v(dt)
	end
	return
end)
--TODO:on setData callbacks for random stuff on da pause screen & such
