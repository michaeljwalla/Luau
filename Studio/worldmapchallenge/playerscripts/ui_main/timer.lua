local text = script.Parent
local starting = tick()
function formattime(num)
	num = math.floor(num)
	local datatbl = {Hour = 0, Minute = 0, Second = 0}
	local hour = num/3600
	if hour >= 1 then
		datatbl.Hour = math.floor(hour)
		num = num-datatbl.Hour*3600
	end
	local minute = num/60
	if minute >= 1 then
		datatbl.Minute = math.floor(minute)
		num = num-datatbl.Minute*60
	end
	datatbl.Second = math.floor(num)
	for i,v in pairs(datatbl) do
		if v < 10 then datatbl[i] = "0"..v end
	end
	return ("%s : %s : %s"):format(datatbl.Hour,datatbl.Minute,datatbl.Second)
end


while task.wait() do
	text.Text = formattime(tick()-starting)
end