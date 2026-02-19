local face = {}
face.__index = face
face.__tostring = function(self)
	return ("Face \"%s\" %dx%d"):format(self.name, self.length, self.width)
end
function face.new(length, width, name)	
	return setmetatable({
		length = length or 1,
		width = width or length or 1,
		faces = {},
		name = type(name) == 'string' and name or "Face"
	}, face)
end
function face:GetName()
	return self.name
end
function face:SetName(n)
	self.name = tostring(n)
end
function face:GetLength()
	return self.length
end
function face:GetArea()
	return self.length * self.width
end
function face:SetLength(n)
	--local z = typeof(n)
	--assert(z == 'number', "Expected number, got "..z)
	self.length = n
end
function face:GetWidth()
	return self.width
end
function face:SetWidth(n)
	--local z = typeof(n)
	--assert(z == 'number', "Expected number, got "..z)
	self.width = n
end
function face:Dilate(length, width)
	width = width or length
	
	--dilation is immutable
	return self.new(self.length * length, self.width * width):SetNeighbors(self.faces)
end
function face:SetNeighbors(data)
	local faces = self.faces
	faces.North = data.North or data[1]
	faces.East = data.East or data[2]
	faces.South = data.South or data[3]
	faces.West = data.West or data[4]
	return self
end
function face:GetNeighbor(what)
	return self.faces[what]
end


local prism = {}
prism.__index = prism
prism.__tostring = function(self)
	return ("Prism \"%s\" %dx%dx%d"):format(self.name, self.length,self.width,self.height)	
end
function prism.new(length, width, height, name)
	length, width, height = length or 1, width or 1, height or 1
	local bottom, top = face.new(length, width, "Bottom"), face.new(length, width, "Top")
	local sideA,sideB = face.new(length, height, "SideA"), face.new(width, height, "SideB")
	local sideC, sideD = face.new(length, height, "SideC"), face.new(width, height, "SideD")
	
	bottom:SetNeighbors{sideA, sideB, sideC, sideD}
	sideA:SetNeighbors{top, sideB, bottom, sideD}
	top:SetNeighbors{sideC, sideB, sideA, sideD}
	sideC:SetNeighbors{bottom, sideB, top, sideD}
	sideB:SetNeighbors{sideA, top, sideC, bottom}
	sideD:SetNeighbors{sideA, bottom, sideC, top}
	
	return setmetatable({
		anchor = bottom,
		sides = { bottom, top, sideA, sideB, sideC, sideD },
		length = length,
		width = width,
		height = height,
		name = type(name) == 'string' and name or "Prism"
	}, prism)
end
function prism:GetName()
	return self.name
end
function prism:SetName(n)
	self.name = tostring(n)
	return
end
function prism:Dilate(length, width, height)
	width = width or length
	height = height or length
	
	return prism.new(self.length * length, self.width * width, self.height * height)
end
function prism:GetAnchor()
	return self.anchor
end
local find = table.find
function prism:SetAnchor(face)
	assert(find(self.sides, face), "Given replacement not part of shape")
	self.anchor = face
	return
end
function prism:Rotate(dir)
	self.anchor = self.anchor:GetNeighbor(dir)
	return self
end
function prism:GetVolume()
	return self.length * self.width * self.height
end
function prism:GetSurfaceArea()
	local sum = 0
	for i,v in next, self.sides do sum = sum + v:GetArea() end
	return sum
end

local tipping = prism.new(100, 100, 200, "Tipping Block")
print(tipping:Rotate"South":Rotate"East":Rotate"North":GetAnchor())