-- ============================================================================
-- XORQEN HUB CONFIGURATION & SOURCE CODE
-- Theme: Dark Slate Gray & Turquoise Glow
-- Layout: Text-Only Header & Bubble Widget Alignment
-- ============================================================================

local Core = {
    Config = {
        Version = "3.0.0-CleanNoImages",
        HubName = "XORQEN HUB",
        Theme = {
            Turquoise = Color3.fromRGB(64, 224, 208),      -- Active Accent Color
            TurquoiseGlow = Color3.fromRGB(0, 245, 212),     -- Glow Pulse Color
            DarkSlateBg = Color3.fromRGB(30, 34, 32),       -- Bubble & UI Dark Gray
            TextWhite = Color3.fromRGB(255, 255, 255),       -- White Text
            ToggleOff = Color3.fromRGB(20, 35, 40),
            CloseRed = Color3.fromRGB(255, 60, 80),
            Warning = Color3.fromRGB(255, 170, 0),
            Danger = Color3.fromRGB(255, 50, 50)
        }
    },
    State = {
        DeskSnapping = false,
        TeacherPositionTracking = false,
        AntiDetect = true,
        TeacherPatrols = false
    },
    Services = {
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
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
        if obj:IsA("Model") and (obj.Name:find("Teacher") or obj.Name:find("Examiner") or obj.Name:find("Proctor") or obj.Name:find("NPC")) then
            if obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") then
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
            elseif part.Name:lower():find("desk") or part.Name:lower():find("chair") or part.Name:lower():find("seat") then
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

-- 1. Teacher Position Tracking (ESP UI Marker)
local TeacherBill = nil

function Features.InitTeacherTracking()
    Core.Connections.Tracking = Core.Services.RunService.RenderStepped:Connect(function()
        if not Core.State.TeacherPositionTracking then
            if TeacherBill then TeacherBill.Enabled = false end
            return
        end

        local teacher = GameAdapter.FindTeacher()
        local myRoot = GameAdapter.GetRootPart()

        if teacher and myRoot then
            local targetPart = teacher:FindFirstChild("Head") or teacher:FindFirstChild("HumanoidRootPart")
            if targetPart then
                if not TeacherBill or not TeacherBill.Parent then
                    TeacherBill = Instance.new("BillboardGui")
                    TeacherBill.Name = "TeacherTrackerESP"
                    TeacherBill.AlwaysOnTop = true
                    TeacherBill.Size = UDim2.new(0, 160, 0, 30)
                    TeacherBill.StudsOffset = Vector3.new(0, 3, 0)

                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "DistLabel"
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 14
                    lbl.TextColor3 = Core.Config.Theme.Warning
                    lbl.TextStrokeTransparency = 0
                    lbl.Parent = TeacherBill
                end

                TeacherBill.Parent = targetPart
                TeacherBill.Enabled = true

                local dist = math.floor((myRoot.Position - targetPart.Position).Magnitude)
                local lbl = TeacherBill:FindFirstChild("DistLabel")
                if lbl then
                    lbl.Text = string.format("🚨 TEACHER [%dm]", dist)
                end
            end
        else
            if TeacherBill then TeacherBill.Enabled = false end
        end
    end)
end

-- 2. Desk Snapping / Sitting Engine
function Features.InitDeskSnapping()
    Core.Connections.DeskSnap = Core.Services.RunService.Heartbeat:Connect(function()
        if not Core.State.DeskSnapping then return end

        local seat = GameAdapter.FindAssignedSeat()
        local root = GameAdapter.GetRootPart()
        local hum = GameAdapter.GetHumanoid()

        if seat and root and hum and not hum.SeatPart then
            root.CFrame = seat.CFrame * CFrame.new(0, 1.8, 0)
            task.wait(0.05)
            seat:Sit(hum)
        end
    end)
end

-- 3. Anti Detect Engine
function Features.InitAntiDetect()
    Core.Connections.AntiDetectLoop = Core.Services.RunService.Heartbeat:Connect(function()
        if not Core.State.AntiDetect then return end

        local char = GameAdapter.GetCharacter()
        if char then
            for _, child in ipairs(char:GetChildren()) do
                if child.Name:lower():find("suspicion") or child.Name:lower():find("detected") or child.Name:lower():find("alert") then
                    child:Destroy()
                end
            end
        end
    end)

    task.spawn(function()
        local rawMeta = getrawmetatable or debug.getmetatable
        if rawMeta and setreadonly then
            local gmt = rawMeta(game)
            local oldIndex = gmt.__index
            setreadonly(gmt, false)

            gmt.__index = newcclosure(function(self, key)
                if Core.State.AntiDetect and type(key) == "string" then
                    if key:lower():find("suspicion") or key:lower():find("caught") then
                        return 0
                    end
                end
                return oldIndex(self, key)
            end)
            setreadonly(gmt, true)
        end
    end)
end

-- 4. Teacher Patrols Tracer Line
local PatrolTracer = Drawing and Drawing.new and Drawing.new("Line") or nil
if PatrolTracer then
    PatrolTracer.Thickness = 2
    PatrolTracer.Color = Core.Config.Theme.Danger
end

function Features.InitTeacherPatrols()
    Core.Connections.Patrols = Core.Services.RunService.RenderStepped:Connect(function()
        if not PatrolTracer then return end
        if not Core.State.TeacherPatrols then
            PatrolTracer.Visible = false
            return
        end

        local teacher = GameAdapter.FindTeacher()
        local camera = Core.Services.Workspace.CurrentCamera

        if teacher and camera then
            local targetPart = teacher:FindFirstChild("HumanoidRootPart") or teacher:FindFirstChild("Head")
            if targetPart then
                local pos, visible = camera:WorldToViewportPoint(targetPart.Position)
                if visible then
                    PatrolTracer.Visible = true
                    PatrolTracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                    PatrolTracer.To = Vector2.new(pos.X, pos.Y)
                else
                    PatrolTracer.Visible = false
                end
            else
                PatrolTracer.Visible = false
            end
        else
            PatrolTracer.Visible = false
        end
    end)
end

-- ============================================================================
-- UI BUILDER
-- ============================================================================
local UI = {}

function UI.CreateToggleSwitchRow(parent, labelText, stateKey)
    local widgetCard = Instance.new("Frame")
    widgetCard.Size = UDim2.new(1, 0, 0, 42)
    widgetCard.BackgroundTransparency = 1
    widgetCard.Parent = parent

    local glassBg = Instance.new("Frame")
    glassBg.Size = UDim2.new(1, 0, 1, 0)
    glassBg.BackgroundColor3 = Color3.fromRGB(15, 20, 20)
    glassBg.BackgroundTransparency = 0.35
    glassBg.Parent = widgetCard

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = glassBg

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Core.State[stateKey] and Core.Config.Theme.Turquoise or Color3.fromRGB(45, 55, 55)
    cardStroke.Thickness = 1.25
    cardStroke.Transparency = 0.1
    cardStroke.Parent = glassBg

    local label = Instance.new("TextLabel")
    label.Text = labelText
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = Core.Config.Theme.TextWhite
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Parent = widgetCard

    local switchBg = Instance.new("TextButton")
    switchBg.Text = ""
    switchBg.Size = UDim2.new(0, 46, 0, 22)
    switchBg.Position = UDim2.new(1, -56, 0.5, -11)
    switchBg.BackgroundColor3 = Core.State[stateKey] and Core.Config.Theme.Turquoise or Core.Config.Theme.ToggleOff
    switchBg.BackgroundTransparency = 0.15
    switchBg.BorderSizePixel = 0
    switchBg.Parent = widgetCard

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchBg

    local switchStroke = Instance.new("UIStroke")
    switchStroke.Color = Core.State[stateKey] and Core.Config.Theme.TurquoiseGlow or Color3.fromRGB(45, 85, 90)
    switchStroke.Thickness = 1.25
    switchStroke.Parent = switchBg

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = Core.State[stateKey] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = switchBg

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    switchBg.MouseButton1Click:Connect(function()
        Core.State[stateKey] = not Core.State[stateKey]
        local active = Core.State[stateKey]
        switchBg.BackgroundColor3 = active and Core.Config.Theme.Turquoise or Core.Config.Theme.ToggleOff
        cardStroke.Color = active and Core.Config.Theme.Turquoise or Color3.fromRGB(45, 55, 55)
        switchStroke.Color = active and Core.Config.Theme.TurquoiseGlow or Color3.fromRGB(45, 85, 90)
        knob.Position = active and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    end)

    return widgetCard
end

function UI.BuildMobileUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "XorqenHubGui"
    ScreenGui.ResetOnSpawn = false

    pcall(function() ScreenGui.Parent = Core.Services.CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = Core.LocalPlayer:WaitForChild("PlayerGui") end

    -- Main UI Container
    local Main = Instance.new("Frame")
    Main.Name = "MainWindow"
    Main.Size = UDim2.new(0, 310, 0, 260)
    Main.Position = UDim2.new(0.5, -155, 0.5, -130)
    Main.BackgroundTransparency = 1
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local MainBgPanel = Instance.new("Frame")
    MainBgPanel.Size = UDim2.new(1, 0, 1, 0)
    MainBgPanel.BackgroundColor3 = Core.Config.Theme.DarkSlateBg
    MainBgPanel.BackgroundTransparency = 0.1
    MainBgPanel.Parent = Main

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 16)
    MainCorner.Parent = MainBgPanel

    local MainNeonStroke = Instance.new("UIStroke")
    MainNeonStroke.Color = Core.Config.Theme.Turquoise
    MainNeonStroke.Thickness = 2
    MainNeonStroke.Parent = MainBgPanel

    -- Header Panel
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, -20, 0, 32)
    Header.Position = UDim2.new(0, 10, 0, 10)
    Header.BackgroundTransparency = 1
    Header.Parent = Main

    -- Text-Only Hub Title (Properly Centered / Aligned)
    local HeaderTitle = Instance.new("TextLabel")
    HeaderTitle.Text = Core.Config.HubName
    HeaderTitle.Font = Enum.Font.GothamBold
    HeaderTitle.TextSize = 14
    HeaderTitle.TextColor3 = Core.Config.Theme.Turquoise
    HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    HeaderTitle.Position = UDim2.new(0, 10, 0, 0)
    HeaderTitle.Size = UDim2.new(0.7, 0, 1, 0)
    HeaderTitle.BackgroundTransparency = 1
    HeaderTitle.ZIndex = 5
    HeaderTitle.Parent = Header

    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseButton"
    CloseBtn.Text = "×"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 18
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.BackgroundColor3 = Core.Config.Theme.CloseRed
    CloseBtn.BackgroundTransparency = 0.1
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseBtn.Position = UDim2.new(1, -24, 0, 4)
    CloseBtn.ZIndex = 5
    CloseBtn.Parent = Header

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(1, 0)
    CloseCorner.Parent = CloseBtn

    -- Draggable Floating Widget Bubble (Matches Screenshot Slate Gray & White Text)
    local OpenBtn = Instance.new("TextButton")
    OpenBtn.Name = "OpenButton"
    OpenBtn.Text = ""
    OpenBtn.Size = UDim2.new(0, 160, 0, 42)
    OpenBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
    OpenBtn.Visible = false
    OpenBtn.Active = true
    OpenBtn.Draggable = true
    OpenBtn.BackgroundColor3 = Core.Config.Theme.DarkSlateBg
    OpenBtn.BackgroundTransparency = 0.05
    OpenBtn.BorderSizePixel = 0
    OpenBtn.Parent = ScreenGui

    local OpenCorner = Instance.new("UICorner")
    OpenCorner.CornerRadius = UDim.new(1, 0) -- Full rounded pill shape
    OpenCorner.Parent = OpenBtn

    local OpenStroke = Instance.new("UIStroke")
    OpenStroke.Color = Color3.fromRGB(60, 65, 62)
    OpenStroke.Thickness = 1.2
    OpenStroke.Parent = OpenBtn

    -- Widget Bubble Title Text
    local OpenText = Instance.new("TextLabel")
    OpenText.Text = Core.Config.HubName
    OpenText.Font = Enum.Font.GothamBold
    OpenText.TextSize = 13
    OpenText.TextColor3 = Core.Config.Theme.TextWhite
    OpenText.TextXAlignment = Enum.TextXAlignment.Center
    OpenText.Position = UDim2.new(0, 0, 0, 0)
    OpenText.Size = UDim2.new(1, 0, 1, 0)
    OpenText.BackgroundTransparency = 1
    OpenText.ZIndex = 5
    OpenText.Parent = OpenBtn

    -- Toggle Window Display
    CloseBtn.MouseButton1Click:Connect(function()
        Main.Visible = false
        OpenBtn.Visible = true
    end)

    OpenBtn.MouseButton1Click:Connect(function()
        Main.Visible = true
        OpenBtn.Visible = false
    end)

    -- Pulsing Neon Accent Effect
    task.spawn(function()
        local t = 0
        while task.wait(0.03) do
            t = t + 0.05
            local pulse = (math.sin(t) + 1) / 2
            local currentTurquoise = Core.Config.Theme.Turquoise:Lerp(Core.Config.Theme.TurquoiseGlow, pulse)
            
            MainNeonStroke.Color = currentTurquoise
            HeaderTitle.TextColor3 = currentTurquoise
        end
    end)

    -- Container for Toggles
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -20, 1, -54)
    Container.Position = UDim2.new(0, 10, 0, 48)
    Container.BackgroundTransparency = 1
    Container.Parent = Main

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = Container

    UI.CreateToggleSwitchRow(Container, "Desk Snapping / Sitting", "DeskSnapping")
    UI.CreateToggleSwitchRow(Container, "Teacher Position Tracking", "TeacherPositionTracking")
    UI.CreateToggleSwitchRow(Container, "Anti Detect Engine", "AntiDetect")
    UI.CreateToggleSwitchRow(Container, "Teacher Patrols Tracker", "TeacherPatrols")

    return ScreenGui
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
function Core.Init()
    UI.BuildMobileUI()
    Features.InitTeacherTracking()
    Features.InitDeskSnapping()
    Features.InitAntiDetect()
    Features.InitTeacherPatrols()
    print("[" .. Core.Config.HubName .. "] Loaded successfully.")
end

Core.Init()
