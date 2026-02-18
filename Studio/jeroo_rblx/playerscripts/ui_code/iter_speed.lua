local x = require(game.ReplicatedStorage.Jeroos.Functions)

local lastspeed = 1/3
local tb = script.Parent
tb.FocusLost:Connect(function()
	if not tonumber(tb.Text) then tb.Text = lastspeed return end
	local speed = tonumber(tb.Text)
	x.setspeed(speed)
	tb.Text = tostring(math.clamp(speed, 0, 3)):sub(1,4)
end)