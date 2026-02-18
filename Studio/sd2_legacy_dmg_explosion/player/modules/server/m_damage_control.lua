

local bloxcount = require(script.Parent:WaitForChild("BloxTable")) --user id as key
local dmg = script:WaitForChild("DamageGui")
local debris = game:GetService("Debris")
local function getmodelhumanoid(model)
	for i,v in pairs(model:GetDescendants()) do if v:IsA("Humanoid") then return v end end
end

local chosencolor = require(game.ServerScriptService.Script.ColorChoice)

local function dealdamage(sender, reciever, damage, optcolor) --sender and reciever should always be a model
	optcolor = optcolor or chosencolor.Color
	damage = math.floor(damage)
	local splayer, rplayer = sender and game.Players:GetPlayerFromCharacter(sender), game.Players:GetPlayerFromCharacter(reciever)
	--if (splayer and rplayer) then error('bro') end
	
	local hum = getmodelhumanoid(reciever)
	if hum and hum.Health > 0 then
		local head = reciever:WaitForChild("Head", 5)
		if not head then return end
		hum.Health -= damage
		local newui = dmg:Clone()
		newui.Sender.Value = sender
		newui.Reciever.Value = reciever
		newui.Damage.Value = math.abs(damage) --ui always shows positive numbers, color determines if lost or gained hp
		if damage >= 0 then
			if splayer then --blox
				bloxcount[splayer.UserId] = (bloxcount[splayer.UserId] and bloxcount[splayer.UserId]+ math.abs(damage)) or math.abs(damage) --for awarding blox at end of round
			end
			newui.TextColor.Value = optcolor or (not rplayer and 'Orange' or 'Red') --npc orange plr red
			else do
				newui.TextColor.Value = optcolor or 'Green'
			end
		end
		newui:SetPrimaryPartCFrame(CFrame.new(head.Position))
		newui.Parent = workspace
		debris:AddItem(newui, 3)
	end
end
return dealdamage