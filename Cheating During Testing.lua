-- ============================================================================
-- XORQEN HUB — DIRECT LUA BUILDER (FULLY FUNCTIONAL MOBILE ENGINE)
-- Target Game: Cheating During Testing [BETA] (Roblox)
-- ============================================================================

local Core = {
    Config = {
        Version = "1.6.0-Mobile",
        Theme = {
            Background = Color3.fromRGB(13, 17, 23),
            Card = Color3.fromRGB(22, 27, 34),
            Accent = Color3.fromRGB(0, 240, 255),
            Text = Color3.fromRGB(230, 245, 255),
            Muted = Color3.fromRGB(120, 140, 160),
            ToggleOff = Color3.fromRGB(50, 60, 75),
            ToggleOn = Color3.fromRGB(0, 240, 255),
            Warning = Color3.fromRGB(255, 170, 0)
        }
    },
    State = {
        DeskSnapping = false,
        TeacherPositionTracking = false,
        AntiDetect = true
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
            -- Clear detection triggers / suspicion tags on local player
            for _, child in ipairs(char:GetChildren()) do
                if child.Name:lower():find("suspicion") or child.Name:lower():find("detected") or child.Name:lower():find("alert") then
                    child:Destroy()
                end
            end
        end
    end)

    -- Hook Metatable Safely
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

-- ============================================================================
-- MOBILE UI ENGINE
-- ============================================================================
local UI = {}

function UI.CreateToggleSwitchRow(parent, labelText, stateKey, onToggleCallback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Text = labelText
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Core.Config.Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 8, 0, 0)
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Parent = row

    local switchBg = Instance.new("TextButton")
    switchBg.Text = ""
    switchBg.Size = UDim2.new(0, 50, 0, 24)
    switchBg.Position = UDim2.new(1, -50, 0.5, -12)
    switchBg.BackgroundColor3 = Core.State[stateKey] and Core.Config.Theme.ToggleOn or Core.Config.Theme.ToggleOff
    switchBg.BorderSizePixel = 0
    switchBg.Parent = row

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchBg

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = Core.State[stateKey] and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    knob.BorderSizePixel = 0
    knob.Parent = switchBg

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local function toggle()
        Core.State[stateKey] = not Core.State[stateKey]
        switchBg.BackgroundColor3 = Core.State[stateKey] and Core.Config.Theme.ToggleOn or Core.Config.Theme.ToggleOff
        knob.Position = Core.State[stateKey] and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        
        if onToggleCallback then
            onToggleCallback(Core.State[stateKey])
        end
    end

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
    Main.Size = UDim2.new(0, 310, 0, 220)
    Main.Position = UDim2.new(0.5, -155, 0.5, -110)
    Main.BackgroundColor3 = Core.Config.Theme.Background
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Main

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(35, 45, 55)
    Stroke.Thickness = 1
    Stroke.Parent = Main

    local Header = Instance.new("TextLabel")
    Header.Text = "XORQEN HUB"
    Header.Font = Enum.Font.GothamBold
    Header.TextSize = 16
    Header.TextColor3 = Core.Config.Theme.Text
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.Position = UDim2.new(0, 14, 0, 12)
    Header.Size = UDim2.new(1, -28, 0, 20)
    Header.BackgroundTransparency = 1
    Header.Parent = Main

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -28, 1, -44)
    Container.Position = UDim2.new(0, 14, 0, 38)
    Container.BackgroundTransparency = 1
    Container.Parent = Main

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = Container

    UI.CreateToggleSwitchRow(Container, "Desk Snapping / Sitting", "DeskSnapping")
    UI.CreateToggleSwitchRow(Container, "Teacher Position Tracking", "TeacherPositionTracking")
    UI.CreateToggleSwitchRow(Container, "Anti Detect", "AntiDetect")

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
    print("[XORQEN HUB v1.6.0] All feature toggles bound and operational.")
end

Core.Init()
