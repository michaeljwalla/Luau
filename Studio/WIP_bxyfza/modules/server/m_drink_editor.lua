--!strict
local sss = game:GetService("ServerScriptService")
local rs = game:GetService("ReplicatedStorage")
local rsModules = rs:WaitForChild("Modules")

local dataCreator = require("./DataCreator")
local orderModule = require(rsModules.Game:WaitForChild("Order"))

local worldDrinksFolder = workspace:WaitForChild("DrinkModels")
local scenesFolder = workspace:WaitForChild("Scenes")
local drinkPartsFolder = workspace:WaitForChild("DrinkParts")

local worldModelIngredientFuncs = {}--: {[string]: (pData: typeof(dataCreator.Game), order: orderModule.Order, addWhat: string)->(...any)} = {}
local function worldModelAddIngredient(pData: typeof(dataCreator.Game), order: orderModule.Order, addType: string, addWhat:string): nil
	local ingredUnlocked : boolean = pData.Unlocks[addType][addWhat]
	if not ingredUnlocked then warn("Attempted ingredient "..addWhat.." is not unlocked")return end
	--
	local f = worldModelIngredientFuncs[addType]
	return f and f(pData,order, addWhat)
end
local function worldGetDrink(id: number) : Model?
	return worldDrinksFolder:FindFirstChild(id) :: Model
end
local module = {
	Funcs = worldModelIngredientFuncs,
	worldAddIngredient = worldModelAddIngredient
}
-----------------------------------
--build station
local function newDrinkModel(id: number): Model
	local new = Instance.new("Model")
	new.Name = tostring(id)
	return new
end
local function getDrinkModel(id: number)
	return worldDrinksFolder:FindFirstChild(tostring(id))
end
module.GetDrinkModel = getDrinkModel
do
	local buildScene = scenesFolder:WaitForChild("Build")
	local cupsFolder = drinkPartsFolder:WaitForChild("Cups")
	--this one is different bc the cup is always the first item in an order
	worldModelIngredientFuncs.CupSize = function(pData: typeof(dataCreator.Game), order: orderModule.Order, addWhat: string) 
		local cup = cupsFolder:FindFirstChild(addWhat) :: Model
		assert(cup, "No cup of type "..addWhat.." exists")
		
		local newDrink = newDrinkModel(order.Id)
		local newCup = cup:Clone()
		newCup.Name = "Cup"
		newCup.Parent = newDrink
		--
		newDrink.Parent = worldDrinksFolder
	end
	worldModelIngredientFuncs.FillCup = function(pData: typeof(dataCreator.Game), order: orderModule.Order)
		local drinkModel: Model = getDrinkModel(order.Id)
		warn("Add server FillCup")
		return
	end
	worldModelIngredientFuncs.MixIn = function(pData: typeof(dataCreator.Game), order: orderModule.Order)
		local drinkModel: Model = getDrinkModel(order.Id)
		warn("Add server MixIn")
		return
	end
	worldModelIngredientFuncs.Syrup = function(pData: typeof(dataCreator.Game), order: orderModule.Order)
		local drinkModel: Model = getDrinkModel(order.Id)
		warn("Add server Syrup")
		return
	end
end


return module