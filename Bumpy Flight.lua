-- ============================================================================
-- XORQEN HUB — BUMPY FLIGHT (ROBLOX)
-- Version: 1.0.0 (Custom UI Styling & Target Game Binding)
-- Active Features (6 Total):
--   1. Passenger ESP
--   2. Flight Crew ESP
--   3. Distance Indicators
--   4. Task & Object ESP
--   5. Fuel & System ESP
--   6. Auto-Equip Emergency Items
-- ============================================================================

local Core = {
    Config = {
        Version = "1.0.0-BumpyFlight",
        Theme = {
            Background = Color3.fromRGB(13, 17, 23),
            Card = Color3.fromRGB(22, 27, 34),
            Accent = Color3.fromRGB(0, 240, 255),
            Text = Color3.fromRGB(230, 245, 255),
            Muted = Color3.fromRGB(120, 140, 160),
            ToggleOff = Color3.fromRGB(50, 60, 75),
            ToggleOn = Color3.fromRGB(0, 240, 255),
            Passenger = Color3.fromRGB(0, 255, 150),
            Crew = Color3.fromRGB(255, 200, 0),
            TaskObj = Color3.fromRGB(0, 180, 255),
            System = Color3.fromRGB(255, 80, 80)
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
-- GAME ADAPTER & HELPERS
-- ============================================================================
local Adapter = {}

function Adapter.GetCharacter(player)
    player = player or Core.LocalPlayer
    return player and player.Character
end

function Adapter.GetRootPart(player)
    local char = Adapter.GetCharacter(player)
    return char and char:FindFirstChild("HumanoidRootPart")
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
    label.TextSize = 13
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
-- FEATURE IMPLEMENTATION
-- ============================================================================
local Features = {}

-- 1, 2 & 3. Passenger ESP, Flight Crew ESP & Distance Indicators
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
                local activeSwitch = isCrew and Core.State.CrewESP or Core.State.PassengerESP

                if activeSwitch and char and root and hum then
                    local color = isCrew and Core.Config.Theme.Crew or Core.Config.Theme.Passenger
                    local bill = Adapter.CreateOrGetBillboard(id, root, color)
                    bill.Enabled = true

                    local statusStr = hum.SeatPart and "[SEATED]" or "[UNBUCKLED]"
                    local roleStr = isCrew and "CREW" or "PASSENGER"
                    local distStr = ""

                    if Core.State.DistanceIndicators and myRoot then
                        local dist = math.floor((myRoot.Position - root.Position).Magnitude)
                        distStr = string.format(" [%dm]", dist)
                    end

                    local lbl = bill:FindFirstChild("Title")
                    if lbl then
                        lbl.Text = string.format("%s: %s %s%s", roleStr, plr.DisplayName, statusStr, distStr)
                    end
                else
                    Adapter.RemoveBillboard(id)
                end
            end
        end
    end)
end

-- 4. Task & Object ESP
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
                if name:find("mask") or name:find("extinguisher") or name:find("seatbelt") or name:find("door") or name:find("valve") or name:find("repair") then
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

-- 5. Fuel & System ESP
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

-- 6. Auto-Equip Emergency Items
function Features.InitAutoEquipEmergency()
    Core.Connections.AutoEquip = Core.Services.RunService.Heartbeat:Connect(function()
        if not Core.State.AutoEquipEmergency then return end

        local char = Adapter.GetCharacter()
        local hum = Adapter.GetHumanoid()
        local backpack = Core.LocalPlayer:FindFirstChildOfClass("Backpack")
        if not char or not hum or not backpack then return end

        -- Depressurization/Oxygen check
        local isDepressurized = Core.Services.Workspace:FindFirstChild("Depressurization") or Core.Services.Workspace:GetAttribute("Depressurized")
        if isDepressurized then
            local mask = backpack:FindFirstChild("Oxygen Mask") or backpack:FindFirstChild("Mask")
            if mask then hum:EquipTool(mask) end
        end

        -- Fire emergency check
        local fireNearby = false
        for _, obj in ipairs(Core.Services.Workspace:GetDescendants()) do
            if obj:IsA("Fire") or obj.Name:lower():find("fire") then
                fireNearby = true
                break
            end
        end

        if fireNearby then
            local ext = backpack:FindFirstChild("Fire Extinguisher") or backpack:FindFirstChild("Extinguisher")
            if ext then hum:EquipTool(ext) end
        end
    end)
end

-- ============================================================================
-- XORQEN HUB MOBILE UI ENGINE
-- ============================================================================
local UI = {}

function UI.CreateToggleSwitchRow(parent, labelText, stateKey)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Text = labelText
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
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

    switchBg.MouseButton1Click:Connect(function()
        Core.State[stateKey] = not Core.State[stateKey]
        switchBg.BackgroundColor3 = Core.State[stateKey] and Core.Config.Theme.ToggleOn or Core.Config.Theme.ToggleOff
        knob.Position = Core.State[stateKey] and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    end)

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
    Main.Size = UDim2.new(0, 310, 0, 320)
    Main.Position = UDim2.new(0.5, -155, 0.5, -160)
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
    Header.Position = UDim2.new(0, 14, 0, 10)
    Header.Size = UDim2.new(1, -28, 0, 20)
    Header.BackgroundTransparency = 1
    Header.Parent = Main

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -28, 1, -40)
    Container.Position = UDim2.new(0, 14, 0, 34)
    Container.BackgroundTransparency = 1
    Container.Parent = Main

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = Container

    -- 6 Requested Features mapped onto XORQEN HUB Design
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
    print("[XORQEN HUB] Loaded for Bumpy Flight with all 6 features.")
end

Core.Init()
