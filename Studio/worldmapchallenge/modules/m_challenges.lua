--[[
	instructions for if i forget
	
	only metamethod that needs to be called is __update (maybe __stringify or __deepcopy for misc use)
	calling __update on main table (from requiring) a clone is made (__deepcopy)
	store clone as updated table
	(this is so the game can be restarted without data from previous games overlapping)
	metatable is saved between copies!!
	calling __update on clone will work
	now, first parameter isn't necessary (since it cloned only a branch)
	ex:
		local x = require(game.ReplicatedStorage.Challenges)
		local newtable = x.__update("{{Table name}}", "{{Country Name}}")
		newtable = newtable.__update(nil, "{{Country Name}}")
		etc etc
	calling __update(NOT nil, ...) won't break code either
	once function sees that self[p1] doesnt exist itll set the table-to-update to itself (which is what it does when p1 == nil)
	
	tldr:
	require table
	save table.__update(level, country) to save new instance of table 
	(its a deep copy to protect original values)
	resave var as self.__update() every time a country is 'found'
]]
local funcs = require(game.ReplicatedStorage.Functions)
local chal = {}
local map = workspace['hello exploiter']
chal.Default = {
	['Morocco'] = {map.Africa.North["Morocco -"]},
	['Egypt'] = {map["The Middle East"]["Egypt -"]},
	['Turkey'] = {map['The Middle East']['Turkey -']},
	['Isreal'] = {map['The Middle East']['Isreal -']},
	['Saudi Arabia'] = {map['The Middle East']['Saudi Arabia -']},
	['Iran'] = {map['The Middle East']['Iran -']},
	['United Kingdom'] = {map.Europe['United Kingdom -']},
	['Spain'] = {map.Europe['Spain -']},
	['Russia'] = {map.Europe['Russia -'], map.Asia.Central['Russia -'], map.Asia.East['Russia -'], map.Asia['Siberia / North']['Russia -']},
	['Germany'] = {map.Europe['Germany -']},
	['France'] = {map.Europe["France -"]},
	['Italy'] = {map.Europe["Italy -"]},
	['Nigeria'] = {map.Africa.West['Nigeria -']},
	['Ghana'] = {map.Africa.West["Ghana -"]},
	['Mali'] = {map.Africa.West["Mali -"],map.Africa.North["Mali -"]},
	['Kenya'] = {map.Africa.East["Kenya -"]},
	['Ethiopia'] = {map.Africa.East["Ethiopia -"]},
	['Congo'] = {map.Africa.Central["Congo -"]},
	['Rwanda'] = {map.Africa.Central["Rwanda -"]},
	['South Africa'] = {map.Africa.Southern["South Africa -"]},
	['India'] = {map.Asia.South["India -"]},
	['Pakistan'] = {map.Asia.South["Pakistan -"]},
	['Vietnam'] = {map.Asia.Southeast["Vietnam -"]},
	['Indonesia'] = {map.Asia.Southeast["Indonesia -"]},
	['Mexico'] = {map.America.Central["Mexico -"]},
	['Brazil'] = {map.America.Latin["Brazil -"]},
	['Haiti'] = {map.America.Latin["Haiti -"]},
	['Argentina'] = {map.America.Latin["Argentina -"]},
	['Peru'] = {map.America.Latin["Peru -"]},
	['Jamaica'] = {map.America.Latin["Jamaica -"]},
	['China'] = {map.Asia.East["China -"]},
	['Japan'] = {map.Asia.East["Japan -"]},
	['Korea'] = {map.Asia.East["Korea -"]},
	['Afghanistan'] = {map["The Middle East"]["Afghanistan -"]},
}

local mt = {}
mt.__index = function(self, index)
	if index == '__length' then
		local function count(challenge)
			local choice = (challenge and (self[challenge] or self)) or self
			if not choice then return end
			local x = 0
			for i,v in pairs(choice) do
				x += 1
			end
			return x
		end
		return count
	elseif index == '__deepcopy' then
		local function deepcopy(challenge)
			local choice = (challenge and (self[challenge] or self)) or self
			if not choice then return end
			local newtable = setmetatable({}, mt)
			for i,v in pairs(choice) do
				rawset(newtable,i,v)
			end
			return newtable
		end
		return deepcopy
	elseif index == '__remaining' then
		local function getremains(challenge)
			local choice = (challenge and (self[challenge] or self)) or self
			if not choice then return end
			local newtable = {}
			for i,v in pairs(choice) do
				if choice[i] then rawset(newtable, i, v) end
			end
			return setmetatable(newtable, mt)
		end
		return getremains
	elseif index == '__update' then
		local function update(challenge, country)
			local choice = country and ((challenge and (self[challenge] or self)) or self)
			if not choice then return end
			local newtable = (challenge and self.__deepcopy(challenge)) or self
			country = country:gsub(" %-", "")
			for i,v in pairs(newtable) do 
				if i == country then 
					newtable[i] = nil
					break 
				end 
			end
			local found = newtable.__remaining()
			return found, found.__length()
		end
		return update
	elseif index == '__stringify' then
		local function stringify(challenge)
			local choice = (challenge and (self[challenge] or self)) or self
			if not choice then return end
			local text = ''
			for i,v in pairs(choice) do
				text..=i..', '
			end
			return text:sub(1,#text-2)
		end
		return stringify
	elseif index ==  '__random' then
		local function random(subtable)
			local len = self.__length(subtable)
			if len == 0 then return {} end
			local random = math.random(1, len)
			subtable = subtable or self
			local x = 0
			for i,v in pairs(subtable) do
				x = x + 1
				if x == random then
					return {Index = i, Value = v}
				end
			end
		end
		return random
	end
	
	
end

return setmetatable(chal, mt)
