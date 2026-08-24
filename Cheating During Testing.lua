-- ============================================================================
-- XORQEN HUB — DIRECT LUA BUILDER (ANDROID / MOBILE COMPACT EDITION)
-- Target Game: Cheating During Testing [BETA] (Roblox)
-- UI Design: Clean Compact Single Card Panel
-- ============================================================================

local Core = {
    Config = {
        Version = "1.3.0-Mobile",
        Theme = {
            Background = Color3.fromRGB(13, 17, 23),
            Card = Color3.fromRGB(22, 27, 34),
            Accent = Color3.fromRGB(0, 240, 255),
            Text = Color3.fromRGB(230, 245, 255),
            Muted = Color3.fromRGB(120, 140, 160),
            ToggleOff = Color3.fromRGB(50, 60, 75),
            ToggleOn = Color3.fromRGB(0, 240, 255)
        }
    },
    State = {
        SpeedEnabled = true,
        Speed = 16,
        JumpPowerEnabled = true,
        JumpPower = 50,
        InfiniteJump = false,
        Fly = true,
        FlyMode = "Normal",
        NoClip = false,
        Sprint = false,
        GravityEnabled = false,
        Gravity = 196.2,

        -- Stealth & Tracking
        TeacherPatrols = true,
        TeacherPositionTracking = true,
        SuspicionGauge = true,
        DeskSnapping = true,
        DeskNPCOutline = true
    },
    Services = {
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        UserInputService = game:GetService("UserInputService"),
        Workspace = game:GetService("Workspace"),
        CoreGui = game:GetService("CoreGui"),
        TweenService = game:GetService("TweenService")
    },
    Connections = {}
}

Core.LocalPlayer = Core.Services.Players.LocalPlayer

-- ============================================================================
-- GAME ADAPTER
-- ============================================================================
local GameAdapter = {}

function GameAdapter.GetCharacter()
    return Core.LocalPlayer.Character
end

function GameAdapter.GetRootPart()
    local char = GameAdapter.GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

function GameAdapter.GetHumanoid()
    local char = GameAdapter.GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function GameAdapter.FindTeacher()
    for _, obj in ipairs(Core.Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:find("Teacher") or obj.Name:find("Examiner") or obj.Name:find("Proctor")) then
            if obj:FindFirstChild("HumanoidRootPart") then
                return obj
            end
        end
    end
    return nil
end

function GameAdapter.FindAssignedSeat()
    local hum = GameAdapter.GetHumanoid()
    if hum and hum.SeatPart then
        return hum.SeatPart
    end
    for _, part in ipairs(Core.Services.Workspace:GetDescendants()) do
        if part:IsA("Seat") or part:IsA("VehicleSeat") then
            if part:FindFirstChild("AssignedPlayer") and part.AssignedPlayer.Value == Core.LocalPlayer then
                return part
            elseif part.Name:find("DeskSeat") or part.Name:find("Chair") then
                return part
            end
        end
    end
    return nil
end

-- ============================================================================
-- FEATURE LOGIC
-- ============================================================================
local Features = {}

function Features.InitMovement()
    Core.Connections.MovementLoop = Core.Services.RunService.Heartbeat:Connect(function()
        local hum = GameAdapter.GetHumanoid()
        if hum then
            if Core.State.SpeedEnabled then hum.WalkSpeed = Core.State.Speed end
            if Core.State.JumpPowerEnabled then hum.JumpPower = Core.State.JumpPower end
        end
        if Core.State.GravityEnabled then
            Core.Services.Workspace.Gravity = Core.State.Gravity
        end
    end)

    Core.Connections.InfJump = Core.Services.UserInputService.JumpRequest:Connect(function()
        if Core.State.InfiniteJump then
            local hum = GameAdapter.GetHumanoid()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)

    Core.Connections.NoClip = Core.Services.RunService.Stepped:Connect(function()
        if Core.State.NoClip then
            local char = GameAdapter.GetCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
    end)
end

-- ============================================================================
-- MOBILE COMPACT UI ENGINE
-- ============================================================================
local UI = {}

