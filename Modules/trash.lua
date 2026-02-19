--cleans tables
local trashedmt = { __mode = 'kv' }
local function trash(tbl: table, optreturn: any?, recursive: boolean?, ignorelist: table?): any?
	
    if not type(tbl) == 'table' then --cant do anything
        return optreturn
    elseif not recursive then -- only empty current table, not nested ones
        for i,v in next, tbl do
            rawset(tbl, i, nil)
        end
    else
		ignorelist = ignorelist or { [tbl] = true } -- to prevent inf recursion via cyclic tables
        for i,v in next, tbl do
            if type(v) == 'table' and not ignorelist[v] then
				ignorelist[v] = true
				trash(v, nil, true, ignorelist) --recursively trash()
			end
            --if type(i) == 'table' and not ignorelist[i] then ignorelist[i] = true trash(i, nil, true, ignorelist) end
            rawset(tbl, i, nil)
        end
    end
    setmetatable(tbl, trashedmt)
    return optreturn
end
return trash