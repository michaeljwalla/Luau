for i,v in pairs(script.Parent:GetChildren()) do
	if v:IsA("TextButton") then
		v.MouseButton1Click:Connect(function()
			local new = v:FindFirstChild(v.Name):Clone()
			new.Parent = script:FindFirstAncestor("Frame").codearea
			new.Position = UDim2.new(0,5*(#new.Parent:GetChildren()%20),0,5*(#new.Parent:GetChildren()%20)+30*math.floor(#new.Parent:GetChildren()/10))
			new.Visible = true
		end)
	end
end