--if shared.prevdata then shared.prevdata:cleanup() end

local uis = game:GetService"UserInputService"
local insert, wait, clamp, ceil, floor, round, abs, max, min = table.insert, task.wait, math.clamp, math.ceil, math.floor, math.round, math.abs, math.max, math.min
local defer = task.defer
local textservice, tweenservice, collectionservice = game:GetService"TextService", game:GetService"TweenService", game:GetService"CollectionService"
local char, random = string.char, math.random
local function rand(len)
    local result = ""
    for i = 1, len do result = result..char(random(0,255)) end
    return result
end
local defaccent = Color3.new(1/6,3/8,2/3)
local defcol, pressedcol = Color3.new(1/3,1/3,1/3), Color3.new(1/5,1/5,1/5)
local subcol = Color3.new(1/4,1/4,1/4)
local defaults = {
    RichText = true,
    BackgroundColor3 = defcol, 
    TextColor3 = Color3.new(1,1,1),
    TextSize = 14,
    TextXAlignment = "Center",
    Font = 18, --10, 18 (17 non bold),
    ScrollBarThickness = 1,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = "Y",
    TextWrapped = true,
}
local function findancestor(inst, name)
    local anc = inst:FindFirstAncestor(name)
    if anc then return anc end
    local p = inst.Parent
    while p and p.Parent do
        p = p.Parent
        local found = p:FindFirstChild(name)
        if found then return found end
    end
    return nil
end
local function hasprop(inst, prop, pcd)
    return pcd and inst[prop] or pcall(hasprop, inst, prop, true)
end
local function apply(inst, props)
    local parent = props.Parent
    props.Parent = nil
    for i,v in next, props do
        if hasprop(inst, i) then
            inst[i] = v
        end
    end
    if parent then inst.Parent = parent end
    return inst
end
local function vec2toudim2(vec2)
    return UDim2.fromOffset(vec2.X,vec2.Y)
end
local mouse = game.Players.LocalPlayer:GetMouse()

local module = {
    Connections = {},
    Draggables = {},
    Resizables = {},
    Popups = {},
    Menus = {}
}
--shared.prevdata = module
module.Gui = apply(Instance.new"ScreenGui", {Name = rand(15)})
--
local mb1 = Enum.UserInputType.MouseButton1
local mb2 = Enum.UserInputType.MouseButton2
local ml = Enum.UserInputType.MouseMovement
local function mouselocation() return Vector2.new(mouse.X, mouse.Y) end
local lastpos = mouselocation()
insert(module.Connections, mouse.Button1Up:Connect(function()
    for i,v in next, module.Draggables do v[1] = false end
    for i,v in next, module.Resizables do v[1] = false end
end))
insert(module.Connections, uis.InputChanged:Connect(function(input)
    if input.UserInputType.Name ~= "MouseMovement" then return end
    lastpos = mouselocation()
end))
local function inbetween(n,min,max, exclude)
    return (exclude and n > min and n < max) or (not exclude and n >= min and n <= max)
end
local fakescrollers = {}
local holdingctrl
insert(module.Connections, uis.InputBegan:Connect(function(inpt, focused)
    if focused or not inpt.KeyCode.Name:find"Control" then return end
    holdingctrl = true
    for i,v in next, fakescrollers do v.Back.Visible = true end
end))
insert(module.Connections, uis.InputEnded:Connect(function(inpt, focused)
    if focused or not inpt.KeyCode.Name:find"Control" then return end
    holdingctrl = false
    for i,v in next, fakescrollers do v.Back.Visible = false end
end))
local main
insert(module.Connections, game["Run Service"].Heartbeat:Connect(function()
    local mpos = mouselocation()

    for inst,v in next, module.Draggables do
        if not v[1] then --[[inst.BackgroundColor3 = defcol]] continue end
        local lp = lastpos
        --inst.BackgroundColor3 = pressedcol
        wait()
        inst = v[2] or inst
        local curpos = inst.AbsolutePosition
        local instsize = inst.AbsoluteSize
        local mousechange, maxpos = mpos - lp, module.Gui.AbsoluteSize - instsize 
        inst.Position = UDim2.fromOffset(
            clamp(curpos.X + mousechange.X, -instsize.X + 20, maxpos.X + instsize.X-20),
            clamp(curpos.Y + mousechange.Y, -instsize.Y, maxpos.Y + instsize.Y-20)
        )
        lastpos = mpos

        break --only drag one at a time hopefully
    end
    
    for inst, v in next, module.Popups do --{ stayon, (inst), (popup), settings, popupdebugid }
        --if not v[2]:IsDescendantOf(game) then rawset(module.Popups, inst, nil) v[3]:Destroy() continue end
        local settings = v[4]
        local pos, size = v[2].AbsolutePosition, v[2].AbsoluteSize
        local popup, popupsize = v[3], v[3].AbsoluteSize
        if not (v[5] or v[1]) then popup.Visible = false continue end
        local newpos = (settings.FollowMouse and mpos or pos) + (
            settings.Offset or (settings.FollowMouse and (settings.MouseOffset or Vector2.new(5, -(popupsize.Y + 5)) )
            or Vector2.new((size.X - popupsize.X)/2, -(popupsize.Y + 5)))
        )
        popup.Position = UDim2.fromOffset(newpos.X, newpos.Y)
        popup.Visible = true
    end
    --put last since it yields
    for inst, v in next, module.Resizables do
        if not v[1] then continue end
        local lp = lastpos
        wait()
        inst = v[2] or inst
        local curpos, mpos = inst.AbsolutePosition, mouselocation()
        local mousechange, minsize, maxsize = mpos - lp, v[3] - inst.AbsoluteSize , v[4] - inst.AbsoluteSize
        inst.Size = inst.Size + UDim2.fromOffset(
            clamp(mousechange.X, minsize.X, maxsize.X),
            clamp(mousechange.Y, minsize.Y, maxsize.Y)
        )
        lastpos = mpos
    end
end))
--
function module:cleanup()  for i,v in next, self.Connections do v:Disconnect() end wait() self.Gui:Destroy() end
function module:Enable() self.Gui.Parent = game.CoreGui or gethui() end
function module:Disable() self.Gui.Parent = nil end
function module:MakeDraggable(inst, dragwhat)
    self.Draggables[inst] = {false, dragwhat}
    insert(module.Connections, inst.InputBegan:Connect(function(type)
        if type.UserInputType == mb1 then self.Draggables[inst][1] = true end
    end))
    insert(module.Connections, inst.InputEnded:Connect(function(type)
        if type.UserInputType == mb1 then self.Draggables[inst][1] = false end
    end))
