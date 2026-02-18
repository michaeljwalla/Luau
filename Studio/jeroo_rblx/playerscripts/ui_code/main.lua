local funcs = require(game.ReplicatedStorage.Functions)
override = true

local uis = game:GetService("UserInputService")
local rp = game.ReplicatedStorage
local ts = game:GetService("TextService")
local function getsize(txt, size)
	size = size or Vector2.new(1e6,1e6)
	return ts:GetTextSize(txt,14,Enum.Font.SourceSans,size)
end
--[[for i,v in pairs(script.Parent:GetChildren()) do 
	if v:IsA("Frame") then
		for a,x in pairs(functions) do x(a) end
	end
end
script.Parent.ChildAdded:Connect(function(v)
	v:WaitForChild("Line") v:WaitForChild("Code")
	for a,x in pairs(functions) do x(a) end
end)

--defining locally does not save name in bytecode
local function newline()
	local newlineind = rp.Line:Clone()
	local layoutorder = #script.Parent.Lines:GetChildren()
	newlineind.LayoutOrder = layoutorder
	newlineind.Name = layoutorder
	newlineind.Text = layoutorder
	newlineind.Parent = lines
end

local function linesandsizes()
	local size = getsize()
	local y = size.Y/14
	local zeroed
	for i,v in pairs(lines:GetChildren()) do if v:IsA"TextLabel" and v.LayoutOrder > y then zeroed = true v:Destroy() end end
	local highest = 0
	for i,v in pairs(lines:GetChildren()) do
		if v:IsA"TextLabel" and v.LayoutOrder > highest then highest = v.LayoutOrder end
	end
	for i = highest, y-1 do
		newline()

	end
	code.Parent.Size = UDim2.new(0,275,size.Y/workspace.CurrentCamera.ViewportSize.Y, 14+size.Y/3.5)
	code.Parent.Parent.Lines.Size = UDim2.new(0,20,size.Y/workspace.CurrentCamera.ViewportSize.Y, 14+size.Y/3.5)
	--code.Parent.Parent.Size = UDim2.new(1,0,size.Y/workspace.CurrentCamera.ViewportSize.Y, 14+size.Y/3.5)
	code.Parent.Parent.CanvasPosition += Vector2.new(0,not zeroed and ((y-1)-highest > -1) and 24 or 0)
end
code:GetPropertyChangedSignal("Text"):Connect(linesandsizes)]]

--
local reservedwords = {"while", "if", "true", "false", "method"}
local varnames = '^[_%a][%a_%d]+'
local function validname(txt)
	if table.find(reservedwords, txt) or #txt:match(varnames) ~= txt then return false else return true end
end
local spawner = require(game.ReplicatedStorage.Jeroos.Functions)
local console = script:FindFirstAncestor("code").Console.ScrollingFrame.Output
console:GetPropertyChangedSignal("Text"):Connect(function()
	local size = getsize(console.Text, Vector2.new(console.Parent.AbsoluteSize.X, 1e6)).Y
	console.Parent.CanvasSize = UDim2.new(0,0,0,size)
	console.Size = UDim2.new(0.9,0,0,size)
	console.Parent.CanvasPosition = Vector2.new(0,console.Parent.CanvasSize.Y.Offset)
end)
local function assertconsole(...)
	local args = {...}
	if not args[1] then console.Text ..= "\nERR: "..(args[2] or "").."\n" return error(args[2]) end
	return unpack(args)
end
local function printconsole(...)
	local txt = ''
	for i,v in pairs({...}) do txt..=' '..tostring(v) end
	console.Text ..= '\n'..txt..'\n'
	return ...
end
function clearconsole()
	console.Text = ''
end
function fromsource() return end
printconsole("hello, world!")

function overrideinstructionsRunMe() return "set runfunc to whatever to change the code taht runs" end
runfunc = function()
	local x = assertconsole(spawner(1,2, 'SOUTH'))
	x.Name = 'bob'
	spawner.method('walk', function(jeroo)
		jeroo['while']('!isWater', {'AHEAD'}, function(jeroo)
			jeroo.hop()
		end)
		jeroo.turn('RIGHT')
		jeroo.walk()
	end)
	x.walk()
--[[local y = assertconsole(spawner(1,3, 'SOUTH',0))
y.Name = 'joy'
	spawner.method('while lol', function(jeroo)
		jeroo['while']('!isWater', {'AHEAD'}, function(jeroo)
			jeroo['while']('!isWater', {'AHEAD'}, function(jeroo)
				jeroo.hop()
			end)
			jeroo.turn('LEFT')
		end)
	end)
	assertconsole(spawner.method('selfandothercall', function(jeroo)
		jeroo['if']('isClear', {'AHEAD'}, function(jeroo)
			jeroo.hop()
			jeroo['selfandothercall']()
		end, function(jeroo)
			jeroo.turn('LEFT')
			jeroo['while lol']()
		end)
	end))
	--rem: first value passed is always jeroo (w/o namecall) (dont namecall [func(jeroo,jeroo) XXXXX])
	x['selfandothercall']() -- you cant tell me this isnt so cool]]
	
end
local playtoggle = script.Parent.toggle

local db
playtoggle.MouseButton1Down:Connect(function()
	db = true
	local run = not funcs.coderunning()
	funcs.coderunning(run)
	playtoggle.Text = if run then 'Stop' else 'Start'
	
	if run then clearconsole() spawner.customs('clear') workspace.Map.Jeroos:ClearAllChildren() for i,v in pairs(spawner.jeroos) do v.Stopped = true spawner.jeroos[i] = nil end task.spawn(runfunc) end
	task.wait(1+spawner.setspeed())
	db = false
end)



