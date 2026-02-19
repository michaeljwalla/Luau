--[[

	registerkeybind example
	
	: keybinddata (arg1, table)
	{
        Info = "MyKeybindName",		-- string
        Key = "T", 					-- EnumItem | string
        Ctrl = true, 				-- boolean
        Alt = false,				-- boolean
        Repetitions = 1				-- number?
    }

	: func (arg2, function)
	function(timeOfRun)
		print('ran at: '..timeOfRun)
	end

	: overwrite (arg3, boolean?)
	registerkeybind(kbdata, runfunc, true | false | nil)

	use . operator for module calls
]]

--modules/externals
local require = loadfile"bell/new/require.lua"""


local stepper = require("bell/new/stepper")
local trash = require"bell/new/trash"
local shared = require"bell/new/shared"

--local module setup
local keycode = Enum.KeyCode
local inputservice = game:GetService"UserInputService"
local module = shared:Get("KeybinderModule", {
	Connection = nil,
	Keybinds = {},
	Keys = keycode,
	UIS = inputservice
})

local keybinds = module.Keybinds
local keybindsinternal = { -- rows are ctrl, columns are alt
	[true] = {
		[true] = { -- ctrl alt

		}, [false] = { --ctrl

		}
	},
	[false] = {
		[true] = { --alt

		},
		[false] = { --nothing

		}
	}
}

--functions
local kbmt = {
	__tostring = function(self: table): string
		return self.Format --qol ig (prints .Format instead of memory address)
	end
}
local removekeybind --since its called earlier than its defined
local function registerkeybind(keybinddata: table, func: method, overwrite: boolean?): (boolean, table)
	assert(keybinddata ~= module, "<Keybinder> use . operator, not : operator") --could prob just add a thing to shift all vars down if keybinddata == module

    local btn, ctrl, alt = typeof(keybinddata.Key) == 'EnumItem' and keybinddata.Key or keycode[keybinddata.Key], keybinddata.Ctrl, keybinddata.Alt --for less indexing
    local numreps = keybinddata.Repetitions or 1
	
	local format = ("%s%s%s"):format(ctrl and "Ctrl + " or "", alt and "Alt + " or "", btn.Name)
    local info = keybinddata.Info

	local path = keybindsinternal[ctrl][alt] --all cases (2^2 -> 4) already defined for boolean so just predefine it to avoid unnecessary indexing
	if (path[btn] or keybinds[info]) then --if keybind name/combination already exists then
		if overwrite then
			--warn(("A keybind has already been created for \"%s\" ( replacing... )"):format(keybinds[info] and info or format)) --matches name else combination
			removekeybind(keybinddata) --remove old & continue
		else
			warn(("A keybind has already been created for \"%s\" ( use overwrite param to replace )"):format(keybinds[info] and info or format)) --matches name else combination
        	return false, keybinds[info] --return old
		end
    end
	format = format..(" ( x%d )"):format(numreps) --only one func can be attached to a keybind, regardless of numreps

    local new = setmetatable({ --keybind data
        Info = info, --user inputted
        Format = info.." : "..format,

        Key = btn, --user inputted
        Ctrl = ctrl, --user inputted
        Alt = alt, --user inputted
        Repetitions = numreps, --user inputted

        Fire = func, --user inputted

        LastCall = 0, --internal, unused
        CurRep = 0	  --internal
    }, kbmt)

    keybinds[keybinddata.Info] = new -- easier to remove for ppl i guess
	path[btn] = new --keybindsinternal, so InputBegan can look it up

    return true, new
end
removekeybind = function(keybinddata: string | table, trashit: boolean?): boolean --true when keybinddata existed -> something actually was removed
	assert(keybinddata ~= module, "<Keybinder> use . operator, not : operator")
	local name = type(keybinddata) == 'string' and keybinddata or keybinddata.Info --if table then get string
    local keybind = keybinds[name]
	
    if keybind then
		rawset(keybinds, name, nil)
		rawset(keybindsinternal[keybind.Ctrl][keybind.Alt], trashit and trash(keybind, keybind.Key) or keybind.Key, nil) -- rare use of optreturn in trash() ( destroys table while returning value from it to use as rawset key )
		return true
	end
    return false
end
--registerkeybind({Info = "LoL", Key = "Space", Ctrl = true, Alt = true, Repetitions = 3}, print, true)
local lctrl, rctrl, lalt, ralt = keycode.LeftControl, keycode.RightControl, keycode.LeftAlt, keycode.RightAlt
local function isctrling() --self explanatory
    return inputservice:IsKeyDown(lctrl) or inputservice:IsKeyDown(rctrl)
end
local function isalting()
    return inputservice:IsKeyDown(lalt) or inputservice:IsKeyDown(ralt)
end

--methods
module.IsHoldingCtrl = isctrling
module.IsHoldingAlt = isalting
module.RegisterKeybind = registerkeybind
module.UnregisterKeybind = removekeybind

--connections
module.Connection = { stepper:Add(inputservice, "InputBegan", "KeybindController", function(input: InputObject, focused: boolean): nil
    local keybind = not focused and keybindsinternal[isctrling()][isalting()][input.KeyCode] --check NOT in a textbox and the ctrl+alt+key exists as a registered keybind
    if not keybind then return end

	--if last succsessive press was within 0.25s, add it to the repitition counter (possible issue: triggering multiple binds ex Rx2 Fx2 ; RFRF -> R() & F() )
	-- % repititions to reset when #presses = keybind specified value
    local cur = tick()
    keybind.CurRep = ((cur - keybind.LastCall > 0.25 and 0 or keybind.CurRep) + 1) % keybind.Repetitions 
    keybind.LastCall = cur --maybe youll be used one day
    if keybind.CurRep == 0 then
		keybind.Fire(cur)
	end
end) }

return module