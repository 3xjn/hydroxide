local Theme = {}

Theme.Colors = {
    Canvas = Color3.fromRGB(11, 14, 18),
    Rail = Color3.fromRGB(14, 18, 23),
    Panel = Color3.fromRGB(17, 23, 29),
    Elevated = Color3.fromRGB(21, 28, 35),
    Hover = Color3.fromRGB(25, 33, 41),
    Border = Color3.fromRGB(41, 50, 58),
    Text = Color3.fromRGB(243, 246, 247),
    SecondaryText = Color3.fromRGB(167, 176, 184),
    MutedText = Color3.fromRGB(111, 121, 130),
    Accent = Color3.fromRGB(98, 214, 173),
    AccentSurface = Color3.fromRGB(23, 53, 45),
    Danger = Color3.fromRGB(230, 107, 110),
    Warning = Color3.fromRGB(234, 179, 61)
}

Theme.Layout = {
    OuterMargin = 16,
    DefaultWindowSize = Vector2.new(1120, 680),
    MinimumWindowSize = Vector2.new(720, 420),
    TitleBarHeight = 44,
    RailWidth = 52,
    StatusBarHeight = 24,
    WorkspaceInset = 12,
    PaneGap = 12,
    ExplorerMinWidth = 224,
    ExplorerMaxWidth = 272,
    PagePadding = 12,
    QueryHeight = 36,
    TabTargetSize = 40,
    TabIconSize = 22,
    TabGap = 6,
    LauncherSize = 36,
    LauncherIconSize = 18,
    ControlTargetSize = 36
}

Theme.Motion = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function addCorner(instance, radius)
    local corner = instance:FindFirstChild("HydroxideCorner")
    if not corner then
        corner = Instance.new("UICorner")
        corner.Name = "HydroxideCorner"
        corner.Parent = instance
    end

    corner.CornerRadius = UDim.new(0, radius)
end

local function addStroke(instance, color)
    local stroke = instance:FindFirstChild("HydroxideStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Name = "HydroxideStroke"
        stroke.Thickness = 1
        stroke.Parent = instance
    end

    stroke.Color = color
    stroke.Transparency = 0
end

local function styleText(instance)
    instance.Font = Enum.Font.Gotham
    instance.TextStrokeTransparency = 1

    if instance:IsA("TextBox") then
        instance.BackgroundColor3 = Theme.Colors.Elevated
        instance.PlaceholderColor3 = Theme.Colors.MutedText
        instance.TextSize = math.max(instance.TextSize, 14)
        addCorner(instance, 5)
        addStroke(instance, Theme.Colors.Border)
    end
end

local function styleDescendant(instance)
    if instance:IsA("GuiObject") then
        instance.BorderSizePixel = 0
    end

    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        styleText(instance)
    elseif instance:IsA("ScrollingFrame") then
        instance.ScrollBarImageColor3 = Theme.Colors.MutedText
        instance.ScrollBarThickness = 4
    elseif instance:IsA("UIStroke") and instance.Name ~= "HydroxideStroke" then
        instance.Color = Theme.Colors.Border
    end
end

local function styleSurface(instance, color, radius)
    if not instance or not instance:IsA("GuiObject") then
        return
    end

    instance.BackgroundColor3 = color
    instance.BorderSizePixel = 0

    if radius then
        addCorner(instance, radius)
    end
end

local function findHomeLogo(home)
    local namedLogo = home:FindFirstChild("Logo", true)
    if namedLogo and (namedLogo:IsA("ImageLabel") or namedLogo:IsA("ImageButton")) then
        return namedLogo
    end

    local largest
    local largestArea = 0
    for _index, descendant in pairs(home:GetDescendants()) do
        if descendant:IsA("ImageLabel") then
            local area = descendant.AbsoluteSize.X * descendant.AbsoluteSize.Y
            if area > largestArea then
                largest = descendant
                largestArea = area
            end
        end
    end

    return largest
end

function Theme.Apply(interface, assets)
    local base = interface.Base
    local body = base.Body
    local pages = body.Pages
    local tabs = base.Tabs

    styleSurface(base, Theme.Colors.Canvas, 8)
    addStroke(base, Theme.Colors.Border)
    styleSurface(base.Drag, Theme.Colors.Rail)
    styleSurface(base.Status, Theme.Colors.Rail)
    styleSurface(body, Theme.Colors.Canvas)
    styleSurface(tabs, Theme.Colors.Rail)

    for _index, page in pairs(pages:GetChildren()) do
        if page:IsA("GuiObject") then
            styleSurface(page, Theme.Colors.Panel, 6)
            addStroke(page, Theme.Colors.Border)
        end
    end

    for _index, descendant in pairs(interface:GetDescendants()) do
        styleDescendant(descendant)
        if descendant:IsA("ImageLabel") and descendant.Name == "Icon" then
            assets.ApplyGlyph(descendant, descendant.Parent.Name)
        end
    end

    local container = tabs.Container
    for _index, tab in pairs(container:GetChildren()) do
        if tab:IsA("ImageButton") and assets.Icons[tab.Name] then
            assets.ApplyIcon(tab.Icon, tab.Name)
            tab.BackgroundColor3 = Theme.Colors.Rail
            tab.Icon.ImageColor3 = Theme.Colors.MutedText
        end
    end

    local homeLogo = findHomeLogo(pages.Home)
    assert(homeLogo, "Hydroxide could not find the Home Page logo image")
    assets.ApplyLogo(homeLogo)
    assets.ApplyLogo(base.Drag.Brand.Logo)
    assets.ApplyLogo(interface.Open.Icon)

    oh.Events.ThemeDescendant = interface.DescendantAdded:Connect(styleDescendant)
end

return Theme
