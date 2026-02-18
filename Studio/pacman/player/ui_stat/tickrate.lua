local changeTPS: BindableEvent = game:GetService("ReplicatedStorage"):WaitForChild("ChangeTPS") :: BindableEvent

local text: TextBox = script.Parent :: TextBox
local lastTPS: number = 8
local function onFocused(): nil
end
local function onUnfocused(): nil
	lastTPS = tonumber(text.Text) or lastTPS
	text.Text = ("TPS: %d"):format(lastTPS)
	text.PlaceholderText = text.Text
	changeTPS:Fire(lastTPS)
end
text.Focused:Connect(onFocused)
text.FocusLost:Connect(onUnfocused)