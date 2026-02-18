--!strict
local lp = game:GetService("Players").LocalPlayer
local runs = game:GetService("RunService")
--
local insert = table.insert
local abs = math.abs
local max = math.max
local inf = 1/0
local audioHelper = require("./Helper_Audios")

local c_create = coroutine.create
local c_yield = coroutine.yield
local c_close = coroutine.close
local c_resume = coroutine.resume
local c_status = coroutine.status

local wait = task.wait


local sin, cos = math.sin, math.cos
local pi = math.pi
local max = math.max
local sqrt = math.sqrt
local ceil = math.ceil

local random = math.random
local vzero = Vector3.zero
local ts = game:GetService("TweenService")

local round = math.round
--
local awaitAction : BindableEvent = script:WaitForChild("AwaitAction")
local module: {
	Info: {
		[string]: {
			[string]: {
				Await: (...any)->(any, boolean),
				CleanUp: (...any)->nil
			}
		}
	},
	Draw: {
		[string]: {
			[string]: {
				Await: (...any)->(any, boolean),
				CleanUp: (isCanceled: boolean, ...any)->nil
			}
		}
	},
	awaitInfo: (scene: string, subscene: string, gameData: any, ...any)->(...any),
	awaitDraw: (scene: string, subscene: string, gameData: any, ...any)->(...any),
	cleanInfo: (scene: string, subscene: string, gameData: any, ...any)->(any),
	cleanDraw: (scene: string, subscene: string, gameData: any, ...any)->(any),
	cancelAllAwaits: ()->(),
} = {
	Info = {},
	Draw = {},
	awaitInfo = nil::any,
	awaitDraw = nil::any,
	cleanInfo = nil::any,
	cleanDraw = nil::any,
	cancelAllAwaits = nil::any
}

local function randRange(a: number, b: number): number --a <= b
	assert(a <= b, "Minimum is greater than maximum.")
	return (b-a)*random() + a
end
local function randInt(a: number, b:number): number
	return ceil(randRange(a,b))
end
local function mergeAtoB(tA: {}, tB: {}): {}
	for i,v in next, tB do
		if tA[i] ~= nil then continue end
		tA[i] = v
	end
	return tA
end
function module.awaitInfo(scene: string, subscene: string, ...:any): ...any
	local response: any = nil
	local f = module.Info[scene] and module.Info[scene][subscene]
	assert(f, "Function not defined for: ", scene..", "..subscene)
	--
	local r, instant = f.Await(...)
	if instant then
		return r
	end
	--
	return awaitAction.Event:Wait()
end
function module.awaitDraw(scene: string, subscene: string, ...:any): ...any
	local response: any = nil
	local f = module.Draw[scene] and module.Draw[scene][subscene]
	assert(f, "Function not defined for: "..tostring(scene)..", "..tostring(subscene))
	--
	local r, instant = f.Await(...)
	if instant then
		return r
	end
	--
	return awaitAction.Event:Wait()
end
function module.cleanInfo(scene: string, subscene: string, gameData: any, ...:any): any
	local response: any = nil
	local f = module.Info[scene] and module.Info[scene][subscene]
	assert(f, "Function not defined for: ", scene..", "..subscene)
	--
	return f.CleanUp(gameData, ...)
end
function module.cleanDraw(scene: string, subscene: string, gameData: any, ...:any): any
	local response: any = nil
	local f = module.Draw[scene] and module.Draw[scene][subscene]
	assert(f, "Function not defined for: ", scene..", "..subscene)
	--
	return f.CleanUp(gameData, ...)
end
local function clearConnections(t: {[any]: RBXScriptConnection}): nil
	if not t then return end
	--
	for i,v in next, t do
		v:Disconnect()
		t[i] = nil
	end
	return
