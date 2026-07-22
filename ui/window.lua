local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Theme = import("ui/theme")

local Window = {}

local margin = 16
local defaultSize = Vector2.new(1120, 680)
local minimumSize = Vector2.new(720, 420)

local function createControl(parent, name, glyph, rightOffset)
    local control = Instance.new("TextButton")
    control.Name = name
    control.AnchorPoint = Vector2.new(1, 0.5)
    control.Position = UDim2.new(1, rightOffset, 0.5, 0)
    control.Size = UDim2.new(0, 36, 0, 36)
    control.BackgroundTransparency = 1
    control.AutoButtonColor = false
    control.Font = Enum.Font.Gotham
    control.Text = glyph
    control.TextColor3 = Theme.Colors.SecondaryText
    control.TextSize = 18
    control.ZIndex = 20
    control.Parent = parent
    return control
end

local function styleExistingControl(control, glyph, rightOffset)
    control.AnchorPoint = Vector2.new(1, 0.5)
    control.Position = UDim2.new(1, rightOffset, 0.5, 0)
    control.Size = UDim2.new(0, 36, 0, 36)
    control.BackgroundTransparency = 1

    if control:IsA("ImageButton") then
        control.ImageTransparency = 1
        local label = Instance.new("TextLabel")
        label.Name = "Glyph"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.Text = glyph
        label.TextColor3 = Theme.Colors.SecondaryText
        label.TextSize = 18
        label.ZIndex = control.ZIndex + 1
        label.Parent = control
    else
        control.Text = glyph
        control.TextColor3 = Theme.Colors.SecondaryText
        control.TextSize = 18
    end
end

