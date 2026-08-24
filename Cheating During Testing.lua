-- ============================================================================
-- XORQEN HUB — DIRECT LUA BUILDER (ANDROID MOBILE SPECIFIC BINDINGS)
-- Target Game: Cheating During Testing [BETA] (Roblox)
-- Architecture: Mobile Compact Reference UI with Custom Stealth Bindings
-- ============================================================================

local Core = {
    Config = {
        Version = "1.4.0-Mobile",
        Theme = {
            Background = Color3.fromRGB(13, 17, 23),
            Card = Color3.fromRGB(22, 27, 34),
            Accent = Color3.fromRGB(0, 240, 255),
            Text = Color3.fromRGB(230, 245, 255),
            Muted = Color3.fromRGB(120, 140, 160),
            ToggleOff = Color3.fromRGB(50, 60, 75),
            ToggleOn = Color3.fromRGB(0, 240, 255),
            Warning = Color3.fromRGB(255, 170, 0),
            Danger = Color3.fromRGB(255, 50, 50)
        }
    },
    State = {
        -- Selected Key Features
        TeacherPatrols = true,
        DeskSnapping = true,
        TeacherPositionTracking = true,
        SuspicionGauge = true,
        DeskNPCOutline = false,
        
        -- Adjustable Tuning Values
        WalkSpeedVal = 16,
        DetectionSensitivity = 50
    },
    Services = {
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        UserInputService = game:GetService("UserInputService"),
        Workspace = game:GetService("Workspace"),
        CoreGui = game:GetService("CoreGui")
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
-- FEATURE MODULES IMPLEMENTATION
-- ============================================================================
local Features = {}

-- 1. Teacher Patrols & Position Tracker
local TeacherTracer = Drawing.new("Line")
TeacherTracer.Thickness = 2
TeacherTracer.Color = Core.Config.Theme.Danger

local TeacherMarker = Drawing.new("Text")
TeacherMarker.Size = 16
TeacherMarker.Center = true
TeacherMarker.Outline = true
TeacherMarker.Color = Core.Config.Theme.Warning

function Features.InitTeacherTracking()
    Core.Connections.Tracking = Core.Services.RunService.RenderStepped:Connect(function()
        local teacher = GameAdapter.FindTeacher()
        local myRoot = GameAdapter.GetRootPart()
        local camera = Core.Services.Workspace.CurrentCamera

        if teacher and myRoot and camera then
            local tRoot = teacher.HumanoidRootPart
            local pos, visible = camera:WorldToViewportPoint(tRoot.Position)
            local dist = math.floor((myRoot.Position - tRoot.Position).Magnitude)

            if visible then
                -- Teacher Position Tracking
                if Core.State.TeacherPositionTracking then
                    TeacherMarker.Visible = true
                    TeacherMarker.Position = Vector2.new(pos.X, pos.Y - 25)
                    TeacherMarker.Text = string.format("🚨 TEACHER [%dm]", dist)
                else
                    TeacherMarker.Visible = false
                end

                -- Teacher Patrols Tracer Line
                if Core.State.TeacherPatrols then
                    TeacherTracer.Visible = true
                    TeacherTracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                    TeacherTracer.To = Vector2.new(pos.X, pos.Y)
                else
                    TeacherTracer.Visible = false
                end
            else
                TeacherTracer.Visible = false
                TeacherMarker.Visible = false
            end
        else
            TeacherTracer.Visible = false
            TeacherMarker.Visible = false
        end
    end)
end

-- 2. Suspicion / Detection Gauge
function Features.InitSuspicionGauge()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SuspicionHUD"
    pcall(function() gui.Parent = Core.Services.CoreGui end)
    if not gui.Parent then gui.Parent = Core.LocalPlayer:WaitForChild("PlayerGui") end

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 180, 0, 14)
    bar.Position = UDim2.new(0.5, -90, 0.08, 0)
    bar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    bar.BorderSizePixel = 0
    bar.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0.1, 0, 1, 0)
    fill.BackgroundColor3 = Core.Config.Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local label = Instance.new("TextLabel")
    label.Text = "SUSPICION GAUGE"
    label.Font = Enum.Font.GothamBold
    label.TextSize = 9
    label.TextColor3 = Core.Config.Theme.Text
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Parent = bar

    Core.Connections.Gauge = Core.Services.RunService.Heartbeat:Connect(function()
        bar.Visible = Core.State.SuspicionGauge
        if not Core.State.SuspicionGauge then return end

        local teacher = GameAdapter.FindTeacher()
        local myRoot = GameAdapter.GetRootPart()

        if teacher and myRoot then
            local dist = (myRoot.Position - teacher.HumanoidRootPart.Position).Magnitude
            local threat = math.clamp(1 - (dist / Core.State.DetectionSensitivity), 0.05, 1)
            fill.Size = UDim2.new(threat, 0, 1, 0)
            
            if threat > 0.7 then
                fill.BackgroundColor3 = Core.Config.Theme.Danger
            elseif threat > 0.4 then
                fill.BackgroundColor3 = Core.Config.Theme.Warning
            else
                fill.BackgroundColor3 = Core.Config.Theme.Accent
            end
        end
    end)
