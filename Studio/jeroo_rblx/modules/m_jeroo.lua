local maptools = require(game.ReplicatedStorage.Functions)
override = true --for fenv
local timeinbetween = 1/3
local funcs, jeroostorage = {}, {}
local maps, jeroos = workspace.Map, workspace.Map.Jeroos

local directions = setmetatable({[Vector3.new(1,0,0)] = 'EAST', [Vector3.new(-1,0,0)] = 'WEST', [Vector3.new(0,0,1)] = 'SOUTH', [Vector3.new(0,0,-1)] = 'NORTH'}, {
	__index = function(self, index)
		if index == "__toVector" then
			return function(dir)
				dir = tostring(dir)
				for i,v in pairs(self) do if v:lower() == dir:lower() then return i end end
			end
		end
	end,
})
local gridoffsets = {
	EAST = {Row = 0, Column = 1},
	WEST = {Row = 0, Column = -1},
	NORTH = {Row = -1, Column = 0},
	SOUTH = {Row = 1, Column = 0},
}
local relfuncs = {
	RIGHT = function(jeroo, tbl)
		if jeroo.Stopped then return unpack(tbl) end
		local starting = directions[CFrame.new(Vector3.new(), tbl[2]).RightVector]
		local pos = (jeroo.Row+gridoffsets[starting].Row).." "..(jeroo.Column+gridoffsets[starting].Column)
		local part = maps:FindFirstChild(pos, true)
		return starting, part
	end,
	LEFT = function(jeroo, tbl)
		if jeroo.Stopped then return unpack(tbl) end
		local starting = directions[CFrame.new(Vector3.new(), tbl[2]).RightVector * (-1)]
		local pos = (jeroo.Row+gridoffsets[starting].Row).." "..(jeroo.Column+gridoffsets[starting].Column)
		local part = maps:FindFirstChild(pos, true)
		return starting, part
	end,
	AHEAD = function(jeroo, tbl)
		if jeroo.Stopped then return unpack(tbl) end
		local starting = directions[CFrame.new(Vector3.new(), tbl[2]).LookVector]
		local pos = (jeroo.Row+gridoffsets[starting].Row).." "..(jeroo.Column+gridoffsets[starting].Column)
		local part = maps:FindFirstChild(pos, true)
		return starting, part
	end,
	HERE = function(jeroo, tbl)
		if jeroo.Stopped then return unpack(tbl) end
		local starting = directions[CFrame.new(Vector3.new(), tbl[2]).LookVector] --returns absolute direction anyways
		local pos = (jeroo.Row).." "..(jeroo.Column)
		local part = maps:FindFirstChild(pos, true)
		return starting, part
	end
}

funcs.getfacingvector = function(jeroo)
	return jeroo.CFrame[jeroo.Front.Value]*(jeroo.Flipped.Value and -1 or 1)
end
funcs.absolutedir = function(jeroo)
	if not (jeroo.Part:IsA"BasePart" and jeroo.Part:FindFirstChild"Front" and jeroo.Part:FindFirstChild"Flipped") then return end
	local facingvector = jeroo.getfacingvector()
	return directions[facingvector], facingvector
end
funcs.turnabsolute = function(jeroo, dir)
	if not directions.__toVector(dir) then return false,"no directional value called "..dir end
	local temp = jeroo.Part:Clone()
	for i,v in pairs(directions) do
		if directions[funcs.getfacingvector(temp)] == dir then break end
		temp.CFrame = CFrame.lookAt(temp.Position, temp.Position+i)
	end
	if directions[funcs.getfacingvector(temp)] ~= dir then return false, 'unable to cast value '..dir..' to Jeroo "'..jeroo.Name..'" (unknown err, f.turnabsolute)' end
	temp:Destroy()
	jeroo.CFrame = temp.CFrame
	return true
