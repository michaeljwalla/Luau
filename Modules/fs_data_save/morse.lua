local info = {
    [1] = 14,
    [2] = 26,
    [3] = 7,
    [4] = 8
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
                {47,39,88},
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
local arctree = {[39] = 21122, [45] = 12123, [95] = 12112, [38] = 12111, [58] = 11221, [46] = 11121, [32] = 3,[69] = 13,[84] = 23,[73] = 113,[65] = 123,[78] = 213,[77] = 223,[83] = 1113,[85] = 1123,[82] = 1213,[87] = 1223,[68] = 2113,[75] = 2123,[71] = 2213,[79] = 2223,[72] = 11113,[86] = 11123,[70] = 11213,[76] = 12113,[80] = 12213,[74] = 12223,[66] = 21113,[88] = 21123,[67] = 21213,[89] = 21223,[90] = 22113,[81] = 22123,[53] = 11111,[52] = 11112,[51] = 11122,[50] = 11222,[43] = 12121,[49] = 12222,[54] = 21111,[61] = 21112,[47] = 21121,[55] = 22111,[56] = 22211,[57] = 22221,[48] = 22222}
local c, b = string.char, string.byte
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
local function parse(tbl)
    if (type(tbl) == 'string' or type(string) == 'number') then
        tbl = split(tbl:reverse():gsub("\n.*$", ""):reverse(), "\3")
    end
    local result = ''
    for i,v in next, tbl do result = result..let(v) end
    return result
end
local function aparse(num, convert)
    num = tostring(num)
    local res = ""
    for i = 1, #num do
        local n = tonumber(num:sub(i,i))
        if (n and info[n]) then
            res = res..(convert and c(info[n]) or info[n])
        end
    end
    return res
end
local function to(str, uR)
    uR = not uR
    str = tostring(str)
    local res = ""
    for i = 1, #str do
        local s, lw = str:sub(i,i), 0
        local ce = b(s)
        if (s:upper() ~= s) then lw = 1 ce = ce - 32 end 
        if arctree[ce] then
            res = res.."\3"..aparse(arctree[ce] + lw, uR)
        end
    end
    return res:sub(2)
end
return {
    Encode = to,
    Decode = parse
}