end
--build smoothie station
do
	local buildFunctions = {}
	module.Info.Build = buildFunctions
	--
	local cupTransparency = 0.5
	local cupEnableHighlight
	local function cupOnMouseClick(cup: Model)
		awaitAction:Fire(cup.Name)
		audioHelper.PlayAudio("kerplunk")
		cupEnableHighlight(cup, false)
	end
	cupEnableHighlight = function(cup: Model, toggle: boolean)
		local highlight = cup:FindFirstChild("Select") :: BasePart
		highlight.Transparency = toggle and 0.5 or 1
		return
	end
	local cupClickConnections: {[ClickDetector]: { [string]: RBXScriptConnection }} = {}
	--CupSize
	buildFunctions.CupSize = {
		Await = function(cupsUnlocked: { [string]: boolean}, cupFolder: Model): (string?, boolean)
			--
			if not (cupsUnlocked.Small or cupsUnlocked.Large) then
				return "!Medium", true --exclamation used to imply "automatic/no choice made"
			end
			--
			for cup, unlocked in next, cupsUnlocked do
					--
				local cupModel = cupFolder:WaitForChild(cup) :: Model
				local cupClick = cupModel:FindFirstChild("Select"):FindFirstChildWhichIsA("ClickDetector") :: ClickDetector
				clearConnections(cupClickConnections[cupClick])
				
				if not unlocked then
					cupClick.MaxActivationDistance = 0 --hides the visual cursor change thing
					continue
				end
				cupClick.MaxActivationDistance = 9e9
				--
				cupClickConnections[cupClick] = {
					MouseClick = cupClick.MouseClick:Once(function()
						cupOnMouseClick(cupModel)
					end),
					MouseHoverEnter = cupClick.MouseHoverEnter:Connect(function()
						cupEnableHighlight(cupModel, true)
						audioHelper.PlayAudio("button2", {
							Volume = 1/3
						})
					end),
					MouseHoverLeave = cupClick.MouseHoverLeave:Connect(function()
						cupEnableHighlight(cupModel, false)
					end)
				}
			end
			return nil, false
		end,
		CleanUp = function(cupsUnlocked: { [string]: boolean}, cupFolder: Model): nil
			for cd,cons in next, cupClickConnections do
				cd.MaxActivationDistance = 0
				clearConnections(cons)
				cupClickConnections[cd] = nil
			end
			for cup, unlocked in next, cupsUnlocked do
				local cupModel = cupFolder:WaitForChild(cup) :: Model
				cupEnableHighlight(cupModel, false)
			end
			return
		end
	}
	--FillCup
	local fillCupConnections: { [Instance]: RBXScriptConnection } = {}
	local posBarScoring = {
		StartDelay = 0.0, --arbitrary value as dispenser animation is starting
		SpeedMap = {
			Max = 2.5, --moves/sec
			Min = 0.5,
			Decrement = 0.5
		},
		Bonus = {
			Range = 0.075, --x% of area around the center to guarantee max
			Lost = {  --when the bar hits an edge after n times, bonus cannot be rewarded and points are lost
				Repeat = 5,
				ScoreLoss = 0.15,
				MinScore = 0.25
			},
			Message = {
				[2] = "AWESOME",
				[1] = "GREAT!",
				[0.5] = "GOOD!"
			},
			Forgiveness = {
				[2] = 0.15,
				[1] = 0.1,
				[0.5] = 0.05
			}
		}
	}
	local function findIndex_geq(t: {[number]: any}, n: number): number?
		local bestFit: number? = nil
		for i,_ in next, t do
			if n >= i and i > (bestFit or -inf)::number then
				bestFit = i
			end
		end
		return bestFit
	end
	--CupSize
	local addSubtr = 1
	local function incrementPosBar(cur: number, add: number): (number, boolean) --increments cur and flips it correspondingly once reaching an end
		cur += add * addSubtr
		--
		if cur > 1 then
			addSubtr = -1
			return 1 - (cur - 1), true --flips it around
		elseif cur < 0 then
			addSubtr = 1
			return abs(cur), true --flips it around
		end
		return cur, false
	end
	
	buildFunctions.FillCup = {
		Await = function(gameData: never, guisFolder: Instance, animateBonusTime: number, posBarStart: UDim2?): (string?, boolean)
			local button = guisFolder:WaitForChild("Button"):WaitForChild("Holder"):WaitForChild("ImageButton") :: ImageButton
			local positionBar = guisFolder:WaitForChild("ProgressBar"):WaitForChild("Holder"):WaitForChild("Position"):WaitForChild("Bar") :: Frame
			--reset stuff that gets changed every time its run
			positionBar.Position = posBarStart or UDim2.new() --start at zero duh
			addSubtr = 1
			--
			--Dispense button
			--progress bar vars
			local numRepeats: number, curSpeed: number
			fillCupConnections[button] = button.MouseButton1Down:Once(function() --NOT button1click we want it to be instant
				local distFromMiddle = abs(0.5 - positionBar.Position.X.Scale)
				local score = 1 - 2*distFromMiddle
				local bonusReqs = posBarScoring.Bonus
				--
				if fillCupConnections[positionBar] then --stop moving the bar
					fillCupConnections[positionBar]:Disconnect()
				end
				--no bonus
				local slowLoss = numRepeats >= bonusReqs.Lost.Repeat
				if slowLoss or distFromMiddle > bonusReqs.Range/2 then
					audioHelper.PlayAudio("kerplunk") 
					if slowLoss then
						score -= bonusReqs.Lost.ScoreLoss
					end
					--
					local minScore = bonusReqs.Lost.MinScore
					awaitAction:Fire(
						max(score, minScore), --minScore OR score - noob loss
						nil --bonusMsg (nil = no bonus)
					)
					return
				end
				--bonus gotten
				audioHelper.PlayAudio("victory")
				local bonusGivenIndex = findIndex_geq(bonusReqs.Forgiveness, curSpeed)
				assert(bonusGivenIndex, "No indices >= n")
				awaitAction:Fire(score + bonusReqs.Forgiveness[bonusGivenIndex], bonusReqs.Message[bonusGivenIndex]) --yes, forgiveness lets the score go above 100!
			end)
			
			--moves the progress bar
			numRepeats = 0
			curSpeed = posBarScoring.SpeedMap.Max
			local startTime = tick()+posBarScoring.StartDelay
			positionBar.Position = UDim2.new()
			fillCupConnections[positionBar] = runs.RenderStepped:Connect(function(dt: number)
				if tick() < startTime then return end
				local dPos = curSpeed * dt
				local newPos, didFlip = incrementPosBar(positionBar.Position.X.Scale, dPos)
				--
				if didFlip then
					numRepeats += 1
					curSpeed = max(posBarScoring.SpeedMap.Min, curSpeed - posBarScoring.SpeedMap.Decrement)
				end
				positionBar.Position = UDim2.fromScale(newPos, 0)
			end)
			return nil, false
		end,
		CleanUp = function(gameData: never): nil
			clearConnections(fillCupConnections)
			return
		end
	}
	local mixInConnections = {}
	
	buildFunctions["MixIn_Chooser"] = {
		Await = function(unlockedFlavors: {[string]:boolean}, flavorGuis: {[string]:Frame}): (string?, boolean)
			for name, enabled in next, unlockedFlavors do
				if not enabled then continue end
				local chooserBtn = flavorGuis[name]:FindFirstChildWhichIsA("ImageButton") :: ImageButton
				mixInConnections[name] = chooserBtn.MouseButton1Click:Once(function()
					audioHelper.PlayAudio("kerplunk")
					awaitAction:Fire(name)
					return
				end)
			end
			return nil, false
		end,
		CleanUp = function(gameData: never): nil
			clearConnections(mixInConnections)
			return
		end
	}
	buildFunctions["MixIn_Dispenser"] = buildFunctions.FillCup
	
	local syrupConnections: {[ClickDetector]: {RBXScriptConnection}} = {}
	
	local function syrupEnableHighlight(m: Model, enabled: boolean)
		local uiHover = m:FindFirstChild("UIHover") :: BasePart
		uiHover.Transparency = enabled and cupTransparency or 1
		return
	end
	local function syrupOnMouseClick(syrup: Model)
		awaitAction:Fire(syrup.Name)
		audioHelper.PlayAudio("kerplunk")
		syrupEnableHighlight(syrup, false)
		return
	end
	buildFunctions["Syrup_Chooser"] = {
		Await = function(unlockedSyrups: {[string]: boolean}, flavorModels: {[string]: BasePart}): (string?, boolean)
			for name,v in next, flavorModels do
				local syrupModel = v.Parent :: Model
				local uiHover = syrupModel:WaitForChild("UIHover") :: BasePart
				local worldClick = uiHover:FindFirstChildWhichIsA("ClickDetector")  :: ClickDetector
				--
				if not unlockedSyrups[name] then
					worldClick.MaxActivationDistance = 0
					uiHover.Transparency = 1
					continue
				end
				--
				worldClick.MaxActivationDistance = 9e9
				syrupConnections[worldClick] = {
					MouseClick = worldClick.MouseClick:Once(function()
						syrupOnMouseClick(syrupModel)
					end),
					MouseHoverEnter = worldClick.MouseHoverEnter:Connect(function()
						syrupEnableHighlight(syrupModel, true)
						audioHelper.PlayAudio("button2", {
							Volume = 1/3
						})
					end),
					MouseHoverLeave = worldClick.MouseHoverLeave:Connect(function()
						syrupEnableHighlight(syrupModel, false)
					end)
				}
			end
			return nil, false
		end,
		CleanUp = function(flavorModels: {[string]: BasePart}): nil
			for cd,cons in next, syrupConnections do
				cd.MaxActivationDistance = 0
				clearConnections(cons)
				cupClickConnections[cd] = nil
			end
			for name, part in next, flavorModels do
				local p: Model = part.Parent :: Model
				syrupEnableHighlight(p, false)
			end
			return
		end
	}
	buildFunctions["Syrup_Dispenser"] = buildFunctions.FillCup
