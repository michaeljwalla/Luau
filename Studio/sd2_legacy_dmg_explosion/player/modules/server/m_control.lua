local control = game:GetService("ReplicatedStorage"):WaitForChild("Control")
local damage = require(game.ServerStorage:WaitForChild("DamageControl"))
local functions = {}

functions.Explode = function(size, pos, nokill)
	if nokill then
		control:FireAllClients('Explode', size, pos)
		else do
			local new = Instance.new("Explosion")
			new.BlastRadius = size
			new.Position = pos
			if size > 100 then warn("Explosion radius caps at 100 - Control Module") end
			new.DestroyJointRadiusPercent = 0.8 --inner circle insta kill
			new.Hit:Connect(function(part)
				local hum = part.Name == 'HumanoidRootPart' and part.Parent:FindFirstChildWhichIsA("Humanoid") --would fire for every limb without (bad)
				if hum then
					local losthp = 100
					local percent = (part.Position - pos).Magnitude/size
					if percent <= 0.8 then damage(nil, part.Parent, 100) return end
					if percent >= 1 then return end
					--print(percent, ((1-percent)/0.2))
					damage(nil, part.Parent, 100 * (1-percent)/0.2)
				end
			end)
			new.Parent = workspace
		end
	end
end

return functions