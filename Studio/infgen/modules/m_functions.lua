local lp = game.Players.LocalPlayer
local rpl = game.ReplicatedStorage
local ground, grounds = rpl.Ground.Base, game.Workspace.Grounds
local walls = game.Workspace.Walls
local settings = UserSettings():GetService("UserGameSettings")
--local ceiling = game.Workspace.Roof

local funcs = {}
funcs.postocoord = function(self,pos: Vector3, opt: number)
	if typeof(pos) == 'number' and opt and typeof(opt) == 'number' then pos = Vector3.new(pos, 0 , opt) end
	local x,z = tostring(pos.X/50),tostring(pos.Z/50)
	return tonumber(x:match("%-?%d*")), tonumber((z:match("%-?%d*")))
end
funcs.coordtopos = function(self, x, z, yoffset)
	return Vector3.new(x*50,yoffset or 0, z*50)
end
funcs.graphics = function(self)
	return settings.SavedQualityLevel.Value
end
funcs.radiustoplist = function(self,radius, sx, sz)
	local x = {}
	for i = -radius, radius do
		for v = -radius, radius do
			table.insert(x, {X = i+sx, Z = v+sz})
		end
	end
	return x
end
funcs.getloadedtiles = function(self)
	local tiles = {}
	for i,v in pairs(grounds:GetChildren()) do
		local x,z = v.Name:match("^%-?%d*"), v.Name:match("%-?%d*$")
		table.insert(tiles, {Part = v, X = tonumber(x), Z = tonumber(z)})
	end
	return tiles
end
funcs.gettile = function(self, x, z)
	return grounds:FindFirstChild(string.format('%d, %d', x, z))
end

funcs.tween = function(self, inst, ti, props)
	return game:GetService("TweenService"):Create(inst, ti, props)
end
funcs.updatewalls = function(self, radius, xoff, zoff)
	radius = (radius or (self:graphics() <= 3 and 3) or self:graphics())
	local w1,w2,w3,w4 = walls:WaitForChild('1'), walls:WaitForChild('2'), walls:WaitForChild('3'), walls:WaitForChild('4')
	local tweentime, tweenoption = 0, Enum.EasingStyle.Elastic
	--[[self:tween(w1, TweenInfo.new(tweentime,tweenoption), {Position = self:coordtopos(xoff or 0, radius+(zoff or 0), 45) + Vector3.new(0,0,25)}):Play()
	self:tween(w2, TweenInfo.new(tweentime,tweenoption), {Position = self:coordtopos(xoff or 0, -radius+(zoff or 0), 45) + Vector3.new(0,0,-25)}):Play()
	self:tween(w3, TweenInfo.new(tweentime,tweenoption), {Position = self:coordtopos(radius+(xoff or 0), zoff or 0, 45) + Vector3.new(25,0,0)}):Play()
	self:tween(w4, TweenInfo.new(tweentime,tweenoption), {Position = self:coordtopos(-radius+(xoff or 0), zoff or 0, 45) + Vector3.new(-25,0,0)}):Play()
	radius += 0.5
	self:tween(w1, TweenInfo.new(tweentime, tweenoption), {Size = Vector3.new(0,100*radius, 100)}):Play()
	self:tween(w2, TweenInfo.new(tweentime, tweenoption), {Size = Vector3.new(0,100*radius, 100)}):Play()
	self:tween(w3, TweenInfo.new(tweentime, tweenoption), {Size = Vector3.new(0,100*radius, 100)}):Play()
	self:tween(w4, TweenInfo.new(tweentime, tweenoption), {Size = Vector3.new(0,100*radius, 100)}):Play()]]
	w1.Position = self:coordtopos(xoff or 0, radius+(zoff or 0), 45) + Vector3.new(0,0,25)
	w2.Position = self:coordtopos(xoff or 0, -radius+(zoff or 0), 45) + Vector3.new(0,0,-25)
	w3.Position = self:coordtopos(radius+(xoff or 0), zoff or 0, 45) + Vector3.new(25,0,0)
	w4.Position = self:coordtopos(-radius+(xoff or 0), zoff or 0, 45) + Vector3.new(-25,0,0)
	radius += 0.5
	w1.Size = Vector3.new(0,100*radius, 100)
	w2.Size = Vector3.new(0,100*radius, 100)
	w3.Size = Vector3.new(0,100*radius, 100)
	w4.Size = Vector3.new(0,100*radius, 100)
end
--[[funcs.updateceiling = function(self, radius)
	if not (lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")) then return end
	radius = (radius or (self:graphics() <= 3 and 3) or self:graphics())
	local x, z = self:coordtopos(self:postocoord(lp.Character.HumanoidRootPart.Position))
	ceiling.Position = Vector3.new(x.X, 95, x.Z)
	local side = math.sqrt(#grounds:GetChildren())*50
	ceiling.Size = Vector3.new(side, 1, side)
end]]
funcs.generate = function(self,x,z)
	if self:gettile(x,z) then return end
	local new = ground:Clone()
	--new.Color = Color3.new(math.random(),math.random(),math.random())
	new.Name = string.format('%d, %d', x, z)
	new.Parent = grounds
	new:SetPrimaryPartCFrame(CFrame.new(x*50, -1, z*50))
	new['Invis barrier'].Touched:Connect(function(part)
		if not (game.Players:GetPlayerFromCharacter(part.Parent) and (part.Position - new.PrimaryPart.Position).Magnitude <= 25 and part.Parent:FindFirstChildWhichIsA("Humanoid") and part.Parent:FindFirstChildWhichIsA("Humanoid").Health > 0) then return end
		local radius = (self:graphics() <= 3 and 3) or self:graphics()
		for d = 1, radius do
			for i,v in pairs(self:radiustoplist(d,x,z)) do
				self:generate(v.X, v.Z)
			end
		end
		for i,v in pairs(self:getloadedtiles()) do
			if (math.abs(v.X - x) > radius) or math.abs(v.Z - z) > radius then v.Part:Destroy() end
		end
		self:updatewalls(radius, x, z)
	end)
end

return funcs
