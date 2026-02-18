--!strict
local module = {}

--functions
local find = table.find
local max = math.max
local insert = table.insert
local concat = table.concat
local clone = table.clone
--order object type/typing help
local dummyVar : any = nil
local orderMT : {
	Equals: (self: Order, other: Order)->boolean,
	--__tostring: (self: Order)->string, --it can just return itself as a table memory address 
	GetIngredient:(self: Order, offset: number?)->string | {string},
	SetIngredient:(self: Order, Ingredient: string, value: string)->nil,
	ScoreIngredient: (self: Order, Ingredient: string, score: number, index: number?)->nil,
	GetIngredientScore: (self:Order, ingName: string, index: number?) -> number,
	Lock: (self: Order)->nil,
	SetId: (self: Order, Id: number)->nil,
	GetId: (self: Order)->number,
	Unlock: (self: Order)->nil,
	__index: any
} = {
	GetIngredient = dummyVar,
	SetIngredient = dummyVar,
	ScoreIngredient = dummyVar,
	GetIngredientScore = dummyVar,
	Lock = dummyVar,
	Unlock = dummyVar,
	SetId = dummyVar,
	GetId = dummyVar,
	--__tostring = dummyVar,
	Equals = dummyVar
}
orderMT.__index = orderMT
local ingredOrder: {string | {string}} = {
	"CupSize",
	"MixIn",
	"Syrup",
	"BlendLevel",
	"WhippedCream",
	{"Sauces", "Sprinkles", "Placeables"}
}
type ScoreBlock = { Name: string, Score: number }
type ScoreBlockArr = { ScoreBlock }
local emptyScoreBlock: ScoreBlock = {Name = "None", Score = -1}
local ingredTbl: {
	CupSize: ScoreBlock,
	MixIn: ScoreBlock,
	Syrup: ScoreBlock,
	BlendLevel: ScoreBlock,
	WhippedCream: ScoreBlock,
	--
	Sauces: ScoreBlockArr,
	Sprinkles: ScoreBlockArr,
	Placeables: ScoreBlockArr
}

local orderData: {
	Locked: boolean,
	Id: number,
	Ingredients: typeof(ingredTbl),
	NextIngredient: number,
}
export type Order = typeof( setmetatable({} :: typeof(orderData), {__index = orderMT}) )
--
orderMT.Lock = function(self: Order): nil
	self.Locked = true
	return
end
orderMT.Unlock = function(self: Order): nil
	self.Locked = false
	return
end
orderMT.GetIngredient = function(self: Order, offset: number?): string | {string}
	local ingredIndx = max(1, self.NextIngredient + (offset or 0) - 1) --can go 'over' total ingredients but not under the start.
	return not self.Locked and ingredOrder[ingredIndx] or "None" --"None" is returned once CurrentIngredient > #ingredOrder
end
orderMT.SetIngredient = function(self: Order, Ingredient: string, name: string): nil
	assert(not self.Locked, "Cannot edit locked order")
	local nextIngredient = self:GetIngredient(1)
	assert(nextIngredient ~= "None", "Order is already completed")
	--
	if typeof(nextIngredient) == "table" then
		assert(find(nextIngredient, Ingredient), "Expected ("..concat(nextIngredient,"/").."), got "..Ingredient)
		insert(self.Ingredients[Ingredient], {
			Name = name,
			Score = -1
		})
	else
		assert(nextIngredient == Ingredient, "Expected "..nextIngredient..", got "..Ingredient)
	end
	self.Ingredients[Ingredient] = {
		Name = name,
		Score = -1
	}
	self.NextIngredient += 1
	return
end

orderMT.GetIngredientScore = function(self:Order, ingName: string, index: number?): number
	local ingredData = self.Ingredients[ingName]
	local ingred : ScoreBlock = ingredData
	if not ingred.Name then
		--ingred : {ScoreBlock}
		ingred = ingred[index :: number] :: ScoreBlock
		assert(ingred, "No index "..tostring(index).." in ingredient "..ingName)
	end
	--ingred : ScoreBlock
	return ingred.Score
end
orderMT.ScoreIngredient = function(self: Order, ingName: string, score: number, index: number?): nil
	local ingredData = self.Ingredients[ingName]
	local ingred : ScoreBlock = ingredData
	if not ingred.Name then
		--ingred : {ScoreBlock}
		ingred = ingred[index :: number] :: ScoreBlock
		assert(ingred, "No index "..tostring(index).." in ingredient "..ingName)
	end
	--ingred : ScoreBlock
	ingred.Score = score
	return
end
orderMT.SetId = function(self: Order, Id: number): nil
	assert(tonumber(Id), "Not a number")
	self.Id = tonumber(Id) :: number
	return
end
orderMT.GetId = function(self: Order): number
	return self.Id
end

orderMT.Equals = function(self: Order, other: Order): boolean
	local sIng, oIng = self.Ingredients, other.Ingredients
	for ing, value in next, sIng do
		if typeof(value) == "table" then --for placeables and sprinkles
			local other : {{Name: string, Score: number}} = oIng[ing]
			if #value ~= #other then return false end
			
			for k,v  in next, value do
				local o = other[k]
				if v.Name ~= o.Name then --will have to remake / remove this bc its not a good comparer
					return false
				end 
			end
			--
		elseif value ~= oIng[ing] then
			return false
		end
	end
	return true
end
--

local proxymt = {__index = orderMT}
module.new = function(data : typeof(ingredTbl)?)
	return setmetatable({
		Locked = data and true,
		Id = -1,
		Ingredients = data or {
			CupSize = clone(emptyScoreBlock),
			MixIn = clone(emptyScoreBlock),
			Syrup = clone(emptyScoreBlock),
			BlendLevel = clone(emptyScoreBlock),
			WhippedCream = clone(emptyScoreBlock),
			Sauces = {},
			Sprinkles = {},
			Placeables = {}
		} :: typeof(ingredTbl),
		NextIngredient = 1
	}, proxymt) :: Order
end

return module
