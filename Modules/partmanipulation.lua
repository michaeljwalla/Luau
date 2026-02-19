local ts = game:GetService("TweenService")
local sin, cos, pi, csc, sec, cot = math.sin, math.cos, math.pi, nil, nil, nil
csc = function(theta) return 1/sin(theta) end
sec = function(theta) return 1/cos(theta) end
cot = function(theta) return cos(theta)/sin(theta) end

local spawn = task.spawn
local module = {}
module.__index = module
module.Parts = {}

local function getdegreefromobj(obj, rps)
	return (((rps or obj.RPS) * tick()) % 1) * 360
end

local fenv = getfenv()
local deffenv = setmetatable({
	degreeAtRPS = function(n) return getdegreefromobj(nil, n) end,
	torad = pi/180,
	tau = 2 * pi,
	csc = csc,
	sec = sec,
	cot = cot,
}, {
	__index = function(self, index)
		return fenv[index] or math[index] or task[index]
	end
})
local zero = Vector3.zero
function module.updatefenv(f) setfenv(f, deffenv) end
local maxforce = Vector3.one * 100000
function module.register(part, data, suppresserror)
	assert(suppresserror or (part:IsA"BasePart" and not (part.Anchored or part:IsGrounded())), "Registers must be BaseParts that are neither anchored nor grounded.") --your job to check network ownership
	local new = setmetatable({
		RPS = tonumber(data.rps) or 1,
		Part = part,
		Radius = tonumber(data.radius) or 5,
		BodyPos = data.method ~= 'tweening' and Instance.new"BodyPosition",
		Mode = data.mode,
		Offset = typeof(data.offset) == 'Vector3' and data.offset or zero,
		__unreg = data.unregister
	}, module)

	if data.mode ~= 'tweening' then
		new.BodyPos.D = tonumber(data.d) or 500
		new.BodyPos.P = tonumber(data.p) or 150000
		new.MaxForce = maxforce
		new.BodyPos.Parent = part
	end
	
	local method = data.method
	if type(method) == 'function' then
		module.updatefenv(method, deffenv)
		module.Parts[new] = method
	else
		module.Parts[new] = module.Parts[method] or error("No valid method specified (expected function or registered BasePart)")
	end
	if data.setup then module.updatefenv(data.setup, deffenv) spawn(data.setup, new, getdegreefromobj(new)) end --assign bodypos and remove bodyvel
	return new
end

local deftinfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
local tweenpos = {}
function module:update(origin, skipoffset, ...)
	assert(self, "Expected namecall when calling update()")
	
	local offset = (skipoffset and zero) or module.Parts[self](self, getdegreefromobj(self), ...) + self.Offset
	
	if self.Mode == 'normal' then
		self.BodyPos.Position = origin + offset
	elseif self.Mode == 'tweening' then
		tweenpos.Position = origin + offset
		self.Part.Velocity = zero
		ts:Create(self.Part, deftinfo, tweenpos):Play()
	elseif self.Mode == 'tp' then
		self.Part.Velocity = zero
		self.Part.Position = origin + offset
	end
	return offset
end
function module:nextupdate(origin, ...)
	assert(self, "Expected namecall when calling nextoffset()")
	return origin + module.Parts[self](self, getdegreefromobj(self), ...) + self.Offset
end
function module:unregister()
	assert(self, "Expected namecall when calling remove()")
	rawset(self.Parts, self.Part, nil)
	if self.__unreg then self:__unreg() end
end
return module