end

-- 3. Desk Snapping / Sitting Engine
function Features.SnapToDesk()
    if not Core.State.DeskSnapping then return end
    local seat = GameAdapter.FindAssignedSeat()
    local root = GameAdapter.GetRootPart()
    local hum = GameAdapter.GetHumanoid()

    if seat and root and hum then
        root.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
        task.wait(0.05)
        seat:Sit(hum)
    end
end

-- 4. Desk & NPC Outline Engine
local HighlightStorage = {}
function Features.InitOutlines()
    Core.Connections.Outlines = Core.Services.RunService.Heartbeat:Connect(function()
        if not Core.State.DeskNPCOutline then
            for _, hl in pairs(HighlightStorage) do hl:Destroy() end
            table.clear(HighlightStorage)
            return
        end

        local teacher = GameAdapter.FindTeacher()
        if teacher and not HighlightStorage["Teacher"] then
            local hl = Instance.new("Highlight")
            hl.FillColor = Core.Config.Theme.Danger
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.Parent = teacher
            HighlightStorage["Teacher"] = hl
        end
    end)
end

-- ============================================================================
-- MOBILE UI ENGINE (EXACT REFERENCE DESIGN)
-- ============================================================================
local UI = {}

function UI.CreateToggleRow(parent, labelText, stateKey, hasSlider, minVal, maxVal, defaultVal, sliderCb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundTransparency = 1
    row.Parent = parent

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

    if hasSlider then
        local sliderBg = Instance.new("Frame")
        sliderBg.Size = UDim2.new(0, 110, 0, 6)
        sliderBg.Position = UDim2.new(1, -150, 0.5, -3)
        sliderBg.BackgroundColor3 = Color3.fromRGB(35, 45, 58)
        sliderBg.BorderSizePixel = 0
        sliderBg.Parent = row

        local sliderFill = Instance.new("Frame")
        sliderFill.Size = UDim2.new((defaultVal - minVal)/(maxVal - minVal), 0, 1, 0)
        sliderFill.BackgroundColor3 = Core.Config.Theme.Accent
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderBg

        local valLabel = Instance.new("TextLabel")
        valLabel.Text = tostring(defaultVal)
        valLabel.Font = Enum.Font.Gotham
        valLabel.TextSize = 15
        valLabel.TextColor3 = Core.Config.Theme.Text
        valLabel.Position = UDim2.new(1, -30, 0, 0)
        valLabel.Size = UDim2.new(0, 30, 1, 0)
        valLabel.BackgroundTransparency = 1
        valLabel.Parent = row
    end

    return row
end

function UI.CreateToggleSwitchRow(parent, labelText, stateKey)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundTransparency = 1
    row.Parent = parent

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
    Main.Size = UDim2.new(0, 320, 0, 310)
    Main.Position = UDim2.new(0.5, -160, 0.5, -155)
    Main.BackgroundColor3 = Core.Config.Theme.Background
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Main

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

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -28, 1, -48)
    Container.Position = UDim2.new(0, 14, 0, 42)
    Container.BackgroundTransparency = 1
    Container.Parent = Main

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = Container

    -- Direct Binds to Key Features
    UI.CreateToggleRow(Container, "Teacher Patrols", "TeacherPatrols", true, 10, 100, 16)
    UI.CreateToggleRow(Container, "Desk Snapping", "DeskSnapping", true, 10, 100, 50)
    UI.CreateToggleSwitchRow(Container, "Teacher Position", "TeacherPositionTracking")
    UI.CreateToggleSwitchRow(Container, "Detection Gauge", "SuspicionGauge")
    UI.CreateToggleSwitchRow(Container, "Desk/NPC Outline", "DeskNPCOutline")

    return ScreenGui
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
function Core.Init()
    UI.BuildMobileUI()
    Features.InitTeacherTracking()
    Features.InitSuspicionGauge()
    Features.InitOutlines()
    print("[XORQEN HUB v1.4.0] Custom Features loaded into Mobile UI.")
end

Core.Init()
