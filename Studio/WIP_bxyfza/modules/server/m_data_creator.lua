--!strict
local module = {}
---------------------
local rsModules = game:GetService("ReplicatedStorage"):WaitForChild("Modules")
local orderModule = require(rsModules:WaitForChild("Game").Order)

local queueMaker = require("./Queue") 
--
module.FastStats = {
	Base = {
		"TotalPoints",
		"TotalCoins"
	},
	Game = {
		"Points",
		"Coins"
	}
	
	
}
module.Base = {
	Unlocks = {
		CupSize = {
			Small = true,
			Medium = true,
			Large = true
		},
		MixIn = {
			["M&Ms"] = true,
			Marshmallow = true,
			Reeses = true,
			Strawberry = true,
			Blueberry = true,
			CookieDough = true,
			Oreos = true,
			Pineapple = true
		},
		Syrup = {
			Banana = true,
			Chocolate = true,
			Mint = true,
			Sherbet = true,
			Strawberry = true,
			Vanilla = true
		},
		BlendLevel = {
			Chunky = true,
			Regular = true,
			Smooth = true
		},
		WhippedCream = {},
		Sauce = {},
		Sprinkles = {},
		Placeables = {}
	},
	Inventory = {
		Unlocked = {},
		Equipped = {}
	},
	TotalPoints = 0,
	TotalCoins = 0,
	Rank = 1,
	Day = 1
}


module.Game = {
	Coins = 0,
	Points = 0,
	NumCreations = 0,
	Rank = ("__match" :: any) :: typeof(module.Base.Rank),
	Day = ("__match" :: any) :: typeof(module.Base.Day),
	Unlocks = ("__match" :: any) :: typeof(module.Base.Unlocks),
	Inventory = {
		Equipped = ("__match" :: any) :: typeof(module.Base.Inventory.Equipped)
	},
	Live = {
		Orders = {} :: {orderModule.Order},
		Creations = {} :: { orderModule.Order },
		Queues = {
			Build = ("__queue" :: any) :: queueMaker.Queue, --(build cant but its to simplify design process)
			Mix = ("__queue" :: any) :: queueMaker.Queue, --Mix/Top stations can have multiple drinks waiting but only allow one at a time
			Top = ("__queue" :: any) :: queueMaker.Queue,
		},
		Customer = {
			Served = {} :: { number },
			Waiting = {} :: { number }
		}
	}
}


--DataHandler creates the entries here so other scripts can edit easily
module.Shared = {} :: {
	[Player]: {
		Base: typeof(module.Base),
		Game: typeof(module.Game)?
	}
}









---------------------
local clone = table.clone
--assumes only regular datatypes are present
local cloneCommands = {}
cloneCommands.__match = function(i: any, v: "__match") : "__match" return v end --used elsewhere
cloneCommands.__queue = function(i: any, v: "__queue") : queueMaker.Queue return queueMaker.new() end

local function deepClone(t: any, antiLoop: {}?): any
	local antiLoop = antiLoop or { [t] = true }
	local c = clone(t)
	for i,obj in next, c do
		if typeof(obj) ~= "table" and assert(not antiLoop[obj], "Cyclic reference found, cannot clone") then
			--
			if cloneCommands[obj] then
				rawset(c, i, cloneCommands[obj](i,obj))
			end
			continue
		end
		antiLoop[obj] = true
		rawset(c, i, deepClone(obj, antiLoop))
		antiLoop[obj] = nil
	end
	return c
end


module.newEntry = function()
	return deepClone(module.Base)
end

--'of' entries called "__match" will be replaced by 'to'
--edits 'of' in-place
local function matchTables(of: {[any]:any}, to: {[any]:any})
	if not to then return end
	--
	for i,v in next, of do
		if typeof(v) == "table" then
			matchTables(v, to[i])
		elseif v == "__match" then
			of[i] = to[i]
		end
	end
	return
end
module.assignNewGameTo = function(playerData) --playerData is some derivative of module.Base
	local newGame = deepClone(module.Game)
	matchTables(newGame, playerData)
	--
	return newGame
end

--edits t in-place to have same entries as ref
local function fillGaps(t: {[any]:any}, ref: {[any]:any})
	for i,v in next, ref do
		if t[i] == nil then
			if typeof(v) == "table" then
				t[i] = deepClone(v)
			else
				t[i] = v
			end
		elseif typeof(v) == "table" then
			fillGaps(t[i], v)
		end
	end
	return
end

module.FillDataGaps = function(t)
	fillGaps(t, module.Base)
	return
end
return module

