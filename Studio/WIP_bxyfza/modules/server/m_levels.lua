local module = {
	Levels = {
		[1] = {
			Customers = {}
		}
	}
}
function module.GetLevel(n: number)
	return module.Levels[n]
end
return module
