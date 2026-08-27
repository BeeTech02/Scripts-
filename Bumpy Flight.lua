-- ============================================================================
-- XORQEN HUB — BUMPY FLIGHT (ROBLOX)
-- Theme: Soft Glassmorphic Light Turquoise (Modern OS Style)
-- Version: 1.0.6-GlassmorphicLightUI
-- ============================================================================

local Core = {
    Config = {
        Version = "1.0.6-GlassmorphicLightUI",
        HubName = "XORQEN HUB",
        Theme = {
            LightTurquoiseBg = Color3.fromRGB(215, 248, 246),   -- Soft pastel turquoise background
            CardBg = Color3.fromRGB(235, 253, 252),           -- Frosted card fill
            TurquoiseBorder = Color3.fromRGB(110, 215, 205),    -- Subtle border outline
            TextDark = Color3.fromRGB(25, 40, 42),              -- High-contrast slate dark text
            ToggleOn = Color3.fromRGB(40, 195, 180),            -- Vibrant active switch accent
            ToggleOff = Color3.fromRGB(185, 205, 202),           -- Soft inactive switch fill
            CloseRed = Color3.fromRGB(255, 85, 100),
            Passenger = Color3.fromRGB(0, 180, 120),
            Crew = Color3.fromRGB(220, 150, 0),
            TaskObj = Color3.fromRGB(0, 150, 220),
            System = Color3.fromRGB(220, 50, 60)
        }
    },
    State = {
        PassengerESP = false,
        CrewESP = false,
        DistanceIndicators = false,
        TaskESP = false,
        SystemESP = false,
        AutoEquipEmergency = false
    },
    Services = {
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        Workspace = game:GetService("Workspace"),
        CoreGui = game:GetService("CoreGui")
    },
    Connections = {},
    Cache = {
        Billboards = {}
    }
}

Core.LocalPlayer = Core.Services.Players.LocalPlayer

-- ============================================================================
-- GAME ADAPTER
-- ============================================================================
local Adapter = {}

function Adapter.GetCharacter(player)
    player = player or Core.LocalPlayer
    return player and player.Character
end

function Adapter.GetRootPart(player)
    local char = Adapter.GetCharacter(player)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char.PrimaryPart
end

function Adapter.GetHumanoid(player)
    local char = Adapter.GetCharacter(player)
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Adapter.IsCrew(player)
    if not player then return false end
    local role = player:GetAttribute("Role") or player:GetAttribute("Team")
    local name = player.Name:lower()
    
    if role and (tostring(role):lower():find("pilot") or tostring(role):lower():find("crew") or tostring(role):lower():find("attendant")) then
        return true
    end
    if name:find("pilot") or name:find("crew") or name:find("attendant") then
        return true
    end
    return false
end

function Adapter.CreateOrGetBillboard(id, targetPart, color)
    if Core.Cache.Billboards[id] and Core.Cache.Billboards[id].Parent then
        return Core.Cache.Billboards[id]
    end

    local bill = Instance.new("BillboardGui")
    bill.Name = "ESP_" .. id
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0, 180, 0, 34)
    bill.StudsOffset = Vector3.new(0, 3, 0)

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.2
    label.Parent = bill

    bill.Parent = targetPart
    Core.Cache.Billboards[id] = bill
    return bill
end

function Adapter.RemoveBillboard(id)
    if Core.Cache.Billboards[id] then
        Core.Cache.Billboards[id]:Destroy()
        Core.Cache.Billboards[id] = nil
    end
end

-- ============================================================================
-- FEATURE MODULES
-- ============================================================================
local Features = {}

