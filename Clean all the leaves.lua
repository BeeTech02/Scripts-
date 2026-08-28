-- ============================================================================
-- VORYZEN HUB — CLEAN ALL THE LEAVES (ROBLOX)
-- Stable Utilities Edition with Dynamic Adjustment Sliders
-- Version: 1.5.0-VoryzenDynamic
-- ============================================================================

local Core = {
    Config = {
        Version = "1.5.0-VoryzenDynamic",
        HubName = "VORYZEN HUB",
        GameName = "Clean All The Leaves",
        Theme = {
            MainBg = Color3.fromRGB(155, 120, 195),          -- Amethyst Glass Panel
            MainBgTransparency = 0.25,                        -- Semi-transparent glass fill
            CardBg = Color3.fromRGB(220, 205, 240),          -- Soft Lavender Inner Card
            CardBgTransparency = 0.35,                        -- Inner Card transparency
            AmethystBorder = Color3.fromRGB(120, 80, 170),    -- Deep Violet Outline Accent
            TextDark = Color3.fromRGB(30, 20, 45),            -- Dark Amethyst/Slate Text
            ToggleOn = Color3.fromRGB(140, 80, 210),           -- Vivid Amethyst Active Switch
            ToggleOff = Color3.fromRGB(185, 175, 200),         -- Greyish Lavender Inactive Switch
            CloseRed = Color3.fromRGB(255, 85, 100)           -- Red Circular Close Button
        }
    },
    State = {
        InfiniteJump = false,
        Noclip = false,
        SpeedBoost = false,
        JumpPowerBoost = false,
        SpeedValue = 32,
        JumpPowerValue = 100
    },
    Services = {
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        CoreGui = game:GetService("CoreGui"),
        UserInputService = game:GetService("UserInputService")
    },
    Connections = {}
}

Core.LocalPlayer = Core.Services.Players.LocalPlayer

-- ============================================================================
-- GAME ADAPTER & STABLE UTILITIES
-- ============================================================================
local Adapter = {}

function Adapter.GetCharacter(player)
    player = player or Core.LocalPlayer
    return player and player.Character
end

function Adapter.GetHumanoid(player)
    local char = Adapter.GetCharacter(player)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local Exploits = {}

function Exploits.InitInfiniteJump()
    Core.Connections.InfJump = Core.Services.UserInputService.JumpRequest:Connect(function()
        if Core.State.InfiniteJump then
            local hum = Adapter.GetHumanoid()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

function Exploits.InitNoclip()
    Core.Connections.Noclip = Core.Services.RunService.Stepped:Connect(function()
        if not Core.State.Noclip then return end
        local char = Adapter.GetCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

function Exploits.UpdateSpeed()
    local hum = Adapter.GetHumanoid()
    if hum and Core.State.SpeedBoost then
        hum.WalkSpeed = Core.State.SpeedValue
    end
end

function Exploits.ToggleSpeed(enabled)
    local hum = Adapter.GetHumanoid()
    if hum then
        hum.WalkSpeed = enabled and Core.State.SpeedValue or 16
    end
end

function Exploits.UpdateJumpPower()
    local hum = Adapter.GetHumanoid()
    if hum and Core.State.JumpPowerBoost then
        hum.UseJumpPower = true
        hum.JumpPower = Core.State.JumpPowerValue
    end
end

function Exploits.ToggleJumpPower(enabled)
    local hum = Adapter.GetHumanoid()
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = enabled and Core.State.JumpPowerValue or 50
    end
end

-- ============================================================================
-- UI BUILDER WITH DYNAMIC SLIDER SUPPORT
-- ============================================================================
local UI = {}

function UI.CreateSliderRow(parent, labelText, minVal, maxVal, stateKey, onValueChanged)
    local sliderCard = Instance.new("Frame")
    sliderCard.Name = stateKey .. "SliderCard"
    sliderCard.Size = UDim2.new(1, 0, 0, 50)
    sliderCard.BackgroundColor3 = Core.Config.Theme.CardBg
    sliderCard.BackgroundTransparency = Core.Config.Theme.CardBgTransparency
    sliderCard.BorderSizePixel = 0
    sliderCard.Visible = false
    sliderCard.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = sliderCard

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Core.Config.Theme.AmethystBorder
    cardStroke.Thickness = 1.0
    cardStroke.Transparency = 0.4
    cardStroke.Parent = sliderCard

    local label = Instance.new("TextLabel")
    label.Text = labelText
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.TextColor3 = Core.Config.Theme.TextDark
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 12, 0, 6)
    label.Size = UDim2.new(0.7, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Parent = sliderCard

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Text = tostring(Core.State[stateKey])
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 10
    valueLabel.TextColor3 = Core.Config.Theme.TextDark
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Position = UDim2.new(0.7, 0, 0, 6)
    valueLabel.Size = UDim2.new(0.3, -12, 0, 18)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Parent = sliderCard

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -24, 0, 8)
    sliderBg.Position = UDim2.new(0, 12, 0, 32)
    sliderBg.BackgroundColor3 = Core.Config.Theme.ToggleOff
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = sliderCard

    local sliderBgCorner = Instance.new("UICorner")
    sliderBgCorner.CornerRadius = UDim.new(1, 0)
    sliderBgCorner.Parent = sliderBg

    local sliderFill = Instance.new("Frame")
    local initialRatio = math.clamp((Core.State[stateKey] - minVal) / (maxVal - minVal), 0, 1)
    sliderFill.Size = UDim2.new(initialRatio, 0, 1, 0)
    sliderFill.BackgroundColor3 = Core.Config.Theme.ToggleOn
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg

    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(1, 0)
    sliderFillCorner.Parent = sliderFill

    local handle = Instance.new("TextButton")
    handle.Text = ""
    handle.Size = UDim2.new(0, 16, 0, 16)
    handle.AnchorPoint = Vector2.new(0.5, 0.5)
    handle.Position = UDim2.new(initialRatio, 0, 0.5, 0)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.BorderSizePixel = 0
    handle.Parent = sliderBg

    local handleCorner = Instance.new("UICorner")
    handleCorner.CornerRadius = UDim.new(1, 0)
    handleCorner.Parent = handle

    local dragging = false
    local function updateInput(input)
        local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local calculatedVal = math.floor(minVal + ((maxVal - minVal) * pos))
        Core.State[stateKey] = calculatedVal
        sliderFill.Size = UDim2.new(pos, 0, 1, 0)
        handle.Position = UDim2.new(pos, 0, 0.5, 0)
        valueLabel.Text = tostring(calculatedVal)
        if onValueChanged then onValueChanged(calculatedVal) end
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateInput(input)
        end
    end)

    Core.Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    Core.Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateInput(input)
        end
    end)

    return sliderCard
