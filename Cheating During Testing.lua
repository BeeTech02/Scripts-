-- ============================================================================
-- XORQEN HUB — DIRECT LUA BUILDER
-- Target Game: Cheating During Testing [BETA] (Roblox)
-- Architecture: Single-Container Modular Script
-- Selected Features Only:
-- 1. Teacher Patrols Tracker
-- 2. Suspicion / Detection Gauge
-- 3. WalkSpeed & Dash
-- 4. Desk Snapping / Sitting
-- 5. Teacher Position Tracking
-- 6. Desk / NPC Outline
-- ============================================================================

local Core = {
    Config = {
        Version = "1.2.0",
        Theme = {
            Background = Color3.fromRGB(13, 17, 23),
            Card = Color3.fromRGB(22, 27, 34),
            Accent = Color3.fromRGB(0, 240, 255),
            Text = Color3.fromRGB(200, 245, 255),
            Muted = Color3.fromRGB(100, 130, 150),
            Warning = Color3.fromRGB(255, 170, 0),
            Danger = Color3.fromRGB(255, 50, 50)
        }
    },
    State = {
        -- Movement
        WalkSpeed = 16,
        DashPower = 50,
        
        -- Stealth & Tracking
        TeacherPatrols = true,
        TeacherPositionTracking = true,
        SuspicionGauge = true,
        
        -- World Interaction & Visuals
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
-- MODULE: GAME ADAPTER
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
-- MODULE 1 & 5: TEACHER PATROLS & POSITION TRACKING
-- ============================================================================
local TeacherTracker = {}
local TeacherTracer = Drawing.new("Line")
TeacherTracer.Thickness = 2
TeacherTracer.Color = Core.Config.Theme.Danger
TeacherTracer.Transparency = 0.8

local TeacherMarker = Drawing.new("Text")
TeacherMarker.Size = 16
TeacherMarker.Center = true
TeacherMarker.Outline = true
TeacherMarker.Color = Core.Config.Theme.Warning

function TeacherTracker.Init()
    Core.Connections.TeacherTracking = Core.Services.RunService.RenderStepped:Connect(function()
        if not (Core.State.TeacherPatrols or Core.State.TeacherPositionTracking) then
            TeacherTracer.Visible = false
            TeacherMarker.Visible = false
            return
        end

        local teacher = GameAdapter.FindTeacher()
        local myRoot = GameAdapter.GetRootPart()
        local camera = Core.Services.Workspace.CurrentCamera

        if teacher and myRoot and camera then
            local tRoot = teacher.HumanoidRootPart
            local pos, visible = camera:WorldToViewportPoint(tRoot.Position)
            local dist = math.floor((myRoot.Position - tRoot.Position).Magnitude)

            if visible then
                -- Position Marker
                if Core.State.TeacherPositionTracking then
                    TeacherMarker.Visible = true
                    TeacherMarker.Position = Vector2.new(pos.X, pos.Y - 25)
                    TeacherMarker.Text = string.format("🚨 TEACHER [%dm]", dist)
                else
                    TeacherMarker.Visible = false
                end

                -- Patrol Line Tracer
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

-- ============================================================================
-- MODULE 2: SUSPICION / DETECTION GAUGE VISUALIZER
-- ============================================================================
local SuspicionVisualizer = {}

function SuspicionVisualizer.Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SuspicionGaugeUI"
    pcall(function() gui.Parent = Core.Services.CoreGui end)
    if not gui.Parent then gui.Parent = Core.LocalPlayer:WaitForChild("PlayerGui") end

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 200, 0, 18)
    container.Position = UDim2.new(0.5, -100, 0.15, 0)
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    container.BorderSizePixel = 0
    container.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container

    local fill = Instance.new("Frame")
    fill.Name = "FillBar"
    fill.Size = UDim2.new(0.05, 0, 1, 0)
    fill.BackgroundColor3 = Core.Config.Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = container

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fill

    local label = Instance.new("TextLabel")
    label.Text = "DETECTION METER"
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.TextColor3 = Core.Config.Theme.Text
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Parent = container

    Core.Connections.GaugeUpdate = Core.Services.RunService.Heartbeat:Connect(function()
        container.Visible = Core.State.SuspicionGauge
        if not Core.State.SuspicionGauge then return end

        local teacher = GameAdapter.FindTeacher()
        local myRoot = GameAdapter.GetRootPart()

        if teacher and myRoot then
            local tRoot = teacher.HumanoidRootPart
            local dist = (myRoot.Position - tRoot.Position).Magnitude
            local threatLevel = math.clamp(1 - (dist / 40), 0.05, 1)

            fill.Size = UDim2.new(threatLevel, 0, 1, 0)
            if threatLevel > 0.7 then
                fill.BackgroundColor3 = Core.Config.Theme.Danger
            elseif threatLevel > 0.4 then
                fill.BackgroundColor3 = Core.Config.Theme.Warning
            else
                fill.BackgroundColor3 = Core.Config.Theme.Accent
            end
        end
    end)
end

-- ============================================================================
-- MODULE 3: WALKSPEED & DASH MECHANICS
-- ============================================================================
local MovementEngine = {}

function MovementEngine.Init()
    -- WalkSpeed Loop
    Core.Connections.WalkSpeedHook = Core.Services.RunService.Heartbeat:Connect(function()
        local hum = GameAdapter.GetHumanoid()
        if hum then
            hum.WalkSpeed = Core.State.WalkSpeed
        end
    end)

    -- Dash Activation (Shift Key)
    Core.Connections.DashInput = Core.Services.UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.LeftShift then
            local root = GameAdapter.GetRootPart()
            local hum = GameAdapter.GetHumanoid()
            if root and hum and hum.MoveDirection.Magnitude > 0 then
                root.Velocity = hum.MoveDirection * Core.State.DashPower
            end
        end
    end)
end

-- ============================================================================
-- MODULE 4: DESK SNAPPING / SITTING
-- ============================================================================
local DeskSnapper = {}

function DeskSnapper.Snap()
    local seat = GameAdapter.FindAssignedSeat()
    local root = GameAdapter.GetRootPart()
    local hum = GameAdapter.GetHumanoid()

    if seat and root and hum then
        root.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
        task.wait(0.05)
        seat:Sit(hum)
    end
end

function DeskSnapper.Init()
    Core.Connections.DeskSnapInput = Core.Services.UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.F then
            DeskSnapper.Snap()
        end
    end)
