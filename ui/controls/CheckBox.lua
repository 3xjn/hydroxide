local CheckBox = {}
local Theme = import("ui/theme")

local function render(checkBox)
    local toggle = checkBox.Toggle
    local enabled = checkBox.Enabled
    checkBox.Label.Text = enabled and '✓' or ''

    local selection = toggle:FindFirstChild("Selection")
    local icon = toggle:FindFirstChild("Icon")
    if selection and icon then
        selection.Visible = enabled
        toggle.BackgroundColor3 = enabled and Theme.Colors.AccentSurface or Theme.Colors.Elevated
        icon.ImageColor3 = enabled and Theme.Colors.Accent or Theme.Colors.MutedText
    end
end

function CheckBox.new(instance)
    local checkBox = {}
    local toggle = instance:FindFirstChild("Toggle") or instance
    local label = toggle.Label

    toggle.MouseButton1Click:Connect(function()
        checkBox.Enabled = not checkBox.Enabled

        if checkBox.Callback then
            checkBox.Callback(checkBox.Enabled)
        end

        render(checkBox)
    end)

    checkBox.Enabled = label.Text == '✓'
    checkBox.Toggle = toggle
    checkBox.Label = label
    checkBox.Instance = instance
    checkBox.SetCallback = CheckBox.setCallback
    render(checkBox)

    return checkBox
end

function CheckBox.setCallback(checkBox, callback)
    checkBox.Callback = callback
end

return CheckBox
