--cycle tracker
--the command line is half broken, will not be fixing as i do not care!
--this script will be updated way more likely than the others, to account for new/removed disasters
if game.CoreGui:FindFirstChild"CycleTrack" then game.CoreGui.CycleTrack:Destroy() end
if _G.cycler then for i,v in pairs(_G.cycler) do v:Disconnect() end end
_G.cycler = {}

local main = Instance.new("ScreenGui", game.CoreGui)
main.Name = 'CycleTrack'
--bonus, hyper, imp, blue boss, red boss
-- ignore "Nuke" disaster (its the nuclear bomb)
local UIS = game:GetService("UserInputService")
local lp = game.Players.LocalPlayer
local mouse = lp:GetMouse()
local rs = game.ReplicatedStorage
local ids = {
    Disasters = {
        [3008364768] = {
            {
                Name = 'Acid Rain',
                Hyper = true
            },
            {
                Name = 'Alexnewtron',
                Hyper = true
            },
            {
                Name = 'Alien Invasion',
                Hyper = true
            },
            {
                Name = 'Avalanche',
                Hyper = true
            },
            {
                Name = 'UFO',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Black Mage',
                Hyper = true,
                Boss = {
                    "Red"
                }
            },
            {
                Name = 'Bombers',
                Hyper = true
            },
            {
                Name = 'Missile Strike',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Cake',
                Hyper = true
            },
            {
                Name = 'Coil Noobs',
                Hyper = true
            },
            {
                Name = 'Crimson Balrog',
                Hyper = true,
                Boss = {
                    "Blue"
                }
            },
            {
                Name = 'Death Trampoline',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Caterdriller',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Dynamites',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Epic Duck',
                Hyper = true
            },
            {
                Name = 'Epic Katana'
            },
            {
                Name = 'Explosive Noobs',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Sawbot',
                Unused = true
            },
            {
                Name = 'Flash Flood',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Ghosts',
                Hyper = true,
                Imp = true
            },
        },
        [3036265979] = {
            {
                Name = 'Giant Noob',
                Boss = {"Blue"},
                Hyper = true
            },
            {
                Name = 'Guest Ambush',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Killbots',
                Hyper = true
            },
            {
                Name = 'Illumina',
                Hyper = true
            },
            {
                Name = 'Neon Blaster',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Korblox Mages'
            },
            {
                Name = 'Meteors',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Mine Spawn',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Neon Trooper',
                Hyper = true
            },
            {
                Name = 'Missile Launcher',
                Hyper = true
            },
            {
                Name = 'Ninjas',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Noobs',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Nyan Cat',
                Hyper = true
            },
            {
                Name = 'Overseer Soldiers',
                Hyper = true
            },
            {
                Name = 'Pacman',
                Hyper = true
            },
            {
                Name = 'Pacman Ghosts',
                Hyper = true
            },
            {
                Name = 'Press The Button',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Raining Tacos',
                Hyper = true
            },
            {
                Name = 'Reaper',
                Hyper = true,
                Boss = {
                    "Red"
                }
            },
            {
                Name = 'Redcliff Warriors',
                Hyper = true
            }
        },
        [2729921706] = {
            {
                Name = 'Rising Acid',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Rising Lava',
                Hyper = true
            },
            {
                Name = 'Rocket Noobs',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Sandstorm',
                Hyper = true
            },
            {
                Name = 'Shedletsky'
            },
            {
                Name = 'Shoop Da Whoop'
            },
            {
                Name = 'Shurikens',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Sighters',
                Hyper = true
            },
            {
                Name = 'Soccer Balls',
                Hyper = true
            },
            {
                Name = 'Spiked Walls',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Nuclear Bomb',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Tetris',
            },
            {
                Name = 'Thieves',
                Hyper = true
            },
            {
                Name = 'Time Bombs',
                Hyper = true
            },
            {
                Name = 'Tornado',
                Hyper = true
            },
            {
                Name = 'Tsunami',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Undyne',
                Hyper = true,
                Boss = {
                    "Blue"
                }
            },
            {
                Name = 'Wolven Footsoldier',
                Hyper = true
            },
            {
                Name = 'X-Bomb',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Zerg Lurker',
                Hyper = true,
                Imp = true
            },
        },
        [2981239797] = {
            {
                Name = 'Zombies',
                Hyper = true
            },
            {
                Name = 'Mystery Disaster',
                Mystery = true,
                Hyper = true
            },
            {
                Name = 'NO IMAGE', --placeholder, most likely used in sd2 testing
                Unused = true
            },
            {
                Name = 'Stonetroid'
            },
            {
                Name = 'Killer Robot',
                Unused = true
            },
            {
                Name = 'Token Hunt B',
                Bonus = true
            },
            {
                Name = 'Get Down',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Murderers',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Crazy Robloxian'
            },
            {
                Name = 'Polyhex',
                Hyper = true
            },
            {
                Name = 'Pizza Dude',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Tix Defense',
                Bonus = true
            },
            {
                Name = 'Slenderman',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Tiny Noobs',
                Hyper = true
            },
            {
                Name = 'Giant Zombie'
            },
            {
                Name = 'Assassin',
                Unused = true
            },
            {
                Name = 'Volcano',
                Hyper = true
            },
            {
                Name = 'Coin Balloon',
                Bonus = true
            },
            {
                Name = 'Falling Hoops',
                Bonus = true
            },
            {
                Name = 'Token Hunt A',
                Bonus = true
            }
        },
        [6061084637] = {
            {
                Name = 'Artemis',
                Unused = true
            },
            {
                Name = 'Guardian',
                Unused = true
            },
            {
                Name = 'Mr. Happy',
                Hyper = true
            },
            {
                Name =  'Orinthian Archers',
                Unused = true
            },
            {
                Name = 'Icicles',
                Hyper = true
            },
            {
                Name = 'Yojimbo',
                Hyper = true,
                Boss = {
                    "Red"
                }
            },
            {
                Name = 'Thunderstorm',
                Hyper = true
            },
            {
                Name = 'Green Zone',
                Hyper = true
            },
            {
                Name = 'Oil Spill'
            },
            {
                Name = 'Hot Potato',
                Hyper = true
            },
            {
                Name = 'Lumberjack',
                Hyper = true,
                Imp = true
            },
            {
                Name = 'Doge'
            },
            {
                Name = 'Counterfeit Coins'
            },
            {
                Name = 'Beehive'
            },
            {
                Name = 'Barrel Boy'
            },
            {
                Name = 'Tipping Block',
                Hyper = true
            },
            {
                Name = 'Cactoball'
            },
            {
                Name = 'Secret Disaster',
                Unused = true
            }
        },
        [7906701624] = {
            [8] = {
                Name = 'Poltergeist'
            },
            [9] = {
                Name = 'Witch'
            }
        },
        [11500844428] = {
            [1] = {
                Name = 'Delinquent'
            },
            [4] = {
                Name = 'Sniper'
            },
            [10] = {
                Name = 'Scoobis'
            },
            [19] = {
                Name = 'Giant Gun'
            }
        }
    },
    Messages = {
        [3942861961] = {}
    }
}
local function disloaded(gui)
    return gui:FindFirstChild("Frame")
        and gui.Frame:FindFirstChild("Frame")
        and gui.Frame.Frame:FindFirstChild("Disaster")
        and gui.Frame.Frame.Disaster:FindFirstChild("Value")
        and gui.Frame.Frame:FindFirstChild("Type")
