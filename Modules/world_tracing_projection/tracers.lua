local lp = game.Players.LocalPlayer
local tracer = {}
tracer.__index = tracer
function tracer.new(pos1, pos2)
    local new = setmetatable({
        Target = pos2 or pos1,
        Root = not pos2 and lp or pos1,
        Method = "3D",
        Color = Color3.new(1),
        Components = {},
        Visible = false,
        Name = "Tracer"
    }, tracer)
    new:SetMethod"3D" --recommended
    return new
end
local char, random = string.char, math.random
local function rand(len)
    local result = ""
    for i = 1, len do result = result..char(random(0,255)) end
    return result
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
local def3d, def2d = {}, {}
do
    def3d.Line = apply(Instance.new"Part", {
        Anchored = true,
        Size = Vector3.new(0.6,0.6,5),
        Transparency = 1, --0.6,
        Color = Color3.new(1),
        CanCollide = false,
        TopSurface = "Smooth",
        BottomSurface = "Smooth",
        Material = "Neon"
    })
    def3d.Text = apply(Instance.new("TextLabel"), {
        Name = "Label",
        Text = "Tracer",
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1),
        TextStrokeTransparency = 0,
        TextSize = 32,
        Font = 18,
        Size = UDim2.new(1,0,1),
        Parent = apply(Instance.new"BillboardGui", {
            Enabled = false,
            ExtentsOffsetWorldSpace = Vector3.new(0,0,-1),
            AlwaysOnTop = true,
            Size = UDim2.new(0,150,0,150),
            MaxDistance = 1/0
        })  
    }).Parent
    
    def2d.Node1 = apply(Drawing.new("Circle"), { --idk the point of all this these are like defaults ig
        Color = Color3.new(1),
        Thickness = 2,
        Radius = 3,
        Filled = false,
        Visible = false,
        Position = Vector2.new(450,450)
    })
    def2d.Node2 = def2d.Node1
    def2d.Line = apply(Drawing.new("Line"), {
        Color = Color3.new(1),
        Visible = false,
        Thickness = 2,
    })
    def2d.Text = apply(Drawing.new"Text", {
        Text = "Tracer",
        Size = 32,
        Center = false,
        Outline = true,
        Visible = false,
        OutlineColor = Color3.new(),
        Color = Color3.new(1),
        Position = Vector2.new(500,400),
    })
end

--[[
do stuff like turn part red, transparent, gui clear except text etc
]]
function tracer:SetMethod(method)
    method = assert(typeof(method) == 'string', "Expected string for method SetMethod()") and method:upper()
    assert(method == "3D" or method == "2D", "Invalid method given: "..method)
    --if (self.Method == method) then return end
    pcall(tracer.Destroy, self)
    self.Method = method
    if method == "3D" then
        self.Components = {
            Line = apply(def3d.Line:Clone(), {Name = rand(5) }),
            Text = apply(def3d.Text:Clone(), { Name = rand(5) })
        }
        self.Components.Text.Parent = self.Components.Line
    else
        self.Components = {
            Node1 = apply(Drawing.new("Circle"), {
                Color = Color3.new(1),
                Thickness = 2,
                Radius = 3,
                Filled = false,
                Position = Vector2.new(450,450),
                Visible = false
            }),
            Node2 = apply(Drawing.new("Circle"), {
                Color = Color3.new(1),
                Thickness = 2,
                Radius = 3,
                Filled = false,
                Position = Vector2.new(450,450),
                Visible = false
            }),
            Line = apply(Drawing.new("Line"), {
                Color = Color3.new(1),
                Thickness = 2,
                Visible = false
            }),
            Text = apply(Drawing.new"Text", {
                Text = "Tracer",
                Size = 32,
                Center = true,
                Outline = true,
                Visible = false,
                OutlineColor = Color3.new(),
                Color = Color3.new(1),
                Position = Vector2.new(500,400),
            })
        }
    end
    self:SetText(self.Text)
    self:SetVisible(self.Visible)
