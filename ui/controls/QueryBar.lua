local Prism = import("ui/prism")
local Theme = import("ui/theme")

local QueryBar = {}
local mounted = {}

local function copyFilter(values)
    return {
        ShowExecutor = values and values.ShowExecutor == true,
        ShowGame = not values or values.ShowGame ~= false,
        ShowRoblox = values and values.ShowRoblox == true,
    }
end

local function create(className, name, parent, properties)
    local instance = Instance.new(className)
    instance.Name = name
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    instance.Parent = parent
    return instance
end

local function addCorner(instance, radius)
    local corner = instance:FindFirstChild("HydroxideCorner")
    if not corner then
        corner = create("UICorner", "HydroxideCorner", instance)
    end
    corner.CornerRadius = UDim.new(0, radius or 5)
    return corner
end

local function addStroke(instance, color)
    local stroke = instance:FindFirstChild("HydroxideStroke")
    if not stroke then
        stroke = create("UIStroke", "HydroxideStroke", instance)
    end
    stroke.Color = color or Theme.Colors.Border
    stroke.Thickness = 1
    return stroke
end

local function addPadding(instance, left, right, top, bottom)
    return create("UIPadding", "Padding", instance, {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or left or 0)
    })
end

local function actionLabel(bar)
    if bar.ActionLabel then
        return bar.ActionLabel
    end
    if bar.Action == "inspect" then
        return "Inspect"
    end
    if bar.Action == "search" then
        return "Search"
    end
    return "Refresh"
end

local function findInput(host)
    local named = host:FindFirstChild("Search") or host:FindFirstChild("Query") or host:FindFirstChild("Path")
    if named and named:IsA("TextBox") then
        return named
    end
    return host:FindFirstChildWhichIsA("TextBox", true)
end