end
local function servernameof(num)
    for i,v in pairs(rs.Images:GetChildren()) do
        if v.Value == num then return v.Name end
    end
    return 'None'
end
--loads before/after disasters
local function getready(gui) --Bonus, Boss, Survived, Wipeout, Warning, Upgraded
    return gui.Name:gsub("Gui", "")
end
local function specinfo(imglbl) --img splashscreen
    local data = 'Normal'
    if imglbl.Visible then
        if imglbl.ImageRectOffset.Y == 256 or imglbl.ImageRectOffset.Y == 704 then
            data = "Blue Boss"
        elseif imglbl.ImageRectOffset.Y == 320 then
            data = "Red Boss"
        elseif imglbl.ImageRectOffset.Y == 384 then
            data = "Hyper"
        elseif imglbl.ImageRectOffset.Y == 448 then
            data = "Impossible"
        elseif imglbl.ImageRectOffset.Y == 512 then
            data = "Bonus"
        end
    end
    return data
end
local function bosstype(imglbl) --ladies and gentlemen it's showtime
    if imglbl.ImageRectOffset == Vector2.new(0, 512) then
        return "Blue"
    elseif imglbl.ImageRectOffset == Vector2.new(0,384) then
        return "Red"
    end
    return "Not a boss round retard"
end
local function gettype(gui) --introduces disaster
    if gui.Name == 'DisasterGui' then
        local type, specialinfo = {}, {}
        local t = tick()
        while tick() - t < 10 and not disloaded(gui) do task.wait() end
        if not disloaded(gui) then 
            gui:Clone().Parent = game:GetService"MarketplaceService" 
            error("Couldnt find all assets. Cloned gui to MarketplaceService.") 
            return
        end
        local asset, offset, distype = tonumber(({gui.Frame.Frame.Disaster.Image:gsub("rbxassetid://", "")})[1]), gui.Frame.Frame.Disaster.Value.Value, gui.Frame.Frame.Type
        type.FromImage = servernameof(asset)
        type.ImageAsset = asset
        type.Data = ids.Disasters[asset][offset]
        type.RoundType = specinfo(distype)
        return type
    end
    return gui.Name
end
local function mousePos()
    return {x = mouse.X, y = mouse.Y}
end
local function draggable(inst,dragwhat)
    local start, curPos
    local movewithme
    inst.InputBegan:Connect(function(InputObject)
        if InputObject.UserInputType == Enum.UserInputType.MouseButton1 then
            movewithme = mouse.Button1Down:Connect(function()
                inst.BackgroundColor3 = Color3.new(1/8,1/8,1/8)
                start = mousePos()
                while task.wait() and movewithme.Connected do
                    curPos = mousePos()
                    menuLast = dragwhat.Position
                    if curPos.x ~= start.x or curPos.y ~= start.y then
                        dragwhat.Position = dragwhat.Position + UDim2.new(0,curPos.x - start.x,0, curPos.y - start.y)
                        start = mousePos()
                    end
                end
                inst.BackgroundColor3 = Color3.new(1/6,1/6,1/6)
            end)
        end
    end)
    local mouseConnection
    mouseConnection = mouse.Button1Up:Connect(function()
        if not inst or not inst.Parent then mouseConnection:Disconnect() else do
            start = mousePos()
            curPos = start
            pcall(function()movewithme:Disconnect()end)
        end end
    end)
