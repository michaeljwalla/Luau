local funcs = require(game.ReplicatedStorage.Functions)
local text = script.Parent
local debounce
script.Parent.Load.MouseButton1Click:Connect(function()
	if debounce or funcs.coderunning() then return end
	debounce = true
	funcs.genmap(script.Parent.Text)
	task.wait(1)
	debounce = false
end)
script.Parent.Sync.MouseButton1Click:Connect(function()
	if debounce or funcs.coderunning() then return end
	debounce = true
	funcs.maptotext(script.Parent)
	task.wait(1)
	debounce = false
end)