local function ensureLuauChrome(bar)
    local host = bar.Host
    local queryHeight = Theme.Layout.QueryHeight
    local hasFilter = bar.FilterValues ~= nil
    local hasAction = bar.Action ~= nil
    local textAction = bar.Action == "search" or bar.Action == "inspect"
    local reserved = 0
    if hasFilter then
        reserved = reserved + 44
    end
    if hasAction then
        reserved = reserved + (textAction and 104 or 44)
    elseif hasFilter then
        reserved = math.max(reserved, 44)
    end

    host.ZIndex = hasFilter and math.max(host.ZIndex, 70) or host.ZIndex

    local input = findInput(host)
    if not input then
        local inputName = textAction and (bar.Action == "inspect" and "Path" or "Query") or "Search"
        input = create("TextBox", inputName, host, {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, reserved > 0 and -reserved or 0, 0, queryHeight),
            BackgroundColor3 = Theme.Colors.Elevated,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Font = Enum.Font.Code,
            PlaceholderColor3 = Theme.Colors.MutedText,
            PlaceholderText = bar.Placeholder,
            Text = bar.Value,
            TextColor3 = Theme.Colors.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        addCorner(input, 5)
        addStroke(input)
        addPadding(input, 12, 12, 0, 0)
    else
        input.PlaceholderText = bar.Placeholder
        input.Text = bar.Value
    end
    bar.Input = input

    if hasAction then
        if textAction then
            local buttonName = bar.Action == "inspect" and "Inspect" or "Search"
            local button = host:FindFirstChild(buttonName) or host:FindFirstChild("Search")
            if not button or not (button:IsA("TextButton") or button:IsA("ImageButton")) then
                button = create("TextButton", buttonName, host, {
                    AutoButtonColor = false,
                    Position = UDim2.new(1, -92, 0, 0),
                    Size = UDim2.new(0, 92, 0, queryHeight),
                    BackgroundColor3 = Theme.Colors.AccentSurface,
                    BorderSizePixel = 0,
                    Font = Enum.Font.Gotham,
                    Text = actionLabel(bar),
                    TextColor3 = Theme.Colors.Accent,
                    TextSize = 14
                })
                addCorner(button, 5)
                addStroke(button)
            else
                if button:IsA("TextButton") then
                    button.Text = actionLabel(bar)
                end
            end
            bar.ActionButton = button
        else
            local refresh = host:FindFirstChild("Refresh")
            if not refresh then
                refresh = create("ImageButton", "Refresh", host, {
                    AutoButtonColor = false,
                    Position = UDim2.new(1, -36, 0, 0),
                    Size = UDim2.new(0, 36, 0, queryHeight),
                    BackgroundColor3 = Theme.Colors.Elevated,
                    BorderSizePixel = 0,
                    Image = ""
                })
                addCorner(refresh, 5)
                addStroke(refresh)
                create("ImageLabel", "Icon", refresh, {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(0, 18, 0, 18),
                    ImageColor3 = Theme.Colors.SecondaryText,
                    ScaleType = Enum.ScaleType.Fit
                })
            end
            bar.ActionButton = refresh
        end
    end

    if hasFilter then
        local filter = host:FindFirstChild("Filter")
        if not filter then
            local filterOffset = hasAction and -80 or -36
            filter = create("ImageButton", "Filter", host, {
                AutoButtonColor = false,
                Position = UDim2.new(1, filterOffset, 0, 0),
                Size = UDim2.new(0, Theme.Layout.ControlTargetSize, 0, queryHeight),
                BackgroundColor3 = Theme.Colors.Elevated,
                BorderSizePixel = 0,
                Image = ""
            })
            addCorner(filter, 5)
            addStroke(filter)
            create("ImageLabel", "Icon", filter, {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0, 18, 0, 18),
                ImageColor3 = Theme.Colors.SecondaryText,
                ScaleType = Enum.ScaleType.Fit
            })
        end

        local popover = host:FindFirstChild("FilterPopover")
        if not popover then
            popover = create("Frame", "FilterPopover", host, {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 1, 8),
                Size = UDim2.new(0, Theme.Layout.FilterPopoverWidth, 0, 148),
                BackgroundColor3 = Theme.Colors.Elevated,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = Theme.Layout.FilterPopoverZIndex
            })
            addCorner(popover, 5)
            addStroke(popover)

            local function filterOption(name, text, layoutOrder)
                local option = create("TextButton", name, popover, {
                    AutoButtonColor = false,
                    Position = UDim2.new(0, 8, 0, 8 + ((layoutOrder - 1) * 44)),
                    Size = UDim2.new(1, -16, 0, Theme.Layout.ControlTargetSize),
                    BackgroundColor3 = Theme.Colors.Hover,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Font = Enum.Font.Gotham,
                    Text = "",
                    TextSize = 14,
                    ZIndex = Theme.Layout.FilterPopoverZIndex + 1
                })
                addCorner(option, 5)
                addStroke(option)
                option.HydroxideStroke.Transparency = 1
                local indicator = create("Frame", "Indicator", option, {
                    Position = UDim2.new(0, 8, 0.5, -10),
                    Size = UDim2.new(0, 20, 0, 20),
                    BackgroundColor3 = Theme.Colors.Elevated,
                    BorderSizePixel = 0,
                    ZIndex = Theme.Layout.FilterPopoverZIndex + 2
                })
                addCorner(indicator, 4)
                addStroke(indicator)
                create("TextLabel", "Checkmark", indicator, {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = "",
                    TextColor3 = Theme.Colors.Accent,
                    TextSize = 14,
                    ZIndex = Theme.Layout.FilterPopoverZIndex + 3
                })
                create("TextLabel", "Label", option, {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 40, 0, 0),
                    Size = UDim2.new(1, -48, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextColor3 = Theme.Colors.SecondaryText,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = Theme.Layout.FilterPopoverZIndex + 2
                })
            end

            filterOption("ShowGame", "Show game code", 1)
            filterOption("ShowRoblox", "Show Roblox code", 2)
            filterOption("ShowExecutor", "Show executor code", 3)
        end
    end
end

