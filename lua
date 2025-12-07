local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

local aimLockEnabled = false
local teleportTool = nil
local espEnabled = false
local tracersEnabled = false
local nameTagsEnabled = false
local aimlockConnection
local aimLockUI = nil  -- For the on-screen aimlock toggle

-- ESP Data and Settings (based on the provided ESP code)
local espData = {} --> player -> { highlight, nameGui, healthGui, attachments = {att0, att1, beam}, connections = {characterAdded, humanoidChanged, cleanup...}}
local ENABLE_HIGHLIGHT = true
local ENABLE_NAMETAG = true
local ENABLE_HEALTHBAR = true
local ENABLE_DISTANCE = true
local ENABLE_TRACERS = true
local NAME_TAG_SIZE = UDim2.new(0, 180, 0, 36)
local HEALTHBAR_SIZE = UDim2.new(0, 100, 0, 12)
local HEALTHBAR_OFFSET = Vector3.new(0, 2.6, 0)
local NAMETAG_OFFSET = Vector3.new(0, 2.9, 0)
local TRACER_WIDTH0 = 0.06
local TRACER_WIDTH1 = 0.06
local TRACER_COLOR = Color3.fromRGB(0, 255, 0)
local HIGHLIGHT_FILL = Color3.fromRGB(0, 255, 0)
local HIGHLIGHT_OUTLINE = Color3.fromRGB(0, 150, 0)

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
        Key = { "615879", "2124267" }  -- Combined keys
    }
})

local MainTab = Window:CreateTab("Main", 4483362458)
local ExtraTab = Window:CreateTab("Extras", 4483362458)  -- New tab for additional features

-- ESP Helper Functions (adapted from the provided code)
local function createHighlightForCharacter(character)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = character
    highlight.FillColor = HIGHLIGHT_FILL
    highlight.OutlineColor = HIGHLIGHT_OUTLINE
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = character
    return highlight
end

local function createNameTag(player, character)
    local head = character:FindFirstChild("Head")
    if not head then return nil end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_NameTag"
    billboard.Adornee = head
    billboard.Size = NAME_TAG_SIZE
    billboard.StudsOffset = NAMETAG_OFFSET
    billboard.AlwaysOnTop = true
    billboard.ResetOnSpawn = false
    billboard.Parent = player:WaitForChild("PlayerGui")

    local text = Instance.new("TextLabel")
    text.Name = "ESP_NameLabel"
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextStrokeTransparency = 0
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.Text = player.Name
    text.Parent = billboard

    return billboard, text
end

local function createHealthBar(player, character)
    local head = character:FindFirstChild("Head")
    if not head then return nil end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_HealthBar"
    billboard.Adornee = head
    billboard.Size = HEALTHBAR_SIZE
    billboard.StudsOffset = HEALTHBAR_OFFSET
    billboard.AlwaysOnTop = true
    billboard.ResetOnSpawn = false
    billboard.Parent = player:WaitForChild("PlayerGui")

    local outer = Instance.new("Frame")
    outer.Name = "Outer"
    outer.Size = UDim2.new(1, 0, 1, 0)
    outer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    outer.BorderSizePixel = 0
    outer.Parent = billboard

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    fill.BorderSizePixel = 0
    fill.Parent = outer

    return billboard, fill
end

local function createTracer(localRoot, targetRoot)
    if not (localRoot and targetRoot) then return nil end

    local att0 = Instance.new("Attachment")
    att0.Name = "ESP_Att0"
    att0.Position = Vector3.new(0, 0.75, 0)
    att0.Parent = localRoot

    local att1 = Instance.new("Attachment")
    att1.Name = "ESP_Att1"
    att1.Position = Vector3.new(0, 0.75, 0)
    att1.Parent = targetRoot

    local beam = Instance.new("Beam")
    beam.Name = "ESP_Beam"
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.FaceCamera = true
    beam.Width0 = TRACER_WIDTH0
    beam.Width1 = TRACER_WIDTH1
    beam.Color = ColorSequence.new(TRACER_COLOR)
    beam.LightEmission = 0.5
    beam.Parent = localRoot
    return {att0 = att0, att1 = att1, beam = beam}
end

local function cleanupESPForPlayer(player)
    local data = espData[player]
    if not data then return end

    if data.connections then
        for _, conn in pairs(data.connections) do
            if conn and conn.Disconnect then
                conn:Disconnect()
            elseif conn and conn.disconnect then
                conn:disconnect()
            end
        end
    end

    if data.highlight and data.highlight.Parent then
        data.highlight:Destroy()
    end

    if player:FindFirstChild("PlayerGui") then
        local pg = player.PlayerGui
        for _, name in ipairs({"ESP_NameTag", "ESP_HealthBar"}) do
            local obj = pg:FindFirstChild(name)
            if obj then obj:Destroy() end
        end
    end

    if data.attachments then
        if data.attachments.att0 and data.attachments.att0.Parent then data.attachments.att0:Destroy() end
        if data.attachments.att1 and data.attachments.att1.Parent then data.attachments.att1:Destroy() end
        if data.attachments.beam and data.attachments.beam.Parent then data.attachments.beam:Destroy() end
    end

    espData[player] = nil
end