function UI.CreateToggleRow(parent, labelText, stateKey, hasSlider, minVal, maxVal, defaultVal, sliderCallback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundTransparency = 1
    row.Parent = parent

    -- Checkbox / Label
    local checkBtn = Instance.new("TextButton")
    checkBtn.Size = UDim2.new(0, 20, 0, 20)
    checkBtn.Position = UDim2.new(0, 0, 0.5, -10)
    checkBtn.BackgroundColor3 = Core.State[stateKey] and Core.Config.Theme.Accent or Color3.fromRGB(25, 32, 42)
    checkBtn.BorderColor3 = Core.Config.Theme.Accent
    checkBtn.Text = Core.State[stateKey] and "✓" or ""
    checkBtn.TextColor3 = Color3.fromRGB(13, 17, 23)
    checkBtn.Font = Enum.Font.GothamBold
    checkBtn.TextSize = 14
    checkBtn.Parent = row

    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(0, 4)
    checkCorner.Parent = checkBtn

    local label = Instance.new("TextLabel")
    label.Text = labelText
    label.Font = Enum.Font.Gotham
    label.TextSize = 15
    label.TextColor3 = Core.Config.Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 28, 0, 0)
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Parent = row

    checkBtn.MouseButton1Click:Connect(function()
        Core.State[stateKey] = not Core.State[stateKey]
        checkBtn.BackgroundColor3 = Core.State[stateKey] and Core.Config.Theme.Accent or Color3.fromRGB(25, 32, 42)
        checkBtn.Text = Core.State[stateKey] and "✓" or ""
    end)

    -- Optional Slider
    if hasSlider then
        local sliderBg = Instance.new("Frame")
        sliderBg.Size = UDim2.new(0, 110, 0, 6)
        sliderBg.Position = UDim2.new(1, -150, 0.5, -3)
        sliderBg.BackgroundColor3 = Color3.fromRGB(35, 45, 58)
        sliderBg.BorderSizePixel = 0
        sliderBg.Parent = row

        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(0, 3)
        sliderCorner.Parent = sliderBg

        local valPct = (defaultVal - minVal) / (maxVal - minVal)

        local sliderFill = Instance.new("Frame")
        sliderFill.Size = UDim2.new(valPct, 0, 1, 0)
        sliderFill.BackgroundColor3 = Core.Config.Theme.Accent
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderBg

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 3)
        fillCorner.Parent = sliderFill

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new(1, -8, 0.5, -8)
        knob.BackgroundColor3 = Color3.fromRGB(200, 215, 225)
        knob.BorderSizePixel = 0
        knob.Parent = sliderFill

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local valLabel = Instance.new("TextLabel")
        valLabel.Text = tostring(defaultVal)
        valLabel.Font = Enum.Font.Gotham
        valLabel.TextSize = 15
        valLabel.TextColor3 = Core.Config.Theme.Text
        valLabel.Position = UDim2.new(1, -30, 0, 0)
        valLabel.Size = UDim2.new(0, 30, 1, 0)
        valLabel.BackgroundTransparency = 1
        valLabel.Parent = row

        -- Touch Drag logic
        local dragging = false
        sliderBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        Core.Services.UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        Core.Services.UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local posX = math.clamp(input.Position.X - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
                local pct = posX / sliderBg.AbsoluteSize.X
                local val = math.floor(minVal + (pct * (maxVal - minVal)))
                sliderFill.Size = UDim2.new(pct, 0, 1, 0)
                valLabel.Text = tostring(val)
                sliderCallback(val)
            end
        end)
    end

    return row
end

function UI.CreateToggleSwitchRow(parent, labelText, stateKey)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundTransparency = 1
    row.Parent = parent

    -- Checkbox
    local checkBtn = Instance.new("TextButton")
    checkBtn.Size = UDim2.new(0, 20, 0, 20)
    checkBtn.Position = UDim2.new(0, 0, 0.5, -10)
    checkBtn.BackgroundColor3 = Core.State[stateKey] and Core.Config.Theme.Accent or Color3.fromRGB(25, 32, 42)
    checkBtn.BorderColor3 = Core.Config.Theme.Accent
    checkBtn.Text = Core.State[stateKey] and "✓" or ""
    checkBtn.TextColor3 = Color3.fromRGB(13, 17, 23)
    checkBtn.Font = Enum.Font.GothamBold
    checkBtn.TextSize = 14
    checkBtn.Parent = row

    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(0, 4)
    checkCorner.Parent = checkBtn

    local label = Instance.new("TextLabel")
    label.Text = labelText
    label.Font = Enum.Font.Gotham
    label.TextSize = 15
    label.TextColor3 = Core.Config.Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 28, 0, 0)
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Parent = row

    -- Switch
    local switchBg = Instance.new("TextButton")
    switchBg.Text = ""
    switchBg.Size = UDim2.new(0, 44, 0, 22)
    switchBg.Position = UDim2.new(1, -44, 0.5, -11)
    switchBg.BackgroundColor3 = Core.State[stateKey] and Core.Config.Theme.ToggleOn or Core.Config.Theme.ToggleOff
    switchBg.BorderSizePixel = 0
    switchBg.Parent = row

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchBg

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = Core.State[stateKey] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    knob.BorderSizePixel = 0
    knob.Parent = switchBg

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local function toggle()
        Core.State[stateKey] = not Core.State[stateKey]
        checkBtn.BackgroundColor3 = Core.State[stateKey] and Core.Config.Theme.Accent or Color3.fromRGB(25, 32, 42)
        checkBtn.Text = Core.State[stateKey] and "✓" or ""
        switchBg.BackgroundColor3 = Core.State[stateKey] and Core.Config.Theme.ToggleOn or Core.Config.Theme.ToggleOff
        knob.Position = Core.State[stateKey] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    end

    checkBtn.MouseButton1Click:Connect(toggle)
    switchBg.MouseButton1Click:Connect(toggle)

    return row