end
local function color(c1,c2,c3, rgb)
    if c1 and not c2 then
        return Color3.new(c1,c1,c1)
    elseif rgb then
        return Color3.fromRGB(c1,c2,c3)
    else return Color3.new(c1,c2,c3) end
end
local function deftxt(type, parent)
    local new = Instance.new(type, parent)
    new.BackgroundColor3 = color(1/3)
    new.TextColor3 = color(1)
    new.RichText = true
    new.TextSize = 14
    new.Font = Enum.Font.Code
    new.TextTruncate = "AtEnd"
    return new
end
local function defframe(type, parent)
    local new = Instance.new(type, parent)
    new.BackgroundColor3 = color(1/3)
    if type == 'ScrollingFrame' then new.AutomaticCanvasSize = "Y" new.ScrollBarThickness = 2 Instance.new("UIListLayout", new) end
    return new
end
local mm = defframe("Frame", main)
mm.Size = UDim2.fromOffset(300, 400)
mm.Position = UDim2.new(1,-300,0.5,-200)
local container = mm:Clone()
container.Parent = mm
container.Size = UDim2.new(1,0,1,-80)
container.Position = UDim2.fromOffset(0,20)
container.ClipsDescendants = true
local curdis = deftxt("TextLabel", mm)
curdis.Position = UDim2.new(0,0,1,-40)
curdis.BackgroundColor3 = color(1/3)
curdis.Size = UDim2.new(1,0,0,20)
curdis.Text = "-"
local nextround = curdis:Clone()
nextround.Parent = mm
nextround.Text = "Next Round Type - Normal"
nextround.Position = UDim2.new(0,0,1,-60)
local updatecurdis = function()
    local txt = rs.Info.Notice.Value
    if txt == 'Mystery Disaster' or txt == 'Hyper Mystery Disaster' then
        local dis = workspace.Disaster:FindFirstChildOfClass"Model" or workspace.Disaster.ChildAdded:Wait()
        txt = dis.Name
    end
    curdis.Text = (txt ~= 'Next Disaster In' and txt ~= 'Stage Select' and txt ~= 'Warning!!!' and txt ~= 'Break Time' and txt) or "-"
end
table.insert(_G.cycler, rs.Info.Notice.Changed:Connect(updatecurdis))
updatecurdis()
table.insert(_G.cycler, workspace.Disaster.ChildRemoved:Connect(function(v)
    if #workspace.Disaster:GetChildren() < 1 then curdis.Text = '-' end
end))
local dragbar = deftxt("TextLabel", mm)
dragbar.Size = UDim2.new(1,0,0,20)
dragbar.BackgroundColor3 = color(1/6)
dragbar.Text = 'Cycle Tracker'
draggable(dragbar,mm)
local pages,index = {}, 1
local function loadpage(page, unload)
    unload = unload or 0
    if pages[unload] then dragbar.Text = "Cycle Tracker - "..pages[unload].Title for i,v in pairs(pages[unload].Items) do v.Parent = nil end end
    if pages[page] then dragbar.Text = "Cycle Tracker - "..pages[page].Title for i,v in pairs(pages[page].Items) do v.Parent = container end end
end
local pagechanger = Instance.new("Frame", mm)
pagechanger.BackgroundTransparency = 0
pagechanger.Size = UDim2.new(1,0,0,20)
pagechanger.Position = UDim2.new(0,0,1,-20)
local leftcolor = deftxt("TextButton", pagechanger)
leftcolor.Text = "<<"
leftcolor.BackgroundColor3 = color(1/8)
leftcolor.TextTransparency = 0.5
leftcolor.Size = UDim2.new(0.5,0,1,0)
local rightcolor = leftcolor:Clone()
rightcolor.Parent = pagechanger
rightcolor.Position = UDim2.new(0.5,0,0,0)
rightcolor.TextTransparency = 0
rightcolor.Text = ">>"
rightcolor.BackgroundColor3 = color(1/5)
leftcolor.MouseButton1Click:Connect(function()
    if index < 2 or index > #pages then return end
    index = index - 1
    loadpage(index, index + 1)
    if index == 1 then
        leftcolor.TextTransparency = 0.5
        leftcolor.BackgroundColor3 = color(1/8)
    else
        leftcolor.TextTransparency = 0
        leftcolor.BackgroundColor3 = color(1/5)
    end
    if index == #pages then
            rightcolor.TextTransparency = 0.5
            rightcolor.BackgroundColor3 = color(1/8)
        else
            rightcolor.TextTransparency = 0
            rightcolor.BackgroundColor3 = color(1/5)
        end
end)
rightcolor.MouseButton1Click:Connect(function()
    if index > #pages-1 then return end
    index = index + 1
    loadpage(index, index - 1)
    if index == #pages then
        rightcolor.TextTransparency = 0.5
        rightcolor.BackgroundColor3 = color(1/8)
    else
        rightcolor.TextTransparency = 0
        rightcolor.BackgroundColor3 = color(1/5)
    end
    if index == 1 then
        leftcolor.TextTransparency = 0.5
        leftcolor.BackgroundColor3 = color(1/8)
    else
        leftcolor.TextTransparency = 0
        leftcolor.BackgroundColor3 = color(1/5)
    end
end)
local cmdline = deftxt("TextBox", mm)
cmdline.Size = UDim2.new(1,0,0,20)
cmdline.Position = UDim2.new(0,0,1,0)
cmdline.PlaceholderText = "Command Line"
cmdline.Text = ""
cmdline.ClearTextOnFocus = false
local entercommand = deftxt("TextButton", mm)
entercommand.Size = cmdline.Size
entercommand.Position = cmdline.Position + UDim2.fromOffset(0,20)
entercommand.Text = 'Send'
local colors = {
    Blue = "#5CD6F5",
    Red = "#C93131",
    Yellow = '#FFFF66'
}
local values = {
    unknown = '<font color="#A8A8A8">?</font>',
    unpassed = '<font color="#C12F2F">X</font>',
    passed = '<font color="#49DB75">✓</font>'
}
local function len(tbl)
    local x = 0;
    for i,v in pairs(tbl) do x = x + 1 end
    return x
