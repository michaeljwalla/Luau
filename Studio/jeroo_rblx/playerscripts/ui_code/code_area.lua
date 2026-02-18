--[[

notes
everything must have a {}Back button! prevents inputting to multiple frames
everything must have a {}Top frame
{}Body for nesting statements e.g. while, if, method creators
{}Bottom for method creators


]]
local drag = require(game.ReplicatedStorage.drag)
local selected
local function resetselectborder()
	for i,v in pairs(script.Parent:GetDescendants()) do
		if v:IsA("GuiObject") then v.BorderColor3 = Color3.fromRGB(27, 42, 53) end
	end
end
local uis = game:GetService("UserInputService")
local nonesting = {'MethodConstructor'}
local function dragstuff(obj)
	obj = obj:WaitForChild("{}Back")
	if drag(obj, script.Parent) then return end --prevent memory buildup from dupe connections
	local parent = obj.Parent
	obj.MouseButton1Down:Connect(function() --select
		if uis:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		resetselectborder()
		selected = parent
		obj.BorderColor3 = Color3.fromRGB(13,155,255)
	end)
	obj.MouseButton2Click:Connect(function() --pop
		selected = parent
		resetselectborder()
		if parent.Parent then 
			if parent.Parent.Name ~= 'codearea' then
				local pos = parent.AbsolutePosition
				local replace = parent.Parent.Parent.Parent
				parent.Parent = parent:FindFirstAncestor('codearea')
				parent.Position = UDim2.fromOffset(pos.X,pos.Y) - UDim2.fromOffset(replace.AbsolutePosition.X,replace.AbsolutePosition.Y)
				selected:WaitForChild("{}Back").BorderSizePixel = 1
				obj.BorderColor3 = Color3.new(0,1,0)
				task.wait(0.5)
				obj.BorderColor3 = (selected == obj and Color3.fromRGB(13,155,255)) or Color3.fromRGB(27,42,53)
			else do
					obj.BorderColor3 = Color3.new(1,0,0)
					task.wait(0.5)
					obj.BorderColor3 = (selected == obj and Color3.fromRGB(13,155,255)) or Color3.fromRGB(27,42,53)
				end
			end
		end
	end)
	obj.MouseButton1Click:Connect(function()
		if not selected then return end
		if table.find(nonesting, selected.Class.Value) then return end
		if selected ~= parent and uis:IsKeyDown(Enum.KeyCode.LeftControl) then
			local body = parent:FindFirstChild("{}Body")
			if body then
				selected.Parent = body
				selected:WaitForChild("{}Back").BorderSizePixel = 0
			end
			
		end
	end)
	local conclick = parent:FindFirstChild("{}ConditionClick")
	if conclick then
		conclick.MouseButton1Click:Connect(function()
			if not selected then return end
			if selected.Class.Value ~= 'BoolMethod' or not(uis:IsKeyDown(Enum.KeyCode.LeftControl)) then return end
			if not conclick:FindFirstChildWhichIsA("GuiObject") and selected ~= parent and uis:IsKeyDown(Enum.KeyCode.LeftControl) then
				selected.Parent = conclick
				selected.Position = UDim2.new()
				selected:WaitForChild("{}Back").BorderSizePixel = 0
			end
		end)
	end
	
end
uis.InputBegan:Connect(function(inpt, chat)
	if not (selected and not chat and inpt.KeyCode == Enum.KeyCode.Delete) then return end
	if selected.Parent then selected:Destroy() selected = nil end
end)
script.Parent.ChildAdded:Connect(dragstuff)