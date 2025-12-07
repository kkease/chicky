local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

local aimLockEnabled = false
local teleportTool = nil
local espEnabled = false
local tracersEnabled = false
local nameTagsEnabled = false
local aimlockConnection
local aimLockUI = nil
local predictionEnabled = true  -- New: Enable prediction for better accuracy
local aimSmoothness = 0.2  -- Lerp factor for smoothness
local aimKey = Enum.UserInputType.MouseButton2  -- Right mouse button to activate aimlock

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success or not Rayfield then
    warn("Rayfield failed to load.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "Saif's Ultimate ChicoBlocko Toolkit",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "Powered by Rayfield - Enhanced Edition",
    ConfigurationSaving = {
        Enabled = true,
        FileName = "SaifUltimateChicoToolkitConfig"
    },
    Discord = { Enabled = false },
    KeySystem = true,
    KeySettings = {
        Title = "Access Required",
        Subtitle = "Enter the key to unlock",
        FileName = "SaifUltimateChicoKeyAccess",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = { "615879", "2124267" }
    }
})

local MainTab = Window:CreateTab("Main", 4483362458)
local ExtraTab = Window:CreateTab("Extras", 4483362458)

-- Function to create aimlock UI
local function createAimLockUI()
    if aimLockUI then return end
    aimLockUI = Instance.new("ScreenGui", game.CoreGui)
    aimLockUI.Name = "AimLockUI"

    local frame = Instance.new("Frame", aimLockUI)
    frame.Size = UDim2.new(0, 200, 0, 80)  -- Larger for more options
    frame.Position = UDim2.new(0.5, -100, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true

    local toggleButton = Instance.new("TextButton", frame)
    toggleButton.Size = UDim2.new(1, 0, 0.5, 0)
    toggleButton.Position = UDim2.new(0, 0, 0, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    toggleButton.Text = "Disable Aim Lock"
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.TextScaled = true

    toggleButton.MouseButton1Click:Connect(function()
        aimLockEnabled = not aimLockEnabled
        if aimLockEnabled then
            toggleButton.Text = "Disable Aim Lock"
            toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        else
            toggleButton.Text = "Enable Aim Lock"
            toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            if aimlockConnection then
                aimlockConnection:Disconnect()
                aimlockConnection = nil
            end
        end
    end)

    local predictionToggle = Instance.new("TextButton", frame)
    predictionToggle.Size = UDim2.new(1, 0, 0.5, 0)
    predictionToggle.Position = UDim2.new(0, 0, 0.5, 0)
    predictionToggle.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    predictionToggle.Text = "Prediction: ON"
    predictionToggle.TextColor3 = Color3.new(0, 0, 0)
    predictionToggle.TextScaled = true

    predictionToggle.MouseButton1Click:Connect(function()
        predictionEnabled = not predictionEnabled
        predictionToggle.Text = predictionEnabled and "Prediction: ON" or "Prediction: OFF"
        predictionToggle.BackgroundColor3 = predictionEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    end)
end

local function destroyAimLockUI()
    if aimLockUI then
        aimLockUI:Destroy()
        aimLockUI = nil
    end
end

-- Aimlock Toggle (improved accuracy)
MainTab:CreateToggle({
    Name = "Aimlock (Accurate with Prediction)",
    CurrentValue = false,
    Flag = "AimlockEnabled",
    Callback = function(v)
        aimLockEnabled = v
        if aimLockEnabled then
            createAimLockUI()
            local function getClosestToCursor()
                local closestPlayer = nil
                local shortestDistance = math.huge
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                        local pos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
                        if onScreen then
                            local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                            local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                            if dist < shortestDistance and dist < 300 then  -- FOV limit
                                shortestDistance = dist
                                closestPlayer = player
                            end
                        end
                    end
                end
                return closestPlayer
            end

            aimlockConnection = RunService.RenderStepped:Connect(function()
                if aimLockEnabled and UserInputService:IsMouseButtonPressed(aimKey) then
                    local target = getClosestToCursor()
                    if target and target.Character and target.Character:FindFirstChild("Head") then
                        local targetPart = target.Character.Head
                        local current = Camera.CFrame
                        local goalPos = targetPart.Position
                        if predictionEnabled and target.Character:FindFirstChild("HumanoidRootPart") then
                            local velocity = target.Character.HumanoidRootPart.Velocity
                            goalPos = goalPos + velocity * 0.1  -- Simple prediction
                        end
                        local goal = CFrame.new(current.Position, goalPos)
                        Camera.CFrame = current:Lerp(goal, aimSmoothness)
                    end
                end
            end)
        else
            destroyAimLockUI()
            if aimlockConnection then
                aimlockConnection:Disconnect()
                aimlockConnection = nil
            end
        end
    end,
})

-- Rest of the script remains the same, as it's not related to aimlock
-- (Teleport Tool, Speed, Jump, ESP, Tracers, etc.)

MainTab:CreateButton({
    Name = "Add Teleport Tool",
    Callback = function()
        if not LocalPlayer.Backpack:FindFirstChild("TeleportTool") then
            teleportTool = Instance.new("Tool")
            teleportTool.RequiresHandle = false
            teleportTool.Name = "TeleportTool"

            teleportTool.Activated:Connect(function()
                local targetPos = mouse.Hit.Position
                local currentPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
                if currentPos and (targetPos - currentPos).Magnitude <= 50 then
                    LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(targetPos + Vector3.new(0, 3, 0)))
                end
            end)

            teleportTool.Parent = LocalPlayer.Backpack
        end
    end
})

MainTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Flag = "SpeedSlider",
    Callback = function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end
})