end

function UI.BuildMobileUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "XorqenHubMobileUI"
    ScreenGui.ResetOnSpawn = false

    pcall(function() ScreenGui.Parent = Core.Services.CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = Core.LocalPlayer:WaitForChild("PlayerGui") end

    local Main = Instance.new("Frame")
    Main.Name = "MainWindow"
    Main.Size = UDim2.new(0, 320, 0, 330)
    Main.Position = UDim2.new(0.5, -160, 0.5, -165)
    Main.BackgroundColor3 = Core.Config.Theme.Background
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true -- Full mobile touch-drag support
    Main.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Main

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(35, 45, 55)
    Stroke.Thickness = 1
    Stroke.Parent = Main

    -- Header
    local Header = Instance.new("TextLabel")
    Header.Text = "XORQEN HUB"
    Header.Font = Enum.Font.GothamBold
    Header.TextSize = 18
    Header.TextColor3 = Core.Config.Theme.Text
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.Position = UDim2.new(0, 14, 0, 12)
    Header.Size = UDim2.new(1, -28, 0, 24)
    Header.BackgroundTransparency = 1
    Header.Parent = Main

    -- Container List
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -28, 1, -48)
    Container.Position = UDim2.new(0, 14, 0, 42)
    Container.BackgroundTransparency = 1
    Container.Parent = Main

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = Container

    -- Controls from Screenshot
    UI.CreateToggleRow(Container, "Speed", "SpeedEnabled", true, 16, 100, 16, function(v) Core.State.Speed = v end)
    UI.CreateToggleRow(Container, "Jump Power", "JumpPowerEnabled", true, 50, 200, 50, function(v) Core.State.JumpPower = v end)
    UI.CreateToggleSwitchRow(Container, "Infinite Jump", "InfiniteJump")
    
    -- Fly Row with Dropdown
    local flyRow = Instance.new("Frame")
    flyRow.Size = UDim2.new(1, 0, 0, 36)
    flyRow.BackgroundTransparency = 1
    flyRow.Parent = Container

    local checkBtn = Instance.new("TextButton")
    checkBtn.Size = UDim2.new(0, 20, 0, 20)
    checkBtn.Position = UDim2.new(0, 0, 0.5, -10)
    checkBtn.BackgroundColor3 = Core.Config.Theme.Accent
    checkBtn.Text = "✓"
    checkBtn.TextColor3 = Color3.fromRGB(13, 17, 23)
    checkBtn.Font = Enum.Font.GothamBold
    checkBtn.TextSize = 14
    checkBtn.Parent = flyRow

    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(0, 4)
    checkCorner.Parent = checkBtn

    local label = Instance.new("TextLabel")
    label.Text = "Fly"
    label.Font = Enum.Font.Gotham
    label.TextSize = 15
    label.TextColor3 = Core.Config.Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 28, 0, 0)
    label.Size = UDim2.new(0.3, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Parent = flyRow

    local modeLabel = Instance.new("TextLabel")
    modeLabel.Text = "Mode"
    modeLabel.Font = Enum.Font.Gotham
    modeLabel.TextSize = 15
    modeLabel.TextColor3 = Core.Config.Theme.Muted
    modeLabel.Position = UDim2.new(0.5, -15, 0, 0)
    modeLabel.Size = UDim2.new(0, 45, 1, 0)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Parent = flyRow

    local dropdown = Instance.new("TextButton")
    dropdown.Text = "Normal ▼"
    dropdown.Font = Enum.Font.Gotham
    dropdown.TextSize = 13
    dropdown.TextColor3 = Core.Config.Theme.Text
    dropdown.Size = UDim2.new(0, 95, 0, 26)
    dropdown.Position = UDim2.new(1, -95, 0.5, -13)
    dropdown.BackgroundColor3 = Color3.fromRGB(22, 28, 36)
    dropdown.BorderColor3 = Color3.fromRGB(45, 55, 70)
    dropdown.Parent = flyRow

    local dropCorner = Instance.new("UICorner")
    dropCorner.CornerRadius = UDim.new(0, 5)
    dropCorner.Parent = dropdown

    UI.CreateToggleSwitchRow(Container, "No Clip", "NoClip")
    UI.CreateToggleSwitchRow(Container, "Sprint", "Sprint")
    UI.CreateToggleRow(Container, "Gravity", "GravityEnabled", true, 0, 196, 196, function(v) Core.State.Gravity = v end)

    return ScreenGui
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
function Core.Init()
    UI.BuildMobileUI()
    Features.InitMovement()
    print("[XORQEN HUB Mobile v1.3.0] Single card interface loaded.")
end

Core.Init()