local function sync(bar)
    if bar.Handle then
        bar.Handle.update({
            kind = "queryBar",
            placeholder = bar.Placeholder,
            value = bar.Value,
            action = bar.Action,
            actionLabel = bar.ActionLabel,
            filter = bar.FilterValues,
            onChange = function(value)
                if bar.Value == value then
                    return
                end
                bar.Value = value
                if bar.Changed then
                    bar.Changed(value)
                end
                sync(bar)
            end,
            onSubmit = function(value)
                bar.Value = value
                if bar.Submitted then
                    bar.Submitted(value)
                end
            end,
            onAction = function(value)
                bar.Value = value
                if bar.Actioned then
                    bar.Actioned(value)
                end
            end,
            onFilterChange = function(values)
                bar.FilterValues = copyFilter(values)
                if bar.Filter.Callback then
                    bar.Filter.Callback(bar.FilterValues)
                end
                sync(bar)
            end,
        })
        return
    end

    if bar.Input and bar.Input.Text ~= bar.Value then
        bar.Input.Text = bar.Value or ""
    end
end

local function mountLuau(bar)
    ensureLuauChrome(bar)

    bar.Input:GetPropertyChangedSignal("Text"):Connect(function()
        if bar.Value == bar.Input.Text then
            return
        end
        bar.Value = bar.Input.Text
        if bar.Changed then
            bar.Changed(bar.Value)
        end
    end)

    bar.Input.FocusLost:Connect(function(enterPressed)
        bar.Value = bar.Input.Text
        if enterPressed and bar.Submitted then
            bar.Submitted(bar.Value)
        end
    end)

    if bar.ActionButton then
        bar.ActionButton.MouseButton1Click:Connect(function()
            bar.Value = bar.Input.Text
            if bar.Actioned then
                bar.Actioned(bar.Value)
            end
        end)
    end
end

function QueryBar.new(host, spec)
    spec = spec or {}
    if mounted[host] then
        return mounted[host]
    end

    local action = spec.action
    if action == false then
        action = nil
    elseif action == nil then
        action = host:GetAttribute("Action")
    end
    local bar = {
        Host = host,
        Placeholder = spec.placeholder or host:GetAttribute("Placeholder") or "",
        Value = spec.value or "",
        Action = action,
        ActionLabel = spec.actionLabel or host:GetAttribute("ActionLabel"),
        FilterValues = spec.filter and copyFilter(type(spec.filter) == "table" and spec.filter or nil) or nil,
        SetCallback = QueryBar.setFilterCallback,
        SetValues = QueryBar.setFilterValues,
        GetText = QueryBar.getText,
        SetText = QueryBar.setText,
        OnChange = QueryBar.onChange,
        OnSubmit = QueryBar.onSubmit,
        OnAction = QueryBar.onAction,
        SetFilterCallback = QueryBar.setFilterCallback,
        SetFilterValues = QueryBar.setFilterValues,
    }

    if Prism.available() then
        if bar.FilterValues then
            bar.Filter = bar
        end

        bar.Handle = Prism.mount(host, {
            kind = "queryBar",
            placeholder = bar.Placeholder,
            value = bar.Value,
            action = bar.Action,
            actionLabel = bar.ActionLabel,
            filter = bar.FilterValues,
        })
        sync(bar)
    else
        mountLuau(bar)
    end

    mounted[host] = bar
    return bar
end

function QueryBar.getText(bar)
    if bar.Input then
        bar.Value = bar.Input.Text
    end
    return bar.Value
end

function QueryBar.setText(bar, value)
    bar.Value = value or ""
    sync(bar)
end

function QueryBar.onChange(bar, callback)
    bar.Changed = callback
    if bar.Handle then
        sync(bar)
    end
end

function QueryBar.onSubmit(bar, callback)
    bar.Submitted = callback
    if bar.Handle then
        sync(bar)
    end
end

function QueryBar.onAction(bar, callback)
    bar.Actioned = callback
    if bar.Handle then
        sync(bar)
    end
end

function QueryBar.setFilterCallback(bar, callback)
    bar.Filter.Callback = callback
end

function QueryBar.setFilterValues(bar, values, notify)
    bar.FilterValues = copyFilter(values)
    if bar.Handle then
        sync(bar)
    end
    if notify ~= false and bar.Filter and bar.Filter.Callback then
        bar.Filter.Callback(bar.FilterValues)
    end
end

return QueryBar
