local debris = game:GetService("Debris")
local deletes = {}
game:GetService("Players").PlayerAdded:Connect(function(p)
	p.Chatted:Connect(function(msg)
		msg = msg:split" "
		if msg[1] == 'b' then
			task.wait(3)
			for i = 1, tonumber(msg[2]) do
				local new = script.Ball:Clone()
				task.delay(1, function() new.Touched:Connect(function(contact) new:Destroy() end) end)
				new.BodyVelocity.Velocity = Vector3.new(math.random()-0.5,math.random()-0.5,math.random()-0.5).Unit * 15
				deletes[new] = tick() + 60
				new.Parent = workspace
				new:SetNetworkOwner(p)
				
			end
		elseif msg[1] == 'c' then
			for i,v in next, workspace:GetChildren() do if v.Name == 'Ball' then v:Destroy() end end
		end
	end)
end)
game["Run Service"].Heartbeat:Connect(function()
	local time = tick()
	for i,v in next, deletes do
		if time > v then i:Destroy() rawset(deletes, i, nil) end
	end
end)