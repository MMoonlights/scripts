-- AnimDetectGUI Script
-- Detects specific animations and performs actions

local SoundIds = {
    "rbxassetid://10503381238",
    "rbxassetid://13379003796"
}

local DetectionDelay = 0.32
local AnimationCooldown = 0.25
local TargetDuration = 0.35

-- Get CoreGui
local CoreGui = game:GetService("CoreGui")

-- Remove existing GUI if it exists
local existingGUI = CoreGui:FindFirstChild("AnimDetectGUI")
if existingGUI then
    existingGUI:Destroy()
end

-- Create main ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AnimDetectGUI"
ScreenGui.Parent = CoreGui

-- Create main frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 160, 0, 60)
MainFrame.Position = UDim2.new(0.5, -80, 0.85, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.BackgroundTransparency = 0.1
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Add rounded corners
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = MainFrame

-- Create toggle button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(1, -20, 1, -20)
ToggleButton.Position = UDim2.new(0, 10, 0, 10)
ToggleButton.Text = "Hexed"
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 20
ToggleButton.BackgroundColor3 = Color3.fromRGB(70, 0, 0)
ToggleButton.Parent = MainFrame

-- Add rounded corners to button
local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 10)
ButtonCorner.Parent = ToggleButton

-- State variables
local isEnabled = false
local animationConnection = nil

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Function to find the nearest enemy
local function findNearestEnemy()
    local character = LocalPlayer.Character
    if not character then
        return nil
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return nil
    end
    
    local playerPosition = humanoidRootPart.Position
    local nearestEnemy = nil
    local nearestDistance = nil
    
    -- Check workspace for enemies
    local liveFolder = workspace:FindFirstChild("Live")
    if liveFolder then
        for _, model in ipairs(liveFolder:GetChildren()) do
            if model:IsA("Model") then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                if hrp then
                    -- Skip if it's a dummy
                    if model.Name ~= "Weakest Dummy" then
                        -- Check if it's a player character
                        local player = Players:GetPlayerFromCharacter(model)
                        if player then
                            -- Skip our own character
                            if model ~= LocalPlayer.Character then
                                local distance = (hrp.Position - playerPosition).Magnitude
                                
                                if not nearestDistance or distance < nearestDistance then
                                    nearestDistance = distance
                                    nearestEnemy = model
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return nearestEnemy
end

-- Function to disable collisions temporarily
local function disableCollisions(character)
    if not character then return end
    
    local descendants = character:GetDescendants()
    for _, descendant in ipairs(descendants) do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
        end
    end
    
    -- Re-enable collisions after delay
    task.delay(1.2, function()
        for _, descendant in ipairs(descendants) do
            if descendant:IsA("BasePart") then
                descendant.CanCollide = true
            end
        end
    end)
end

-- Function to handle animation detection
local function setupAnimationDetection()
    -- Disconnect existing connection if any
    if animationConnection then
        animationConnection:Disconnect()
        animationConnection = nil
    end
    
    -- Wait for character if needed
    local character = LocalPlayer.Character
    if not character then
        character = LocalPlayer.CharacterAdded:Wait()
    end
    
    -- Get humanoid
    local humanoid = character:WaitForChild("Humanoid")
    
    -- Connect to animation played event
    animationConnection = humanoid.AnimationPlayed:Connect(function(animTrack)
        local animation = animTrack.Animation
        if not animation then return end
        
        local animationId = animation.AnimationId
        
        -- Check if animation is in our detection list
        local foundAnimation = table.find(SoundIds, animationId)
        if foundAnimation then
            print("       Phát hiện animation:", animationId)
            
            -- Disable collisions temporarily
            disableCollisions(LocalPlayer.Character)
            
            -- Wait before sending remote
            task.wait(DetectionDelay)
            
            -- Prepare remote data
            local remoteData = {{
                Dash = Enum.KeyCode.W,
                Key = Enum.KeyCode.Q,
                Goal = "KeyPress"
            }}
            
            -- Send remote if it exists
            local communicateRemote = LocalPlayer.Character:FindFirstChild("Communicate")
            if communicateRemote then
                communicateRemote:FireServer(unpack(remoteData))
                print("✅ Đã gửi Remote sau 0.32s")
            else
                warn("⚠️ Không tìm thấy Remote 'Communicate'")
            end
            
            -- Wait before targeting
            task.wait(AnimationCooldown)
            
            -- Find humanoid root part
            local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                -- Create attachment for alignment
                local attachment = Instance.new("Attachment")
                attachment.Name = "Lix_Att"
                attachment.Parent = humanoidRootPart
                
                -- Create alignment object
                local alignOrientation = Instance.new("AlignOrientation")
                alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
                alignOrientation.Attachment0 = attachment
                alignOrientation.MaxTorque = math.huge
                alignOrientation.Responsiveness = 1000
                alignOrientation.RigidityEnabled = false
                alignOrientation.Parent = humanoidRootPart
                
                local startTime = tick()
                local heartbeatConnection = nil
                
                -- Heartbeat function for continuous targeting
                heartbeatConnection = RunService.Heartbeat:Connect(function()
                    local currentTime = tick()
                    local elapsedTime = currentTime - startTime
                    
                    -- Stop after duration
                    if elapsedTime >= TargetDuration then
                        heartbeatConnection:Disconnect()
                        
                        if alignOrientation then
                            alignOrientation:Destroy()
                        end
                        
                        if attachment then
                            attachment:Destroy()
                        end
                        
                        return
                    end
                    
                    -- Find nearest enemy
                    local nearestEnemy = findNearestEnemy()
                    if nearestEnemy and nearestEnemy:FindFirstChild("HumanoidRootPart") then
                        local enemyHrp = nearestEnemy.HumanoidRootPart
                        local enemyPosition = enemyHrp.Position
                        
                        -- Calculate look direction
                        local humanoidPosition = humanoidRootPart.Position
                        local lookCFrame = CFrame.lookAt(
                            humanoidPosition,
                            Vector3.new(enemyPosition.X, humanoidPosition.Y, enemyPosition.Z)
                        )
                        
                        -- Add rotation offset
                        local rotationOffset = CFrame.Angles(
                            math.rad(30),
                            100,
                            -100
                        )
                        
                        local finalCFrame = lookCFrame * rotationOffset
                        
                        -- Apply to humanoid root part
                        humanoidRootPart.CFrame = finalCFrame
                        
                        -- Apply to attachment if it still exists
                        if attachment then
                            attachment.CFrame = finalCFrame
                        end
                    end
                end)
            end
        end
    end)
end

-- Toggle button click handler
ToggleButton.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    
    if isEnabled then
        ToggleButton.Text = "Hexed: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        
        -- Start animation detection
        setupAnimationDetection()
    else
        ToggleButton.Text = "Hexed: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(70, 0, 0)
        
        -- Stop animation detection
        if animationConnection then
            animationConnection:Disconnect()
            animationConnection = nil
        end
    end
end)

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function()
    if isEnabled then
        task.wait(1)  -- Wait for character to fully load
        setupAnimationDetection()
    end
end)

return ScreenGui
