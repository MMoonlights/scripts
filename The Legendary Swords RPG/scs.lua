local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local Window = OrionLib:MakeWindow({
    Name = "LSRS Hub", 
    HidePremium = false, 
    SaveConfig = true,
    ConfigFolder = "LSRSConfig"
})

if not _G.Flags then
    _G.Flags = {
        Killaura = false,
        Distance = 10,
        AutoRebirth = false,
        AuraTarget = nil,
        AuraPrefix = nil,
        MinimumLevel = 1,
        TargetLevel = false,
        Teleport = false,
        AutoEquip = false,
        AutoUpgrade = {},
        Popups = false
    }
end

local Flags = _G.Flags

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
local Mobs = Workspace:WaitForChild("Mobs", 3)
local PlayerGui = Player:WaitForChild("PlayerGui", 3)
local UI = PlayerGui:WaitForChild("UI", 3)
local CS = UI and UI:WaitForChild("CS", 3)
local Leaderstats = Player:WaitForChild("leaderstats", 3)
local Lvl = Leaderstats and Leaderstats:WaitForChild("Lvl", 3)
local StatPoints = Player:WaitForChild("StatPoints", 3)

local ValidMobs = {"Any"}
local ValidPrefixes = {"Any"}

if Mobs then
    for _, v in next, Mobs:GetChildren() do
        local Name = v.Name
        local Prefix = nil
        if Name:find("%[") then
            Prefix = "[" .. Name:split("%[")[2]
        end
        if not table.find(ValidMobs, Name) then
            table.insert(ValidMobs, Name)
        end
        if Prefix and not table.find(ValidPrefixes, Prefix) then
            table.insert(ValidPrefixes, Prefix)
        end
    end
end

local Tab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false
})

Tab:AddSection({
    Name = "Killaura"
})

Tab:AddToggle({
    Name = "Enabled",
    Default = false,
    Callback = function(Value)
        Flags.Killaura = Value
    end    
})

Tab:AddSlider({
    Name = "Distance",
    Min = 0,
    Max = 50,
    Default = 10,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "studs",
    Callback = function(Value)
        Flags.Distance = Value
    end    
})

Tab:AddToggle({
    Name = "Teleport",
    Default = false,
    Callback = function(Value)
        Flags.Teleport = Value
    end    
})

Tab:AddSection({
    Name = "Target"
})

Tab:AddDropdown({
    Name = "Mob To Target",
    Default = "Any",
    Options = ValidMobs,
    Callback = function(Value)
        if Value == "Any" then
            Flags.AuraTarget = nil
        else
            Flags.AuraTarget = Value
        end
    end    
})

Tab:AddDropdown({
    Name = "Target Prefix",
    Default = "Any",
    Options = ValidPrefixes,
    Callback = function(Value)
        if Value == "Any" then
            Flags.AuraPrefix = nil
        else
            Flags.AuraPrefix = Value
        end
    end    
})

Tab:AddTextbox({
    Name = "Minimum Level",
    Default = "1",
    TextDisappear = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            Flags.MinimumLevel = num
        end
    end    
})

Tab:AddToggle({
    Name = "Only Target Our Level",
    Default = false,
    Callback = function(Value)
        Flags.TargetLevel = Value
    end    
})

Tab:AddSection({
    Name = "Auto Upgrade"
})

if StatPoints then
    for _, v in next, Player:GetChildren() do
        if v.Name:find("UP") then
            Flags.AutoUpgrade[v.Name] = false
            Tab:AddToggle({
                Name = v.Name,
                Default = false,
                Callback = function(Value)
                    Flags.AutoUpgrade[v.Name] = Value
                end    
            })
        end
    end
end

Tab:AddSection({
    Name = "Auto Rebirth"
})

Tab:AddToggle({
    Name = "Auto Rebirth",
    Default = false,
    Callback = function(Value)
        Flags.AutoRebirth = Value
    end    
})

Tab:AddSection({
    Name = "Auto Farm"
})

Tab:AddToggle({
    Name = "Auto Equip Best Weapon",
    Default = false,
    Callback = function(Value)
        Flags.AutoEquip = Value
    end    
})

local SettingsTab = Window:MakeTab({
    Name = "Settings",
    Icon = "rbxassetid://9753762469",
    PremiumOnly = false
})

SettingsTab:AddBind({
    Name = "Toggle UI",
    Default = Enum.KeyCode.Delete,
    Hold = false,
    Callback = function()
        OrionLib:Destroy()
    end    
})

SettingsTab:AddToggle({
    Name = "Disable Damage Popups",
    Default = false,
    Callback = function(Value)
        Flags.Popups = Value
    end    
})

local Platform = Instance.new("Part")
Platform.Name = HttpService:GenerateGUID(false)
Platform.Size = Vector3.new(5, 1, 5)
Platform.Anchored = true
Platform.Transparency = 0.5
Platform.CanCollide = false
Platform.Parent = Workspace
Platform.CFrame = CFrame.new(0, -1000, 0)

