local debris = game:GetService("Debris")
local ts = game:GetService("TweenService")
local lp = game.Players.LocalPlayer
local maketext = require(game.ReplicatedStorage.MakeText)
local control = game:GetService("ReplicatedStorage"):WaitForChild("Control")
local function renderexplosion(bomb, position)
	local size = (typeof(bomb) == 'number' and bomb * 2) or bomb.BlastRadius * 2
	position = position and ((typeof(position) == 'Vector3' and CFrame.new(position)) or (typeof(bomb) == 'Instance' and CFrame.new(bomb.Position))) or CFrame.new(0,0,0)
	local model, lifetime = script:WaitForChild('ExplosionSmoke'):Clone(), (size/2)/33
	for i,v in pairs(model:GetChildren()) do v.Size *= size end
	model:SetPrimaryPartCFrame(position)
	model.Parent = workspace
	debris:AddItem(model, lifetime)
	ts:Create(model.Smoke, TweenInfo.new(lifetime, Enum.EasingStyle.Linear), {Orientation = model.Smoke.Orientation + Vector3.new(0,15*lifetime, 0)}):Play()
	task.wait(lifetime/2)
	for i,v in pairs(model:GetChildren()) do
		ts:Create(v, TweenInfo.new(lifetime/2, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
	end
end
control.OnClientEvent:Connect(function(call, ...)
	print(call)
	local args = {...}
	if call == 'Explode' then
		renderexplosion(args[1], args[2])
	end
end)
workspace.ChildAdded:Connect(function(child)
	--bomb effect
	if child:IsA("Explosion") and child.BlastRadius > 5 then
		renderexplosion(child)
		
	--damage effect
	else if child.Name == 'DamageGui' then
			local front,shadow = child:WaitForChild("Float"):WaitForChild("Damaged"):WaitForChild("Frame"):WaitForChild("Front"), child.Float.Damaged.Frame:WaitForChild("Shadow")
			local sender,reciever,color, damage = child:WaitForChild("Sender").Value, child:WaitForChild("Reciever").Value, child:WaitForChild("TextColor").Value, child:WaitForChild("Damage").Value
			
			front.Text, shadow.Text = damage, damage
			maketext(front,front.Text, color, not ((sender == lp) or (reciever == lp)))
			maketext(shadow,shadow.Text, "Black", not ((sender == lp) or (reciever == lp)))
			for i,v in pairs(front.Parent:GetChildren()) do
				local resize = 0
				for _, x in pairs(v:GetChildren()) do
					resize = resize + x.Size.X.Offset
				end
				v.Size = UDim2.new(0,resize,0,20)
				v.Position = UDim2.new(0.5,-v.Size.X.Offset/2, 0.5, -9 - i)
			end
			ts:Create(front.Parent, TweenInfo.new(1, Enum.EasingStyle.Linear), {Position = UDim2.new(0,0, 0, -35)}):Play()
			front.Parent.Visible = true
			task.wait(0.5)
			for i,v in pairs(front.Parent:GetDescendants()) do
				if v:IsA("ImageLabel") then 
					ts:Create(v, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {ImageTransparency = 1}):Play() 
				end
			end
		end
	end
end)