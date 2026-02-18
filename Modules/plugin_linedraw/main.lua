
local uis = game:GetService("UserInputService")

local enabled = false

plugin:Activate(false)
local mouse = plugin:GetMouse()

local thisPlugin = script.Parent
local insert = table.insert


local toolbar = plugin:CreateToolbar("Line Maker")
local pluginButton = toolbar:CreateButton(
	"Lines, Paths, Curves",
	"Click to draw lines in the 3D world",
	"") --Button iconds
local info = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float, --From what side gui appears
	false, --Widget will be initially enabled
	false, --Don't overdrive previouse enabled state
	500, --default width
	250, --default height
	250, --minimum width (optional)
	125 --minimum height (optional)
)
local infoGuiWidget : ScreenGui = plugin:CreateDockWidgetPluginGui(
	"InformationGui", --A unique and consistent identifier used to storing the widget’s dock state and other internal details
	info --dock widget info
)
local mainHolder = thisPlugin.MainHolder
mainHolder.Parent = infoGuiWidget

local lctrl, rctrl = Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl

local function isctrld()
	return uis:IsKeyDown(lctrl) or uis:IsKeyDown(rctrl)
end


local function toggleGui(toggle: boolean)
	infoGuiWidget.Enabled = toggle
end

local defaultpart = Instance.new("Part")
defaultpart.Anchored = true
defaultpart.Size = Vector3.one

local attrs = {"Link", "Segments", "Divisions"}

local function attrIfNot(inst, k, v)
	if inst:GetAttribute(k) == nil then
		inst:SetAttribute(k,v)
	end
	return
end
local function tryDefaultAttr(inst)
	for i,v in next, attrs do
		attrIfNot(inst,v,-1)
	end
end
tryDefaultAttr(defaultpart)

Instance.new("Model", defaultpart).Name = "Path"
Instance.new("Model", defaultpart).Name = "Bezier"

--intvalues for dragging (to 'remember' what curve the point is on)

local function clearChildType(inst, t)
	for i,v in next, inst:GetChildren() do
		if v:IsA(t) then v:Destroy() end
	end	
	return
end
--
local linefolder, points = nil, {}

local function drawLine(a: Vector3, b:Vector3, name: string, parent: Instance?): BasePart
	local new = defaultpart:Clone()
	local diff = b - a
	
	new.Size = Vector3.new(defaultpart.Size.X, defaultpart.Size.Y, diff.Magnitude == 0 and defaultpart.Size.Z or diff.Magnitude)
	
	new.CFrame = a == b and CFrame.new(a) or CFrame.new(a + diff*0.5, b)
	new.Name = tostring(name)
	new.Parent = parent or linefolder
	
	return new
end

local previewBezier = false
local bezierColors = {Color3.new(1),Color3.new(0,1)} --alternates to show
local bezierDivisions = 5
local bezierSegments = 3 -- 2; + 1 added in debug

local bezFlipHelp = false
local function drawAllLines()
	if not points then return end
	
	local len = #points
	
	local bezierCounter = 0
	bezFlipHelp = false --reset
	for i = 2, len do
		local newLine = drawLine(points[i-1], points[i], (i-1).."-"..i)
		
		
		if previewBezier then
			newLine.Color = bezierColors[bezFlipHelp and 1 or 2]
			--
			bezierCounter = (bezierCounter+1) % (bezierSegments-1)
			if bezierCounter == 0 then bezFlipHelp = not bezFlipHelp end --flip color
		end
		
	end
	linefolder.Name = "Line"
end
local newfolder = Instance.new("Model")
newfolder.Name = "Line"

local function clearOldLines()
	if not linefolder then return end
	linefolder:ClearAllChildren()
end
local function setupFolder(toggle: boolean)
	if not toggle then return #points < 2 and linefolder:Destroy() end
	points = {}
	linefolder = newfolder:Clone()
	linefolder.Parent = workspace
end

pluginButton.Click:Connect(function()
	enabled = not enabled
	
	plugin:Activate(enabled)
	toggleGui(enabled)
	setupFolder(enabled)
end)


--for pathify---------------------------------------------------------------------
local rand = Random.new()
local function lerp(a,b,p)
	return a + (b-a)*p
end
local function randRange(a,b)
	if not b then
		a,b = -a, a
	end
	return lerp(a,b, rand:NextNumber())