function Features.InitPlayerESP()
    Core.Connections.PlayerESP = Core.Services.RunService.RenderStepped:Connect(function()
        local myRoot = Adapter.GetRootPart()

        for _, plr in ipairs(Core.Services.Players:GetPlayers()) do
            if plr ~= Core.LocalPlayer then
                local char = Adapter.GetCharacter(plr)
                local root = Adapter.GetRootPart(plr)
                local hum = Adapter.GetHumanoid(plr)
                local id = "PLR_" .. plr.UserId

                local isCrew = Adapter.IsCrew(plr)
                local isPassenger = not isCrew

                local shouldShow = (isCrew and Core.State.CrewESP) or (isPassenger and Core.State.PassengerESP) or Core.State.DistanceIndicators

                if shouldShow and char and root then
                    local color = isCrew and Core.Config.Theme.Crew or Core.Config.Theme.Passenger
                    local bill = Adapter.CreateOrGetBillboard(id, root, color)
                    bill.Enabled = true

                    local isSeated = (hum and hum.SeatPart) or false
                    local statusStr = isSeated and "[SEATED]" or "[UNBUCKLED]"
                    local roleStr = isCrew and "CREW" or "PASSENGER"
                    local distStr = ""

                    if myRoot then
                        local dist = math.floor((myRoot.Position - root.Position).Magnitude)
                        distStr = string.format(" [%dm]", dist)
                    end

                    local lbl = bill:FindFirstChild("Title")
                    if lbl then
                        if (isCrew and Core.State.CrewESP) or (isPassenger and Core.State.PassengerESP) then
                            lbl.Text = string.format("%s: %s %s%s", roleStr, plr.DisplayName, statusStr, distStr)
                        else
                            lbl.Text = string.format("%s%s", plr.DisplayName, distStr)
                        end
                    end
                else
                    Adapter.RemoveBillboard(id)
                end
            end
        end
    end)
end

function Features.InitTaskESP()
    Core.Connections.TaskESP = Core.Services.RunService.RenderStepped:Connect(function()
        if not Core.State.TaskESP then
            for id, _ in pairs(Core.Cache.Billboards) do
                if id:sub(1, 5) == "TASK_" then
                    Adapter.RemoveBillboard(id)
                end
            end
            return
        end

        local myRoot = Adapter.GetRootPart()
        for _, obj in ipairs(Core.Services.Workspace:GetDescendants()) do
            local name = obj.Name:lower()
            if obj:IsA("BasePart") or obj:IsA("Model") then
                if name:find("mask") or name:find("extinguisher") or name:find("seatbelt") or name:find("door") or name:find("valve") or name:find("repair") or name:find("oxygen") then
                    local targetPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                    if targetPart then
                        local id = "TASK_" .. obj:GetDebugId()
                        local bill = Adapter.CreateOrGetBillboard(id, targetPart, Core.Config.Theme.TaskObj)
                        bill.Enabled = true

                        local distStr = ""
                        if Core.State.DistanceIndicators and myRoot then
                            local dist = math.floor((myRoot.Position - targetPart.Position).Magnitude)
                            distStr = string.format(" [%dm]", dist)
                        end

                        local lbl = bill:FindFirstChild("Title")
                        if lbl then
                            lbl.Text = string.format("🔧 %s%s", obj.Name, distStr)
                        end
                    end
                end
            end
        end
    end)
end

function Features.InitSystemESP()
    Core.Connections.SystemESP = Core.Services.RunService.RenderStepped:Connect(function()
        if not Core.State.SystemESP then
            for id, _ in pairs(Core.Cache.Billboards) do
                if id:sub(1, 4) == "SYS_" then
                    Adapter.RemoveBillboard(id)
                end
            end
            return
        end

        local myRoot = Adapter.GetRootPart()
        for _, obj in ipairs(Core.Services.Workspace:GetDescendants()) do
            local name = obj.Name:lower()
            if name:find("fuel") or name:find("engine") or name:find("pressure") or name:find("generator") or name:find("tank") then
                local targetPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or (obj:IsA("BasePart") and obj)
                if targetPart then
                    local id = "SYS_" .. obj:GetDebugId()
                    local bill = Adapter.CreateOrGetBillboard(id, targetPart, Core.Config.Theme.System)
                    bill.Enabled = true

                    local val = obj:FindFirstChild("Level") or obj:FindFirstChild("Value") or obj:FindFirstChild("Health")
                    local valStr = val and string.format(" (%s)", tostring(val.Value)) or ""

                    local distStr = ""
                    if Core.State.DistanceIndicators and myRoot then
                        local dist = math.floor((myRoot.Position - targetPart.Position).Magnitude)
                        distStr = string.format(" [%dm]", dist)
                    end

                    local lbl = bill:FindFirstChild("Title")
                    if lbl then
                        lbl.Text = string.format("⚡ %s%s%s", obj.Name, valStr, distStr)
                    end
                end
            end
        end
    end)
end

