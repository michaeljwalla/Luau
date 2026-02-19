local morse = loadstring(readfile"bell/morse.lua")()
local c = string.char
local key = {
    Valid = {
        string = c(27),
        number = c(30),
        boolean = c(15),
        table = c(18)
    },
    NameDelimiter = c(23),
    TypeDelimiter = c(25),
    Comma = c(4),
    --for tables
    Opening = c(22),
    Closing = c(17)
    
}
--function to turn tbl into string
local function isValid(item)
    return key.Valid[typeof(item)] ~= nil
end
local function stringify(tbl, nocycles)
    nocycles = nocycles or {}
    local result = ""
    for i,v in next, tbl do
        assert(("stringnumber"):find(typeof(i)), "Only numeric/string values for keys")
        assert(isValid(v), "Unsaveable type ("..typeof(v)..") at key \""..i.."\"")
        result = result..morse.Encode(i)..key.NameDelimiter..key.Valid[typeof(v)]..key.TypeDelimiter..(typeof(v) == 'table' and assert(not nocycles[v], "Cyclic tables cannot be saved.") and (not rawset(nocycles, v, true) or stringify(v, nocycles)) or (--[[not nm and]] morse.Encode(v) or tostring(v)))..key.Comma
        if type(v) == 'table' then rawset(nocycles, v, nil) end
    end
    return key.Opening..result:sub(1,-2)..key.Closing
end

local function parseWithType(data, ofType)
    local some, stuff = pcall(morse.Decode, data)
    if not some then return
    elseif ofType == key.Valid.number then local x, num = pcall(tonumber, stuff) return x and num
    elseif ofType == key.Valid.boolean then return stuff == "true"--true -> true, false -> false
    end
    return stuff --string
end
local debracer = ("^%s(.*)%s$"):format(key.Opening, key.Closing)
local function destringify(str, recursed)
    recursed = recursed or 0
    local decoded = {}
    str = str:gsub(debracer, "%1") --remove braces
    
    local transpose = str
    while true do
        local endName, endType = transpose:find(key.NameDelimiter), transpose:find(key.TypeDelimiter)
        if not (endName or endType) then break end
        local curKey = morse.Decode(transpose:sub(1, endName-1))
        curKey = tonumber(curKey) or curKey
        local curType = transpose:sub(endName+1,endType-1)
        transpose = transpose:sub(endType+1)
        local curData, nextEntry
        --print(curKey)
        if curType ~= key.Valid.table then
            --print("not tbl")
            nextEntry = transpose:find(key.Comma)
            curData = transpose:sub(1, (nextEntry and nextEntry -1) or -1) --unreadable
            decoded[curKey] = parseWithType(curData, curType)
            --print(decoded[curKey])
        else
            local startings, endings = 0, 0
            local searchthrough = transpose
            local isAt = 1
            while true do
                local char = searchthrough:sub(isAt,isAt)
                if char == '' then
                    break
                elseif char == key.Opening then 
                    startings = startings + 1
                elseif char == key.Closing then 
                    endings = endings + 1
                end
                if startings == endings then
                    searchthrough = searchthrough:sub(1,isAt)
                    --print('recursing '..recursed+1)
                    decoded[curKey] = destringify(searchthrough, recursed+1)
                    --print('finished recursion '..recursed+1)
                    nextEntry = isAt+1
                    break
                end
                isAt = isAt + 1
            end
        end
        if not nextEntry then break end
        transpose = transpose:sub(nextEntry+1)
    end
    return decoded
end
--writefile("test.txt", stringify({5,4,5,6,126,4,"hello world", {69, {{{false}}}}}))

--[[local sample = {
    LastPlayback = {
        Name = "hi",
        RecordMetadata = { --can only be edited before starting the recording (wouldnt make sense if not)
            Type = "Distance",
            Distance = { Interval = 5, TotalSteps = 0 },
            Time = { Interval = 1/3, TimeLength = 0 },
        },
        InvertPlayback = false,
        PlayPosition = 0,
        Steps = {},
        
        WalkSpeed = nil,
        JumpPower = nil,
    }
    
}
writefile("bell/testing.bll", stringify(sample))
local x = destringify(readfile"bell/testing.bll")
for i,v in pairs(x.LastPlayback) do print(i,v) end]]
local defaults = {
    string = '"%s"',
    number = '%d',
    boolean = "%s"
}
local function stringtable(tbl, depth, entries)
    entries = entries or {}
    depth = depth or 0
    assert(not entries[tbl], "Cyclic tables cannot be formatted.")

    local defindent = ("  | "):rep(depth)
    local defindenttbl = defindent.."{ %s } ┐ \n%s"
    defindent = defindent.."[ %s ] = %s\n"

    local output = ""
    for i,v in next, tbl do
        
        local ti, tv = type(i), type(v)
        assert(("stringnumber"):find(typeof(i)), "Only numeric/string values for keys")
        assert(isValid(v), "Unsaveable type ("..typeof(v)..") at key \""..i.."\"")

        if tv == 'table' then
            entries[tbl] = true
            output = output..defindenttbl:format(defaults[ti]:format(i), stringtable(v, depth+1, entries))
            rawset(entries, tbl, nil)
        else
            output = output..defindent:format(defaults[ti]:format(i), defaults[tv]:format(tostring(v)))
        end
    end
    return output
end
local module; module = {
    Create = stringify,
    Parse = destringify,
    EncodeStr = morse.Encode,
    DecodeStr = morse.Decode,
    SetSave = function(path, data)
        writefile(path..".bll", stringify(data))
        return
    end,
    GetSave = function(path)
        if not isfile(path..".bll") then return end
        local x, stuff = pcall(destringify, readfile(path..".bll"))
        return x and stuff
    end,
    StringifySave = function(path)
        return stringtable(module.GetSave(path) or error"File does not exist!")
    end
}
return module