end
local defresizer = apply(apply(Instance.new"TextButton", defaults), {
    BorderSizePixel = 0,
    BackgroundTransparency = 1,
    Text = " _\n -",
    Size = UDim2.new(0,20,0,20),
    Position = UDim2.new(1,-20,1,-20),
    Name = "Resizer"
})
function module:MakeResizable(inst, resizewhat, minsize, maxsize)
    assert(minsize.Magnitude <= maxsize.Magnitude, "Max size must be greater than or equal to minimum")
    self.Resizables[inst] = {false, resizewhat or inst, minsize, maxsize}
    local rs = apply(defresizer:Clone(), {
        Parent = inst
    })
    insert(module.Connections, rs.MouseButton1Down:Connect(function()
        self.Resizables[inst][1] = true
    end))
    insert(module.Connections, rs.InputEnded:Connect(function(type)
        if type.UserInputType == mb1 then self.Resizables[inst][1] = false end
    end))
    return rs
end
function module:AddBasic(type, size, pos, parent)
    return apply(apply(Instance.new(type), defaults), {
        Size = size,
        Position = pos,
        Parent = parent
    })
end

local defpopup = apply(module:AddBasic("TextLabel", UDim2.new(0,100,0,20), nil, nil), {
    BorderSizePixel = 0,
    BackgroundColor3 = Color3.new(),
    BackgroundTransparency = 0.4,
    ZIndex = 69420,
    TextSize = 10
})
function module:DefaultPopup(msg)
    return apply(defpopup:Clone(), {Text = msg})
end
function module:RemovePopup(inst)
    local entry = self.Popups[inst]
    if not entry then return end

    rawset(self.Popups, inst, nil)
    entry[3]:Destroy()
end
function module:MakePopup(inst, popupinst, settings) --offset is from bottom left (mouse, nonstatic) or top right (instance, static)
    local entry = {false, inst, popupinst, settings, false, popupinst:GetDebugId()} --last is lock
    self.Popups[inst] = entry
    if not settings.FollowMouse then 
        insert(module.Connections, inst.InputBegan:Connect(function(type)
            type = type.UserInputType
            if type == mb1 then
                entry[5] = not entry[5] --lock
            elseif type == ml then
                entry[1] = true
            end
        end))
        insert(module.Connections, inst.InputEnded:Connect(function(type)
            type = type.UserInputType
            if type == ml then
                entry[1] = false
            end
        end))
        insert(module.Connections, popupinst.InputBegan:Connect(function(type)
            type = type.UserInputType
            if type == mb2 then
                entry[5] = false
            end
        end))
    else
        insert(module.Connections, inst.InputBegan:Connect(function(type)
            type = type.UserInputType
            if type == ml then
                entry[1] = true
            end
        end))
        insert(module.Connections, inst.InputEnded:Connect(function(type)
            type = type.UserInputType
            if type == ml then
                entry[1] = false
            end
        end))
    end
    collectionservice:AddTag(inst, entry[6]) --cestroyed check
    
    popupinst.Visible = false
    popupinst.Parent = self.Gui.Popups
    return popupinst
end
main = module:AddBasic("Frame", UDim2.new(0,400,0,400), UDim2.new(0.5,-200,0.5,-200), module.Gui)
function module:SetMainMenu(inst)
    if main == inst then return end
    pcall(game.Destroy, main)
    main = inst
    module._main = main
    main.Parent = self.Gui
    self:MakeDraggable(main)
end

Instance.new("Folder", module.Gui).Name = "Popups"
Instance.new("Folder", module.Gui).Name = "Notifications"

module._main = main
apply(module:AddBasic("TextLabel", UDim2.new(1,0,0,20), UDim2.new(0,0,0,-27), main), {
  Text = "    hi guys",
  TextXAlignment = "Left",
  BackgroundColor3 = pressedcol,
  Name = "Title"
})

apply(apply(Instance.new"ScrollingFrame", defaults), {
    Name = "Fitter",
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Size = UDim2.new(1,20,1,0),
    Position = UDim2.new(0,-10,0,0),
    ScrollBarThickness = 1,
    AutomaticCanvasSize = "X",
    ClipsDescendants = true,
    Parent = apply(module:AddBasic("Frame", UDim2.new(1,-20,0,25), UDim2.new(0,10,0,-6), main), {BackgroundTransparency = 0.2, BackgroundColor3 = defaccent, Name = "Menus", ZIndex = 0})
})
module:MakeDraggable(main)
module:MakeDraggable(main.Title, main)
module:MakeDraggable(main.Menus.Fitter, main)
local menuentry, menuframe = apply(apply(Instance.new"TextButton", defaults), {
    Text = "Menu",
    Size = UDim2.new(0,50,0,20)
}), apply(apply(Instance.new"Frame", defaults), {
    Size = UDim2.new(1,0,1,-20),
    Position = UDim2.new(0,0,0,19),
    BackgroundColor3 = pressedcol,
    ClipsDescendants = true
})
apply(Instance.new"UIListLayout", {
    FillDirection = "Horizontal",
    SortOrder = "LayoutOrder",
    VerticalAlignment = "Bottom",
    --Padding = UDim.new(10,10),
    Parent = main.Menus.Fitter
})
function module:SwitchTo(menu)
    menu = tostring(menu)
    local menus = self.Menus
    assert(menus[menu], "nonexistent menu '"..menu.."'")
    for i,v in next, menus do
        if i == menu then continue end
        v.Button.BackgroundColor3 = defcol
        v.Frame.Parent = nil
    end
    menu = menus[menu]
    main.Menus.BackgroundColor3 = menu.Accent or defaccent
    menu.Button.BackgroundColor3 = pressedcol
    menu.Frame.Parent = main
    return menu
