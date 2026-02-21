local info = {
    [1] = 14,
    [2] = 26,
    [3] = 7,
    [4] = 8,
    e = 18, --table
    b = 15, --bool
    n = 30, --num
    s = 27, --string
    ee = 22, --exit nested table read
    ea = 23, --exit value-read (non table)
    u = 25, --lowercase,
    ne = 3, --next
    k = 17, --key: before, value: after
    c = 4, --comma (table values)
}

local tree = {
    {
        {
            {
                {53,52,72},
                {46,51,86},
                83
            },
            {
                {37, 47, 70},
                {58, 50, 43},
                85
            },
            73
        },
        {
            {
                {38,95,76},
                {43,61,45},
                82
            },
            {
                {nil,nil,80},
                {nil,49,74},
                87
            },
            65
        },
        69
    },
    {
        {
            {
                {54,61,66},
                {47,nil,88},
                68
            },
            {
                {nil,nil,67},
                {nil,nil,89},
                75
            },
            78
        },
        {
            {
                {55,nil,90},
                {nil,nil,81},
                71
            },
            {
                {56,nil,nil},
                {57,48,nil},
                79
            },
            77
        },
        84
    },
    32
}
local arctree = {[45] = 12123, [95] = 12112, [38] = 12111, [58] = 11221, [46] = 11121, [32] = 3,[69] = 13,[84] = 23,[73] = 113,[65] = 123,[78] = 213,[77] = 223,[83] = 1113,[85] = 1123,[82] = 1213,[87] = 1223,[68] = 2113,[75] = 2123,[71] = 2213,[79] = 2223,[72] = 11113,[86] = 11123,[70] = 11213,[76] = 12113,[80] = 12213,[74] = 12223,[66] = 21113,[88] = 21123,[67] = 21213,[89] = 21223,[90] = 22113,[81] = 22123,[53] = 11111,[52] = 11112,[51] = 11122,[50] = 11222,[43] = 12121,[49] = 12222,[54] = 21111,[61] = 21112,[47] = 21121,[55] = 22111,[56] = 22211,[57] = 22221,[48] = 22222}
local c, b = string.char, string.byte
local comma = c(info.c)
local bools = {
    ['true'] = true,
    ['false'] = false
}
local typetable = {
    string = 's',
    number = 'n',
    table = 'e',
    boolean = 'b'
}
local function find(tbl, val)
    for i,v in next, tbl do if v == val then return i end end
    return
end
local function isescape(str)
    local ind = find(info, b(str))
    return ind and type(ind) == 'string' and ind
end
local function tf(tbl, item)
    for i,v in next, tbl do
        if v == item then return i end
    end
   return 