spawn(function()
    while task.wait() do
        if Flags.Killaura then
            local Character = Player.Character or Player.CharacterAdded:Wait()
            local Tool = Character:FindFirstChildOfClass("Tool")
            local Damage = Character:WaitForChild("SwordDamage", 3)
            
            if not (Tool and Damage) then
                continue
            end
            
            if Flags.Teleport then
                Platform.CFrame = Character:GetPivot() * CFrame.new(0, -2.75, 0)
                for _, v in next, Character:GetChildren() do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            else
                Platform.CFrame = CFrame.new(0, -1000, 0)
            end
            
            if Mobs then
                for _, v in next, Mobs:GetChildren() do
                    if v:IsA("Model") then
                        local Humanoid = v:FindFirstChildOfClass("Humanoid")
                        local Pivot = v:GetPivot()
                        local Settings = v:FindFirstChild("Settings")
                        local Level = Settings and Settings:FindFirstChild("Lvl")
                        
                        if not Level or not Humanoid or Humanoid.Health <= 0 then
                            continue
                        end
                        
                        if Flags.AuraPrefix and not v.Name:find(Flags.AuraPrefix) then
                            continue
                        end
                        
                        if Flags.AuraTarget and v.Name ~= Flags.AuraTarget then
                            continue
                        end
                        
                        if Level.Value < Flags.MinimumLevel then
                            continue
                        end
                        
                        if Flags.TargetLevel and Lvl and Level.Value > Lvl.Value then
                            continue
                        end
                        
                        local distance = (Pivot.Position - Character:GetPivot().Position).Magnitude
                        if distance > Flags.Distance then
                            continue
                        end
                        
                        if Flags.Teleport then
                            Character:PivotTo(Pivot * CFrame.new(0, -5, 5))
                        end
                        
                        Damage:FireServer(Humanoid, Tool, 1, 1)
                        break
                    end
                end
            end
        else
            task.wait(0.1)
        end
    end
end)

spawn(function()
    if Lvl and CS then
        while task.wait(1) do
            if Flags.AutoRebirth and Lvl.Value >= 300 then
                CS:FireServer("reb", Lvl)
            end
        end
    end
end)

spawn(function()
    if StatPoints and CS then
        StatPoints:GetPropertyChangedSignal("Value"):Connect(function()
            local Val = StatPoints.Value
            if Val > 0 then
                for statName, shouldUpgrade in pairs(Flags.AutoUpgrade) do
                    if shouldUpgrade then
                        local Stat = Player:FindFirstChild(statName)
                        if Stat then
                            for i = 1, Val do
                                CS:FireServer("add", Stat, false)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

spawn(function()
    while task.wait(1) do
        if Flags.AutoEquip then
            local Character = Player.Character or Player.CharacterAdded:Wait()
            local Humanoid = Character:WaitForChild("Humanoid", 3)
            local Backpack = Player:WaitForChild("Backpack", 3)
            
            if not (Humanoid and Backpack) then
                continue
            end
            
            local BestTool = nil
            local BestDamage = 0
            
            for _, v in next, Backpack:GetChildren() do
                if v:IsA("Tool") then
                    local Conf = v:FindFirstChild("Conf")
                    local MaxDmg = Conf and Conf:FindFirstChild("MaxDmg")
                    if MaxDmg and MaxDmg.Value > BestDamage then
                        BestTool = v
                        BestDamage = MaxDmg.Value
                    end
                end
            end
            
            local EquippedTool = Character:FindFirstChildOfClass("Tool")
            if EquippedTool then
                local Conf = EquippedTool:FindFirstChild("Conf")
                local MaxDmg = Conf and Conf:FindFirstChild("MaxDmg")
                if MaxDmg and MaxDmg.Value >= BestDamage then
                    BestTool = EquippedTool
                else
                    Humanoid:UnequipTools()
                end
            end
            
            if BestTool and BestTool.Parent == Backpack then
                Humanoid:EquipTool(BestTool)
            end
        end
    end
end)

spawn(function()
    if PlayerGui then
        PlayerGui.ChildAdded:Connect(function(Child)
            if Child.Name == "dmg" and Flags.Popups then
                task.wait()
                Child:Destroy()
            end
        end)
    end
end)

if Mobs then
    Mobs.ChildAdded:Connect(function(v)
        task.wait()
        local Name = v.Name
        local Prefix = nil
        if Name:find("%[") then
            Prefix = "[" .. Name:split("%[")[2]
        end
        
        if not table.find(ValidMobs, Name) then
            table.insert(ValidMobs, Name)
        end
        
        if Prefix and not table.find(ValidPrefixes, Prefix) then
            table.insert(ValidPrefixes, Prefix)
        end
    end)
end

OrionLib:Init()