end
funcs.turn = function(jeroo, dir)
	if not (dir == 'RIGHT' or dir == 'LEFT') then return false, 'can only cast directions LEFT or RIGHT to Jeroo "'..jeroo.Name..'"' end
	local face = relfuncs[dir](jeroo, {jeroo.absolutedir()})
	if not face then return false, 'unable to cast value '..dir..' to Jeroo "'..jeroo.Name..'" (unknown err, f.turn)' end
	return jeroo.turnabsolute(face)
end
funcs.relativedir = function(jeroo, direction)
	local facing = {jeroo.absolutedir()}
	if relfuncs[direction] then return relfuncs[direction](jeroo, facing) else return false, tostring(direction).." is not a valid relative direction (LEFT / RIGHT / AHEAD / HERE)" end
end
funcs.getjerooatpos = function(row,column)
	row,column = tonumber(row), tonumber(column)
	for i,v in pairs(jeroostorage) do
		if v.Row == row and v.Column == column then return v end
	end
	return
end

funcs.die = function(jeroo, msg)
	local died = script.Parent.Dead:Clone()
	died.Position = jeroo.Position 
	died.Parent = jeroos
	died.Pos.Value = jeroo.Pos.Value
	jeroo:Destroy()
	return false, msg
end

funcs.flowercheck = function(jeroo)
	if maps.Flower:FindFirstChild(jeroo.Row..' '..jeroo.Column) then jeroo.Transparency = 1 else jeroo.Transparency = 0 end
end
funcs.hop = function(jeroo, times)
	times = tonumber(times) or 1
	if times < 1 then times = 1 end
	for i = 1, times do
		local dir,part = relfuncs.AHEAD(jeroo, {jeroo.absolutedir()})
		jeroo.Position = jeroo.Position + directions.__toVector(dir)*4
		jeroo.Row = jeroo.Row + gridoffsets[dir].Row
		jeroo.Column = jeroo.Column + gridoffsets[dir].Column
		jeroo.Pos.Value = jeroo.Row*24+jeroo.Column
		if not part or part:IsDescendantOf(maps.Water) then return jeroo.die('Jeroo "'..jeroo.Name..'" is in water') elseif part:IsDescendantOf(maps.Net) then return jeroo.die('Jeroo '..jeroo.Name..' is on a net') end
		jeroo.flowercheck()
	end
	
	return true
end
funcs.pick = function(jeroo)
	if maps.Flower:FindFirstChild(jeroo.Row..' '..jeroo.Column) then
		jeroo.Flowers = jeroo.Flowers + 1
		maptools.settile(jeroo.Row,jeroo.Column,".") --auto override (__index from maptools sees fenv(2).fromsource)
		jeroo.flowercheck()
	end
	return jeroo.Flowers
end
funcs.plant = function(jeroo)
	if jeroo.Flowers > 0 and maps.Grass:FindFirstChild(jeroo.Row..' '..jeroo.Column) then
		jeroo.Flowers = jeroo.Flowers - 1
		maptools.settile(jeroo.Row,jeroo.Column,"F") --auto override (__index from maptools sees fenv(2).fromsource)
		jeroo.flowercheck()
	end
	return jeroo.Flowers
end
funcs.toss = function(jeroo)
	if jeroo.Flowers > 0 then
		jeroo.Flowers = jeroo.Flowers - 1
		local dir,part = relfuncs.AHEAD(jeroo, {jeroo.absolutedir()})
		if part and part:IsDescendantOf(maps.Net) then
			maptools.settile(jeroo.Row+gridoffsets[dir].Row,jeroo.Column+gridoffsets[dir].Column, '.')
		end
	end
	return jeroo.Flowers
end
funcs.give = function(jeroo, dir)
	dir = dir or 'AHEAD'
	if not relfuncs[dir] then return false, 'no relative direction named '..dir end
	if jeroo.Flowers > 0 then
		local dir,part = relfuncs[dir](jeroo, {jeroo.absolutedir()})
		if part then
			local giveto = funcs.getjerooatpos(part.Name:match("^%d+"),part.Name:match("%d+$"))
			if giveto then
				jeroo.Flowers = jeroo.Flowers - 1
				giveto.Flowers = giveto.Flowers + 1
				return jeroo.Flowers, giveto.Flowers
			end
		end
	end
	return jeroo.Flowers
