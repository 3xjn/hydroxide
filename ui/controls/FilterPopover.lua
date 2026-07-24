local UserInput = game:GetService("UserInputService")
local Theme = import("ui/theme")
local session = getgenv().oh

local FilterPopover = {}

local optionNames = {
    "ShowGame",
    "ShowRoblox",
    "ShowExecutor",
}

local function containsPoint(guiObject, point)
    local position = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize

    return point.X >= position.X
        and point.X <= position.X + size.X
        and point.Y >= position.Y
        and point.Y <= position.Y + size.Y
end

local function render(popover)
    local open = popover.Panel.Visible
    local filtered = false

    for _, name in ipairs(optionNames) do
        local option = popover.Options[name]
        local enabled = popover.Values[name] == true
        option.Checkmark.Text = enabled and "✓" or ""
        option.Indicator.BackgroundColor3 = enabled and Theme.Colors.AccentSurface or Theme.Colors.Elevated
        filtered = filtered or not enabled
    end

    popover.Filter.Icon.ImageColor3 = (filtered or open) and Theme.Colors.Accent or Theme.Colors.SecondaryText
    popover.Filter.BackgroundColor3 = open and Theme.Colors.Hover or Theme.Colors.Elevated
end

function FilterPopover.new(query, eventName)
    local popover = {}
    local filter = query.Filter
    local panel = query.FilterPopover

    popover.Values = {}
    popover.Options = {}
    popover.Filter = filter
    popover.Panel = panel
    popover.SetCallback = FilterPopover.setCallback
    popover.SetValues = FilterPopover.setValues

    for _, name in ipairs(optionNames) do
        local button = panel[name]
        local option = {
            Button = button,
            Indicator = button.Indicator,
            Checkmark = button.Indicator.Checkmark,
        }
        popover.Options[name] = option

        button.MouseEnter:Connect(function()
            button.BackgroundTransparency = 0
        end)

        button.MouseLeave:Connect(function()
            button.BackgroundTransparency = 1
        end)

        button.MouseButton1Click:Connect(function()
            local values = {}
            for key, value in pairs(popover.Values) do
                values[key] = value
            end
            values[name] = not values[name]
            popover:SetValues(values)
        end)
    end

    filter.MouseButton1Click:Connect(function()
        panel.Visible = not panel.Visible
        render(popover)
    end)

    filter.MouseEnter:Connect(function()
        filter.BackgroundColor3 = Theme.Colors.Hover
    end)

    filter.MouseLeave:Connect(function()
        filter.BackgroundColor3 = panel.Visible and Theme.Colors.Hover or Theme.Colors.Elevated
    end)

    session.Events[eventName] = UserInput.InputEnded:Connect(function(input)
        if not panel.Visible or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        local point = Vector2.new(input.Position.X, input.Position.Y)
        if not containsPoint(filter, point) and not containsPoint(panel, point) then
            panel.Visible = false
            render(popover)
        end
    end)

    render(popover)
    return popover
end

function FilterPopover.setCallback(popover, callback)
    popover.Callback = callback
end

function FilterPopover.setValues(popover, values, notify)
    popover.Values = {
        ShowExecutor = values.ShowExecutor == true,
        ShowGame = values.ShowGame ~= false,
        ShowRoblox = values.ShowRoblox == true,
    }
    render(popover)

    if notify ~= false and popover.Callback then
        popover.Callback(popover.Values)
    end
end

return FilterPopover
