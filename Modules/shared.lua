--just a shared library
--equiv to _G shared getgenv() etc
--extra functionality ig (onNewCreate could js be an __index mm )

shared.bell = shared.bell or {}
local shared = shared.bell

local module = {}
function module:Get(key: any, onNewCreate: any?): (any?, boolean) --gets key from table, if not present then set key & return it (2nd param says if it existed prior)
	if not shared[key] then
		return self:Set(key, onNewCreate), false
	end
	return shared[key], true
end
function module:Set(key: any, value: any): any 
	rawset(shared, key, value)
	return value
end
--ermm __index __newindex?
return module