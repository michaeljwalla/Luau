--lets me require other modules in the workspace easily
-- line1 : local require = loadfile"bell/new/require.lua""";

--get with the times synapse
local getthread, rethread
if syn then
    getthread, rethread = syn.get_thread_identity, syn.set_thread_identity
else
    getthread, rethread = getthreadidentity, setthreadidentity
end

local robloxrequire = require
local function require(module: string | Instance, recache: boolean?): any?
    shared.requirecache = shared.requirecache or {} --to cache modules

    if (typeof(module) ~= 'string') then --possible instance?
        local pre = getthread()
        rethread(2) --since it likes to bug out sometimes (attempt to require roblox module from non roblox script or whatever)
        local value = robloxrequire(module)
        rethread(pre)
        return value --no requirecache since roblox will do it for me
    elseif module:find"^https?://" then --possible link?
		if not recache and shared.requirecache[module] then return shared.requirecache[module] end --return cached if not explicitly told to recache

		local name = module:sub(1,12)
		local chunk = loadstring(game:HttpGet(module), module:sub(1,12)) --2nd param names it after the link (w/ len cutoff)
		
        assert(chunk, "Error in webmodule: "..name) --compile err
		chunk = chunk()
		shared.requirecache[module] = chunk
		return chunk 
    else --possible file?
        if not recache and shared.requirecache[module] then return shared.requirecache[module] end

        local n, a = pcall(readfile, module..".lua") --loadfile whoops
        --print(({a:gsub("\n","\n")})[2] + 1) --terrible line counter

        assert(n, "No local module '"..module.."'") --file not found
        local chunk = loadstring(a, module)
        assert(chunk, "Error in local module: "..module) -- compile err

        chunk = chunk()
		shared.requirecache[module] = chunk
		return chunk
    end
end
return require