end
function module:GetMenu(name)
    return self.Menus[tostring(name)]
end
local clone = table.clone
local menusordered = {}
function module:GetMenus()
    return clone(menusordered)
end
local function lowestpos(stuff)
    local lowest = -1/0
    for i,v in next, stuff do
        if not hasprop(v, "AbsoluteSize") then
            continue
        end
        lowest = max(v.AbsolutePosition.Y + v.AbsoluteSize.Y, lowest)
    end
    return lowest
end
function module:AddFakeScroll(frame, maxup, maxdown, includeold)
    local data = {
        Back = apply(self:UnclickableThrough(frame),{Visible = false}),
        MaxUp = maxup,
        MaxDown = maxdown
    }
    fakescrollers[frame] = data
    
    local children = {}
    insert(module.Connections, frame.ChildAdded:Connect(function(p) if not hasprop(p, "Position") then return end children[p] = {p.Position, 0} end))
    insert(module.Connections, frame.ChildRemoved:Connect(function(p) rawset(children, p, nil) end))

    if includeold then
        for i,v in next, frame:GetChildren() do
            if v.Name == 'ClickBlocker' or not hasprop(v, "Position") then continue end
            children[v] = {v.Position, 0}
        end
    end

    insert(module.Connections, frame.MouseWheelForward:Connect(function(x,y)
        if not holdingctrl then return end
        for i,v in next, children do
            if v[2] + 5 > data.MaxUp then return end
            v[2] = v[2] + 5
            i.Position = v[1] + UDim2.fromOffset(0, v[2])
        end
    end))
    insert(module.Connections, frame.MouseWheelBackward:Connect(function(x,y)
        if not holdingctrl then return end
        for i,v in next, children do
            if v[2] - 5 < data.MaxDown then return end
            v[2] = v[2] - 5
            i.Position = v[1] + UDim2.fromOffset(0, v[2])
        end
    end))
    return data
end
function module:AddMenu(name, changecol, maxup, maxdown)
    maxup, maxdown = maxup or 0, maxdown or 0
    maxup, maxdown = maxup - (maxup % 5), -(maxdown - (maxdown % 5))
    assert(not changecol or typeof(changecol) == 'Color3', 'Invalid accent type: '..typeof(changecol))
    name = tostring(name)
    assert(not self.Menus[name], "Menu '"..name.."' already exists")
    local tsize = textservice:GetTextSize(name, 14, 18, Vector2.new(1920, 1080)).X
    local b, f = apply(menuentry:Clone(), {
        Parent = main.Menus.Fitter,
        Text = name,
        Name = name,
        Size = UDim2.new(
            0, tsize+20,
            0,20
        )
    }),apply(menuframe:Clone(), {Name = name})
    changecol = changecol or defaccent
    local newentry = {
        Name = name,
        Button = b,
        Frame = f,
        Accent = changecol
    }
    apply(Instance.new"Color3Value", {
        Name = 'Accent',
        Value = changecol,
        Parent = f
    })
    self.Menus[name] = newentry
    insert(menusordered, name)
    insert(module.Connections, b.MouseButton1Click:Connect(function()
        self:SwitchTo(name)
    end))
    self:AddFakeScroll(f, maxup, maxdown, false)
    return newentry
end
local clickblocker = apply(Instance.new"TextButton", {
    Text = "",
    Name = "ClickBlocker",
    Size = UDim2.fromScale(1,1),
    BackgroundTransparency = 1
})
function module:Name(name, inst)
    if typeof(inst) == 'string' then name, inst = inst, name end
    inst.Name = tostring(name)
    return inst
end
function module:Text(text, inst)
    --assert(hasprop(inst, "Text"), "Instance does not ha")
    inst.Text = tostring(text)
    return inst
end
function module:UnclickableThrough(inst)
    return apply(clickblocker:Clone(), {Parent = inst})
end
local function addtoggle(inst, starting)
    return apply(Instance.new"BoolValue", {
        Value = starting == true,
        Name = "Toggle",
        Parent = inst
    })
end
local function addstrvalue(inst, starting)
    return apply(Instance.new"StringValue", {
        Value = starting or "",
        Name = "Option",
        Parent = inst
    })
end
local function addnumvalue(inst, starting)
    return apply(Instance.new"NumberValue", {
        Value = starting or "",
        Name = "Percent",
        Parent = inst
    })
end
function module:BindToggleClick(button, opts, starting)
    assert(button:IsA"GuiButton", "Not a button: "..tostring(button))
    local toggle = addtoggle(button, false)
    local debounce
    insert(module.Connections, button.MouseButton1Click:Connect(function()
        if debounce then return end
        toggle.Value = not toggle.Value
    end))
    if opts then
        insert(module.Connections, toggle.Changed:Connect(function(val)
            debounce = true
            local f = opts[val and 'On' or 'Off']
            if f then f(val) end
            debounce = false
        end))
    end
    if starting then firesignal(button.MouseButton1Click) end
    return button, toggle