MainTab:CreateToggle({
    Name = "Enable Jump",
    CurrentValue = false,
    Flag = "EnableJump",
    Callback = function(state)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.UseJumpPower = state
            LocalPlayer.Character.Humanoid.JumpPower = state and 50 or 0
        end
    end
})

MainTab:CreateSlider({
    Name = "Jump Power",
    Range = {0, 200},
    Increment = 1,
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = Value
        end
    end
})

MainTab:CreateButton({
    Name = "Allow Jump (Infinite)",
    Callback = function()
        UserInputService.JumpRequest:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end,
})

MainTab:CreateToggle({
    Name = "ESP (White Highlights & Name Tags)",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(state)
        espEnabled = state
        local function setupESP(character, player)
            if character:FindFirstChild("ESP_Highlight") then
                character.ESP_Highlight:Destroy()
            end
            if character:FindFirstChild("NameTag") then
                character.NameTag:Destroy()
            end
            if espEnabled then
                local highlight = Instance.new("Highlight")
                highlight.Name = "ESP_Highlight"
                highlight.Adornee = character
                highlight.FillColor = Color3.fromRGB(255, 255, 255)  -- Changed to white
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)  -- Changed to white
                highlight.Parent = character

                local billboard = Instance.new("BillboardGui")
                billboard.Name = "NameTag"
                billboard.Size = UDim2.new(0, 200, 0, 50)
                billboard.Adornee = character:WaitForChild("Head")
                billboard.AlwaysOnTop = true
                billboard.Parent = character

                local text = Instance.new("TextLabel")
                text.Size = UDim2.new(1, 0, 1, 0)
                text.BackgroundTransparency = 1
                text.TextColor3 = Color3.new(1, 1, 1)
                text.TextStrokeTransparency = 0
                text.Font = Enum.Font.SourceSansBold
                text.TextScaled = true
                text.Text = player.Name .. " [" .. math.floor((LocalPlayer.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude) .. "m]"
                text.Parent = billboard
            end
        end

        local function onCharacterAdded(character, player)
            if espEnabled then
                setupESP(character, player)
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            player.CharacterAdded:Connect(function(character)
                onCharacterAdded(character, player)
            end)
            if player.Character then
                onCharacterAdded(player.Character, player)
            end
        end

        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(character)
                onCharacterAdded(character, player)
            end)
        end)
    end
})

MainTab:CreateToggle({
    Name = "Tracers",
    CurrentValue = false,
    Flag = "TracersEnabled",
    Callback = function(state)
        tracersEnabled = state
        if not state then
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("TracerLine") then
                    player.Character.TracerLine:Destroy()
                end
            end
        end
    end
})

ExtraTab:CreateButton({
    Name = "Instant Proximity Prompts",
    Callback = function()
        local function makeInstant(prompt)
            if prompt:IsA("ProximityPrompt") then
                prompt.HoldDuration = 0
            end
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            makeInstant(obj)
        end
        workspace.DescendantAdded:Connect(makeInstant)
    end,
})

ExtraTab:CreateButton({
    Name = "Tp to Apt",
    Callback = function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        hrp.CFrame = CFrame.new(-122, 3, -663)
    end,
})

ExtraTab:CreateButton({
    Name = "Tp to Cookers",
    Callback = function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        hrp.CFrame = CFrame.new(-331, 3, -430)
    end,
})

ExtraTab:CreateButton({
    Name = "Tp to MM",
    Callback = function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        hrp.CFrame = CFrame.new(-443, 3, -772)
    end,
})

ExtraTab:CreateToggle({
    Name = "Fly Mode",
    CurrentValue = false,
    Flag = "FlyEnabled",
    Callback = function(state)
        if state then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
                bodyVelocity.Parent = char.HumanoidRootPart

                local flyConnection
                flyConnection = RunService.RenderStepped:Connect(function()
                    if not state then flyConnection:Disconnect() return end
                    local moveDirection = Vector3.new()
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
                    bodyVelocity.Velocity = moveDirection * 50
                end)
            end
        else
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local bv = LocalPlayer.Character.HumanoidRootPart:FindFirstChild("BodyVelocity")
                if bv then bv:Destroy() end
            end
        end
    end
})

RunService.RenderStepped:Connect(function()
    if tracersEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local tracer = player.Character:FindFirstChild("TracerLine")
                if not tracer then
                    local beam = Instance.new("Beam")
                    beam.Name = "TracerLine"
                    beam.FaceCamera = true
                    beam.Color = ColorSequence.new(Color3.new(0, 1, 0))
                    beam.Width0 = 0.1
                    beam.Width1 = 0.1

                    local att0 = Instance.new("Attachment", LocalPlayer.Character.HumanoidRootPart)
                    local att1 = Instance.new("Attachment", player.Character.HumanoidRootPart)

                    beam.Attachment0 = att0
                    beam.Attachment1 = att1
                    beam.Parent = player.Character
                end
            end
        end
    end

    if espEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character.Head:FindFirstChild("NameTag") then
                local text = player.Character.Head.NameTag.TextLabel
                text.Text = player.Name .. " [" .. math.floor((LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude) .. "m]"
            end
        end
    end
end)
```