end
local toRad = math.pi/180
local min = math.min
local clamp = math.clamp
local function fixNumber(box, lower, upper, sub)
	box.Text = tostring(
		clamp(
			tonumber(box.Text) or sub or 0,
			lower or 0, upper or 1/0
		)
	) --
end
local function invertC3(c3: Color3): Color3
	return Color3.new(1-c3.R, 1-c3.G, 1-c3.B)
end
local white, black = Color3.new(1,1,1), Color3.new()

local function C3toBW(c3: Color3, threshold: number?): Color3
	local grayscale = (c3.R + c3.G + c3.B) / 3
	--
	return grayscale < (threshold or 0.5) and black or white
end
local pathify = mainHolder.Pathify
local colors = pathify.Right.Colors
local colContainer = colors.ScrollingFrame
local addColBtn = colors.Colors.Go
local colTemplate = addColBtn.Template
do
	
	local left : ScrollingFrame = pathify.Left.ScrollingFrame
	
	
	local r,g,b = colors.Colors.R, colors.Colors.G, colors.Colors.B
	
	
	local function updateTestColor()
		local newCol = Color3.fromRGB(
			tonumber(r.Text) or 0,
			tonumber(g.Text) or 0,
			tonumber(b.Text) or 0
		)
		addColBtn.BackgroundColor3 = newCol
		addColBtn.TextColor3 = invertC3( C3toBW(newCol, 0.5) ) --changes white/black depending on color
	end
	for i,v in next, left:GetChildren() do
		for _,ui in next, v:GetChildren() do
			if not ui:IsA"TextBox" then continue end
			
			if v.Name == "Rotate" then
				ui.FocusLost:Connect(function()
					fixNumber(ui, -180, 180)
				end)
			else
				ui.FocusLost:Connect(function()
					fixNumber(ui, nil, nil, ui.PlaceholderText)
				end)
			end
			
			
		end
	end
	for _, ui in colors.Colors:GetChildren() do
		if not ui:IsA"TextBox" then continue end
		
		ui.FocusLost:Connect(function()
			fixNumber(ui, 0, 255)
			updateTestColor()
		end)
	end
		
	
	addColBtn.MouseButton1Click:Connect(function()
		local newCol = colTemplate:Clone()
		newCol.BackgroundColor3 = addColBtn.BackgroundColor3
		newCol.Color.TextColor3 = invertC3( C3toBW(addColBtn.BackgroundColor3, 0.5) )
		newCol.Color.Text = ("%d, %d, %d"):format(tonumber(r.Text) or 0, tonumber(g.Text) or 0, tonumber(b.Text) or 0)
		newCol.Name = "COLOR"
		
		newCol.Color.MouseButton1Click:Connect(function()
			newCol:Destroy()
		end)
		newCol.Frequency.FocusLost:Connect(function()
			fixNumber(newCol.Frequency, nil, nil, 1)
		end)
		newCol.Visible = true
		newCol.Parent = colContainer
	end)
	
	local plank = Instance.new("Part")
	plank.Anchored = true
	plank.Name = "Plank"
	
	--algo:
	--find the 'weight' of each color, REassign it into a list with the summed weight
	--as each color is added, the sum increases
	--	Red,1 ; Blue, 2; Green, 1 | Sum 0 then add prev weight
	--  Red,0 ; Blue, 1; Green, 3 | Sum 4
	--pick random number between 0 and Sum
	--iterate from start of list and find when Weight > Sum
	--pick the color BEFORE trigger^ as this is where the number fell
	-- rand(0,4) -> 2.333
	-- [0 < 2, 1 < 2, 3 > 2🍎] -> 1 spot before Green(3) => Blue
	--O(n) time and memory complexity
	
	

	local function fetchColors(): ({{any}}, number)
		local sum = 0
		local colors = {}
		for i,v in next, colContainer:GetChildren() do
			if v.Name ~= "COLOR" then continue end
			local toAdd = tonumber(v.Frequency.Text) or 0
			local colorParse = Color3.fromRGB( unpack(v.Color.Text:split", ") ) --"n, n, n" -> Color3
			insert(colors, { colorParse, sum })
			sum += toAdd
		end
		return colors, sum
	end
	local function getRandomColor()
		local colors, sum = fetchColors()
		if sum == 0 then
			return defaultpart.Color
		end
		
		local choice = rand:NextNumber() * sum
		for i = 0, #colors-1 do
			local nextData = colors[i+1]
			if choice < nextData[2] then
				return colors[i][1]
			end
		end
		return colors[#colors][1] --just in case
		
	end
	local function pathifyPart(part: BasePart, axis: Vector3) -- ex (0,0,1) -> forwards. (0,-1,0) -> under | (0, 0, 0.5) -> stop halfway, forwards
		local len = part.Size.Z
		local orient = part.CFrame.LookVector
		local l,w,h = tonumber(left.Length.TextBox.Text), tonumber(left.Width.TextBox.Text), tonumber(left.Thickness.TextBox.Text)
		local gap = tonumber(left.Gap.TextBox.Text)
		
		local _start = part.CFrame - orient*len/2
		local _end = part.CFrame + orient*len/2
		
		local rx,ry,rz = toRad * left.Rotate.X.Text, toRad *  left.Rotate.Y.Text, toRad * left.Rotate.Z.Text
		--plank maker
		for i = 0, len, w + gap do
			
			--part
			local newPlank = plank:Clone()
			newPlank.CFrame = _start:Lerp(_end, i/len)
			newPlank.Size = Vector3.new( l,h,w )
			
			--looks
			newPlank.Color = getRandomColor()
			newPlank.Material = defaultpart.Material
			newPlank.CFrame *= CFrame.Angles(
				randRange(rx),
				randRange(ry),
				randRange(rz)
			)
			newPlank.Parent = part.Path
		end
	end
	local function drawPath(line: Model, pause: boolean, isBezier: boolean): nil
		for i,LinePart:BasePart in next, line:GetChildren() do
			if pause then task.wait() end
			if isBezier then LinePart.Path:ClearAllChildren() end --has to be like this to remove bezier paths
			pathifyPart(LinePart, Vector3.new(0,0,1))
			LinePart.Transparency = 1
		end
		return
	end
	pathify.Left.Pathify.MouseButton1Click:Connect(function()
		if not linefolder then return end
		for i,v : defaultpart in next, linefolder:GetChildren() do
			v.Path:ClearAllChildren()
		end
		if linefolder.Name == "BezierCurve" then
			for i,v in next, linefolder:GetChildren() do
				drawPath(v.Bezier, false, true)
				task.wait()
			end
		else
			drawPath(linefolder, true, false)
		end
	end)
end

--only returns word when one match is present
--ex: Red, reach
--match: R ❌
--		 Re ❌
--		 Rea ✅ Reach
local function findSingleOption(strings, match): string | boolean
	local len = #match
	if len == 0 then return nil end
	match = match:lower()
	
	local word = false
	for _, phrase in next, strings do
		local segment = phrase:lower():sub(1,len)
		--
		if segment ~= match then continue end --if not same prefix, move on
		if word then return true end --if multiple matches, return true (indicating exists, but not single)
		word = phrase
	end
	return word
end
--for line options-------------------------------------------
local mainFrame = mainHolder.Main

local tFind = table.find
local tRemove = table.remove

local max = math.max
local min = math.min
local floor = math.floor

local selector = game:GetService("Selection")
local toggleNodeEditor: (boolean, number?) -> nil = nil
local updNodesGui: () -> nil = nil
local summonNodePhysical: (Vector3) -> BasePart = nil
local function fetchMaxNodes()
	return max(points and #points, 1) or 1
end

local runservice = game:GetService("RunService")
local nodeUpdPerSecond = 5

local isEditingNode = false
local currentNodeEditor = nil
local currentNode = 1

local generateBezier : ({Vector3}, number) -> Vector3 = nil
do
	--Material
	local materialInput = mainFrame.Material.TextBox
	local materials = Enum.Material:GetEnumItems()
	for i,v in next, materials do materials[i] = v.Name end --to string
	
	--autofill materials
	local force = false
	materialInput:GetPropertyChangedSignal("Text"):Connect(function()
		local query = materialInput.Text
		local material = findSingleOption(materials, query)
		
		if typeof(material) == "string" then
			materialInput.Text = material
			force = true
			materialInput:ReleaseFocus()
		elseif not material then
			materialInput.Text = ""
		end
	end)
	
	--write focusLost event to update material :p
	--and have a "remembering" lastMaterial
	local lastMaterial = defaultpart.Material
	materialInput.FocusLost:Connect(function()
		local query = materialInput.Text
		
		if not force then --was manually done
			local match = false
			for _, mat in next, materials do
				if mat:lower() == query:lower() then --find exact match
					materialInput.Text = mat
					query =  mat
					match = true
					break
				end
			end
			if not match then
				materialInput.Text = lastMaterial.Name
				return
			end
		end
		force = false
		local nextMat = Enum.Material:FromName(query)
		lastMaterial = nextMat or lastMaterial
		--
		defaultpart.Material = lastMaterial
		materialInput.PlaceholderText = lastMaterial.Name
		materialInput.Text = lastMaterial.Name
		--
		clearOldLines()
		drawAllLines()
	end)
	
	--Color
	local colors = mainFrame.Color
	do
		local rgbs = {}
		for i,ui in next, colors:GetChildren() do
			rgbs[ui.Name] = ui --for lookup
			ui.FocusLost:Connect(function()
				fixNumber(ui, 0, 255, ui.PlaceholderText)
				defaultpart.Color = Color3.fromRGB(
					rgbs.R.Text,
					rgbs.G.Text,
					rgbs.B.Text
				)
				--
				clearOldLines()
				drawAllLines()
			end)
		end
	end
	
	--Node Editing
	local nodeEditorPhysical = thisPlugin.NodeHelper
	
	local selected = mainHolder.Main.Selected
	
	local nodeEditorLeftBtn = selected.Left
	local nodeEditorRightBtn = selected.Right
	local nodeEditorTextBox = selected.TextBox
	local nodeEditorBegin = selected.EditNode
	

	
	
	local function updNodesBillboard()
		if not (currentNodeEditor and currentNodeEditor.Parent) then return end
		currentNodeEditor.Gui.TextButton.Text = ("%d/%d"):format(currentNode, fetchMaxNodes())
	end
	
	--spawn/grab the current node
	summonNodePhysical = function(pos: Vector3): BasePart
		if not (currentNodeEditor and currentNodeEditor.Parent == workspace) then --make a new one
			local newHelper = nodeEditorPhysical:Clone()
			--
			newHelper.Parent = workspace
			currentNodeEditor = newHelper
		end
		--
		currentNodeEditor.Position = pos
		updNodesBillboard()
		return currentNodeEditor
	end
	
	
	--for Button and (user exit) to interact with node
	toggleNodeEditor = function(toggle: boolean?, setNode: number?)
		if #points < 1 then return end
		--
		if toggle == nil then
			return toggleNodeEditor(not isEditingNode, setNode) --no input = normal toggle
		end
		isEditingNode = toggle
		currentNode = setNode or currentNode
		--
		if isEditingNode then
			if not points or #points < 0 then return end

			nodeEditorBegin.Text = "Stop"
			nodeEditorBegin.BackgroundColor3 = Color3.new(1,1,0)
			
			local editor = summonNodePhysical(points[currentNode])
			updNodesBillboard()
			selector:Set{ editor }
		else
			if currentNodeEditor then currentNodeEditor:Destroy() end
			--
			nodeEditorBegin.Text = "Edit Node"
			nodeEditorBegin.BackgroundColor3 = Color3.fromRGB(35,255,145)
			nodeEditorTextBox.Text = currentNode
			plugin:Activate(true) --regain control of mouse after moveHandles summoned
		end
		return
	end
	selector.SelectionChanged:Connect(function() --"turn off" selection once it is unselected in explorer
		local curSelected = selector:Get()
		if not tFind(curSelected, currentNodeEditor) then
			toggleNodeEditor(false)
		end
		return
	end)
	nodeEditorBegin.MouseButton1Click:Connect(toggleNodeEditor)
	
	
	nodeEditorTextBox.FocusLost:Connect(function()
		local max = fetchMaxNodes()
		fixNumber(nodeEditorTextBox, 1, max, max)
		currentNode = tonumber(nodeEditorTextBox.Text)
		--
		summonNodePhysical(points[currentNode])
		updNodesGui()
	end)
	
	local function incrementCurNode(amount: number): nil
		local max = fetchMaxNodes()
		local next = currentNode + amount
		--
		if next < 1 then
			currentNode = next + max --wraps around
		elseif next > max then
			currentNode = next - max
		else
			currentNode = next
		end
		summonNodePhysical(points[currentNode])
		updNodesGui()
	end
	nodeEditorLeftBtn.MouseButton1Click:Connect(function()
		incrementCurNode(-1)
	end)
	nodeEditorRightBtn.MouseButton1Click:Connect(function()
		incrementCurNode(1)
	end)
	
	updNodesGui = function()
		local max = fetchMaxNodes()
		currentNode = clamp(currentNode, 1, max)
		--
		nodeEditorTextBox.Text = currentNode
		nodeEditorTextBox.PlaceholderText = max
		--
		updNodesBillboard()
	end
	
	--movement checker
	
	local lastPosition = Vector3.zero
	local lastTick = tick()
	runservice.Heartbeat:Connect(function()
		--stop conditions
		if not (
				enabled and isEditingNode 								--GUI is proper
				--and points[currentNode] and linefolder and linefolder.Parent				--Line exists
				and currentNodeEditor and currentNodeEditor.Parent		--billboard exists
			)
		then
			return
		end
		if 
			lastTick < 1/nodeUpdPerSecond
			or currentNodeEditor.Position == lastPosition
		then
			return
		end
		lastTick = tick()
		lastPosition = currentNodeEditor.Position
		--
		points[currentNode] = lastPosition
		
		--reposition surrounding lines
		
		--prior line
		if currentNode > 1 then
			local leftLine = linefolder:FindFirstChild( ("%d-%d"):format(currentNode-1, currentNode) )
			local attr = leftLine:GetAttributes()
			if leftLine then
				leftLine:Destroy() --delete old line
			end
			leftLine = drawLine(points[currentNode-1], points[currentNode], (currentNode-1).."-"..currentNode) --reattach at new position
			for i,v in next, attr do
				leftLine:SetAttribute(i,v)
			end
			
			if previewBezier then
				local offset = bezierSegments - 1
				local curLoop = floor( (currentNode-2) / (offset) )

				if curLoop % 2 == 1 then
					leftLine.Color = bezierColors[1]
				else
					leftLine.Color = bezierColors[2]
				end
			end
			
			if attr.Link > 0 then --its on a bezier curve
				local link = attr.Link
				local sourceLine = linefolder:FindFirstChild( ("%d-%d"):format(link, link+1))
				local segments = sourceLine:GetAttribute("Segments")-1
				local increment = sourceLine:GetAttribute("Divisions")-1
				
				local currentCurve = {}
				for i = link, link+segments do
					insert(currentCurve, points[i])
				end
				
				local curvePoints = {}
				local assignedLine = linefolder:FindFirstChild(link.."-"..(link+1))
				--
				for percent = 0, 1, 1/increment do
					insert( curvePoints, generateBezier(currentCurve, percent)) --curve builder
				end
				insert( curvePoints, generateBezier(currentCurve, 1))
				--
				assignedLine.Bezier:ClearAllChildren()
				for i = 2, #curvePoints do
					local newLine = drawLine(curvePoints[i-1], curvePoints[i], (i-1).."-"..i, assignedLine.Bezier)
				end
			end
			
		end
		--next line
		if currentNode < fetchMaxNodes() then
			local rightLine = linefolder:FindFirstChild( ("%d-%d"):format(currentNode, currentNode+1) )
			local attr = rightLine:GetAttributes()
			if rightLine then
				rightLine:Destroy()
			end
			rightLine = drawLine(points[currentNode], points[currentNode+1], currentNode.."-"..(currentNode+1))
			for i,v in next, attr do
				rightLine:SetAttribute(i,v)
			end
			--
			if previewBezier then
				local offset = bezierSegments - 1
				local curLoop = floor( (currentNode-1) / (offset) )

				if curLoop % 2 == 1 then
					rightLine.Color = bezierColors[1]
				else
					rightLine.Color = bezierColors[2]
				end
			end
			
			if attr.Link > 0 then --its on a bezier curve
				local link = attr.Link
				local sourceLine = linefolder:FindFirstChild( ("%d-%d"):format(link, link+1))
				local segments = sourceLine:GetAttribute("Segments")-1
				local increment = sourceLine:GetAttribute("Divisions")-1

				local currentCurve = {}
				for i = link, link+segments do
					insert(currentCurve, points[i])
				end

				local curvePoints = {}
				local assignedLine = linefolder:FindFirstChild(link.."-"..(link+1))
				--
				for percent = 0, 1, 1/increment do
					insert( curvePoints, generateBezier(currentCurve, percent)) --curve builder
				end
				insert( curvePoints, generateBezier(currentCurve, 1))
				--
				assignedLine.Bezier:ClearAllChildren()
				for i = 2, #curvePoints do
					local newLine = drawLine(curvePoints[i-1], curvePoints[i], (i-1).."-"..i, assignedLine.Bezier)
				end
			end
		end
		--
		
	end)
end

generateBezier = function(points: {Vector3}, percent: number): Vector3
	--end condition
	if #points == 1 or percent <= 0 then
		return points[1]
	elseif percent >= 1 then --"unsolvable" case
		return points[#points]
	end
	--
	local newPts = {}
	for i=1, #points-1 do
		insert(newPts, points[i]:Lerp(points[i+1], percent))
	end
	
	return generateBezier(newPts, percent)
end



--for bezier options-------------------------------------
do
	local showBezier = mainFrame.ShowBezier
	local bezHideLines = false
	
	local function toggleBezierPreview(toggle: boolean): nil
		if toggle == nil then
			return toggleBezierPreview(not previewBezier)
		end
		--
		previewBezier = toggle
		showBezier.TextButton.Text = previewBezier and "Yes" or "No"
		clearOldLines()
		drawAllLines()
	end
	showBezier.TextButton.MouseButton1Click:Connect(toggleBezierPreview)
	--
	
	local bezierDivisionsInput = mainFrame.Divisions.TextBox
	bezierDivisionsInput.FocusLost:Connect(function()
		fixNumber(bezierDivisionsInput, 2, 150, 5)
		bezierDivisions = tonumber(bezierDivisionsInput.Text)
	end)
	local bezierSegmentsInput = mainFrame.Segments.TextBox
	bezierSegmentsInput.FocusLost:Connect(function()
		fixNumber(bezierSegmentsInput, 2, 5, 2)
		bezierSegments = tonumber(bezierSegmentsInput.Text) + 1 --sneaky
		clearOldLines()
		drawAllLines()
	end)
	
	local bezierRevealLines = mainFrame.MakeBezier.Reveal
	bezierRevealLines.MouseButton1Click:Connect(function()
		bezHideLines = not bezHideLines
		for i,v in next, linefolder:GetChildren() do
			v.Transparency = bezHideLines and 1 or 0
		end
		return
	end)
	local makeBezier = mainFrame.MakeBezier
	makeBezier.MouseButton1Click:Connect(function()
		--ensures 3 points per bezier. clips off end if not enough
		if #points < bezierSegments then return end
		
		local curveSets = {}
		local increment = 1/(bezierDivisions-1) --clip last one off to manually ensure it ends at 100%
		

		--hide the supports
		if bezHideLines then
			for i,v : BasePart in next, linefolder:GetChildren() do v.Transparency = 1 end
		end
		
		--increment by 2 because the 3rd point becomes the 1st in next
		--yes this means every Other line has no bezier parts; i dont care :p
		local inc = bezierSegments - 1
		for i = 1, #points - inc, inc do
			local currentCurve = {}
			local refs = {}
			for j = i, i+inc do
				insert(currentCurve, points[j])
				--for dragging
				local curLine = linefolder:FindFirstChild(j.."-"..(j+1))
				if not curLine then continue end
				curLine:SetAttribute("Link", i)
			end
			local curvePoints = {}
			local assignedLine = linefolder:FindFirstChild(i.."-"..(i+1))
			assignedLine:SetAttribute("Divisions", bezierDivisions)
			assignedLine:SetAttribute("Segments", bezierSegments)
			--
			for percent = 0, 1, increment do
				insert( curvePoints, generateBezier(currentCurve, percent)) --curve builder
			end
			insert( curvePoints, generateBezier(currentCurve, 1))
			--
			assignedLine.Bezier:ClearAllChildren()
			for i = 2, #curvePoints do
				local newLine = drawLine(curvePoints[i-1], curvePoints[i], (i-1).."-"..i, assignedLine.Bezier)
			end
			
			task.wait()
		end
		linefolder.Name = "BezierCurve"
	end)
end

local attr

--for line claimer---------------------------------------
do
	local claimLineBtn = mainFrame.Claim
	local claimLineInfo = claimLineBtn.TextLabel
	local curSelection = {}
	--
	selector.SelectionChanged:Connect(function()
		curSelection = selector:Get()
		--
		if #curSelection == 1 then
			claimLineInfo.Text = "'"..curSelection[1].Name.."'"
		else
			claimLineInfo.Text = "Select from Explorer"
		end
	end)
	
	
	claimLineBtn.MouseButton1Click:Connect(function()
		if #curSelection ~= 1 then return end
		local sel : Instance = curSelection[1]
		if not sel:IsA"Model" then
			claimLineInfo.Text = "Must be a Model"
			return
		end
		
		local colors = {}
		local pts = {}
		local i = 1
		repeat
			local newPart = sel:FindFirstChild(i.."-"..(i+1))
			if not (newPart and newPart:IsA"BasePart") then break end
			
			--setting attributes
			tryDefaultAttr(newPart)
			if not (newPart:FindFirstChild"Bezier" and newPart.Bezier:IsA"Model") then
				Instance.new("Model", newPart).Name = "Bezier"
			end
			if not (newPart:FindFirstChild"Path" and newPart.Bezier:IsA"Model") then
				Instance.new("Model", newPart).Name = "Path"
			end
			
			--getting path colors
			do
				for _,v in next, newPart.Path:GetChildren() do
					if not v:IsA"BasePart" then continue end
					colors[tostring(v.Color)] = v.Color
				end
				
				local bez = newPart.Bezier:GetChildren()
				if #bez > 0 then
					for _,k in next, bez do --for each curve point
						for _,v in next, k.Path:GetChildren() do --for each path
							if not v:IsA"BasePart" then continue end
							colors[tostring(v.Color)] = v.Color
						end
						
					end
				end
			end
			
			--getting Points
			local size = newPart.Size.Z * newPart.CFrame.LookVector
			
			if i == 1 then --left side
				insert(pts, newPart.Position - size/2)
			end
			
			insert(pts, newPart.Position + size/2)--right side
			--
			i += 1
		until false
		if #pts == 0 then
			claimLineInfo.Text = "Failed"
		else
			claimLineInfo.Text = "Claimed "..#pts.." Points"
		end
		--get path colors into UI
		clearChildType(colContainer, "Frame")
		for str, color in next, colors do
			local newCol = colTemplate:Clone()
			newCol.BackgroundColor3 = color
			newCol.Color.TextColor3 = invertC3( C3toBW(color, 0.5) )
			newCol.Color.Text = ("%d, %d, %d"):format(floor(color.R * 255), floor(color.G * 255), floor(color.B * 255))
			newCol.Name = "COLOR"

			newCol.Color.MouseButton1Click:Connect(function()
				newCol:Destroy()
			end)
			newCol.Frequency.FocusLost:Connect(function()
				fixNumber(newCol.Frequency, nil, nil, 1)
			end)
			newCol.Visible = true
			newCol.Parent = colContainer
		end
		--
		points = pts
		if #linefolder:GetChildren() == 0 then linefolder:Destroy() end --clear old
		linefolder = sel
		return
	end)
	
end
uis.InputBegan:Connect(function(obj, proc)
	if proc then return end
	--
	if isEditingNode and currentNodeEditor then
		local max = fetchMaxNodes()
		if obj.KeyCode.Name == "R" then --R to reset orientation
			currentNodeEditor.CFrame = CFrame.new(currentNodeEditor.Position)
		elseif max > 1 and obj.KeyCode.Name == "BackSlash" and points[currentNode] then
			tRemove(points, currentNode)
			if currentNode == max then currentNode -= 1 end
			summonNodePhysical(points[currentNode])
			--
			clearOldLines()
			drawAllLines()
		end
	end
end)
--on click
mouse.Button1Down:Connect(function()
	local hit = mouse.Hit.p
	if not enabled then
		return
	end

	if not isctrld() then
		points[#points+1] = hit
	else
		rawset(points, #points, nil)
	end


	clearOldLines()

	if #points == 0 then
		drawLine(hit, hit, 1)
	else
		drawAllLines()
	end
	updNodesGui()
end)
--when widget is closed
infoGuiWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
	enabled = infoGuiWidget.Enabled
	plugin:Activate(enabled)
	

	toggleNodeEditor(false, 1)
	updNodesGui()
end)