end

local function primPart(m: Model) : BasePart
	return m.PrimaryPart :: BasePart
end

local function awaitDescendants(inst: Instance, numDescendants: number): (boolean, RBXScriptConnection?)
	local count = #inst:GetDescendants()
	if count == numDescendants then
		return true
	end
	--
	local con;
	con = inst.DescendantAdded:Connect(function()
		count += 1
		if count == numDescendants then
			con:Disconnect()
		end
	end)
	return false, con
end
--build draws
do
	local buildFunctions = {}
	module.Draw.Build = buildFunctions
	
	
	local function coroutine_tweenSlush(cup: Model, dispAttachment: Attachment, pourTime: number)
		pourTime /= 2 --split into 2 waits
		local pourSpreadTime = pourTime/3 -- 1/3th of time dedicated to "spreading" at the bottom

		--
		local glass = primPart(cup)
		local center, r1, r2 = glass:WaitForChild("Center") :: Attachment, glass:WaitForChild("Ratio1") :: Attachment, glass:WaitForChild("Ratio2") :: Attachment

		local startRad = abs( (center.Position - r1.Position).Z )
		local endRad = abs( (center.Position - r2.Position).Z )
		--
		local startHeight = 0
		local endHeight = abs( (r2.Position - r1.Position).Y )
		--
		local slush = cup:WaitForChild("Slush") :: Model
		local slushMain = primPart(slush)
		local slushTop = slush:WaitForChild("Top") :: BasePart
		local slushPour = slush:WaitForChild("Pour") :: BasePart
		local slushResizeMult = 0.95
		--start size/pos
		slushMain.Size = Vector3.new(startRad*2, startHeight, startRad * 2)
		slushTop.Size = Vector3.new(0.05, startRad*2 * slushResizeMult, startRad * 2 * slushResizeMult) --constant height (which is x axis bc rotated)
		--
		slushMain.Position = center.WorldPosition
		slushTop.Position = slushMain.Position + Vector3.new(0, startHeight/2, 0)

		--animate pour first
		slushPour.Transparency = 0
		slushPour.Position = dispAttachment.WorldPosition

		local pour_dy = (center.WorldPosition - dispAttachment.WorldPosition).Y
		local pour_r = slushPour.Size.Y


		--delay to "hit" bottom of cup
		local tweens = {}
		tweens.Pour_Start = ts:Create(
			slushPour,
			TweenInfo.new(pourTime - pourSpreadTime, Enum.EasingStyle.Linear),
			{
				Position = slushPour.Position + Vector3.new(0, pour_dy/2, 0),
				Size = Vector3.new(abs(pour_dy), pour_r, pour_r)
			}
		)


		tweens.Pour_Start:Play()
		c_yield(pourTime - pourSpreadTime, tweens) --gives waitTime back, runs above




		--widen with splash
		slushMain.Transparency = 0
		slushTop.Transparency = 0

		do
			local startMain, startTop = Vector3.new(pour_r, 0.05, pour_r), Vector3.new(0.05, pour_r, pour_r)
			local endMain, endTop = slushMain.Size, slushTop.Size
			--
			slushMain.Size = startMain
			slushTop.Size = startTop

			tweens.Spread_Main = ts:Create(
				slushMain,
				TweenInfo.new(pourSpreadTime, Enum.EasingStyle.Linear),
				{
					Size = endMain
				}
			)

			tweens.Spread_Top = ts:Create(
				slushTop,
				TweenInfo.new(pourSpreadTime, Enum.EasingStyle.Linear),
				{
					Size = endTop
				}
			)
		end
		tweens.Spread_Main:Play()
		tweens.Spread_Top:Play()
		c_yield(pourSpreadTime, tweens) --gives waitTime back, runs above


		--fill
		tweens.Fill_Main = ts:Create(
			slushMain,
			TweenInfo.new(pourTime, Enum.EasingStyle.Linear),
			{
				Size = Vector3.new(endRad * 2, endHeight, endRad * 2),
				Position = slushMain.Position + Vector3.new(0, endHeight/2)
			}	
		)
		tweens.Fill_Top = ts:Create(
			slushTop,
			TweenInfo.new(pourTime, Enum.EasingStyle.Linear),
			{
				Size = Vector3.new(0.05, endRad*2* slushResizeMult, endRad*2* slushResizeMult),
				Position = slushTop.Position + Vector3.new(0, endHeight - slushTop.Size.X)
			}	
		)
		--end pour
		tweens.Pour_End = ts:Create(
			slushPour,
			TweenInfo.new(pourTime, Enum.EasingStyle.Linear),
			{
				Position = slushPour.Position + Vector3.new(0, pour_dy/2, 0),
				Size = Vector3.new(0, slushPour.Size.Y, slushPour.Size.Z)
			}
		)

		tweens.Pour_End:Play()
		tweens.Fill_Main:Play()
		tweens.Fill_Top:Play()
		c_yield(pourTime, tweens) --gives waitTime back, runs above
		
		slushPour:Destroy()
		return
	end
	
	local fillCupOptions = {
		AnimTime = {
			Small = 1,
			Medium = 1,
			Large = 1
		}
	}
	
	local fillCup_coData: {
		Tweens: { [string]: Tween },
		Thread: thread?
	} = { --thread : thread and pcall to close it in Await and CleanUp. then test after 
		Tweens = {},
		Thread = nil
	}
	buildFunctions.FillCup = {
		Await = function(data: {
			Cup: Model,
			PourAttachment: Attachment,
			AnimTime: number?})
			--
			pcall(c_close, fillCup_coData.Thread :: thread)
			local thread = c_create(coroutine_tweenSlush)
			fillCup_coData.Thread = thread
			
			local cup, pourAttachment = data.Cup, data.PourAttachment
			local animTime = data.AnimTime or fillCupOptions.AnimTime[(cup:WaitForChild("Size") :: StringValue).Value]
			--
			spawn(function()
				while c_status(thread) ~= "dead" do
					local success, nextWaitTime, curTweens = assert(
						c_resume(
							thread,
							cup,
							pourAttachment,
							animTime or fillCupOptions.AnimTime)
					)
					
					if curTweens then
					 	fillCup_coData.Tweens = curTweens
						wait(nextWaitTime)
					end
				end
				awaitAction:Fire()
			end)
			
			return nil, false --has to be spawn()d because .Await needs to immediately return a value AND if false then it yields.
		end,
		CleanUp = function(cup: Model)
			cup = cup:FindFirstChild("Cup") :: Model
			local slush = cup:FindFirstChild("Slush") :: Model
			--
			if fillCup_coData.Thread then
				c_close(fillCup_coData.Thread)
			end
			--
			if slush:FindFirstChild"Pour" then
				slush:FindFirstChild("Pour"):Destroy()
			end
			for i,v: Tween in next, fillCup_coData.Tweens do
				v:Cancel()
			end
			--
			fillCup_coData = {
				Tweens = {}	
			}
			return
		end,
	}
	
	local flavors = workspace.DrinkParts.MixIns
	local function lerp(a: number,b: number,p: number): number
		return a + (b-a) * p
	end
	local function randAngles(max: number)
		return CFrame.Angles(
			(2 * random() - 1) * max,
			(2 * random() - 1) * max,
			(2 * random() - 1) * max
		)
	end
	local function randVec(radius: number)
		return radius * Vector3.new(
			random() - 0.5,
			random() - 0.5,
			random() - 0.5
		).Unit
	end
	local function randVecXZ(radius: number)
		return radius * Vector3.new(
			cos(2*pi*random()),
			0,
			sin(2*pi*random())
		)
	end
	--

	local mixInTweenAdjustTime = 0.1
	local function coroutine_tweenMixIn(data:{
		Cup: Model,
		PourAttachment: Attachment,
		Flavor: string,
		Revolutions: number,
		AnimTime: number,
		CountOverride: number?
		})
		--
		local revolutions = data.Revolutions
		local cup, pourTime = data.Cup, data.AnimTime
		local pourAttachment = data.PourAttachment
		--
		local glass = primPart(cup)
		local center, r1, r2 = glass:WaitForChild("Center") :: Attachment, glass:WaitForChild("Ratio1") :: Attachment, glass:WaitForChild("Ratio2") :: Attachment


		--
		local mixin = (flavors:WaitForChild(data.Flavor) :: Model):Clone()
		mixin.Name = "MixIn"
		mixin.Parent = cup
		--
		local base = mixin:WaitForChild("Part") :: BasePart
		;(base:WaitForChild("MainWeld") :: WeldConstraint).Part1 = glass
		base.Parent = nil

		local count = data.CountOverride or (mixin:WaitForChild("Count") :: IntValue).Value
		local colors = mixin:WaitForChild("Colors"):GetChildren()

		--delay to "hit" bottom of cup

		local tweenCenter = Vector3.new(
			center.WorldPosition.X,
			r2.WorldPosition.Y,
			center.WorldPosition.Z
		)
		local dxz_max = 0.95 * 0.5 * (glass.Size.Z - base.Size.Magnitude) --80% of radius for potential err
		local dy_fall = pourAttachment.WorldPosition.Y - tweenCenter.Y
		local dt_fall = sqrt(2 * dy_fall / workspace.Gravity) --derived from dy = vt + 1/2at^2
		local tweens = {}

		local pourSize = dxz_max/2
		--places the parts in a cirlce then welds them to the cup
		pourTime = max( (pourTime - mixInTweenAdjustTime)/count , 0)
		for i = 1, count do
			local newParticle = base:Clone()
			newParticle.Color = (colors[ceil(random() * #colors)] :: Color3Value).Value
			newParticle.AssemblyLinearVelocity = vzero
			newParticle.CFrame = CFrame.new(pourAttachment.WorldPosition + randVecXZ(pourSize))
				* randAngles(pi/2) --offset rotation
				
			newParticle.Transparency = 0 --jsut in case
			newParticle.Parent = mixin

			local weld = newParticle:WaitForChild("MainWeld") :: WeldConstraint
			weld.Enabled = false
			--
			local curRadian = 2*pi*(i/count)*revolutions 
			--
			local randRot = randVec(pi/4)
			local tween = ts:Create( --tween to a circle of radius i/count to make a spiral.
				newParticle,
				TweenInfo.new(mixInTweenAdjustTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{
					CFrame = CFrame.new( tweenCenter + Vector3.new(
							i/count * dxz_max * cos(curRadian),
							0,
							i/count * dxz_max * sin(curRadian)
						)) * randAngles(pi/8)
				}
			)
			--
			
			--cant tween cframe if welded, so anchor in place first
			
			delay(dt_fall, function()
				--weld it now to cup primary part to stop physics
				newParticle.Anchored = true
				newParticle.AssemblyLinearVelocity = vzero
				--
				tweens[i] = tween
				tween:Play()
			end)
			
			--unanchor to allow whole model to move
			delay(dt_fall+mixInTweenAdjustTime, function()
				newParticle.Anchored = false
				weld.Enabled = true
			end)

			c_yield(pourTime, tweens) --let it fall

			continue
		end
		c_yield(dt_fall + mixInTweenAdjustTime, tweens) --this is for the last particle
		print("Done")
		return
	end
	
	local mixIn_coData: {
		Tweens: { [string]: Tween },
		Thread: thread?
	} = { --thread : thread and pcall to close it in Await and CleanUp. then test after 
		Tweens = {},
		Thread = nil
	}
	
	local mixInOptions = {
		AnimTime = {
			Small = 1,
			Medium = 1,
			Large = 1
		},
		Revolutions = {1.5, 5},
		DropCount = {
			Small = {4, 8},
			Medium = {7, 14},
			Large = {10, 20}
		}
	}
	buildFunctions.MixIn = {
		Await = function(data:{
			Cup: Model,
			PourAttachment: Attachment,
			Flavor: string,
			Score: number,
			AnimTime: number?
			})
			--
			
			local size = (data.Cup:WaitForChild("Size") :: StringValue).Value
			local animTime = data.AnimTime or mixInOptions.AnimTime[size]
			local revs = randRange(unpack(mixInOptions.Revolutions))
			local count = round(lerp(
				mixInOptions.DropCount[size][1],
				mixInOptions.DropCount[size][2],
				data.Score
				))
			
			
			local newData = mergeAtoB(data, {
				Revolutions =  revs,
				AnimTime =  animTime,
				CountOverride = count
			})
			
			pcall(c_close, mixIn_coData.Thread :: thread)
			local thread = c_create(coroutine_tweenMixIn)
			mixIn_coData.Thread = thread

			--
			spawn(function()
				while c_status(thread) ~= "dead" do
					local success, nextWaitTime, curTweens = assert(c_resume(thread, newData))

					if curTweens then
						mixIn_coData.Tweens = curTweens
						wait(nextWaitTime)
					end
				end
				awaitAction:Fire()
			end)

			return nil, false --has to be spawn()d because .Await needs to immediately return a value AND if false then it yields.
		end,
		CleanUp = function()
			if mixIn_coData.Thread then
				c_close(mixIn_coData.Thread)
			end
			--
			for i,v: Tween in next, mixIn_coData.Tweens do
				if v.Instance and (v.Instance :: BasePart).Anchored then --it is anchored while tweening
					v.Instance:Destroy()
				end
				v:Cancel()
			end
			--
			mixIn_coData = {
				Tweens = {}	
			}
		end,
	}
end
return module
