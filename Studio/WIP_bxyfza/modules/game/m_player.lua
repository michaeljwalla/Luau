--!nonstrict

--ENUM PRIORITY Enum.AnimationPriority.Action WILL BE RESERVED FOR SUBSCENE ANIMATIONS

local players = game:GetService("Players")
local lp: Player = players.LocalPlayer

local playerModule = require(lp:WaitForChild"PlayerScripts":WaitForChild("PlayerModule"))
local starter = game:GetService("StarterPlayer")

local vzero = Vector3.zero
local random = math.random

local module = {
	Instance = lp,
}

function module:GetHumanoid(): Humanoid?
	return (lp.Character :: Model):FindFirstChildOfClass("Humanoid")
end
function module:GetRoot(): (BasePart?, Humanoid?)
	local hum : Humanoid? = self:GetHumanoid()
	return hum and hum.RootPart, hum
end
function module:WalkSpeed(n: number?): Humanoid?
	local ws : number = n or starter.CharacterWalkSpeed
	local hum : Humanoid? = self:GetHumanoid()
	if hum then
		hum.WalkSpeed = ws
	end
	--
	return hum
end
function module:JumpHeight(n: number?): Humanoid?
	local jh : number = n or starter.CharacterWalkSpeed
	local hum : Humanoid? = self:GetHumanoid()
	if hum then
		hum.JumpHeight = jh
	end
	--
	return hum
end
function module:Teleport(to: CFrame | Vector3): Humanoid?
	local root : BasePart?, hum : Humanoid? = self:GetRoot()
	if not root then return hum end
	
	--reset speed
	root.AssemblyLinearVelocity = vzero
	root.AssemblyAngularVelocity = vzero
	root.CFrame = (typeof(to) == "Vector3" and CFrame.new(to)) or to :: CFrame
	return hum
end
function module:WalkTo(to: CFrame | Vector3, partRef: BasePart?, speed: number?): Humanoid?
	local hum : Humanoid? = self:WalkSpeed(speed) --set speed and grab humanoid
	if not hum then return hum end
	--
	if typeof(to) == "CFrame" then
		hum:MoveTo(to.Position, partRef)
	else--to :: Vector3
		hum:MoveTo(to, partRef)
	end
	
	return hum
end

function module:SurrenderMovement()
	playerModule.controls:Disable()
	return
end
function module:ReturnMovement()
	playerModule.controls:Enable()
	return
end

local loadedAnims : { [string]: AnimationTrack } = {}
local function getAnimator(): Animator?
	local hum : Humanoid ? = module:GetHumanoid()
	return hum and hum:FindFirstChildOfClass"Animator"
end
local function tryLoadAnimation(name: string) : (AnimationTrack?, number?)
	local animator : Animator? = getAnimator()
	if not animator then return end
	
	local anim = script:FindFirstChild(name) :: Animation
	--for dances
	if name:find("Dance") then
		if name == "Dance" then
			local dances = script.Dance:GetChildren()
			anim = dances[random(1, #dances)]
		else
			anim = script.Dance:FindFirstChild(name)
		end
	end
	local speedRange : Vector2 = anim:GetAttribute("SpeedRange")
	--
	local animTrack = loadedAnims[name] or animator:LoadAnimation(anim)
	animTrack.Priority = Enum.AnimationPriority.Action
	animTrack.Looped = false
	
	--
	loadedAnims[name] = animTrack
	return loadedAnims[name], speedRange.X + (random() * (speedRange.Y - speedRange.X))
end
function module:Emote(emote: string): boolean
	local anim : AnimationTrack?, speed: number? = tryLoadAnimation(emote)
	if not anim then return false end
	
	self:CancelEmotes()
	anim:Play()
	anim:AdjustSpeed(speed) --must be set after anim (why? idk)
	return true
end
function module:CancelEmotes(): nil
	local animator : Animator? = getAnimator()
	if not animator then return end
	
	for i,v : AnimationTrack in next, animator:GetPlayingAnimationTracks() do
		if v.Priority.Name == "Action" then v:Stop() end
	end
	return
end
return module