--add comments to me and trash

-- connection handler/formatter with extra capability
local require = loadfile"bell/new/require.lua"""

--modules/externals
local shared = require"bell/new/shared"

--local module setup
local module = shared:Get("StepperModule", { Functions = {}, Delays = {}, Connections = {}, ContextActions = {} })

--constants
local cx = game:GetService"ContextActionService"
local defer = task.defer
local wrap = coroutine.wrap
local funcs, cons, contexts = module.Functions, module.Connections, module.ContextActions

local nan = 0/0
--functions
local function toentryname(inst: Instance, step: string): string --creates an id from 'inst' and its RBXScriptSignal 'step'
    return inst:GetDebugId().."|"..step
end
--the actual connection created by Stepper, returns id^
--only gets connected ONCE to any Instance|Signal; does NOT immediately contain user code, rather iterates through a table which can have funcs added/removed
local function estnewconnection(inst: Instance, step: string, pre: string?): string
    local entryname = pre or toentryname(inst, step) --generate id
    if cons[entryname] and cons[entryname].Connected then --if a given connection already exists for the id, do nothing
        return entryname
    elseif not cons[entryname] then --else create an entry which user can add functions to run when signal activated
        funcs[entryname] = {}
    end
    local funcs = funcs[entryname]
    local signal = (step:find"^!" and inst:GetPropertyChangedSignal(step:sub(2))) or inst[step] -- to use getpropchangedsignal(), make step = "!<Property>" ; else default to inst[step] signal
    
    local new = signal:Connect(function(...) --create the connection, ... bc connections have varying #args
        local curtime = tick()
        for i,v in next, funcs do --for every function added to this connection's table...
            if not v.Active or curtime - v.LastRun < v.Delay then continue else v.LastRun = curtime end --ignore if func is disabled or last run was shorter than specified delay
            
            if v.Deferred then defer(v.Function, ...) else wrap(v.Function)(...) end --ex a func that immediately destroys an inst's children needs to be deferred() or else it will error (attempt to destroy while setting parent)
        end
    end)
    cons[entryname] = new --save the connection
    return entryname
end

--methods
function module:AddContext(name: string, func: f, createtouchbtn: boolean, priority: number, ...: UserInputType | KeyCode): string --compatiblity for contextactionservice (maybe improve if i end up needing to use it more)
    cx:BindActionAtPriority(name, func, createtouchbtn, priority, ...)
	contexts[name] = true
    return name
end
function module:RemoveContext(name: string): nil
	if not contexts[name] then return end
	rawset(contexts, name, nil)
    cx:UnbindAction(name)
end
function module:Remove(inst: Instance, step: string, fname: string?): (string, string) -- does not take signal as param, takes instance and signal name + name given to function
    local entryname
    if typeof(inst) == 'string' then --for when connection name is returned from :Get(), :Add()
        entryname = inst  --(2 param "overload")
        fname = step
    else
        entryname = toentryname(inst, step)
    end

	local functable = funcs[entryname]
    if not functable then return end
    rawset(functable, fname, nil)
	
    if not next(functable) then --no functions in it = no reason for connection
        cons[entryname]:Disconnect()
        rawset(cons, entryname, nil)
        rawset(funcs, entryname, nil)
    end
    return entryname, fname
end

--what to use to create a connection
--returns a tuple which can be used to immediately call :Remove()
--usually i save the connections by doing somesharedtable["someidentifyingname"] = { stepper:Add(...) } ;  stepper:Remove( unpack(somesharedtable["someidentifyingname"]) )
function module:Add(inst: Instance, step: name, fname: name, func: f, deloverride: number?, deferred: boolean?): (string, string)
	local cname = toentryname(inst, step)
	if(funcs[cname] and funcs[cname][fname]) then --recreate connection & warn
		warn("A connection for "..cname..": "..fname.." has already been created ( old has been removed )")
		self:Remove(inst, step, fname)
	end
	
    estnewconnection(inst, step, cname) --establishes the connection
    funcs[cname][fname] = {				--inserts the function + data, to-be-called by the connection
        Function = func,
        Delay = tonumber(deloverride) or -1, --no delay
        LastRun = nan, --for calculating delay (nan < delay always false -> always triggers once without delay)
        Active = true,
        Deferred = deferred
    }
    return cname, fname --identifiers returned for other funcs
end
function module:Get(inst: Instance, step: string, fname: string): (string, table) --getter
    local entry = toentryname(inst, step)
    return entry, funcs[entry]
end
function module:Enable(inst: Instance, step: string, fname: string): nil --allows connections to be temporarliy disabeled and reenabled
    local entry = toentryname(inst, step)
    if funcs[entry] and funcs[entry][fname] then --if valid entry then:
		funcs[entry][fname].Active = true
	end
	return
end
function module:Disable(inst: Instance, step: string, fname: string): nil
    local entry = toentryname(inst, step)
    if funcs[entry] and funcs[entry][fname] then --if valid entry then:
		funcs[entry][fname].Active = false
	end
	return
end
return module