end

-- ============================================================================
-- MODULE 6: DESK & NPC OUTLINE (HIGHLIGHT SYSTEM)
-- ============================================================================
local OutlineEngine = {}
local Highlights = {}

function OutlineEngine.ApplyHighlight(object, color)
    if not object:FindFirstChildOfClass("Highlight") then
        local hl = Instance.new("Highlight")
        hl.FillColor = color
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0.1
        hl.Parent = object
        table.insert(Highlights, hl)
    end
end

function OutlineEngine.ClearHighlights()
    for _, hl in ipairs(Highlights) do
        hl:Destroy()
    end
    table.clear(Highlights)
end

function OutlineEngine.Init()
    Core.Connections.OutlineUpdate = Core.Services.RunService.Heartbeat:Connect(function()
        if not Core.State.DeskNPCOutline then
            OutlineEngine.ClearHighlights()
            return
        end

        -- Highlight Teacher NPC
        local teacher = GameAdapter.FindTeacher()
        if teacher then
            OutlineEngine.ApplyHighlight(teacher, Core.Config.Theme.Danger)
        end

        -- Highlight Neighbor Student NPCs & Desks
        for _, obj in ipairs(Core.Services.Workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name:find("Student") or obj.Name:find("Desk")) then
                OutlineEngine.ApplyHighlight(obj, Core.Config.Theme.Accent)
            end
        end
    end)
end

-- ============================================================================
-- XORQEN HUB UI ARCHITECTURE INTEGRATION
-- ============================================================================
local UI = {}

function UI.Create()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "XorqenHubUI"
    ScreenGui.ResetOnSpawn = false

    pcall(function() ScreenGui.Parent = Core.Services.CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = Core.LocalPlayer:WaitForChild("PlayerGui") end

    local Main = Instance.new("Frame")
    Main.Name = "MainWindow"
    Main.Size = UDim2.new(0, 920, 0, 520)
    Main.Position = UDim2.new(0.5, -460, 0.5, -260)
    Main.BackgroundColor3 = Core.Config.Theme.Background
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Main

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Core.Config.Theme.Accent
    Stroke.Thickness = 1.2
    Stroke.Transparency = 0.6
    Stroke.Parent = Main

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 160, 1, 0)
    Sidebar.BackgroundColor3 = Core.Config.Theme.Card
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = Main

    local Logo = Instance.new("TextLabel")
    Logo.Text = "XORQEN HUB"
    Logo.Font = Enum.Font.GothamBold
    Logo.TextSize = 18
    Logo.TextColor3 = Core.Config.Theme.Accent
    Logo.Position = UDim2.new(0, 15, 0, 20)
    Logo.Size = UDim2.new(1, -30, 0, 25)
    Logo.TextXAlignment = Enum.TextXAlignment.Left
    Logo.BackgroundTransparency = 1
    Logo.Parent = Sidebar

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Text = "Game: Cheating During Testing\nStatus: Connected\nVersion: " .. Core.Config.Version
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextSize = 10
    StatusLabel.TextColor3 = Core.Config.Theme.Muted
    StatusLabel.Position = UDim2.new(0, 15, 0, 50)
    StatusLabel.Size = UDim2.new(1, -30, 0, 45)
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Parent = Sidebar

    return ScreenGui
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
function Core.Init()
    UI.Create()
    TeacherTracker.Init()
    SuspicionVisualizer.Init()
    MovementEngine.Init()
    DeskSnapper.Init()
    OutlineEngine.Init()
    print("[XORQEN HUB v1.2.0] Selected 6 features successfully initialized.")
end

Core.Init()
