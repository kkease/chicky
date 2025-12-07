local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local aimLockEnabled = false
local teleportTool = nil
local espEnabled = false
local tracersEnabled = false
local nameTagsEnabled = false
local aimlockConnection

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success or not Rayfield then
    warn("Rayfield failed to load.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "Saif's ChicoBlocko Toolkit",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "Powered by Rayfield",
    ConfigurationSaving = {
        Enabled = true,
        FileName = "SaifChicoToolkitConfig"
    },
    Discord = { Enabled = false },
    KeySystem = true,
    KeySettings = {
        Title = "Access Required",
        Subtitle = "Enter the key to unlock",
        FileName = "SaifChicoKeyAccess",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = { "615879", "2124267" }  -- Combined keys from both scripts
    }
})

local MainTab = Window:CreateTab("Main", 4483362458)

-- Aimlock Toggle (from Script 2, improved)
MainTab:CreateToggle({
    Name = "Aimlock",
    CurrentValue = false,
    Flag = "AimlockEnabled",
    Callback = function(v)
        aimLockEnabled = v
        if aimLockEnabled then
            local function getClosestToCursor()
                local closestPlayer = nil
                local shortestDistance = math.huge
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local pos, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
                        if onScreen then
                            local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                            local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                            if dist < shortestDistance then
                                shortestDistance = dist
                                closestPlayer = player
                            end
                        end
                    end
                end
                return closestPlayer
            end

            aimlockConnection = RunService.RenderStepped:Connect(function()
                if aimLockEnabled then
                    local target = getClosestToCursor()
                    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.HumanoidRootPart.Position)
                    end
                end
            end)
        else
            if aimlockConnection then
                aimlockConnection:Disconnect()
                aimlockConnection = nil
            end
        end
    end,
})

-- Teleport Tool (from Script 1)
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

-- Speed Control (combined from both)
MainTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = 16,
    Flag = "SpeedSlider",
    Callback = function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end
})

-- Jump Enable (from Script 1)
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

-- Jump Power (from Script 2)
MainTab:CreateSlider({
    Name = "Jump Power",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 16,
    Flag = "JumpPowerSlider",
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = Value
        end
    end
})

-- Allow Jump Button (from Script 2)
MainTab:CreateButton({
    Name = "Allow Jump",
    Callback = function()
        local UserInputService = game:GetService("UserInputService")
        UserInputService.JumpRequest:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end,
})

-- ESP Toggle (combined from both)
MainTab:CreateToggle({
    Name = "ESP (Green Highlights & Name Tags)",
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
                highlight.FillColor = Color3.fromRGB(0, 255, 0)
                highlight.OutlineColor = Color3.fromRGB(0, 150, 0)
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
                text.Text = player.Name
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

-- Tracers Toggle (from Script 1)
MainTab:CreateToggle({
    Name = "Tracers",
    CurrentValue = false,
    Flag = "TracersEnabled",
    Callback = function(state)
        tracersEnabled = state
    end
})

-- Instant Proximity Prompts (from Script 2)
MainTab:CreateButton({
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

-- Teleport Buttons (from Script 2)
MainTab:CreateButton({
    Name = "Tp to Apt",
    Callback = function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        hrp.CFrame = CFrame.new(-122, 3, -663)
    end,
})

MainTab:CreateButton({
    Name = "Tp to Cookers",
    Callback = function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        hrp.CFrame = CFrame.new(-331, 3, -430)
    end,
})

MainTab:CreateButton({
    Name = "Tp to MM",
    Callback = function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        hrp.CFrame = CFrame.new(-443, 3, -772)
    end,
})

-- RenderStepped for Tracers (from Script 1)
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
end)