end
function module:DropdownButton(button, size, options, settings, extfuncs) --defaults to alphabetical sort
    local dropdown = apply(self:AddBasic("Frame", size, UDim2.new(0,0,1,0), button), { ClipsDescendants = true, BackgroundColor3 = pressedcol, Visible = false,Name = "Dropdown"})
    local body = self:AddBasic("Frame", UDim2.new(1,0,1,0), nil, dropdown)
    apply(Instance.new"UIListLayout", {
        Parent = body,
        SortOrder = settings.SortOrder
    })
    local curval = addstrvalue(button, button.Text)
    insert(module.Connections, curval.Changed:Connect(function(val)
        button.Text = val
        if extfuncs.OnChange then extfuncs.OnChange(val) end
    end))
    local click
    for i,v in next, options do
        v = tostring(v)
        local btn = self:Name(v, self:AddBasic("TextButton", settings.Size, nil, body))
        apply(btn, {
            Text = v,
            BackgroundColor3 = subcol,
            TextSize = 12
        })
        insert(module.Connections, btn.MouseButton1Click:Connect(function()
            curval.Value = v
            firesignal(button.MouseButton1Click)
        end))
        if not settings.Default or settings.Default == v then click = btn end
    end
    local offset = 0
    local maxoffset = settings.Size.Y.Offset * (#options - floor(size.Y.Offset / settings.Size.Y.Offset))
    insert(module.Connections, dropdown.MouseWheelForward:Connect(function(x,y)
        if holdingctrl then return end
        offset = max(offset - settings.Step, 0)
        body.Position = UDim2.fromOffset(0,-offset)
    end))
    insert(module.Connections, dropdown.MouseWheelBackward:Connect(function(x,y)
        if holdingctrl then return end
        offset = min(offset + settings.Step, maxoffset)
        body.Position = UDim2.fromOffset(0,-offset)
    end))
    local moveby = UDim2.new(UDim.new(), dropdown.Size.Y)
    firesignal(click.MouseButton1Click)
    self:BindToggleClick(button, {
        On = function()
            for i,v in next, button.Parent:GetChildren() do
                if not v:IsA"GuiObject" or v.AbsolutePosition.Y <= button.AbsolutePosition.Y then continue end
                v.Position = v.Position + moveby
            end
            if extfuncs.On then extfuncs.On(dropdown, curval.Value) end
            dropdown.Visible = true
        end,
        Off = function()
            for i,v in next, button.Parent:GetChildren() do
                if not v:IsA"GuiObject" or v.AbsolutePosition.Y <= button.AbsolutePosition.Y then continue end
                v.Position = v.Position - moveby
            end
            if extfuncs.Off then extfuncs.Off(dropdown,curval.Value) end
            dropdown.Visible = false
        end
    })
    return button
end
function module:SquishInto(obj, item, rightside)
    if hasprop(obj, "Text") then
        local imgsize = obj.AbsoluteSize.Y
        apply(item, {
            Parent = obj,
            Size = UDim2.fromOffset(imgsize,imgsize),
            Position = rightside and UDim2.new(1,-imgsize) or UDim2.new()
        })
        local newtextbounds = apply(self:AddBasic("TextLabel", UDim2.new(1,-imgsize,1,0), rightside and UDim2.new() or UDim2.new(0,imgsize), obj), {
            BorderSizePixel = 0,
            Text = obj.Text,
            TextSize = obj.TextSize,
            Font = obj.Font,
            Name = "RealText",
            TextXAlignment = obj.TextXAlignment,
            TextYAlignment = obj.TextYAlignment,
            BackgroundTransparency = 1
        })
        obj.Text = ""
        return item
    else
        --idc
    end
end
function module:AddImgToText(obj, imgasset, rightside)
    local imgsize = obj.AbsoluteSize.Y
    local imginsert = apply(self:AddBasic("ImageLabel", UDim2.fromOffset(imgsize,imgsize), rightside and UDim2.new(1,-imgsize) or UDim2.new(), obj), {
        Image = imgasset,
        BorderSizePixel = 0,
        Name = "Icon",
        BackgroundTransparency = 1
    })
    local newtextbounds = apply(self:AddBasic("TextLabel", UDim2.new(1,-imgsize,1,0), rightside and UDim2.new() or UDim2.new(0,imgsize), obj), {
        BorderSizePixel = 0,
        Text = obj.Text,
        TextSize = obj.TextSize,
        Font = obj.Font,
        Name = "RealText",
        TextXAlignment = obj.TextXAlignment,
        TextYAlignment = obj.TextYAlignment,
        BackgroundTransparency = 1
    })
    obj.Text = ""
    return obj
end
function module:AddUiToggle(obj, size, rightside, defval, dead)
    local togglesize = obj.AbsoluteSize.Y
    local accent = findancestor(obj, "Accent")
    accent = accent and accent.Value or defaccent
    local newbtn, toggle = apply(self:AddBasic("TextButton", size or UDim2.fromOffset(togglesize,togglesize), rightside and UDim2.new(1,-togglesize) or UDim2.new(), obj), {
        BackgroundColor3 = defval == true and accent or pressedcol, --boolean == true is crazy but i dont want random params to activate true (just 'defval and accent' could make defval=-69 trigger)
        Text = "",
        Name = "Button"
    })
    local newtextbounds = apply(self:AddBasic("TextLabel", UDim2.new(1,-togglesize,1,0), rightside and UDim2.new() or UDim2.new(0,togglesize), obj), {
        BorderSizePixel = 0,
        Text = obj.Text,
        TextSize = obj.TextSize,
        Font = obj.Font,
        Name = "RealText",
        TextXAlignment = obj.TextXAlignment,
        TextYAlignment = obj.TextYAlignment,
        BackgroundTransparency = 1
    })
    if not dead then
        newbtn, toggle = self:BindToggleClick(newbtn)
        insert(module.Connections, toggle.Changed:Connect(function(val)
            newbtn.BackgroundColor3 = val and accent or pressedcol
        end))
    end
    obj.Text = ""
    return obj
end
local function updateradioframe(rbframe, choice)
    local updcol = findancestor(rbframe, "Accent")
    updcol = updcol and updcol.Value or defaccent
    local foundat = -1
    for i,v in next, rbframe:GetChildren() do
        if not v:IsA"GuiObject" then
            continue
        elseif tostring(v) == choice then
            foundat = i - 2 --2 other insts
            v.Button.BackgroundColor3 =  updcol
            continue
        end
        v.Button.BackgroundColor3 =  pressedcol
    end
    return foundat
end
--framedata for new frame made for radio buttons
function module:AddRadioButtons(framedata, buttondata, options, extfunc)
    local rbframe = self:AddBasic(
        "ScrollingFrame",
        framedata.Size + ((buttondata.SortingOpt and UDim2.new()) or UDim2.new(0, buttondata.Size.X.Offset * (buttondata.Horizontal and #options or 1), 0, buttondata.Size.Y.Offset * (buttondata.Horizontal and 1 or #options))),
        framedata.Position, framedata.Parent)
    rbframe.Name = "RadioButtons"
    if not buttondata.SortingOpt then
        apply(Instance.new"UIListLayout", {Parent = rbframe, SortOrder = "LayoutOrder", FillDirection = buttondata.Horizontal and "Horizontal" or "Vertical"})
    elseif typeof(buttondata.SortingOpt) == 'Instance' then
        buttondata.SortingOpt.Parent = rbframe
        buttondata.SortingOpt = nil
    end
    local rbval = addstrvalue(rbframe, starting and options[starting])
    for i,v in next, options do
        local newrb = self:AddUiToggle(apply(
            self:AddBasic("TextLabel",buttondata.Size,nil,rbframe),
            {
                Name = v,
                Text = (buttondata.StartsFrom == 'Left' and "    " or "")..v..((buttondata.StartsFrom == 'Right' and "    " or "")),
                TextXAlignment = buttondata.StartsFrom,
                TextSize = buttondata.TextSize,
                LayoutOrder = i,
                BackgroundColor3 = buttondata.Background
            }), nil, buttondata.RightSide, i == buttondata.Default, true)
        if extfunc and i == buttondata.Default then defer(extfunc, v, i) end
        insert(module.Connections, apply(newrb, {Position = buttondata.SortingOpt and buttondata.SortingOpt[i]}).Button.MouseButton1Click:Connect(function()
            rbval.Value = v
        end))
        
    end
    insert(module.Connections, rbval.Changed:Connect(function(val)
        local indxat = updateradioframe(rbframe, val)
        if extfunc then extfunc(val, indxat) end
    end))
    return rbframe
end
local function lerp(a,b,t)
    if typeof(a) == 'UDim2' then
        return UDim2.new(
            lerp(a.X.Scale, b.X.Scale, t),
            lerp(a.X.Offset, b.X.Offset, t),
            lerp(a.Y.Scale, b.Y.Scale, t),
            lerp(a.Y.Offset, b.Y.Offset, t)
        )
    end
    return a + (b - a)*t
end

local function listlerp(valuerange, value)
    local tdat = {}
    for i,v in next, valuerange do
        tdat[i] = lerp(v[1], v[2], value)
    end
    return tdat
end
module.Lerp = lerp
function module:AddLerp(inst, lerpvalues, initial)
    local lval = addnumvalue(inst, clamp(initial or 0, 0, 1))
    apply(inst, listlerp(lerpvalues, lval.Value))
    
    insert(module.Connections, lval.Changed:Connect(function(val)
        apply(inst, listlerp(lerpvalues, lval.Value))
    end))
    return lval
end
--tweenvalues = {Position = {minp, maxp}, ...}
--returns numvalue
function module:AddTweenLerp(inst, tweenvalues, tweeninfo, initial)
    local lval = addnumvalue(inst, clamp(initial or 0, 0, 1))
    apply(inst, listlerp(tweenvalues, lval.Value))
    
    insert(module.Connections, lval.Changed:Connect(function(val)
        tweenservice:Create(inst, tweeninfo, listlerp(tweenvalues, val)):Play()
    end))
    return lval
end
local function redecimal(n, places)
    n = tostring(floor(n*10^places)/10^places)
    if places < 1 then return n end
    n = n:find"%." and n or n.."."
    
    local numdec = n:match"%.%d*"
    for i = #numdec, places do n = n.."0" end
    return n
end
function module:AddDragbar(dbdata, inddata, valuedata, extfuncs)
    local dragbar = apply(self:AddBasic("Frame", dbdata.Size, dbdata.Position, dbdata.Parent), {
        Name = dbdata.Name or 'Dragbar',
        BackgroundColor3 = subcol
    })
    local accent = findancestor(dragbar, "Accent")
    accent = accent and accent.Value or defaccent
    local curval = addnumvalue(dragbar, valuedata.Default or 0)
    local extentsX, extentsY = dragbar.AbsoluteSize.X, dragbar.AbsoluteSize.Y
    local valindicator = apply(self:AddBasic(inddata.Type or "TextLabel", inddata.Size, inddata.RightSide and UDim2.new(1,-extentsY) or UDim2.new(), dragbar), {
        Name = "Indicator",
        TextSize = inddata.TextSize,
        BackgroundColor3 = subcol,
        Text = tostring(valuedata.Default or 0):match"%-?%d+%.?%d?%d?" --numbers up to two decimals
    })
    
    local valabsx = valindicator.AbsoluteSize.X
    local border = dbdata.Border or 0
    local dbcontainer = apply(self:AddBasic("Frame", UDim2.fromOffset(extentsX-valabsx-2*border, extentsY-2*border), UDim2.fromOffset(border,border) + UDim2.new(0, inddata.RightSide and 0 or valabsx+1), dragbar), {
        Name = 'Container',
        BackgroundColor3 = pressedcol,
        ClipsDescendants = true
    })
    local dbfiller = apply(self:AddBasic("Frame", UDim2.new(0,0,1,0), nil, dbcontainer), {
        BackgroundColor3 = accent,
        Name = 'Fillbar'
    })
    local dbtextoverlay = apply(self:AddBasic("TextLabel", UDim2.new(1,-valabsx,1,0), inddata.RightSide and UDim2.new() or UDim2.fromOffset(valabsx), dragbar), {
        Name = 'TextOverlay',
        Text = dbdata.Text,
        TextSize = inddata.TextSize,
        BackgroundTransparency = 1,
        TextColor3 = dbdata.OverlayColor
    })
    if not dbdata.NoCode then
        dbfiller.Size = UDim2.new(valuedata.Default/valuedata.Max, 0,1,0)
        if valindicator:IsA"TextBox" then
            insert(module.Connections, valindicator.FocusLost:Connect(function()
                local newnum = tonumber(valindicator.Text)
                if newnum  then
                    local step = valuedata.Step
                    newnum = clamp(floor(newnum) - (newnum % step), valuedata.Min, valuedata.Max)
                    curval.Value = newnum
                end
                valindicator.Text = curval.Value
                return
            end))
        end
        local dbhitbox = self:UnclickableThrough(dbcontainer)
        if not dbdata.InvertScrolling then
            insert(module.Connections, dbhitbox.MouseWheelForward:Connect(function(x,y)
                if holdingctrl then return end
                local step = valuedata.Step
                local lastval = curval.Value
                curval.Value = clamp(lastval + step, valuedata.Min, valuedata.Max)
            end))
            insert(module.Connections, dbhitbox.MouseWheelBackward:Connect(function(x,y)
                if holdingctrl then return end
                local step = valuedata.Step
                local lastval = curval.Value
                curval.Value = clamp(lastval - step, valuedata.Min, valuedata.Max)
            end))
        else
            insert(module.Connections, dbhitbox.MouseWheelBackward:Connect(function(x,y)
                if holdingctrl then return end
                local step = valuedata.Step
                local lastval = curval.Value
                curval.Value = clamp(lastval + step, valuedata.Min, valuedata.Max)
            end))
            insert(module.Connections, dbhitbox.MouseWheelForward:Connect(function(x,y)
                if holdingctrl then return end
                local step = valuedata.Step
                local lastval = curval.Value
                curval.Value = clamp(lastval - step, valuedata.Min, valuedata.Max)
            end))
        end
        
        insert(module.Connections, dbhitbox.MouseMoved:Connect(function(x, y)
            if not uis:IsMouseButtonPressed(mb1) then return end
            local percentfull = (x - dbhitbox.AbsolutePosition.X)/dbhitbox.AbsoluteSize.X
            local val = round(lerp(valuedata.Min, valuedata.Max, percentfull))
            local step = valuedata.Step
            curval.Value = clamp((val - step) + (step - val % step), valuedata.Min, valuedata.Max)
        end))
        insert(module.Connections, dbhitbox.MouseButton1Down:Connect(function()
            local x = mouselocation().X
            local percentfull = (x - dbhitbox.AbsolutePosition.X)/dbhitbox.AbsoluteSize.X
            local val = round((lerp(valuedata.Min, valuedata.Max, percentfull) - valuedata.Min)/valuedata.Step) * valuedata.Step + valuedata.Min
            curval.Value = clamp(val, valuedata.Min, valuedata.Max)
        end))
        curval.Value = valuedata.Default
        local debounce
        local offset = 1/(valuedata.Max - valuedata.Min)
        insert(module.Connections, curval.Changed:Connect(function(val)
            if debounce then return end
            debounce = true
            val = clamp(val, valuedata.Min, valuedata.Max)
            valindicator.Text = val
            local min, max = valuedata.Min, valuedata.Max
            local newfill = (val-min) * offset
            dbfiller.Size = UDim2.fromScale(newfill, 1)
            if extfuncs.OnChange then extfuncs.OnChange(val, dragbar) end
            curval.Value = val
            debounce = false
        end))
        firesignal(curval.Changed, curval.Value)
    end
    return dragbar, curval
end

local function phase3(colors, perc) --lerp the colors that a num is in between
    local curcol, nextcol = colors[1], colors[2]
    if perc <= 0.5 then
        return Color3.new(
            lerp(curcol.R, nextcol.R, perc*2),
            lerp(curcol.G, nextcol.G, perc*2),
            lerp(curcol.B, nextcol.B, perc*2)
        )
    end
    curcol, nextcol = colors[2], colors[3]
    return Color3.new(
        lerp(curcol.R, nextcol.R, perc*2-1),
        lerp(curcol.G, nextcol.G, perc*2-1),
        lerp(curcol.B, nextcol.B, perc*2-1)
    )
end
local linear = Enum.EasingStyle.Linear
function module:AddFillbar(framedata, fillbardata, colorshifts, extfuncs) --range lock [0, 1]
    if not colorshifts or #colorshifts < 1 then
        local accent = framedata.Parent and findancestor(framedata.Parent, "Accent")
        colorshifts = {accent and accent.Value or defaccent}
    end
    framedata.NoCode = true
    local fillbar, curval = self:AddDragbar(framedata, fillbardata, {Default = fillbardata.Default})
    local numshifts, lastcolor = #colorshifts, 1
    local filler = fillbar.Container.Fillbar
    insert(module.Connections, curval.Changed:Connect(function(val)
        val = clamp(val, 0, 1)
        if fillbar.ClassName:find"Text" then
            fillbar.Indicator.Text =
            redecimal(val*100, 0) end
        tweenservice:Create(filler, TweenInfo.new(1, linear), {Size = UDim2.fromScale(val,1)}):Play()
        --[[local nextcolor = ceil(val*numshifts)
        local increment = nextcolor < lastcolor and -1 or 1
        local numsteps = max(abs(lastcolor - nextcolor), 1)
        for i = lastcolor, nextcolor, increment do
            --fillbar.BackgroundColor3 = colorshifts[i]
            local nextshiftvalue = i == nextcolor and val or i/numshifts
            local newshift = tweenservice:Create(filler, TweenInfo.new(0.5 * 1/numsteps, Enum.EasingStyle.Linear), {
                BackgroundColor3 = colorshifts[i],
                Size = UDim2.new(i/numshifts, 0, 1, 0)
            })
            newshift:Play()
            newshift.Completed:Wait()
            if curval.Value ~= val then break end
        end]]
    end))
    insert(module.Connections, filler:GetPropertyChangedSignal("Size"):Connect(function()
        filler.BackgroundColor3 = phase3(colorshifts, filler.Size.X.Scale)
    end))
    return fillbar
end


function module:AddClickMenu(frame, childoptions, populatedata, extfuncs)
    populatedata = populatedata or {}
    frame.Name = "ClickMenu"

    local accent = findancestor(frame, "Accent")
    accent = accent and accent.Value or defaccent
    
    apply(Instance.new("UI"..childoptions.Sorting.Type.."Layout", frame), childoptions.Sorting)
    local internaldata = extfuncs.UpdateTable or {}
    local base, lastclicked, lastcol

    local connections = {} --if you wanna clean up ig i shouldve added it for everything
    if childoptions.Type == 'Image' then
        base = apply(self:AddBasic("ImageButton"), childoptions.Properties)
        for i = 1, childoptions.Amount do
            local btn = apply(base:Clone(), {Parent = frame, Image = populatedata[i], Name = i})
            
           insert(connections, btn.MouseButton1Click:Connect(function()
                if not childoptions.NoHighlight then
                    if lastclicked then lastclicked.BackgroundColor3 = lastcol end
                    lastclicked, lastcol = btn, btn.BackgroundColor3
                    btn.BackgroundColor3 = accent
                end
                if extfuncs.OnChange then extfuncs.OnChange(frame, i, btn) end
            end))
        end
    else
        base = apply(self:AddBasic"TextButton", childoptions.Properties)
        for i = 1, childoptions.Amount do
            local btn = apply(base:Clone(), {Parent = frame, Text = populatedata[i], Name = i})
            insert(connections, btn.MouseButton1Click:Connect(function()
                if not childoptions.NoHighlight then
                    if lastclicked then lastclicked.BackgroundColor3 = lastcol end
                    lastclicked, lastcol = btn, btn.BackgroundColor3
                    btn.BackgroundColor3 = accent
                end
                if extfuncs.OnChange then extfuncs.OnChange(frame, i, btn) end
            end))
        end
    end
    local def = childoptions.Default
    if def and def > 0 and def <= childoptions.Amount then
        firesignal(frame[def].MouseButton1Click)
    end
    return frame, connections
end

local dragdrop
local function imgdragdrop(onchange, internaldata, accent)
    return function(frame, indxclicked, btn)
        if dragdrop then
            if dragdrop.Owner ~= frame then --if player attempted to swap items not on the same draganddrop
                dragdrop.Inst.BackgroundColor3 = dragdrop.Accent

                dragdrop = {
                    Accent = btn.BackgroundColor3,
                    Inst = btn,
                    Owner = frame
                }
                btn.BackgroundColor3 = accent
            end
            btn.Image, dragdrop.Inst.Image = dragdrop.Inst.Image, btn.Image
            dragdrop.Inst.BackgroundColor3 = dragdrop.Accent
            
            local i, k = tonumber(btn.Name), tonumber(dragdrop.Inst.Name)
            internaldata[i], internaldata[k] = internaldata[k], internaldata[i]
            if onchange then onchange(frame, internaldata, i, k) end
            dragdrop = nil
        else
            dragdrop = {
                Accent = btn.BackgroundColor3,
                Value = btn.Image,
                Inst = btn,
                Owner = frame
            }
            btn.BackgroundColor3 = accent
        end
    end
end
local function txtdragdrop(onchange, internaldata, accent)
    return function(frame, indxclicked, btn)
        if dragdrop then
            if dragdrop.Owner ~= frame then --if player attempted to swap items not on the same draganddrop
                dragdrop.Inst.BackgroundColor3 = dragdrop.Accent

                dragdrop = {
                    Accent = btn.BackgroundColor3,
                    Inst = btn,
                    Owner = frame
                }
                btn.BackgroundColor3 = accent
            end
            btn.Text, dragdrop.Inst.Text = dragdrop.Inst.Text, btn.Text
            dragdrop.Inst.BackgroundColor3 = dragdrop.Accent
            
            local i, k = tonumber(btn.Name), tonumber(dragdrop.Inst.Name)
            internaldata[i], internaldata[k] = internaldata[k], internaldata[i]
            if onchange then onchange(frame, internaldata, i, k) end
            dragdrop = nil
        else
            dragdrop = {
                Accent = btn.BackgroundColor3,
                Value = btn.Text,
                Inst = btn,
                Owner = frame
            }
            btn.BackgroundColor3 = accent
        end
    end
end
function module:AddDragAndDrop(frame, childoptions, populatedata, extfuncs)
    populatedata = populatedata or {}
    frame.Name = "DragAndDrop"

    local accent = findancestor(frame, "Accent")
    accent = accent and accent.Value or defaccent

    local internaldata = extfuncs.UpdateTable or {}
    childoptions.NoHighlight = true
    return self:AddClickMenu(frame, childoptions, populatedata, {
        OnChange = childoptions.Type == 'Image' and imgdragdrop(extfuncs.OnChange, internaldata, accent) or txtdragdrop(extfuncs.OnChange, internaldata, accent)
    })

end
local notifications = {}
function module:ToggleNotification(name, state, ...)
    local notifdata = notifications[name]
    assert(notifications[name], "No notification with the given name: "..name)
    
    if state == nil then state = not notifdata.Object.Visible end
    local funcs = notifdata.funcs
    if funcs then
        if state and funcs.OnOpen then
            funcs.OnOpen(notifdata.Body, ...)
        elseif not state and funcs.OnClose then
            funcs.OnClose(notifdata.Body, ...)
        end
    end
    notifdata.Object.Position = notifdata.Position
    notifdata.Object.Visible = state
end
local defnotification = apply(module:AddBasic("Frame", UDim2.new(0,200,0,145)), {
    Name = "Notification"
})
apply(module:AddBasic("Frame", UDim2.new(1,0,1,-45), UDim2.new(0,0,0,20), defnotification), {
    ClipsDescendants = true,
    Name = "Body"
})
apply(module:AddBasic("TextLabel", UDim2.new(1,0,0,20), nil, defnotification), {
    Text = "Notification",
    BackgroundColor3 = pressedcol,
    TextSize = 12,
    Name = "Top"
})

apply(module:AddBasic("TextButton", UDim2.new(0,25,0,15), UDim2.new(0.5,-12.5, 0.5,-7.5), apply(module:AddBasic("Frame", UDim2.new(1,0,0,25), UDim2.new(0,0,1,-25), defnotification), {
    Name = "Bottom",
    BackgroundColor3 = pressedcol
})), {
    Name = "OK",
    TextSize = 12,
    BackgroundColor3 = subcol,
    BorderColor3 = Color3.new(1,1,1),
    Text = "OK",
})
module:UnclickableThrough(defnotification.Body)

function module:AddNotification(name, data, extfuncs)
    assert(typeof(name) == 'string', "invalid type given for name (requires string)")
    local new = {funcs = extfuncs }
    notifications[name:gsub("<.+>", "")] = new --if u want rich text

    new.Size = data.Size or UDim2.fromOffset(200,100)
    new.Position = data.Position or UDim2.new(0.5,-new.Size.X.Offset * 0.5, 0.5, -new.Size.Y.Offset * 0.5 - 2.5) --minus 2.5 because +20 top +25 bottom, 5 diff/2 = 2.5
    new.Object = apply(defnotification:Clone(), {
        Visible = false,
        Position = new.Position,
        Parent = self.Gui.Notifications,
        Size = new.Size + UDim2.fromOffset(0,45) --20 for top, 25 for bottom
    })
    new.Object.Top.Text = tostring(name)
    new.Body = new.Object.Body
    self:MakeDraggable(new.Object)
    if data.NoBottom then
        new.Object.Bottom:Destroy()
    else
        insert(module.Connections, new.Object.Bottom.OK.MouseButton1Click:Connect(function()
            self:ToggleNotification(name, false)
        end))
    end
    
    return new.Body, new
end
function module:GetNotification(name)
    return notifications[name]
end
local defsearchdrop = apply(module:AddBasic("ScrollingFrame", nil, UDim2.new(0,0,1)), { Name = "SearchDropdown", Visible = false })
function module:AddSearchDropdown(txtbox, searchboxdata, searchboxchoices, extfuncs)
    local searchbox = apply(defsearchdrop:Clone(), { Size = searchboxdata.Size ,BackgroundColor3 = searchboxdata.Color})
    Instance.new("UIListLayout", searchbox).SortOrder = searchboxdata.SortOrder or "LayoutOrder"

    local filter = {}
    for i,v in next, searchboxchoices do
        local new = apply(module:AddBasic("TextButton", searchboxdata.ChoiceSize, nil, searchbox), {
            Name = v,
            Text = extfuncs.Index and v[extfuncs.Index] or v
        })
        insert(module.Connections, new.MouseButton1Click:Connect(function()
            if txtbox.Text == v then return end --perfect match will fire extfuncs in focuslost
            txtbox.Text = v
            searchbox.Visible = false
            if extfuncs.OnChange then extfuncs.OnChange(txtbox, v) end
        end))
        filter[v] = v:gsub("[^%w]+", ""):lower()
    end
    insert(module.Connections, txtbox:GetPropertyChangedSignal"Text":Connect(function() -- because text clears is on, when focused(), it should auto reset everything to visible
        local msg = "^"..txtbox.Text:gsub("[^%w]+", ""):lower() --remove ends spaces
        for i,v in next, filter do
            searchbox[i].Visible = v:find(msg) and true or false
        end
    end))
    insert(module.Connections, txtbox.Focused:Connect(function()
        searchbox.Visible = true 
    end))
    insert(module.Connections, txtbox.FocusLost:Connect(function()
        local exists = searchbox:FindFirstChild(txtbox.Text:gsub("[^%w]", ""))
        
        if exists and not exists:IsA"UIListLayout" then 
            local result = tostring(exists)
            txtbox.Text = result
            searchbox.Visible = false
            if extfuncs.OnChange then extfuncs.OnChange(txtbox, result) end
        end
        return
    end))
    searchbox.Parent = txtbox
    return txtbox
end
local colassign = {
    Light = defcol,
    Dark = pressedcol,
    Medium = subcol,
    Accent = defaccent
}
function module:GetThemeColor(c)
    return colassign[c]
end
function module:ApplyProps(inst, props)
    return apply(inst, props)
end
function module:RandomString(len)
    return rand(len)
end
return module