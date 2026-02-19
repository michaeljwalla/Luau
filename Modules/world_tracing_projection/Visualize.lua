shared.Visualizers3D =  shared.Visualizers3D or {
    Render = nil, --remind
    Drawings = {},
    Multiplier = 3
}
local function shift(col, amount)
    return Color3.fromRGB(col.R*255+amount,col.G*255+amount,col.B*255+amount)
end
local colors = {
    Blue = Color3.fromRGB(52, 91, 235),
    Red = Color3.fromRGB(219, 46, 31),
    Yellow = Color3.fromRGB(232, 208, 26),
    Orange = Color3.fromRGB(230, 107, 25),
    Green = Color3.fromRGB(40, 217, 24),
    Purple = Color3.fromRGB(121, 24, 217),
    Pink = Color3.fromRGB(224, 25, 184),
    Brown = Color3.fromRGB(92, 49, 9),
    Black = Color3.new(),
    White = Color3.new(1,1,1)
}
local stuff = shared.Visualizers3D
local drawings = stuff.Drawings
local function bindTo(data) -- -> Drawing
    --[[
    
    ex:
    bindTo{
        Type = "Circle",
        At = {vec3s, insts w positions, player insts},
        Mul = number(size multiplier)
        MaxDistance = nil, 50, etc, dist from CHARACTER not camera, default show all
        Color = color3, default whit
        Thickness = nil, default 2
    }
    
    ]]
    data.Mul = data.Mul or stuff.Multiplier
    data.Color = data.Color or Color3.new(1,1,1)
    
    local new = Drawing.new(data.Type)
    new.Visible = true
    new.Color = data.Color
    new.Thickness = 2
    drawings[new] = data--{Type = data.Type, At = data.At, Mul = data.Mul or stuff.Multiplier, Color = color}
    return new
end
local function toggle(d, force)
    if force ~= nil then d.Visible = force else d.Visible = not d.Visible end
    return
end
local function destroy(d) -- d: drawing
    d:Remove()
    drawings[d] = nil
end
local function update(d, color, mul)
    local data = drawings[d]
    local cc, to = workspace.currentCamera, data and data.At[1] or Vector3.zero
    to =( typeof(to) == 'Vector3' and to) or (typeof(to) == 'Instance'
        and (to:IsA"Player" 
            and to.Character and to.Character:FindFirstChild("HumanoidRootPart") and to.Character.HumanoidRootPart.Position)
            or to.Position)
    if data.MaxDistance and (to - workspace.CurrentCamera.CFrame.p).Magnitude > data.MaxDistance then d.Visible = false return end
    local center, vis = cc:WorldToViewportPoint(to)
    if not vis then toggle(d, false) return end
    --good enough resizer
    mul = math.min(mul or data.Mul, (mul or data.Mul) * (100/(cc.CFrame.p - to).Magnitude)^-1)
    
    d.Color = color or data.Color
    if data.Type == 'Quad' then
        d.PointA = Vector2.new(center.X,center.Y-5*mul) --makes /\ shape
        d.PointC = Vector2.new(center.X,center.Y+1*mul)
        
        d.PointB = Vector2.new(center.X-2*mul,center.Y+4*mul)
        d.PointD = Vector2.new(center.X+2*mul, center.Y+4*mul)
    elseif data.Type == 'Line' then
        local from = data.At[2]
        from = ( typeof(from) == 'Vector3' and from) or (typeof(from) == 'Instance'
        and (from:IsA"Player" 
            and from.Character and from.Character:FindFirstChild("HumanoidRootPart") and from.Character.HumanoidRootPart.Position)
            or from.Position)
        local from, vis = cc:WorldToViewportPoint(from or Vector3.zero)
        if not vis then toggle(d, false) return end
        d.To = Vector2.new(center.X,center.Y)
        d.From = Vector2.new(from.X, from.Y)
    else
        d.Position = Vector2.new(center.X,center.Y)
        if data.Type == 'Circle' then d.Radius = data.Mul end
    end
    toggle(d, true)
end
local function clear()
    for i,v in next, drawings do destroy(i) end
end
if stuff.Render then stuff.Render:Disconnect() end
stuff.Render = game["Run Service"].RenderStepped:Connect(function()
    for i,v in next, drawings do update(i) end
end)



clear()
return {
    Create = bindTo,
    Upd = update,
    Drawings = drawings,
    Destroy = destroy,
    ClearAllDrawings = clear,
    Colors = colors
}