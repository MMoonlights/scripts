local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

local Window = Kavo.CreateLib("LSRS Hub", "DarkTheme")

if not _G.Flags then
    _G.Flags = {
        Killaura = false,
        Distance = 50, -- Увеличил дефолтное расстояние
        AutoRebirth = false,
        AuraTarget = nil,
        AuraPrefix = nil,
        MinimumLevel = 1,
        TargetLevel = false,
        Teleport = false,
        AutoEquip = false,
        AutoUpgrade = {},
        Popups = false,
        AttackDelay = 0.1, -- Добавил задержку между атаками
        TargetAll = false -- Добавил опцию атаковать всех в радиусе
    }
end

local Flags = _G.Flags

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
local Mobs = Workspace:WaitForChild("Mobs", 3)
local PlayerGui = Player:WaitForChild("PlayerGui", 3)
local UI = PlayerGui and PlayerGui:WaitForChild("UI", 3)
local CS = UI and UI:WaitForChild("CS", 3)
local Leaderstats = Player:WaitForChild("leaderstats", 3)
local Lvl = Leaderstats and Leaderstats:WaitForChild("Lvl", 3)
local StatPoints = Player:WaitForChild("StatPoints", 3)

local ValidMobs = {"Any"}
local ValidPrefixes = {"Any"}

if Mobs then
    for _, v in next, Mobs:GetChildren() do
        if v:IsA("Model") then
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
end

local MainTab = Window:NewTab("Main")
local SettingsTab = Window:NewTab("Settings")

local KillauraSection = MainTab:NewSection("Killaura")
local TargetSection = MainTab:NewSection("Target")
local UpgradeSection = MainTab:NewSection("Auto Upgrade")
local RebirthSection = MainTab:NewSection("Auto Rebirth")
local FarmSection = MainTab:NewSection("Auto Farm")
local UISection = SettingsTab:NewSection("UI Settings")

KillauraSection:NewToggle("Enabled", "Toggle killaura", function(Value)
    Flags.Killaura = Value
end)

KillauraSection:NewSlider("Distance", "Attack distance", 100, 10, function(Value)
    Flags.Distance = Value
end)

KillauraSection:NewSlider("Attack Delay", "Delay between attacks", 100, 1, function(Value)
    Flags.AttackDelay = Value / 100 -- Конвертируем в секунды
end)

KillauraSection:NewToggle("Teleport", "Teleport to mobs", function(Value)
    Flags.Teleport = Value
end)

KillauraSection:NewToggle("Target All", "Attack all mobs in range", function(Value)
    Flags.TargetAll = Value
end)

TargetSection:NewDropdown("Mob To Target", "Select mob", ValidMobs, function(Value)
    if Value == "Any" then
        Flags.AuraTarget = nil
    else
        Flags.AuraTarget = Value
    end
end)

TargetSection:NewDropdown("Target Prefix", "Select prefix", ValidPrefixes, function(Value)
    if Value == "Any" then
        Flags.AuraPrefix = nil
    else
        Flags.AuraPrefix = Value
    end
end)

TargetSection:NewTextBox("Minimum Level", "Min level to attack", function(Value)
    local num = tonumber(Value)
    if num then
        Flags.MinimumLevel = num
    end
end)

TargetSection:NewToggle("Only Target Our Level", "Attack same level", function(Value)
    Flags.TargetLevel = Value
end)

if StatPoints then
    for _, v in next, Player:GetChildren() do
        if v.Name:find("UP") then
            Flags.AutoUpgrade[v.Name] = false
            UpgradeSection:NewToggle(v.Name, "Auto upgrade "..v.Name, function(Value)
                Flags.AutoUpgrade[v.Name] = Value
            end)
        end
    end
end

RebirthSection:NewToggle("Auto Rebirth", "Auto rebirth at 300", function(Value)
    Flags.AutoRebirth = Value
end)

FarmSection:NewToggle("Auto Equip Best Weapon", "Auto equip best weapon", function(Value)
    Flags.AutoEquip = Value
end)

UISection:NewKeybind("Toggle UI", "Toggle GUI visibility", Enum.KeyCode.Delete, function()
    Kavo:ToggleUI()
end)

UISection:NewToggle("Disable Damage Popups", "Hide damage popups", function(Value)
    Flags.Popups = Value
end)

local Platform = Instance.new("Part")
Platform.Name = HttpService:GenerateGUID(false)
Platform.Size = Vector3.new(5, 1, 5)
Platform.Anchored = true
Platform.Transparency = 0.5
Platform.CanCollide = false
Platform.Parent = Workspace
Platform.CFrame = CFrame.new(0, -1000, 0)

