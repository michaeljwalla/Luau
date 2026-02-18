local proxy = {}
do
	local funcs = {}
	local fields = {
		['.'] = "Grass",
		W = 'Water',
		N = 'Net',
		F = 'Flower'
	}
	local maps = workspace.Map
	funcs.clearboard = function()
		for i,v in pairs(maps:GetChildren()) do v:ClearAllChildren() end
		for i = 0, 24^2-1 do
			local new = script.Grass:Clone()
			local row, column = math.floor(i/24),i % 24
			new.Position = Vector3.new((row-12)*4,0.5,(column-12)*4)
			new.Name = column.." "..row
			new.Parent = maps.Grass
		end
	end
	funcs.settile = function(row, column, type)
		if not (row and column and type) then return end
		type = fields[type]
		local replace = maps:FindFirstChild(row.." "..column, true)
		if replace then replace:Destroy() end
		local new = script[type]:Clone()
		new.Position = Vector3.new((column-12)*4, 0.5, (row-12)*4)
		new.Name = row.." "..column
		new.Parent = maps[type]
	end
	funcs.genmap = function(str)
		if str == '' then for i = 1, 24^2 do str ..= "." end end
		str = str:gsub("%s", "")
		for i = 0, #str-1 do
			if i > 575 then break end
			local row, column = math.floor(i/24),i % 24
			funcs.settile(row, column, str:sub(i+1,i+1))
		end
	end
	funcs.maptotext = function(guiobj)
		local endstr = ""
		for i = 1, 24^2 do
			--print(i,updtbl[i])
			local row, column, choice = math.floor((i-1)/24), (i-1) % 24, nil
			choice = maps:findFirstChild(row.." "..column,true)
			if not choice then error('bro '..row.." "..column) end
			endstr = endstr..((choice.Parent.Name == 'Grass' and '.') or choice.Parent.Name:sub(1,1))
			if i % 24 == 0 then endstr = endstr.."\n" end
		end
		endstr = endstr:sub(1,#endstr-1)
		if guiobj then guiobj.Text = endstr end
		return endstr
	end
	funcs.namefrompart = function(part)
		for i,v in pairs(script:GetChildren()) do
			if v.BrickColor == part.BrickColor then return (v.Name == "Grass" and ".") or v.Name:sub(1,1) end
		end
	end
	local active = false
	funcs.coderunning = function(toggle)
		if toggle == nil then return active else active = toggle end
	end
	
	local mt = {}
	local function silly() return "lol" end
	mt.__index = function(self, index)
		if not getfenv(2).override and index ~= "coderunning" and active then return silly end
		return rawget(funcs, index)
	end
	setmetatable(proxy, mt)
end
return proxy