end
--bool functions
funcs.hasFlower = function(jeroo)
	return (jeroo.Flowers > 0 and 1) or -1
end
funcs.isFacing = function(jeroo, dir)
	local cleared = directions.__toVector(dir)
	if not cleared then return false, 'expected compass direction when invoking isFacing()' end
	return (directions[jeroo.getfacingvector()] == dir and 1) or -1
end
funcs.isFlower = function(jeroo, dir)
	dir = tostring(dir)
	if not relfuncs[dir] then return false, 'expected relative direction when invoking isFlower()' end
	local dir,part = relfuncs[dir](jeroo, {jeroo.absolutedir()})
	return (part and part:IsDescendantOf(maps.Flower) and 1) or -1
end
funcs.isJeroo = function(jeroo, dir)
	dir = tostring(dir)
	if not relfuncs[dir] then return false, 'expected relative direction when invoking isJeroo()' end
	local dir = relfuncs[dir](jeroo, {jeroo.absolutedir()})
	local row, column = jeroo.Row + gridoffsets[dir].Row, jeroo.Column + gridoffsets[dir].Column
	return (funcs.getjerooatpos(row,column) and 1) or -1
end
funcs.isNet = function(jeroo, dir)
	dir = tostring(dir)
	if not relfuncs[dir] then return false, 'expected relative direction when invoking isJeroo()' end
	local dir = relfuncs[dir](jeroo, {jeroo.absolutedir()})
	local row, column = jeroo.Row + gridoffsets[dir].Row, jeroo.Column + gridoffsets[dir].Column
	return (maps.Net:FindFirstChild(row..' '..column) and 1) or -1
end
funcs.isWater = function(jeroo, dir)
	dir = tostring(dir)
	if not relfuncs[dir] then return false, 'expected relative direction when invoking isJeroo()' end
	local dir = relfuncs[dir](jeroo, {jeroo.absolutedir()})
	local row, column = jeroo.Row + gridoffsets[dir].Row, jeroo.Column + gridoffsets[dir].Column
	if row < 0 or row > 23 or column < 0 or column > 23 then return 1 end
	return (maps.Water:FindFirstChild(row..' '..column) and 1) or -1
end
funcs.isClear = function(jeroo, dir)
	dir = tostring(dir)
	if not relfuncs[dir] then return false, 'expected relative direction when invoking isJeroo()' end
	local dir = relfuncs[dir](jeroo, {jeroo.absolutedir()})
	local row, column = jeroo.Row + gridoffsets[dir].Row, jeroo.Column + gridoffsets[dir].Column
	return (maps.Grass:FindFirstChild(row..' '..column) and 1) or -1
end