end
function tracer:Destroy()
    local comps = self.Components
    if self.Method == '3D' then
        comps.Line:Destroy()
        comps.Text:Destroy()
    else
        for i,v in next, comps do v:Remove() end
        --[[comps.Line:Remove()
        comps.Text:Remove()
        comps.Node1:Remove()
        comps.Node2:Remove()]]
    end
    self.Components = {}
end
function tracer:SetText(n)
    local comps = self.Components
    local msg = tostring(n)
    if self.Method == '3D' then
        comps.Text.Label.Text = msg
    else
        comps.Text.Text = msg
    end
    self.Text = msg
end
function tracer:SetVisible(state)
    local comps = self.Components
    if self.Method == '3D' then
        comps.Line.Transparency = state and 0.5 or 1
        comps.Text.Enabled = state
    else
        local trans = state and 1 or 0 --0 is transparent (reversed for Drawing lib lol)
        for i,v in next, comps do v.Transparency = trans end 
    end
    self.Visible = state
end
function tracer:SetColor(c3)
    local comps = self.Components
    if self.Method == '3D' and comps.Line and comps.Text then
        comps.Line.Color = c3
        comps.Text.Label.TextColor3 = c3
    else
        for i,v in next, comps do v.Color = c3 end 
    end
    self.Color = c3
end
local function getroot(plr)
    return plr and plr.Character and plr.Character:FindFirstChild"HumanoidRootPart"
end
local cc = workspace.CurrentCamera
local toworld = cc.WorldToViewportPoint
local function lerp(a, b, p)
    return a + (b - a) * p
end
local onFailedLookup = Instance.new"Part"
function tracer:Render() --use in renderstep loop in other scr
    if not self.Visible then
        return
    end
    
    local comps = self.Components --player, part, point
    local target, root = self.Target , self.Root
    local tt, tr = typeof(target), typeof(root)
    if tt == 'Instance' then
        target = (target:IsA"Player" and getroot(target) or target:IsA"BasePart" and target or onFailedLookup).Position
        
    else
        target = tt == 'Vector3' and tt or Vector3.zero
    end
    if tr == 'Instance' then
        root = (root:IsA"Player" and getroot(root) or root:IsA"BasePart" and root or onFailedLookup).Position
    else
        root = tr == 'Vector3' and tr or Vector3.zero
    end
    if not comps.Text and comps.Line then return end
    if self.Method == '3D' then
        --comps.Text.StudsOffsetWorldSpace = target --no adornee bc can't be assigned to vec3s
        apply(comps.Line, {
            CFrame = CFrame.new(lerp(root, target, 0.5), target),
            Size = Vector3.new(0.5,0.5, (target - root).Magnitude)
        })
    elseif comps.Node1 and comps.Node2 then --alr check text and line
        local rscreenpos, ronscreen
        if (cc.CFrame.Position - cc.Focus.Position).Magnitude <= 5 then
            rscreenpos, ronscreen = Vector2.new(cc.ViewportSize.X/2, 0), true
        else
            rscreenpos, ronscreen = toworld(cc, root)
        end
        local tscreenpos, tonscreen = toworld(cc, target)
        rscreenpos, tscreenpos = Vector2.new(rscreenpos.X, rscreenpos.Y), Vector2.new(tscreenpos.X, tscreenpos.Y)
        
        comps.Node1.Visible = ronscreen
        comps.Node2.Visible = tonscreen
        comps.Text.Visible = tonscreen
        comps.Line.Visible = tonscreen

        comps.Node2.Position = tscreenpos
        comps.Text.Position = tscreenpos - Vector2.new(0, comps.Text.TextBounds.Y/2)
        comps.Line.To = tscreenpos
        if not ronscreen then
            rscreenpos = Vector2.new(cc.ViewportSize.X/2, 0)
        end
        comps.Line.From = rscreenpos
        comps.Node1.Position = rscreenpos
    end
end

return tracer