function Features.InitAutoEquipEmergency()
    local emergencyKeywords = { "mask", "oxygen", "extinguisher", "fire", "gear", "life", "vest", "parachute", "flashlight" }

    local function checkAndEquipTool(tool)
        if not Core.State.AutoEquipEmergency then return end
        if not tool or not tool:IsA("Tool") then return end

        local toolName = tool.Name:lower()
        for _, kw in ipairs(emergencyKeywords) do
            if toolName:find(kw) then
                local hum = Adapter.GetHumanoid()
                if hum then
                    hum:EquipTool(tool)
                end
                break
            end
        end
    end

    Core.Connections.AutoEquip = Core.Services.RunService.Heartbeat:Connect(function()
        if not Core.State.AutoEquipEmergency then return end

        local backpack = Core.LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                checkAndEquipTool(item)
            end
        end
    end)

    local backpack = Core.LocalPlayer:FindFirstChildOfClass("Backpack") or Core.LocalPlayer:WaitForChild("Backpack", 5)
    if backpack then
        backpack.ChildAdded:Connect(function(child)
            task.wait(0.1)
            checkAndEquipTool(child)
        end)
    end
end

-- ============================================================================
-- UI BUILDER (XORQEN HUB GLASSMORPHIC BLUEPRINT)
-- ============================================================================
local UI = {}

function UI.CreateToggleSwitchRow(parent, labelText, stateKey)
    local widgetCard = Instance.new("Frame")
    widgetCard.Size = UDim2.new(1, 0, 0, 40)
    widgetCard.BackgroundTransparency = 1
    widgetCard.Parent = parent

    local glassBg = Instance.new("Frame")
    glassBg.Size = UDim2.new(1, 0, 1, 0)
    glassBg.BackgroundColor3 = Core.Config.Theme.CardBg
    glassBg.BackgroundTransparency = 0.25
    glassBg.Parent = widgetCard

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = glassBg

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Core.State[stateKey] and Core.Config.Theme.ToggleOn or Core.Config.Theme.TurquoiseBorder
    cardStroke.Thickness = 1.2
    cardStroke.Transparency = 0.2
    cardStroke.Parent = glassBg

    local label = Instance.new("TextLabel")
    label.Text = labelText
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextColor3 = Core.Config.Theme.TextDark
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Parent = widgetCard

    local switchBg = Instance.new("TextButton")
    switchBg.Text = ""
    switchBg.Size = UDim2.new(0, 44, 0, 20)
    switchBg.Position = UDim2.new(1, -52, 0.5, -10)
    switchBg.BackgroundColor3 = Core.State[stateKey] and Core.Config.Theme.ToggleOn or Core.Config.Theme.ToggleOff
    switchBg.BackgroundTransparency = 0.1
    switchBg.BorderSizePixel = 0
    switchBg.Parent = widgetCard

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchBg

    local switchStroke = Instance.new("UIStroke")
    switchStroke.Color = Core.State[stateKey] and Core.Config.Theme.ToggleOn or Core.Config.Theme.TurquoiseBorder
    switchStroke.Thickness = 1
    switchStroke.Parent = switchBg

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = Core.State[stateKey] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
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
        cardStroke.Color = active and Core.Config.Theme.ToggleOn or Core.Config.Theme.TurquoiseBorder
        switchStroke.Color = active and Core.Config.Theme.ToggleOn or Core.Config.Theme.TurquoiseBorder
        knob.Position = active and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    end)

    return widgetCard
end

