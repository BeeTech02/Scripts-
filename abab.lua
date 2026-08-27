-- ============================================================================
-- NYZORA HUB — BUMPY FLIGHT (ROBLOX)
-- Master UI Match: Pumpkin Orange Glassmorphic Style
-- Version: 1.1.0-NyzoraPumpkin
-- ============================================================================

local Core = {
    Config = {
        Version = "1.1.0-NyzoraPumpkin",
        HubName = "NYZORA HUB",
        Theme = {
            MainBg = Color3.fromRGB(245, 130, 60),           -- Pumpkin Glass Panel
            MainBgTransparency = 0.25,                        -- Semi-transparent glass fill
            CardBg = Color3.fromRGB(255, 215, 185),          -- Soft Peach Inner Card
            CardBgTransparency = 0.35,                        -- Inner Card transparency
            PumpkinBorder = Color3.fromRGB(210, 95, 30),     -- Deep Warm Orange Border Accent
            TextDark = Color3.fromRGB(45, 25, 15),            -- Dark Charcoal/Warm Slate Text
            ToggleOn = Color3.fromRGB(235, 100, 30),          -- Vivid Pumpkin Active Switch
            ToggleOff = Color3.fromRGB(210, 190, 180),        -- Muted Peach-Grey Inactive Switch
            CloseRed = Color3.fromRGB(255, 85, 100),           -- Red Circular Close Button
            Passenger = Color3.fromRGB(235, 110, 30),
            Crew = Color3.fromRGB(220, 150, 0),
            TaskObj = Color3.fromRGB(240, 140, 50),
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
                    valStr = val and string.format(" (%s)", tostring(val.Value)) or ""

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
-- UI BUILDER (PUMPKIN NYZORA HUB DESIGN)
-- ============================================================================
local UI = {}

function UI.CreateToggleSwitchRow(parent, labelText, stateKey)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 42)
    card.BackgroundColor3 = Core.Config.Theme.CardBg
    card.BackgroundTransparency = Core.Config.Theme.CardBgTransparency
    card.BorderSizePixel = 0
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 14)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Core.Config.Theme.PumpkinBorder
    cardStroke.Thickness = 1.2
    cardStroke.Transparency = 0.3
    cardStroke.Parent = card

    local label = Instance.new("TextLabel")
    label.Text = labelText
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = Core.Config.Theme.TextDark
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 14, 0, 0)
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Parent = card

    local switchBg = Instance.new("TextButton")
    switchBg.Text = ""
    switchBg.Size = UDim2.new(0, 48, 0, 24)
    switchBg.Position = UDim2.new(1, -56, 0.5, -12)
    switchBg.BackgroundColor3 = Core.State[stateKey] and Core.Config.Theme.ToggleOn or Core.Config.Theme.ToggleOff
    switchBg.BorderSizePixel = 0
    switchBg.Parent = card

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchBg

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = Core.State[stateKey] and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
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
        knob.Position = active and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    end)

    return card
end

function UI.BuildMobileUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NyzoraHubGui"
    ScreenGui.ResetOnSpawn = false

    pcall(function() ScreenGui.Parent = Core.Services.CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = Core.LocalPlayer:WaitForChild("PlayerGui") end

    -- Main Panel Window
    local Main = Instance.new("Frame")
    Main.Name = "MainWindow"
    Main.Size = UDim2.new(0, 320, 0, 340)
    Main.Position = UDim2.new(0.5, -160, 0.5, -170)
    Main.BackgroundColor3 = Core.Config.Theme.MainBg
    Main.BackgroundTransparency = Core.Config.Theme.MainBgTransparency
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 22)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Core.Config.Theme.PumpkinBorder
    MainStroke.Thickness = 1.5
    MainStroke.Transparency = 0.2
    MainStroke.Parent = Main

    -- Header Section
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, -20, 0, 36)
    Header.Position = UDim2.new(0, 10, 0, 10)
    Header.BackgroundTransparency = 1
    Header.Parent = Main

    local HeaderTitle = Instance.new("TextLabel")
    HeaderTitle.Text = Core.Config.HubName
    HeaderTitle.Font = Enum.Font.GothamBold
    HeaderTitle.TextSize = 14
    HeaderTitle.TextColor3 = Core.Config.Theme.TextDark
    HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    HeaderTitle.Position = UDim2.new(0, 8, 0, 0)
    HeaderTitle.Size = UDim2.new(0.7, 0, 1, 0)
    HeaderTitle.BackgroundTransparency = 1
    HeaderTitle.Parent = Header

    -- Red Circular Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseButton"
    CloseBtn.Text = "×"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 18
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.BackgroundColor3 = Core.Config.Theme.CloseRed
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -26, 0.5, -13)
    CloseBtn.Parent = Header

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(1, 0)
    CloseCorner.Parent = CloseBtn

    -- Master Floating Capsule Button Widget (Pumpkin)
    local OpenBtn = Instance.new("TextButton")
    OpenBtn.Name = "OpenButton"
    OpenBtn.Text = Core.Config.HubName
    OpenBtn.Font = Enum.Font.GothamBold
    OpenBtn.TextSize = 13
    OpenBtn.TextColor3 = Core.Config.Theme.TextDark
    OpenBtn.Size = UDim2.new(0, 160, 0, 42)
    OpenBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
    OpenBtn.Visible = false
    OpenBtn.Active = true
    OpenBtn.Draggable = true
    OpenBtn.BackgroundColor3 = Core.Config.Theme.MainBg
    OpenBtn.BackgroundTransparency = Core.Config.Theme.MainBgTransparency
    OpenBtn.BorderSizePixel = 0
    OpenBtn.Parent = ScreenGui

    local OpenCorner = Instance.new("UICorner")
    OpenCorner.CornerRadius = UDim.new(1, 0)
    OpenCorner.Parent = OpenBtn

    -- Minimize and Restore Logic
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
    Container.Size = UDim2.new(1, -24, 1, -56)
    Container.Position = UDim2.new(0, 12, 0, 48)
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