end
local pc1, pc2 = {}, {}
local mode = rs.Info.Gamemode.Value
if _G.mode ~= mode then
    _G.mode = mode
    _G.pc1 = pc1
    _G.pc2 = pc2
    print('overwriting...')
else
    pc1 = _G.pc1
    pc2 = _G.pc2
end
local function uncheck(type, name, from, altfrom, unknown)
    local valtbl, ui = type[name], from.Scroller:FindFirstChild(name) or (altfrom and altfrom.Scroller:FindFirstChild(name))
    if not valtbl then return end
    valtbl.checked = (unknown and values.unknown) or values.unpassed
    
    if ui then
        ui.Parent = from.Parent:FindFirstChild("Unpassed").Scroller
        ui.Text = name.." - "..valtbl.checked
    end
    if type == pc2 then return end
    if valtbl.data.Boss then
        from.Parent:FindFirstChild("Bosses").Scroller[name].Text = string.format('<font color="%s">%s - </font>%s', (mode == 'Normal' and colors['Blue']) or colors[valtbl.data.Boss[1]], name, valtbl.checked)
    elseif valtbl.data.Bonus then
        from.Parent:FindFirstChild("Bonuses").Scroller[name].Text = string.format('<font color="%s">%s - </font>%s', colors['Yellow'], name, valtbl.checked)
    end
end
function notify(title, text, duration, icon)
    local options = {}
    if not title and text then return end
    options.Title = title
    options.Text = text
    if duration then options.Duration = duration else do options.Duration = 5 end end
    if icon then options.Icon = icon end
    game.StarterGui:SetCore("SendNotification", options)
end
local function cyclereset(tbl, where, to)
    for i,v in pairs(tbl) do
        uncheck(tbl, v.data.Name, where, to)
    end
    notify("Cycle Reset", (mode == 'Normal' and ((tbl == pc1 and 'Standard Cycle') or 'Hyper Cycle')) or ((tbl == pc1 and 'Hyper Cycle') or 'Impossible Cycle'))
end
local function checkoff(type, name, where, to) --type is which cycle tbl, name is disName, where and to are for gui (unpass -> pass)
    local valtbl, ui = type[name], where.Scroller:FindFirstChild(name)
    if not (valtbl and ui) then
        if valtbl.checked == values.passed and to.Scroller:FindFirstChild(name) then
            cyclereset(type, where, to)
            ui = to.Scroller:FindFirstChild(name) or where.Scroller:FindFirstChild(name)
        end
    end
    valtbl.checked = values.passed
    ui.LayoutOrder = -1*#to.Scroller:GetChildren()
    ui.Parent = to.Scroller
    ui.Text = name.." - "..valtbl.checked
    if type == pc2 then return end
    if valtbl.data.Boss then
        where.Parent:FindFirstChild("Bosses").Scroller[name].Text = string.format('<font color="%s">%s - </font>%s', (mode == 'Normal' and colors['Blue']) or colors[valtbl.data.Boss[1]], name, valtbl.checked)
    elseif valtbl.data.Bonus then
        where.Parent:FindFirstChild("Bonuses").Scroller[name].Text = string.format('<font color="%s">%s - </font>%s', colors['Yellow'], name, valtbl.checked)
    end
end