function UI.BuildMobileUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "XorqenHubMobileUI"
    ScreenGui.ResetOnSpawn = false

    pcall(function() ScreenGui.Parent = Core.Services.CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = Core.LocalPlayer:WaitForChild("PlayerGui") end
    Core.ScreenGui = ScreenGui

    -- Main Frame Window
    local Main = Instance.new("Frame")
    Main.Name = "MainWindow"
    Main.Size = UDim2.new(0, 310, 0, 330)
    Main.Position = UDim2.new(0.5, -155, 0.5, -165)
    Main.BackgroundTransparency = 1
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local MainBgPanel = Instance.new("Frame")
    MainBgPanel.Size = UDim2.new(1, 0, 1, 0)
    MainBgPanel.BackgroundColor3 = Core.Config.Theme.LightTurquoiseBg
    MainBgPanel.BackgroundTransparency = 0.15
    MainBgPanel.Parent = Main

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 16)
    MainCorner.Parent = MainBgPanel

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Core.Config.Theme.TurquoiseBorder
    MainStroke.Thickness = 1.5
    MainStroke.Parent = MainBgPanel

    -- Header Panel
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, -20, 0, 32)
    Header.Position = UDim2.new(0, 10, 0, 10)
    Header.BackgroundTransparency = 1
    Header.Parent = Main

    local HeaderTitle = Instance.new("TextLabel")
    HeaderTitle.Text = Core.Config.HubName
    HeaderTitle.Font = Enum.Font.GothamBold
    HeaderTitle.TextSize = 14
    HeaderTitle.TextColor3 = Core.Config.Theme.TextDark
    HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    HeaderTitle.Position = UDim2.new(0, 6, 0, 0)
    HeaderTitle.Size = UDim2.new(0.7, 0, 1, 0)
    HeaderTitle.BackgroundTransparency = 1
    HeaderTitle.ZIndex = 5
    HeaderTitle.Parent = Header

    -- Close (Minimize) Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseButton"
    CloseBtn.Text = "×"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 18
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.BackgroundColor3 = Core.Config.Theme.CloseRed
    CloseBtn.BackgroundTransparency = 0.05
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseBtn.Position = UDim2.new(1, -24, 0, 4)
    CloseBtn.ZIndex = 5
    CloseBtn.Parent = Header

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(1, 0)
    CloseCorner.Parent = CloseBtn

    -- Floating Open Widget Button
    local OpenBtn = Instance.new("TextButton")
    OpenBtn.Name = "OpenButton"
    OpenBtn.Text = ""
    OpenBtn.Size = UDim2.new(0, 160, 0, 42)
    OpenBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
    OpenBtn.Visible = false
    OpenBtn.Active = true
    OpenBtn.Draggable = true
    OpenBtn.BackgroundColor3 = Core.Config.Theme.LightTurquoiseBg
    OpenBtn.BackgroundTransparency = 0.15
    OpenBtn.BorderSizePixel = 0
    OpenBtn.Parent = ScreenGui

    local OpenCorner = Instance.new("UICorner")
    OpenCorner.CornerRadius = UDim.new(1, 0)
    OpenCorner.Parent = OpenBtn

    local OpenStroke = Instance.new("UIStroke")
    OpenStroke.Color = Core.Config.Theme.TurquoiseBorder
    OpenStroke.Thickness = 1.5
    OpenStroke.Parent = OpenBtn

    local OpenText = Instance.new("TextLabel")
    OpenText.Text = Core.Config.HubName
    OpenText.Font = Enum.Font.GothamBold
    OpenText.TextSize = 13
    OpenText.TextColor3 = Core.Config.Theme.TextDark
    OpenText.TextXAlignment = Enum.TextXAlignment.Center
    OpenText.Position = UDim2.new(0, 0, 0, 0)
    OpenText.Size = UDim2.new(1, 0, 1, 0)
    OpenText.BackgroundTransparency = 1
    OpenText.ZIndex = 5
    OpenText.Parent = OpenBtn

    -- Toggle Display Logic
    CloseBtn.MouseButton1Click:Connect(function()
        Main.Visible = false
        OpenBtn.Visible = true
    end)

    OpenBtn.MouseButton1Click:Connect(function()
        Main.Visible = true
        OpenBtn.Visible = false
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

    UI.CreateToggleSwitchRow(Container, "Passenger ESP", "PassengerESP")
    UI.CreateToggleSwitchRow(Container, "Flight Crew ESP", "CrewESP")
    UI.CreateToggleSwitchRow(Container, "Distance Indicators", "DistanceIndicators")
    UI.CreateToggleSwitchRow(Container, "Task & Object ESP", "TaskESP")
    UI.CreateToggleSwitchRow(Container, "Fuel & System ESP", "SystemESP")
    UI.CreateToggleSwitchRow(Container, "Auto-Equip Emergency Items", "AutoEquipEmergency")

    return ScreenGui
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
function Core.Init()
    UI.BuildMobileUI()
    Features.InitPlayerESP()
    Features.InitTaskESP()
    Features.InitSystemESP()
    Features.InitAutoEquipEmergency()
    print("[" .. Core.Config.HubName .. "] Loaded successfully.")
end

Core.Init()