funcs['if'] = function(jeroo, func, arglist, runfunc, elsefunc)
	arglist = arglist or {}
	runfunc = runfunc or function() end
	local flip
	if func:sub(1,1) == '!' then func = func:sub(2,#func) flip = true end
	if jeroo[func] then
		if (flip and jeroo[func](unpack(arglist)) ~= 1) or (not flip and jeroo[func](unpack(arglist)) == 1) then
			return runfunc(jeroo) or 1
		elseif elsefunc then return elsefunc(jeroo) or 1 end
	else return -1 end
end
funcs['while'] = function(jeroo, func, arglist, runfunc)
	arglist = arglist or {}
	if not runfunc then return end
	local flip
	if func:sub(1,1) == '!' then func = func:sub(2,#func) flip = true end
	if jeroo[func] then
		while maptools.coderunning() and (flip and jeroo[func](unpack(arglist)) ~= 1) or (not flip and jeroo[func](unpack(arglist)) == 1) do
			runfunc(jeroo)
		end
		return 1
	else return -1 end
end

--
local usables = {method = true, turn = true, hop = true, pick = true, plant = true, setspeed = true, toss = true, give = true, hasFlower = true, isFacing = true, isFlower = true, isJeroo = true, isNet = true, isWater = true, isClear = true,['if'] = true, ['while'] = true}
local custommethods = {}
local classmt = {}
classmt.__index = function(self, index)
	if not maptools.coderunning() then return function() return false, 'program is not currently running' end end
	if custommethods[index] then
		return function(...)
			return custommethods[index](self, ...) 
		end 
	elseif funcs[index] then
		--[[if getfenv(2).fromsource and not usables[index] then -- prevent 
			return function() task.wait(timeinbetween) return false, 'method "'..index..'" not found' end
		end]]
		
		return function(...)
			--[[if getfenv(2).fromsource then ]]task.wait(timeinbetween) --end
			return funcs[index](self, ...) 
		end 
	end
	if type(self.Part[index]) == 'function' then
		return function(...)
			return self.Part[index](self.Part, ...)
		end
	else return self.Part[index] end
end
classmt.__newindex = function(self, index, value)
	rawset(self,index,nil) --no adding attributes
	if pcall(function() return self.Part[index] end) then self.Part[index] = value else error('attempt to index '..index..' on Jeroo "'..self.Name..'"') end
end

local basejeroo = setmetatable({Stopped = false, Name = '',Row = 0, Column = 0, Flowers = 0,Part = Instance.new("Part")}, {__call = function(self) local x = {} for i,v in pairs(self) do rawset(x,i,v) end return setmetatable(x,classmt) end})


local makejeroo, jmt = {}, {}
jmt.__call = function(self,...)
	if not maptools.coderunning() then return false, 'program is not currently running' end
	task.wait(timeinbetween)
	if #jeroos:GetChildren() >= 4 then return false, 'maximum number (4) Jeroos created' end
	local tbl = {...}
	local row, column, dir,flowers = typeof(tbl[1]) == 'number' and tbl[1],typeof(tbl[2]) == 'number' and tbl[2],(type(tbl[3] or true) == 'number' and nil) or tbl[3], (type(tbl[3] or true) == 'number' and tbl[3]) or tbl[4]
	
	if not ((row and column and flowers) or (row and column)) then return false, 'invalid invocation' end

	--pos
	row, column = row or 0, column or 0
	local new = script.Parent:FindFirstChild(#jeroos:GetChildren()+1):Clone()
	new.Position = Vector3.new((column-12)*4,1,(row-12)*4)
	for i,v in pairs(jeroos:GetChildren()) do if v.Position == new.Position then return funcs.die(new,'Jeroos cannot spawn on each other') end end
	new.Pos.Value = row*24+column
	
	--setup
	dir = (not tonumber(dir) and dir) or 'EAST'
	if not directions.__toVector(dir) then return  false, 'unable to cast direction '..dir..' to Jeroo while creating' end
	local jeroo = basejeroo()
	jeroo.Row = row
	jeroo.Column = column
	jeroo.Flowers = flowers or 0
	jeroo.Part = new
	jeroo.turnabsolute(dir)
	jeroo.flowercheck()
	new.Parent = jeroos
	
	local posname = jeroo.Row.." "..jeroo.Column
	if maps.Net:FindFirstChild(posname) or maps.Water:FindFirstChild(posname) then return jeroo.die('Jeroo cannot spawn on current terrain') end
	table.insert(jeroostorage, jeroo)
	return jeroo
end
makejeroo.setspeed = function(num)
	if not num then return timeinbetween end
	timeinbetween = math.clamp(num, 0, 3)
	return timeinbetween
end
makejeroo.method = function(funcname, func)
	if custommethods[funcname] or funcs[funcname] then return false, 'method "'..funcname..'" is already defined'..(funcs[funcname] and not usables[funcname] and " (core function)" or '') end
	custommethods[funcname] = func
	return true
end
makejeroo.jeroos = jeroostorage
makejeroo.customs = function(type)
	if type == 'clear' then custommethods = {} end
	return custommethods
end
return setmetatable(makejeroo, jmt)