end

function UI.CreateToggleSwitchRow(parent, labelText, stateKey, callback, sliderCardRef)
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
    cardStroke.Color = Core.Config.Theme.AmethystBorder
    cardStroke.Thickness = 1.2
    cardStroke.Transparency = 0.3
    cardStroke.Parent = card

    local label = Instance.new("TextLabel")
    label.Text = labelText
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextColor3 = Core.Config.Theme.TextDark
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(0.62, 0, 1, 0)
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
        
        if sliderCardRef then
            sliderCardRef.Visible = active
        end

        if callback then callback(active) end
    end)

    return card
end

function UI.BuildMobileUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VoryzenDynamicGui"
    ScreenGui.ResetOnSpawn = false

    pcall(function() ScreenGui.Parent = Core.Services.CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = Core.LocalPlayer:WaitForChild("PlayerGui") end

    -- Main Window Panel
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
    MainStroke.Color = Core.Config.Theme.AmethystBorder
    MainStroke.Thickness = 1.5
    MainStroke.Transparency = 0.2
    MainStroke.Parent = Main

    -- Sticky Header Section
    local Header = Instance.new("Frame")
    Header.Name = "StickyHeader"
    Header.Size = UDim2.new(1, -20, 0, 36)
    Header.Position = UDim2.new(0, 10, 0, 10)
    Header.BackgroundTransparency = 1
    Header.ZIndex = 5
    Header.Parent = Main

    -- Close Button
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
    CloseBtn.ZIndex = 6
    CloseBtn.Parent = Header

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(1, 0)
    CloseCorner.Parent = CloseBtn

    -- Header Title
    local HeaderTitle = Instance.new("TextLabel")
    HeaderTitle.Text = string.format("<b>%s</b> — <i>%s</i>", Core.Config.HubName, Core.Config.GameName)
    HeaderTitle.RichText = true
    HeaderTitle.Font = Enum.Font.Gotham
    HeaderTitle.TextSize = 10
    HeaderTitle.TextColor3 = Core.Config.Theme.TextDark
    HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    HeaderTitle.Position = UDim2.new(0, 4, 0, 0)
    HeaderTitle.Size = UDim2.new(0.78, 0, 1, 0)
    HeaderTitle.BackgroundTransparency = 1
    HeaderTitle.ZIndex = 5
    HeaderTitle.Parent = Header

    -- Master Floating Capsule Button Widget
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

    CloseBtn.MouseButton1Click:Connect(function()
        Main.Visible = false
        OpenBtn.Visible = true
    end)

    OpenBtn.MouseButton1Click:Connect(function()
        Main.Visible = true
        OpenBtn.Visible = false
    end)

    -- Scrolling Frame Container
    local ScrollContainer = Instance.new("ScrollingFrame")
    ScrollContainer.Name = "FeaturesScrollContainer"
    ScrollContainer.Size = UDim2.new(1, -20, 1, -56)
    ScrollContainer.Position = UDim2.new(0, 10, 0, 50)
    ScrollContainer.BackgroundTransparency = 1
    ScrollContainer.BorderSizePixel = 0
    ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 360)
    ScrollContainer.ScrollBarThickness = 3
    ScrollContainer.Parent = Main

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = ScrollContainer

    -- Instantiate Sliders first so toggles can reference them
    local speedSlider = UI.CreateSliderRow(ScrollContainer, "Adjust Speed Value", 16, 120, "SpeedValue", function(val)
        Core.State.SpeedValue = val
        Exploits.UpdateSpeed()
    end)

    local jumpSlider = UI.CreateSliderRow(ScrollContainer, "Adjust Jump Power", 50, 250, "JumpPowerValue", function(val)
        Core.State.JumpPowerValue = val
        Exploits.UpdateJumpPower()
    end)

    -- Instantiate Toggles with reference to their respective dynamic sliders
    UI.CreateToggleSwitchRow(ScrollContainer, "Infinite Jump", "InfiniteJump")
    UI.CreateToggleSwitchRow(ScrollContainer, "Noclip", "Noclip")
    UI.CreateToggleSwitchRow(ScrollContainer, "Speed Boost", "SpeedBoost", Exploits.ToggleSpeed, speedSlider)
    UI.CreateToggleSwitchRow(ScrollContainer, "Super Jump Power", "JumpPowerBoost", Exploits.ToggleJumpPower, jumpSlider)

    return ScreenGui
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
function Core.Init()
    UI.BuildMobileUI()
    Exploits.InitInfiniteJump()
    Exploits.InitNoclip()
    print("[" .. Core.Config.HubName .. " — " .. Core.Config.GameName .. "] Initialized Successfully.")
end

Core.Init()