end
local function split(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        local s = "([^"..sep.."]+)"
        for str in string.gmatch(inputstr, s) do
            table.insert(t, str)
        end
        return t
end
local function totalsplit(str)
    local n = {}
    for i = 1, #str do table.insert(n, str:sub(i,i)) end
    return n
end
local function let(str)
    str = totalsplit(tostring(str))
    local res
    local st = tree
    for i = 1, #str do
        local s = tonumber(tf(info, b(str[i])))
        local off = 0
        if (s == 4) then s = s - 1 off = 32 end
        st = st[s]
        if (type(st) == 'number') then st = st + off end
    end
    assert(st and type(st) == 'number')
    res = c(st)
    return res
end
local function parse(tbl, cc)
    if (type(tbl) == 'string') then
        tbl = split(tbl:reverse():gsub("\n.*$", ""):reverse(), "\3")
    end
    local result = ''
    for i,v in next, tbl do result = result..let(v) end
    return result
end
local function aparse(num)
    num = tostring(num)
    local res = ""
    for i = 1, #num do
        local n = tonumber(num:sub(i,i))
        if (n and info[n]) then
            res = res..c(info[n])
        end
    end
    return res
end
local function to(str)
    str = tostring(str)
    local res = ""
    for i = 1, #str do
        local s, lw = str:sub(i,i), 0
        local ce = b(s)
        if (s:upper() ~= s) then lw = 1 ce = ce - 32 end 
        if arctree[ce] then
            res = res.."\3"..aparse(arctree[ce] + lw)
        end
    end
    return res:sub(2)
end

local tableencode,tabledecode = (function() 
    --[[local types = {
        k = 17, --key: before, value: after
        e = 18, --table
        ee = 22, --exit table scope
        ea = 23, --exit value-read (non table)
        n = 30, --num
        s = 27, --string
        c = 4, --comma (table values)
    }]]
    
    local function csplit(str)
        local x = {}
        local scope = 0
        local start = str
        while true do
            local comma, nest = start:find(comma), start:find"^\18[\14\26\7\8]*\17"
            if not comma then
                if #start > 0 then table.insert(x, start) end
                break
            elseif not nest then
                local value = start:sub(1,comma-1)
                start = start:sub(comma+1)
                if #value > 0 then table.insert(x, value) end
            elseif nest < comma then
                local chunk = start:sub(nest)
                local value = ""
                scope = 0 --always pushes to 1
                for i = 1, #chunk do
                    local char = b(chunk:sub(i,i))
                    if char == info.e then scope = scope + 1
                    elseif char == info.ee then scope = scope - 1 end
                    value = value..c(char)
                    if (scope == 0) then break end
                end
                assert(scope == 0, 'unequal table grouping.')
                start = start:sub(nest + #value)
                table.insert(x, value)
            end
        end
        return x
        --[[
        for i in str:gmatch("[^"..comma.."]+") do --for nested tables
            local a1, a2 = #spillover > 0, i:find()
            if a1 or a2 then
                if a2 then scope = scope + 1 end
                spillover = spillover..(a1 and comma or "")..i
                if i:reverse():find("^"..ch(info.ee)) then
                    scope = scope - 1
                    if (scope == 0) then
                        table.insert(x, spillover)
                        spillover = ""
                    end
                end
            else
                table.insert(x, i)
            end
        end]]
        
    end
    local function decode(str, recursed)
        local str = (type(str) == 'table' and str) or csplit(str:reverse():gsub("\n.*$", ""):reverse())
        local new = {}
        
        for i,v in next, str do
            local data = v
            local type = isescape(data)
            data = data:sub(2,-1) --remove identifier
            
            if rawequal(type, "n") then
                local _start, _end = data:find(c(info.k))
                assert(_start, "Invalid key.")
                local key = parse(data:sub(1, _end-1))
                local ending = data:find(c(info.ea))
                assert(ending, "Read left open for key: "..key)
                local value = tonumber(parse(data:sub(_end+1, ending - 1)))
                assert(value, "Invalid double for key: "..key)
                new[
                    tonumber(key) and tonumber(key) or key
                    ] = value
            elseif rawequal(type, "b") then
                local _start, _end = data:find(c(info.k))
                assert(_start, "Invalid key.")
                local key = parse(data:sub(1, _end-1))
                local ending = data:find(c(info.ea))
                assert(ending, "Read left open for key: "..key)
                local value = bools[parse(data:sub(_end+1, ending - 1))]
                assert(value ~= nil, "Invalid boolean for key: "..key)
                new[
                    tonumber(key) and tonumber(key) or key
                    ] = value
            elseif rawequal(type, "s") then
                local _start, _end = data:find(c(info.k))
                assert(_start, "Invalid key.")
                local key = parse(data:sub(1, _end-1))
                local ending = data:find(c(info.ea))
                assert(ending, "Read left open for key: "..key)
                local value = parse(data:sub(_end+1, ending - 1))
                new[
                    tonumber(key) and tonumber(key) or key
                    ] = value
            elseif rawequal(type, "e") then
                local _start, _end = data:find(c(info.k))
                assert(_start, "Invalid key.")
                local key = parse(data:sub(1, _end-1))
                local ending = data:reverse():find(c(info.ee)) --last index of closetbl
                assert(ending, "Unclosed table for key: "..key)
                ending = #data - ending
                local newtblstr = data:sub(_end+1, ending)
                --if #newtblstr ~= 0 then
                    local value = decode(newtblstr, true)
                    new[
                        tonumber(key) and tonumber(key) or key
                        ] = value
                --end
            else
                error"Invalid decode format."
            end
        end
        return new
    end
    local function encode(tbl, nocycles, recursed)
        recursed = (recursed or -1) + 1
        nocycles = nocycles or {}
        local str = ""
        local ctr = 0
        for i,v in next, tbl do
            if ctr > 0 then str = str..comma end
            local type = type(v)
            type = typetable[type] or error("unsupported type: "..type)
            if type ~= 'e' then
                str = str..c(info[type])
                ..to(i)..c(info.k)
                ..to(v)..c(info.ea)--..c(info.c)
            else
                --print()
                assert(not tf(nocycles, v), "Cyclic table detected.")
                
                local data = encode(v, nocycles, recursed)
                table.insert(nocycles, v) --no cyclic detection = stack overflow
                local newentry = c(info.e)..to(i)..c(info.k)..(data or "")..c(info.ee)
                str = str..newentry
            end
    --append to old:   [datatype],      [keyname],   [key-value separator], [value], [END OF READ], [comma]
            ctr = ctr + 1
        end
        return str, ctr, recursed
    end
    return encode, decode
end)()
local module = {
    DecodeText = parse,
    EncodeText = to,
    EncodeTable = tableencode,
    DecodeTable = tabledecode,
    FetchSave = function(path)
        if not isfile(path) then return end
        local a, save = pcall(tabledecode, readfile(path))
        if a then return save end
        return 
        -- some ppl like `if fetchsave() == nil`
        -- instead of just `if not fetchsave()`
        -- looks so ugly
        -- `return a and save` on top...
    end,
    SaveTo = function(path, tbl)
        return writefile(path, tableencode(tbl)) or path
    end
}
return module
