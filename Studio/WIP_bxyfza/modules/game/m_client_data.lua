--!nonstrict

local lp = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local fastStat : Folder = rs:WaitForChild("FastStats"):WaitForChild(lp.Name) :: Folder

local insert = table.insert

local serverSet = script:WaitForChild("Set")
local serverGet = script:WaitForChild("Get")
local module = {
	Game = {},


}
local function argSet(...:any)
	local path = {...}
	local dir = module
	for i = 1, #path-2 do
		dir = module[path[i]]
	end
	--there is an error here
	dir[ path[#path-1]] = path[#path]
	return
end

function module:Fetch(k: string): any
	return self[k]
end
function module:ServerFetch(...: any) --sets data and returns
	local data = {...}
	insert(data, serverGet:InvokeServer(...))
	--
	argSet(unpack(data))
	
	return data[#data]
end
function module:FastStat(name: string): any
	local stat = fastStat:FindFirstChild(name) :: ValueBase
	return stat and stat.Value
end
serverSet.OnClientEvent:Connect(argSet)
return module