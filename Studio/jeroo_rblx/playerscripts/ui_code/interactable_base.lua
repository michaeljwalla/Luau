local base = script:FindFirstAncestor("Jeroo")
local reservedwords = {"while", "if", "true", "false", "method", "Jeroo"}
local validname = '^[_%a][%a_%d]+'

local lasttxt = ''
script.Parent.FocusLost:Connect(function()
	script.Parent.Text = script.Parent.Text:gsub("%s", "")
	local txt = script.Parent.Text
	if not txt:match(validname) or table.find(reservedwords,txt) then script.Parent.Text = lasttxt else lasttxt = txt base.Name = 'Jeroo "'..txt..'"' end
end)