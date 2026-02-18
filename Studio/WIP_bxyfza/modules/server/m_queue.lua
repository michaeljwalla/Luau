--!strict

local insert = table.insert
local remove = table.remove


local module = {}
--

local tempEntry : any = nil
local queueMT = {}
queueMT.__index = queueMT

export type Queue = typeof( setmetatable({} :: {
	Size: (self: Queue) -> number,
	Add: (self: Queue, a: any) -> nil,
	Remove: (self: Queue) -> any,
	--
	Peek: (self: Queue) -> any,
	__ForceRemoveIndex: (self: Queue, index: number) -> any,
	__ForceRemoveObject: (self: Queue, object: any) -> number,
	Clear: (self: Queue) -> nil
	}, queueMT) )

local x = tempEntry :: Queue

queueMT.Size = function(self: Queue) : number
	return #self
end

queueMT.Add = function(self: Queue, ...:any)
	for i,v in next, {...} do --ignores nils
		self[#self+1] = v
	end
	return
end
queueMT.Remove = function(self: Queue): any?
	return #self ~= 0 and remove(self :: any, 1) or nil
end
queueMT.Peek = function(self: Queue)
	return self[1]
end
queueMT.__ForceRemoveIndex = function(self: Queue, index: number): any
	return remove(self :: any, index)
end
queueMT.__ForceRemoveObject = function(self: Queue, object: any): number? --still respect first in first out
	local start : number? = nil
	for i = 1, #self do
		print(self[i] == object)
		if self[i] == object then
			start = i
			break
		end
	end
	if not start then return end
	
	for i = start, #self do
		self[i] = self[i+1] --last one becomes nil when i == #self.
	end
	print(self)
	return start
end

queueMT.Clear = function(self: Queue)
	for i = #self, 1, -1 do
		self[i] = nil
	end
	return
end


module.new = function(...) : Queue
	local t = {}
	for i,v in next, {...} do --skips nil values
		insert(t,v)
	end
	return setmetatable(t, queueMT) :: Queue
end

return module