function Window.Attach(interface)
    local camera = workspace.CurrentCamera
    assert(camera, "Hydroxide could not access the current camera viewport")

    local base = interface.Base
    local drag = base.Drag
    local collapse = drag.Collapse
    local open = interface.Open
    local maximized = false
    local collapsed = false
    local dragging = false
    local resizing = false
    local dragStart
    local dragPosition
    local resizeStart
    local resizeSize
    local restorePosition
    local restoreSize
    local collapsedPosition
    local transitionId = 0

    local function viewportSize()
        return camera.ViewportSize
    end

    local function availableSize()
        local viewport = viewportSize()
        return Vector2.new(math.max(320, viewport.X - margin * 2), math.max(240, viewport.Y - margin * 2))
    end

    local function clampSize(size)
        local available = availableSize()
        local minWidth = math.min(minimumSize.X, available.X)
        local minHeight = math.min(minimumSize.Y, available.Y)
        return Vector2.new(
            math.max(minWidth, math.min(size.X, available.X)),
            math.max(minHeight, math.min(size.Y, available.Y))
        )
    end

    local function center(size)
        local viewport = viewportSize()
        base.Position = UDim2.new(0, math.floor((viewport.X - size.X) / 2), 0, math.floor((viewport.Y - size.Y) / 2))
    end

    local function updateWorkspace()
        local body = base.Body
        local workspaceWidth = math.max(0, base.AbsoluteSize.X - base.Tabs.AbsoluteSize.X)
        local explorerWidth = math.max(200, math.min(288, math.floor(workspaceWidth * 0.26 + 0.5)))
        body.Pages.Size = UDim2.new(1, -explorerWidth - 12, 1, 0)
        body.Explorer.Position = UDim2.new(1, -explorerWidth, 0, 0)
        body.Explorer.Size = UDim2.new(0, explorerWidth, 1, 0)
    end

    local function fitInitialWindow()
        local size = clampSize(defaultSize)
        base.Size = UDim2.new(0, size.X, 0, size.Y)
        center(size)
        updateWorkspace()
    end

    styleExistingControl(collapse, "×", -4)
    open.Position = UDim2.new(0.5, 0, 0, -68)
    open.Size = UDim2.new(0, 52, 0, 52)
    open.Visible = false
    local maximize = createControl(drag, "Maximize", "□", -40)

    local resizeHandle = createControl(base, "Resize", "◢", -2)
    resizeHandle.AnchorPoint = Vector2.new(1, 1)
    resizeHandle.Position = UDim2.new(1, -2, 1, -2)
    resizeHandle.Size = UDim2.new(0, 28, 0, 28)
    resizeHandle.TextColor3 = Theme.Colors.MutedText
    resizeHandle.TextSize = 14

    local function setMaximized(value)
        if value == maximized then
            return
        end

        if value then
            restorePosition = base.Position
            restoreSize = base.Size
            local available = availableSize()
            base.Position = UDim2.new(0, margin, 0, margin)
            base.Size = UDim2.new(0, available.X, 0, available.Y)
            maximize.Text = "❐"
            resizeHandle.Visible = false
        else
            base.Position = restorePosition
            base.Size = restoreSize
            maximize.Text = "□"
            resizeHandle.Visible = true
        end

        maximized = value
        updateWorkspace()
    end

    fitInitialWindow()

    oh.Events.WindowDragStart = drag.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not maximized then
            dragging = true
            dragStart = input.Position
            dragPosition = base.Position

            if oh.Events.WindowDragEnd then
                oh.Events.WindowDragEnd:Disconnect()
            end

            oh.Events.WindowDragEnd = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    oh.Events.WindowDragEnd:Disconnect()
                    oh.Events.WindowDragEnd = nil
                end
            end)
        end
    end)

    oh.Events.WindowResizeStart = resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not maximized then
            resizing = true
            resizeStart = input.Position
            resizeSize = base.AbsoluteSize

            if oh.Events.WindowResizeEnd then
                oh.Events.WindowResizeEnd:Disconnect()
            end

            oh.Events.WindowResizeEnd = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    oh.Events.WindowResizeEnd:Disconnect()
                    oh.Events.WindowResizeEnd = nil
                end
            end)
        end
    end)

    oh.Events.WindowInput = UserInput.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        if dragging then
            local viewport = viewportSize()
            local delta = input.Position - dragStart
            local x = math.max(-base.AbsoluteSize.X + 96, math.min(dragPosition.X.Offset + delta.X, viewport.X - 96))
            local y = math.max(0, math.min(dragPosition.Y.Offset + delta.Y, viewport.Y - 48))
            base.Position = UDim2.new(0, x, 0, y)
        elseif resizing then
            local delta = input.Position - resizeStart
            local size = clampSize(resizeSize + Vector2.new(delta.X, delta.Y))
            base.Size = UDim2.new(0, size.X, 0, size.Y)
            updateWorkspace()
        end
    end)

    oh.Events.WindowMaximize = maximize.MouseButton1Click:Connect(function()
        setMaximized(not maximized)
    end)

    oh.Events.WindowCollapse = collapse.MouseButton1Click:Connect(function()
        if collapsed then
            return
        end

        collapsed = true
        collapsedPosition = base.Position
        transitionId = transitionId + 1
        local thisTransition = transitionId
        local hideWindow = TweenService:Create(base, Theme.Motion, {
            Position = UDim2.new(0, base.Position.X.Offset, 0, -base.AbsoluteSize.Y - margin)
        })
        local showOpen = TweenService:Create(open, Theme.Motion, {
            Position = UDim2.new(0.5, 0, 0, margin)
        })

        open.Visible = true
        hideWindow:Play()
        showOpen:Play()
        hideWindow.Completed:Connect(function()
            if collapsed and transitionId == thisTransition then
                base.Visible = false
            end
        end)
    end)

    oh.Events.WindowOpen = open.MouseButton1Click:Connect(function()
        if not collapsed then
            return
        end

        collapsed = false
        transitionId = transitionId + 1
        local thisTransition = transitionId
        local destination = (maximized and UDim2.new(0, margin, 0, margin)) or collapsedPosition
        local hideOpen = TweenService:Create(open, Theme.Motion, {
            Position = UDim2.new(0.5, 0, 0, -68)
        })
        local showWindow = TweenService:Create(base, Theme.Motion, { Position = destination })

        base.Visible = true
        hideOpen:Play()
        showWindow:Play()
        hideOpen.Completed:Connect(function()
            if not collapsed and transitionId == thisTransition then
                open.Visible = false
            end
        end)
    end)

    oh.Events.WindowViewport = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if maximized then
            local available = availableSize()
            base.Position = UDim2.new(0, margin, 0, margin)
            base.Size = UDim2.new(0, available.X, 0, available.Y)
        else
            local size = clampSize(base.AbsoluteSize)
            base.Size = UDim2.new(0, size.X, 0, size.Y)
        end
        updateWorkspace()
    end)
end

return Window
