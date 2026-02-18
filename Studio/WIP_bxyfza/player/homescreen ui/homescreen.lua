local gui = script.Parent
local readyEvent = script.Ready

--use UIanimator to tween
--this is  a placeholder rn
local playGui = gui.Play
playGui.Background.Bottom.Indent.Play.MouseButton1Click:Connect(function()
	readyEvent:Fire()
end)