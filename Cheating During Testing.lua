-- ============================================================================
-- XORQEN HUB — DIRECT LUA BUILDER (OS 26 GLASS WIDGETS + NEON BG)
-- Target Game: Cheating During Testing [BETA] (Roblox)
-- Architecture: Dynamic Neon Background + OS 26 Glass Floating Widgets
-- Version: 2.1.0-NeonGlass
-- ============================================================================

local Core = {
    Config = {
        Version = "2.1.0-NeonGlass",
        Theme = {
            NeonCyan = Color3.fromRGB(0, 240, 255),
            NeonBlue = Color3.fromRGB(0, 120, 255),
            NeonDarkTint = Color3.fromRGB(5, 25, 35), -- Dynamic Glass Tint
            Text = Color3.fromRGB(240, 250, 255),
            ToggleOff = Color3.fromRGB(20, 30, 45),
            ToggleOn = Color3.fromRGB(0, 240, 255),
            CloseRed = Color3.fromRGB(255, 40, 70),
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
-- OS 26 NEON GLASS UI ENGINE (BUTTON-MATCHED NEON BACKGROUND + GLASS WIDGETS)
-- ============================================================================
local UI = {}

function UI.CreateToggleSwitchRow(parent, labelText, stateKey)
    local widgetCard = Instance.new("Frame")
    widgetCard.Size = UDim2.new(1, 0, 0, 42)
    widgetCard.BackgroundTransparency = 1
    widgetCard.Parent = parent

    -- OS 26 Floating Glass Container
    local glassBg = Instance.new("Frame")
    glassBg.Size = UDim2.new(1, 0, 1, 0)
    glassBg.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
    glassBg.BackgroundTransparency = 0.45
    glassBg.Parent = widgetCard

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = glassBg

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Core.State[stateKey] and Core.Config.Theme.NeonCyan or Color3.fromRGB(45, 65, 90)
    cardStroke.Thickness = 1.25
    cardStroke.Transparency = 0.1
    cardStroke.Parent = glassBg

    local label = Instance.new("TextLabel")
    label.Text = labelText
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = Core.Config.Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Parent = widgetCard

    -- Neon Switch Button (Matches Hub Accent Glow)
    local switchBg = Instance.new("TextButton")
    switchBg.Text = ""
    switchBg.Size = UDim2.new(0, 46, 0, 22)
    switchBg.Position = UDim2.new(1, -56, 0.5, -11)
    switchBg.BackgroundColor3 = Core.State[stateKey] and Core.Config.Theme.ToggleOn or Core.Config.Theme.ToggleOff
    switchBg.BackgroundTransparency = 0.15
    switchBg.BorderSizePixel = 0
    switchBg.Parent = widgetCard

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchBg

    local switchStroke = Instance.new("UIStroke")
    switchStroke.Color = Core.State[stateKey] and Core.Config.Theme.NeonCyan or Color3.fromRGB(70, 90, 115)
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
        switchBg.BackgroundColor3 = active and Core.Config.Theme.ToggleOn or Core.Config.Theme.ToggleOff
        cardStroke.Color = active and Core.Config.Theme.NeonCyan or Color3.fromRGB(45, 65, 90)
        switchStroke.Color = active and Core.Config.Theme.NeonCyan or Color3.fromRGB(70, 90, 115)
        knob.Position = active and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    end)

    return widgetCard
end

function UI.BuildMobileUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "XorqenHubOS26Neon"
    ScreenGui.ResetOnSpawn = false

    pcall(function() ScreenGui.Parent = Core.Services.CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = Core.LocalPlayer:WaitForChild("PlayerGui") end

    -- Main Container Window
    local Main = Instance.new("Frame")
    Main.Name = "MainWindow"
    Main.Size = UDim2.new(0, 310, 0, 260)
    Main.Position = UDim2.new(0.5, -155, 0.5, -130)
    Main.BackgroundTransparency = 1
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    -- Neon Tinted Main Background Panel (Color Matches Cyan Button Theme)
    local MainBgPanel = Instance.new("Frame")
    MainBgPanel.Size = UDim2.new(1, 0, 1, 0)
    MainBgPanel.BackgroundColor3 = Core.Config.Theme.NeonDarkTint
    MainBgPanel.BackgroundTransparency = 0.25 -- Translucent Glass Effect
    MainBgPanel.Parent = Main

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 16)
    MainCorner.Parent = MainBgPanel

    local MainNeonStroke = Instance.new("UIStroke")
    MainNeonStroke.Color = Core.Config.Theme.NeonCyan
    MainNeonStroke.Thickness = 2
    MainNeonStroke.Parent = MainBgPanel

    -- Header Title Bar Widget
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, -20, 0, 32)
    Header.Position = UDim2.new(0, 10, 0, 10)
    Header.BackgroundTransparency = 1
    Header.Parent = Main

    local HeaderTitle = Instance.new("TextLabel")
    HeaderTitle.Text = "⚡ XORQEN OS 26"
    HeaderTitle.Font = Enum.Font.GothamBold
    HeaderTitle.TextSize = 14
    HeaderTitle.TextColor3 = Core.Config.Theme.NeonCyan
    HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    HeaderTitle.Position = UDim2.new(0, 4, 0, 0)
    HeaderTitle.Size = UDim2.new(0.7, 0, 1, 0)
    HeaderTitle.BackgroundTransparency = 1
    HeaderTitle.Parent = Header

    -- Red Close Widget Icon
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseButton"
    CloseBtn.Text = "✕"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 13
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.BackgroundColor3 = Core.Config.Theme.CloseRed
    CloseBtn.BackgroundTransparency = 0.2
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -28, 0, 2)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = Header

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(1, 0)
    CloseCorner.Parent = CloseBtn

    local CloseStroke = Instance.new("UIStroke")
    CloseStroke.Color = Core.Config.Theme.CloseRed
    CloseStroke.Thickness = 1.5
    CloseStroke.Parent = CloseBtn

    -- Floating OS 26 Re-open Widget Badge
    local OpenBtn = Instance.new("TextButton")
    OpenBtn.Name = "OpenButton"
    OpenBtn.Text = "⚡ OS 26"
    OpenBtn.Font = Enum.Font.GothamBold
    OpenBtn.TextSize = 12
    OpenBtn.TextColor3 = Core.Config.Theme.NeonCyan
    OpenBtn.BackgroundColor3 = Core.Config.Theme.NeonDarkTint
    OpenBtn.BackgroundTransparency = 0.25
    OpenBtn.Size = UDim2.new(0, 90, 0, 36)
    OpenBtn.Position = UDim2.new(0.02, 0, 0.45, 0)
    OpenBtn.Visible = false
    OpenBtn.Active = true
    OpenBtn.Draggable = true
    OpenBtn.Parent = ScreenGui

    local OpenCorner = Instance.new("UICorner")
    OpenCorner.CornerRadius = UDim.new(0, 18)
    OpenCorner.Parent = OpenBtn

    local OpenStroke = Instance.new("UIStroke")
    OpenStroke.Color = Core.Config.Theme.NeonCyan
    OpenStroke.Thickness = 2
    OpenStroke.Parent = OpenBtn

    -- Actions
    CloseBtn.MouseButton1Click:Connect(function()
        Main.Visible = false
        OpenBtn.Visible = true
    end)

    OpenBtn.MouseButton1Click:Connect(function()
        Main.Visible = true
        OpenBtn.Visible = false
    end)

    -- Pulsing Neon Theme Effect (Pulses Background & Outlines synchronously with buttons)
    task.spawn(function()
        local t = 0
        while task.wait(0.03) do
            t = t + 0.05
            local pulse = (math.sin(t) + 1) / 2
            local currentNeon = Core.Config.Theme.NeonCyan:Lerp(Core.Config.Theme.NeonBlue, pulse)
            
            MainNeonStroke.Color = currentNeon
            OpenStroke.Color = currentNeon
            MainBgPanel.BackgroundColor3 = Color3.fromRGB(5, 20, 30):Lerp(Color3.fromRGB(0, 30, 45), pulse)
        end
    end)

    -- Widget Rows Holder Container
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -20, 1, -54)
    Container.Position = UDim2.new(0, 10, 0, 48)
    Container.BackgroundTransparency = 1
    Container.Parent = Main

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = Container

    -- 4 Clean OS 26 Floating Widgets
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
    print("[XORQEN HUB OS 26] Button-Matched Neon Background & Glass Widgets Loaded.")
end

Core.Init()
