--!strict
local ingredTbl: {
	CupSize: string,
	MixIn: string,
	Syrup: string,
	BlendLevel: string,
	WhippedCream: string,
	Sauce: string,
	Sprinkles: {
		string
	},
	Placeables: {
		string
	}
}

local module : {
	Customers: {[string]: typeof(ingredTbl)},
	NewModel: (c: string) -> Model,
	GetOrder: (c:string)-> typeof(ingredTbl)
}= { Customers = {}, NewModel = nil :: any, GetOrder = nil :: any }

module.NewModel = function(c: string): Model
	return script:FindFirstChild(c) and script[c]:Clone()
end
module.GetOrder = function(c: string): typeof(ingredTbl)
	return module.Customers[c]
end
--Customers
local customers = module.Customers
customers["Test1"] = {
	CupSize = "Medium",
	MixIn = "Blueberries",
	Syrup = "Chocolate",
	BlendLevel = "Regular",
	WhippedCream = "Regular",
	Sauce = "None",
	Sprinkles = {},
	Placeables = {}
}
return module