local function setupESPForPlayer(player)
    if player == LocalPlayer then return end
    if espData[player] then return end

    local data = { connections = {} }
    espData[player] = data

    local function onCharacter(character)
        if data.highlight and data.highlight.Parent then
            data.highlight:Destroy()
            data.highlight = nil
        end
        if player:FindFirstChild("PlayerGui") then
            for _, name in ipairs({"ESP_NameTag", "ESP_HealthBar"}) do
                local existing = player.PlayerGui:FindFirstChild(name)
                if existing then existing:Destroy() end
            end
        end
        if data.attachments then
            if data.attachments.att0 and data.attachments.att0.Parent then data.attachments.att0:Destroy() end
            if data.attachments.att1 and data.attachments.att1.Parent then data.attachments.att1:Destroy() end
            if data.attachments.beam and data.attachments.beam.Parent then data.attachments.beam:Destroy() end
            data.attachments = nil
        end

        if not character then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not (hrp and head and humanoid) then return end

        if ENABLE_HIGHLIGHT then
            data.highlight = createHighlightForCharacter(character)
        end

        if ENABLE_NAMETAG then
            local billboard, textLabel = createNameTag(player, character)
            data.nameGui = billboard
            data.nameText = textLabel
        end

        if ENABLE_HEALTHBAR then
            local healthGui, healthFill = createHealthBar(player, character)
            data.healthGui = healthGui
            data.healthFill = healthFill
        end

        if ENABLE_TRACERS then
            local localRoot = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) or nil
            if localRoot then
                data.attachments = createTracer(localRoot, hrp)
            end
        end

        local conn = RunService.RenderStepped:Connect(function()
            if not player or not player.Parent or not player.Character or not player.Character.PrimaryPart then
                return
            end

            if data.nameText and data.nameText.Parent and ENABLE_DISTANCE then
                local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if localHRP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (localHRP.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    local display = player.Name .. " [" .. tostring(math.floor(dist)) .. "m]"
                    data.nameText.Text = display
                end
            end

            if data.healthFill and player.Character and player.Character:FindFirstChildOfClass("Humanoid") and ENABLE_HEALTHBAR then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                local maxHealth = math.max(hum.MaxHealth, 1)
                local frac = math.clamp(hum.Health / maxHealth, 0, 1)
                data.healthFill.Size = UDim2.new(frac, 0, 1, 0)
                if frac > 0.6 then
                    data.healthFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
                elseif frac > 0.3 then
                    data.healthFill.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
                else
                    data.healthFill.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                end
            end
        end)

        table.insert(data.connections, conn)
    end

    local charConn = player.CharacterAdded:Connect(onCharacter)
    table.insert(data.connections, charConn)

    if player.Character then
        onCharacter(player.Character)
    end
end

local function cleanupAllESP()
    for player, _ in pairs(espData) do
        cleanupESPForPlayer(player)
    end
end

-- Function to create aimlock UI
local function createAimLockUI()
    if aimLockUI then return end
    aimLockUI = Instance.new("ScreenGui", game.CoreGui)
    aimLockUI.Name = "AimLockUI"

    local frame = Instance.new("Frame", aimLockUI)
    frame.Size = UDim2.new(0, 150, 0, 60)
    frame.Position = UDim2.new(0.5, -75, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true

    local toggleButton = Instance.new("TextButton", frame)
    toggleButton.Size = UDim2.new(1, 0, 1, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    toggleButton.Text = "Disable Aim Lock"
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.TextScaled = true

    toggleButton.MouseButton1Click:Connect(function()
        aimLockEnabled = not aimLockEnabled
        if aimLockEnabled then
            toggleButton.Text = "Disable Aim Lock"
            toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            -- Restart connection if it was disconnected
            if not aimlockConnection then
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
            end
        else
            toggleButton.Text = "Enable Aim Lock"
            toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            if aimlockConnection then
                aimlockConnection:Disconnect()
                aimlockConnection = nil
            end
        end
    end)
end

local function destroyAimLockUI()
    if aimLockUI then
        aimLockUI:Destroy()
        aimLockUI = nil
    end
end

-- Aimlock Toggle (improved)
MainTab:CreateToggle({
    Name = "Aimlock (with On-Screen Toggle)",
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
            destroyAimLockUI()
            if aimlockConnection then
                aimlockConnection:Disconnect()
                aimlockConnection = nil
            end
        end
    end,
})

-- Teleport Tool (mobile-adapted: uses raycast from camera center)
MainTab:CreateButton({
    Name = "Add Teleport Tool",
    Callback = function()
        if not LocalPlayer.Backpack:FindFirstChild("TeleportTool") then
            teleportTool = Instance.new("Tool")
            teleportTool.RequiresHandle = false
            teleportTool.Name = "TeleportTool"

            teleportTool.Activated:Connect(function()
                local ray = Camera:ViewportPointToRay(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
                if raycastResult then
                    local targetPos = raycastResult.Position
                    local currentPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
                    if currentPos and (targetPos - currentPos).Magnitude <= 50 then
                        LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(targetPos + Vector3.new(0, 3, 0)))
                    end
                end
            end)

            teleportTool.Parent = LocalPlayer.Backpack
        end
    end
})

-- Speed Control
MainTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},  -- Increased range
    Increment = 1,
    CurrentValue = 16,
    Flag = "SpeedSlider",
    Callback = function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end
})

-- Jump Enable
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

--