if mode == 'Normal' then
    if (len(pc1) < 1) or (len(pc2) < 1) then
        for i,v in pairs(ids.Disasters) do
            for a,x in pairs(v) do
                if x.Unused or x.Mystery then continue end
                pc1[x.Name] = {data = x, checked = values.unknown}
                if x.Hyper then pc2[x.Name] = {data = x, checked = values.unknown} end
            end
        end
    end
    local normpagecontainer = container:Clone()
    normpagecontainer.Size = UDim2.new(1,0,1,0)
    normpagecontainer.Position = UDim2.new()
    normpagecontainer.BackgroundTransparency = 1
    
    local unpassnorm = defframe("Frame", normpagecontainer)
    unpassnorm.Name = 'Unpassed'
    unpassnorm.Size = UDim2.new(0.5,0,0.5,0)
    local unpasslabel = deftxt("TextLabel", unpassnorm)
    unpasslabel.BackgroundColor3 = color(1/5)
    unpasslabel.Size = UDim2.new(1,0,0,20)
    unpasslabel.Text = '<font color="#8795C3">Unpassed</font>'
    unpasslabel.Name = 'Unpassed'
    local unpassscroller = defframe("ScrollingFrame", unpassnorm)
    unpassscroller.Size = UDim2.new(1,0,1,0)
    unpassscroller.Position = UDim2.new(0,0,0,20)
    unpassscroller.CanvasSize = UDim2.new()
    unpassscroller.Name = 'Scroller'
    local passnorm = unpassnorm:Clone()
    passnorm.Parent = normpagecontainer
    passnorm.Name = 'Passed'
    passnorm.Unpassed.Name = 'Passed'
    passnorm.Passed.Text = '<font color="#8795C3">Passed</font>'
    passnorm.Size = UDim2.new(0.5,-1,0.5,20)
    passnorm.Position = UDim2.new(0.5,1,0,0)
    passnorm.Scroller.UIListLayout.SortOrder = 'LayoutOrder'
    local bossnorm = unpassnorm:Clone()
    bossnorm.Parent = normpagecontainer
    bossnorm.Name = 'Bosses'
    bossnorm.Position = UDim2.new(0,0,0.5,20)
    bossnorm.Unpassed.Name = 'Bosses'
    bossnorm.Bosses.Text = '<font color="#8795C3">Bosses - Formatted</font>'
    local bonusnorm = bossnorm:Clone()
    bonusnorm.Parent = normpagecontainer
    bonusnorm.Name = 'Bonuses'
    bonusnorm.Position = UDim2.new(0.5,0,0.5,40)
    bonusnorm.Bosses.Name = 'Bonuses'
    bonusnorm.Bonuses.Text = '<font color="#8795C3">Bonuses - Formatted</font>'
    
    local hyppagecontainer = container:Clone()
    hyppagecontainer.Size = UDim2.new(1,0,1,0)
    hyppagecontainer.Position = UDim2.new()
    hyppagecontainer.BackgroundTransparency = 1
    local unpasshyp = unpassnorm:Clone()
    unpasshyp.Parent = hyppagecontainer
    unpasshyp.Size = UDim2.new(0.5,0,1,0)
    unpasshyp.Unpassed.Text = '<font color="#F0C4FF">Unpassed</font>'
    local passhyp = passnorm:Clone()
    passhyp.Parent = hyppagecontainer
    passhyp.Size = UDim2.new(0.5,0,1,0)
    passhyp.Passed.Text = '<font color="#F0C4FF">Passed</font>'
    
    for i,v in pairs(pc1) do
        local new = deftxt("TextLabel")
        new.Name = i
        new.Text = i.." - "..v.checked
        new.Size = UDim2.new(1,-2,0,20)
        new.TextWrapped = true
        new.AutomaticSize = "Y"
        new.Parent = ((v.checked == values.unpassed or v.checked == values.unknown) and unpassnorm.Scroller) or passnorm.Scroller
        if v.data.Boss then
            local boss = new:Clone()
            boss.Size = UDim2.new(1,0,0,20)
            boss.Text = string.format('<font color="%s">%s - </font>%s', colors['Blue'], i, v.checked)
            boss.Parent = bossnorm.Scroller
        elseif v.data.Bonus then
            local bonus = new:Clone()
            bonus.Size = UDim2.new(1,0,0,20)
            bonus.Text = string.format('<font color="%s">%s - </font>%s', colors['Yellow'], i, v.checked)
            bonus.Parent = bonusnorm.Scroller
        end
    end
    for i,v in pairs(pc2) do
        local new = deftxt("TextLabel")
        new.Name = i
        new.Text = i.." - "..v.checked
        new.Size = UDim2.new(1,-2,0,20)
        new.TextWrapped = true
        new.AutomaticSize = "Y"
        new.Parent = ((v.checked == values.unpassed or v.checked == values.unknown) and unpasshyp.Scroller) or passhyp.Scroller
    end
    pages[1] = {Title = '<font color="#8795C3">Normal</font>', Items = {normpagecontainer}}
    pages[2] = {Title = '<font color="#F0C4FF">Hyper</font>', Items = {hyppagecontainer}}
    table.insert(_G.cycler, lp.PlayerGui.ChildAdded:Connect(function(c)
        local info = gettype(c)
        if type(info) ~= 'table' then
            --[[if info == 'MultiDisasterGui' then
                local txt = rs.Info.Notice
                local t = tick()
                while tick() - t < 10 and not (txt ~= 'Next Disaster In' and txt ~= 'Stage Select' and txt ~= 'Warning!!!' and txt ~= 'Break Time') do task.wait() end
                if not (txt.Value ~= 'Next Disaster In' and txt.Value ~= 'Stage Select' and txt.Value ~= 'Warning!!!' and txt.Value ~= 'Break Time') then return end
                curdis.Text = txt.Value
            else]]if info == 'SurvivedGui' or info == 'WipeoutGui' then
                nextround.Text = "Next Round Type - <font color=\"#8795C3\">Normal</font>"
            elseif info == 'WarningGui' then 
                nextround.Text = "Next Round Type - <font color=\"#CC5A1D\">Multi</font> / Mystery / <font color=\"#F0C4FF\">Hyper</font>"
            elseif info == 'BonusGui' then
                nextround.Text = ('Next Round Type - <font color=\"%s\">Bonus</font>'):format(colors.Yellow)
            elseif info == 'BossGui' then
                nextround.Text = ('Next Round Type - <font color=\"%s\">Boss ('..bosstype(c:WaitForChild"Frame":WaitForChild"Frame":WaitForChild"Disaster")..")</font>"):format(colors.Blue)
            end
            return 
        end
        if info.Data.Mystery then
            local dis = workspace.Disaster:FindFirstChildOfClass"Model" or workspace.Disaster.ChildAdded:Wait()
            checkoff(pc1, dis.Name, unpassnorm, passnorm)
        elseif info.RoundType == 'Hyper' then
            checkoff(pc2, info.Data.Name, unpasshyp, passhyp)
        else
            checkoff(pc1, info.Data.Name, unpassnorm, passnorm)
        end
    end))
    cmdline.Focused:Connect(function()
        local txt = cmdline.Text:gsub('<font color="#%x*">', ''):gsub('</font>', '')
        cmdline.Text = txt
    end)
    cmdline.FocusLost:Connect(function()
        local txt = cmdline.Text:gsub("^%s*", ""):gsub("%s*$", "")
        local args = txt:split" "
        if args[1] == 'check' or args[1] == 'uncheck' or args[1] =='unknown' or args[1] == 'unk' or args[1] == 'reset' or args[1] == 'add' or args[1] == 'rem' then
            args[1] = '<font color="#468AB7">'..args[1]..'</font>'
        end
        if args[2] then
            if args[1] == '<font color="#468AB7">reset</font>' then
                if args[2] == 'h' or args[2] == 'n' then
                    args[2] = '<font color="#D84141">'..args[2]..'</font>'
                end
            else
                for i = 3, #args - 1 do
                    args[2] = args[2].." "..args[i]
                end
                args[3] = args[#args]
                if #args ~= 2 and (args[3] == 'h' or args[3] =='i') then
                    args[3] = '<font color="#D84141">'..args[3]..'</font>'
                    for i,v in pairs(pc2) do
                        if v.data.Name:lower():find(args[2]:lower()) == 1 then
                            args[2] = '<font color="#50D841">'..v.data.Name..'</font>'
                            break
                        end
                    end
                else
                    args[3] = nil
                    for i,v in pairs(pc1) do
                        if v.data.Name:lower():find(args[2]:lower()) == 1 then
                            args[2] = '<font color="#50D841">'..v.data.Name..'</font>'
                            break
                        end
                    end
                end
            end
        end
        local result = ''
        for i = 1, 3 do result = result..(args[i] or "").." " end
        cmdline.Text = result:gsub("%s*$", "")
    end)
    entercommand.MouseButton1Click:Connect(function()
        local txt = cmdline.Text:gsub('<font color="#%x*">', ''):gsub('</font>', '')
        local args = txt:split" "
        if args[2] then
            if args[1] == 'reset' then
                if args[2] == 'h' then
                    cyclereset(pc2, unpasshyp, passhyp)
                    cmdline.Text = ''
                elseif args[2] == 'n' then
                    cyclereset(pc1, unpassnorm, passnorm)
                    cmdline.Text = ''
                end
            else
                for i = 3, #args do
                    if i >= 4 then break end
                    args[2] = args[2].." "..args[i]
                end
                if args[3] == 'h' then args[2] = args[2]:sub(1,-3) end
                args[3] = args[#args]
                if args[3] == 'h' then
                    for i,v in pairs(pc2) do
                        if v.data.Name == args[2] then
                            if (args[1] == 'check' or args[1] == 'add') and v.checked ~= values.passed then
                                checkoff(pc2, v.data.Name, unpasshyp, passhyp)
                                cmdline.Text = ''
                            elseif (args[1] == 'uncheck' or args[1] == 'rem') and v.checked ~= values.unpassed then
                                uncheck(pc2, v.data.Name, unpasshyp, passhyp)
                                cmdline.Text = ''
                            elseif (args[1] == 'unknown' or args[1] == 'unk') and v.checked ~= values.unknown then
                                uncheck(pc1, v.data.Name, unpasshyp, passhyp, true)
                                cmdline.Text = ''
                            end
                            return
                        end
                    end
                else
                    for i,v in pairs(pc1) do
                        if v.data.Name == args[2] then
                            if (args[1] == 'check' or args[1] == 'add') and v.checked ~= values.passed then
                                checkoff(pc1, v.data.Name, unpassnorm, passnorm)
                                cmdline.Text = ''
                            elseif (args[1] == 'uncheck' or args[1] == 'rem') and v.checked ~= values.unpassed then
                                uncheck(pc1, v.data.Name, unpassnorm, passnorm)
                                cmdline.Text = ''
                            elseif (args[1] == 'unknown' or args[1] == 'unk') and v.checked ~= values.unknown then
                                uncheck(pc1, v.data.Name, unpassnorm, passnorm, true)
                                cmdline.Text = ''
                            end
                            return
                        end
                    end
                end
            end
        end
    end)
elseif mode == 'Hardcore' then
    if (len(pc1) < 1) or (len(pc2) < 1) then
        for i,v in pairs(ids.Disasters) do
            for a,x in pairs(v) do
                if x.Mystery or x.Unused or not x.Hyper then continue end
                pc1[x.Name] = {data = x, checked = values.unknown}
                if x.Imp then pc2[x.Name] = {data = x, checked = values.unknown} end
            end
        end
    end
    local normpagecontainer = container:Clone()
    normpagecontainer.Size = UDim2.new(1,0,1,0)
    normpagecontainer.Position = UDim2.new()
    normpagecontainer.BackgroundTransparency = 1
    
    local unpassnorm = defframe("Frame", normpagecontainer)
    unpassnorm.Name = 'Unpassed'
    unpassnorm.Size = UDim2.new(0.5,0,0.5,0)
    local unpasslabel = deftxt("TextLabel", unpassnorm)
    unpasslabel.BackgroundColor3 = color(1/5)
    unpasslabel.Size = UDim2.new(1,0,0,20)
    unpasslabel.Text = '<font color="#F0C4FF">Unpassed</font>'
    unpasslabel.Name = 'Unpassed'
    local unpassscroller = defframe("ScrollingFrame", unpassnorm)
    unpassscroller.Size = UDim2.new(1,0,1,0)
    unpassscroller.Position = UDim2.new(0,0,0,20)
    unpassscroller.CanvasSize = UDim2.new()
    unpassscroller.Name = 'Scroller'
    local passnorm = unpassnorm:Clone()
    passnorm.Parent = normpagecontainer
    passnorm.Name = 'Passed'
    passnorm.Unpassed.Name = 'Passed'
    passnorm.Passed.Text = '<font color="#F0C4FF">Passed</font>'
    passnorm.Size = UDim2.new(0.5,-1,1, 0)
    passnorm.Position = UDim2.new(0.5,1,0,0)
    passnorm.Scroller.UIListLayout.SortOrder = 'LayoutOrder'
    local bossnorm = unpassnorm:Clone()
    bossnorm.Parent = normpagecontainer
    bossnorm.Name = 'Bosses'
    bossnorm.Position = UDim2.new(0,0,0.5,20)
    bossnorm.Unpassed.Name = 'Bosses'
    bossnorm.Bosses.Text = '<font color="#F0C4FF">Bosses - Formatted</font>'
    
    local hyppagecontainer = container:Clone()
    hyppagecontainer.Size = UDim2.new(1,0,1,0)
    hyppagecontainer.Position = UDim2.new()
    hyppagecontainer.BackgroundTransparency = 1
    local unpasshyp = unpassnorm:Clone()
    unpasshyp.Parent = hyppagecontainer
    unpasshyp.Size = UDim2.new(0.5,0,1,0)
    unpasshyp.Unpassed.Text = '<font color="#CC2B1D">Unpassed</font>'
    local passhyp = passnorm:Clone()
    passhyp.Parent = hyppagecontainer
    passhyp.Size = UDim2.new(0.5,0,1,0)
    passhyp.Passed.Text = '<font color="#CC2B1D">Passed</font>'
    
    for i,v in pairs(pc1) do
        local new = deftxt("TextLabel")
        new.Name = i
        new.Text = i.." - "..v.checked
        new.Size = UDim2.new(1,-2,0,20)
        new.TextWrapped = true
        new.AutomaticSize = "Y"
        new.Parent = ((v.checked == values.unpassed or v.checked == values.unknown) and unpassnorm.Scroller) or passnorm.Scroller
        if v.data.Boss then
            local boss = new:Clone()
            boss.Size = UDim2.new(1,0,0,20)
            boss.Text = string.format('<font color="%s">%s - </font>%s', colors[v.data.Boss[1]], i, v.checked)
            boss.Parent = bossnorm.Scroller
        end
    end
    for i,v in pairs(pc2) do
        local new = deftxt("TextLabel")
        new.Name = i
        new.Text = i.." - "..v.checked
        new.Size = UDim2.new(1,-2,0,20)
        new.TextWrapped = true
        new.AutomaticSize = "Y"
        new.Parent = ((v.checked == values.unpassed or v.checked == values.unknown) and unpasshyp.Scroller) or passhyp.Scroller
    end
    pages[1] = {Title = '<font color="#F0C4FF">Hyper</font>', Items = {normpagecontainer}}
    pages[2] = {Title = '<font color="#CC2B1D">Impossible</font>', Items = {hyppagecontainer}}
    nextround.Text = "Next Round Type - <font color=\"#F0C4FF\">Hyper</font>"
    table.insert(_G.cycler, lp.PlayerGui.ChildAdded:Connect(function(c)
        local info = gettype(c)
        if type(info) ~= 'table' then
            --[[if info == 'MultiDisasterGui' then
                local txt = rs.Info.Notice
                local t = tick()
                while tick() - t < 10 and not (txt ~= 'Next Disaster In' and txt ~= 'Stage Select' and txt ~= 'Warning!!!' and txt ~= 'Break Time') do task.wait() end
                if not (txt.Value ~= 'Next Disaster In' and txt.Value ~= 'Stage Select' and txt.Value ~= 'Warning!!!' and txt.Value ~= 'Break Time') then return end
                curdis.Text = txt.Value
            else]]if info == 'SurvivedGui' or info == 'WipeoutGui' then
                nextround.Text = "Next Round Type - <font color=\"#F0C4FF\">Hyper</font>"
            elseif info == 'WarningGui' then 
                nextround.Text = "Next Round Type - <font color=\"#CC5A1D\">Multi</font> / Mystery / <font color=\"#CC2B1D\">Imp</font>"
            elseif info == 'BossGui' then
                nextround.Text = ("Next Round Type - <font color=\"%s\">Boss (%s)</font>"):format(colors[bosstype(c.Frame.Frame.Disaster)], bosstype(c.Frame.Frame.Disaster))
            end
            return 
        end
        if info.Data.Mystery then
            local dis = workspace.Disaster:FindFirstChildOfClass"Model" or workspace.Disaster.ChildAdded:Wait()
            checkoff(pc1, dis.Name, unpassnorm, passnorm)
        elseif info.RoundType == 'Impossible' then
            checkoff(pc2, info.Data.Name, unpasshyp, passhyp)
        else
            checkoff(pc1, info.Data.Name, unpassnorm, passnorm)
        end
    end))
    cmdline.Focused:Connect(function()
        local txt = cmdline.Text:gsub('<font color="#%x*">', ''):gsub('</font>', '')
        cmdline.Text = txt
    end)
    cmdline.FocusLost:Connect(function()
        local txt = cmdline.Text:gsub("^%s*", ""):gsub("%s*$", "")
        local args = txt:split" "
        if args[1] == 'check' or args[1] == 'uncheck' or args[1] =='unknown' or args[1] == 'unk' or args[1] == 'reset' or args[1] == 'add' or args[1] == 'rem' then
            args[1] = '<font color="#468AB7">'..args[1]..'</font>'
        end
        if args[2] then
            if args[1] == '<font color="#468AB7">reset</font>' then
                if args[2] == 'h' or args[2] == 'n' then
                    args[2] = '<font color="#D84141">'..args[2]..'</font>'
                end
            else
                for i = 3, #args - 1 do
                    args[2] = args[2].." "..args[i]
                end
                args[3] = args[#args]
                if #args ~= 2 and (args[3] == 'h' or args[3] =='i') then
                    args[3] = '<font color="#D84141">'..args[3]..'</font>'
                    for i,v in pairs(pc2) do
                        if v.data.Name:lower():find(args[2]:lower()) == 1 then
                            args[2] = '<font color="#50D841">'..v.data.Name..'</font>'
                            break
                        end
                    end
                else
                    args[3] = nil
                    for i,v in pairs(pc1) do
                        if v.data.Name:lower():find(args[2]:lower()) == 1 then
                            args[2] = '<font color="#50D841">'..v.data.Name..'</font>'
                            break
                        end
                    end
                end
            end
        end
        local result = ''
        for i = 1, 3 do result = result..(args[i] or "").." " end
        cmdline.Text = result:gsub("%s*$", "")
    end)
    entercommand.MouseButton1Click:Connect(function()
        local txt = cmdline.Text:gsub('<font color="#%x*">', ''):gsub('</font>', '')
        local args = txt:split" "
        if args[2] then
            if args[1] == 'reset' then
                if args[2] == 'h' then
                    cyclereset(pc2, unpasshyp, passhyp)
                    cmdline.Text = ''
                elseif args[2] == 'n' then
                    cyclereset(pc1, unpassnorm, passnorm)
                    cmdline.Text = ''
                end
            else
                for i = 3, #args do
                    if i >= 4 then break end
                    args[2] = args[2].." "..args[i]
                end
                if args[3] == 'h' then args[2] = args[2]:sub(1,-3) end
                args[3] = args[#args]
                if args[3] == 'h' then
                    for i,v in pairs(pc2) do
                        if v.data.Name == args[2] then
                            if (args[1] == 'check' or args[1] == 'add') and v.checked ~= values.passed then
                                checkoff(pc2, v.data.Name, unpasshyp, passhyp)
                                cmdline.Text = ''
                            elseif (args[1] == 'uncheck' or args[1] == 'rem') and v.checked ~= values.unpassed then
                                uncheck(pc2, v.data.Name, unpasshyp, passhyp)
                                cmdline.Text = ''
                            elseif (args[1] == 'unknown' or args[1] == 'unk') and v.checked ~= values.unknown then
                                uncheck(pc1, v.data.Name, unpasshyp, passhyp, true)
                                cmdline.Text = ''
                            end
                            return
                        end
                    end
                else
                    for i,v in pairs(pc1) do
                        if v.data.Name == args[2] then
                            if (args[1] == 'check' or args[1] == 'add') and v.checked ~= values.passed then
                                checkoff(pc1, v.data.Name, unpassnorm, passnorm)
                                cmdline.Text = ''
                            elseif (args[1] == 'uncheck' or args[1] == 'rem') and v.checked ~= values.unpassed then
                                uncheck(pc1, v.data.Name, unpassnorm, passnorm)
                                cmdline.Text = ''
                            elseif (args[1] == 'unknown' or args[1] == 'unk') and v.checked ~= values.unknown then
                                uncheck(pc1, v.data.Name, unpassnorm, passnorm, true)
                                cmdline.Text = ''
                            end
                            return
                        end
                    end
                end
            end
        end
    end)
end
loadpage(1)
table.insert(_G.cycler, UIS.InputBegan:Connect(function(key, chat)
    if not chat and key.KeyCode == Enum.KeyCode.F4 then main.Enabled = not main.Enabled end
end))