-- Основная функция Killaura
spawn(function()
    local lastAttack = tick()
    
    while task.wait(0.05) do -- Увеличил частоту проверки
        if Flags.Killaura then
            local Character = Player.Character
            if not Character then
                Character = Player.CharacterAdded:Wait()
            end
            
            local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 1)
            local Tool = Character:FindFirstChildOfClass("Tool")
            local Damage = Character:WaitForChild("SwordDamage", 1)
            
            if not (Tool and Damage and HumanoidRootPart) then
                continue
            end
            
            -- Управление платформой для телепорта
            if Flags.Teleport then
                local success, err = pcall(function()
                    Platform.CFrame = Character:GetPivot() * CFrame.new(0, -2.75, 0)
                    for _, v in next, Character:GetChildren() do
                        if v:IsA("BasePart") then
                            v.CanCollide = false
                        end
                    end
                end)
            else
                Platform.CFrame = CFrame.new(0, -1000, 0)
            end
            
            -- Поиск и атака мобов
            if Mobs then
                local attacked = false
                local mobsInRange = {}
                
                -- Сначала собираем всех подходящих мобов
                for _, v in next, Mobs:GetChildren() do
                    if v:IsA("Model") then
                        local Humanoid = v:FindFirstChildOfClass("Humanoid")
                        local Head = v:FindFirstChild("Head")
                        local Settings = v:FindFirstChild("Settings")
                        local Level = Settings and Settings:FindFirstChild("Lvl")
                        
                        if not (Humanoid and Head and Level) or Humanoid.Health <= 0 then
                            continue
                        end
                        
                        -- Проверка префикса
                        if Flags.AuraPrefix and Flags.AuraPrefix ~= "Any" then
                            if not v.Name:find(Flags.AuraPrefix, 1, true) then
                                continue
                            end
                        end
                        
                        -- Проверка имени моба
                        if Flags.AuraTarget and Flags.AuraTarget ~= "Any" then
                            if v.Name ~= Flags.AuraTarget then
                                continue
                            end
                        end
                        
                        -- Проверка уровня
                        if Level.Value < Flags.MinimumLevel then
                            continue
                        end
                        
                        if Flags.TargetLevel and Lvl and Level.Value > Lvl.Value then
                            continue
                        end
                        
                        local distance = (Head.Position - HumanoidRootPart.Position).Magnitude
                        if distance <= Flags.Distance then
                            table.insert(mobsInRange, {
                                Mob = v,
                                Humanoid = Humanoid,
                                Distance = distance,
                                Level = Level.Value
                            })
                        end
                    end
                end
                
                -- Сортируем по расстоянию
                table.sort(mobsInRange, function(a, b)
                    return a.Distance < b.Distance
                end)
                
                -- Атакуем мобов
                if #mobsInRange > 0 and (tick() - lastAttack) > Flags.AttackDelay then
                    if Flags.TargetAll then
                        -- Атакуем всех мобов в радиусе
                        for _, mobData in ipairs(mobsInRange) do
                            if Flags.Teleport then
                                pcall(function()
                                    Character:PivotTo(mobData.Mob:GetPivot() * CFrame.new(0, -5, 5))
                                end)
                            end
                            
                            -- Атака
                            local success, err = pcall(function()
                                Damage:FireServer(mobData.Humanoid, Tool, 1, 1)
                            end)
                            
                            if not success then
                                warn("Attack error:", err)
                            end
                            
                            attacked = true
                            task.wait(0.05) -- Маленькая задержка между атаками разных мобов
                        end
                    else
                        -- Атакуем только ближайшего моба
                        local closestMob = mobsInRange[1]
                        if closestMob then
                            if Flags.Teleport then
                                pcall(function()
                                    Character:PivotTo(closestMob.Mob:GetPivot() * CFrame.new(0, -5, 5))
                                end)
                            end
                            
                            -- Атака
                            local success, err = pcall(function()
                                Damage:FireServer(closestMob.Humanoid, Tool, 1, 1)
                            end)
                            
                            if not success then
                                warn("Attack error:", err)
                            end
                            
                            attacked = true
                        end
                    end
                    
                    if attacked then
                        lastAttack = tick()
                    end
                end
            end
        end
    end
end)

-- Авто ребирт
spawn(function()
    if Lvl and CS then
        while task.wait(1) do
            if Flags.AutoRebirth and Lvl.Value >= 300 then
                local success, err = pcall(function()
                    CS:FireServer("reb", Lvl)
                end)
                if success then
                    print("Auto Rebirth executed")
                else
                    warn("Rebirth error:", err)
                end
            end
        end
    end
end)

-- Авто апгрейд
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
                                pcall(function()
                                    CS:FireServer("add", Stat, false)
                                end)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- Авто экипировка
spawn(function()
    while task.wait(2) do -- Увеличил интервал
        if Flags.AutoEquip then
            local Character = Player.Character
            if not Character then
                Character = Player.CharacterAdded:Wait()
            end
            
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
                    pcall(function()
                        Humanoid:UnequipTools()
                    end)
                end
            end
            
            if BestTool and BestTool.Parent == Backpack then
                pcall(function()
                    Humanoid:EquipTool(BestTool)
                end)
            end
        end
    end
end)

-- Удаление попапов урона
spawn(function()
    if PlayerGui then
        PlayerGui.ChildAdded:Connect(function(Child)
            if Child.Name == "dmg" and Flags.Popups then
                task.wait()
                pcall(function()
                    Child:Destroy()
                end)
            end
        end)
    end
end)

-- Обновление списка мобов при их появлении
if Mobs then
    Mobs.ChildAdded:Connect(function(v)
        task.wait(1)
        if v:IsA("Model") then
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
    end)
end

print("LSRS Hub loaded successfully!")