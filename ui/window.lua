-- TODO(prism-window): Replace this temporary chrome host with Prism Window
-- (title bar, content slot, optional rail, drag, resize, collapse, maximize;
-- close only if onClose is passed). Do not expand this module. Do not compose
-- Draggable+Box chrome. Hydroxide must consume Window from @prism when it
-- ships on master and then delete this file.

local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Theme = import("ui/theme")
local Geometry = import("ui/window_geometry")
local VisualAssets = import("ui/assets")

local Window = {}

local layout = Theme.Layout
local margin = layout.OuterMargin
local defaultSize = layout.DefaultWindowSize
local minimumSize = layout.MinimumWindowSize

local function addControlCorner(control)
    local corner = control:FindFirstChild("HydroxideCorner")
    if not corner then
        corner = Instance.new("UICorner")
        corner.Name = "HydroxideCorner"
        corner.Parent = control
    end
    corner.CornerRadius = UDim.new(0, 5)
end

local function createControl(parent, name, iconName, rightOffset)
    local control = Instance.new("ImageButton")
    control.Name = name
    control.AnchorPoint = Vector2.new(1, 0.5)
    control.Position = UDim2.new(1, rightOffset, 0.5, 0)
    control.Size = UDim2.new(0, layout.ControlTargetSize, 0, layout.ControlTargetSize)
    control.BackgroundTransparency = 1
    control.AutoButtonColor = false
    control.ImageTransparency = 1
    control.ZIndex = 20
    control.Parent = parent
    addControlCorner(control)

    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.Size = UDim2.new(0, 14, 0, 14)
    icon.BackgroundTransparency = 1
    icon.ImageColor3 = Theme.Colors.SecondaryText
    icon.ZIndex = control.ZIndex + 1
    icon.Parent = control
    VisualAssets.ApplyWindowIcon(icon, iconName)
    return control
end

local function styleExistingControl(control, iconName, rightOffset)
    control.AnchorPoint = Vector2.new(1, 0.5)
    control.Position = UDim2.new(1, rightOffset, 0.5, 0)
    control.Size = UDim2.new(0, layout.ControlTargetSize, 0, layout.ControlTargetSize)
    control.BackgroundTransparency = 1
    addControlCorner(control)

    local stroke = control:FindFirstChild("HydroxideStroke")
    if stroke then
        stroke.Transparency = 1
    end

    control.ImageTransparency = 1
    local icon = control:FindFirstChild("Icon")
    assert(icon and icon:IsA("ImageLabel"), control.Name .. " must contain an Icon ImageLabel")
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.Size = UDim2.new(0, 14, 0, 14)
    icon.BackgroundTransparency = 1
    icon.ImageColor3 = Theme.Colors.SecondaryText
    icon.ZIndex = control.ZIndex + 1
    VisualAssets.ApplyWindowIcon(icon, iconName)
end

local function setControlHover(control, hovered, destructive)
    control.BackgroundColor3 = Theme.Colors.Hover
    control.BackgroundTransparency = hovered and 0 or 1

    local icon = control:FindFirstChild("Icon")
    if icon then
        icon.ImageColor3 = hovered and (destructive and Theme.Colors.Danger or Theme.Colors.Text) or Theme.Colors.SecondaryText
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

    local function viewportSize()
        return camera.ViewportSize
    end

    local function clampSize(size)
        local viewport = viewportSize()
        local width, height = Geometry.ClampSize(
            size.X,
            size.Y,
            viewport.X,
            viewport.Y,
            margin,
            minimumSize.X,
            minimumSize.Y
        )
        return Vector2.new(width, height)
    end

    local function clampRestoredPosition(position, size)
        local viewport = viewportSize()
        local x, y = Geometry.ClampRestoredPosition(
            position.X.Offset,
            position.Y.Offset,
            size.X,
            size.Y,
            viewport.X,
            viewport.Y,
            margin
        )
        return UDim2.new(0, x, 0, y)
    end

    local function center(size)
        local viewport = viewportSize()
        base.Position = UDim2.new(0, math.floor((viewport.X - size.X) / 2), 0, math.floor((viewport.Y - size.Y) / 2))
    end

    local function updateWorkspace()
        base.Body.Pages.Size = UDim2.new(1, 0, 1, 0)
    end

    local function fitInitialWindow()
        local size = clampSize(defaultSize)
        base.Size = UDim2.new(0, size.X, 0, size.Y)
        center(size)
        updateWorkspace()
    end

    local function setShellMaximized(value)
        local corner = base:FindFirstChild("HydroxideCorner")
        local stroke = base:FindFirstChild("HydroxideStroke")
        assert(corner and corner:IsA("UICorner"), "Hydroxide window must retain its shell corner")
        assert(stroke and stroke:IsA("UIStroke"), "Hydroxide window must retain its shell stroke")
        corner.CornerRadius = UDim.new(0, value and 0 or 8)
        drag.HydroxideCorner.CornerRadius = UDim.new(0, value and 0 or 8)
        stroke.Transparency = value and 1 or 0
    end

    styleExistingControl(collapse, "Collapse", -76)
    open.Position = UDim2.new(0.5, 0, 0, -layout.LauncherSize - layout.WorkspaceInset)
    open.Size = UDim2.new(0, layout.LauncherSize, 0, layout.LauncherSize)
    open.Visible = false
    local maximize = createControl(drag, "Maximize", "Maximize", -40)
    local exit = createControl(drag, "Exit", "Exit", -4)

    oh.Events.WindowCollapseEnter = collapse.MouseEnter:Connect(function()
        setControlHover(collapse, true)
    end)
    oh.Events.WindowCollapseLeave = collapse.MouseLeave:Connect(function()
        setControlHover(collapse, false)
    end)
    oh.Events.WindowMaximizeEnter = maximize.MouseEnter:Connect(function()
        setControlHover(maximize, true)
    end)
    oh.Events.WindowMaximizeLeave = maximize.MouseLeave:Connect(function()
        setControlHover(maximize, false)
    end)
    oh.Events.WindowExitEnter = exit.MouseEnter:Connect(function()
        setControlHover(exit, true, true)
    end)
    oh.Events.WindowExitLeave = exit.MouseLeave:Connect(function()
        setControlHover(exit, false, true)
    end)
    oh.Events.WindowOpenEnter = open.MouseEnter:Connect(function()
        open.BackgroundColor3 = Theme.Colors.Hover
    end)
    oh.Events.WindowOpenLeave = open.MouseLeave:Connect(function()
        open.BackgroundColor3 = Theme.Colors.Elevated
    end)

    local resizeHandle = Instance.new("Frame")
    resizeHandle.Name = "Resize"
    resizeHandle.AnchorPoint = Vector2.new(1, 1)
    resizeHandle.Position = UDim2.new(1, -4, 1, -4)
    resizeHandle.Size = UDim2.new(0, 28, 0, 28)
    resizeHandle.BackgroundTransparency = 1
    resizeHandle.BorderSizePixel = 0
    resizeHandle.Active = true
    resizeHandle.ZIndex = 20
    resizeHandle.Parent = base

    local resizeIcon = Instance.new("ImageLabel")
    resizeIcon.Name = "Icon"
    resizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    resizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    resizeIcon.Size = UDim2.new(0, 13, 0, 13)
    resizeIcon.BackgroundTransparency = 1
    resizeIcon.ImageColor3 = Theme.Colors.SecondaryText
    resizeIcon.ZIndex = 21
    resizeIcon.Parent = resizeHandle
    VisualAssets.ApplyWindowIcon(resizeIcon, "Resize")

    local resizeCursor = Instance.new("ImageLabel")
    resizeCursor.Name = "ResizeCursor"
    resizeCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    resizeCursor.Size = UDim2.new(0, 24, 0, 24)
    resizeCursor.BackgroundTransparency = 1
    resizeCursor.Image = VisualAssets.Load().ResizeCursor
    resizeCursor.Visible = false
    resizeCursor.ZIndex = 1000
    resizeCursor.Parent = interface

    local resizeHovered = false
    local previousCursorEnabled
    local function updateResizeGrip()
        resizeIcon.ImageColor3 = resizing and Theme.Colors.Accent or (resizeHovered and Theme.Colors.Text or Theme.Colors.SecondaryText)
    end
    local function positionResizeCursor(position)
        resizeCursor.Position = UDim2.new(0, position.X, 0, position.Y)
    end
    local function showResizeCursor()
        if maximized then
            return
        end

        if previousCursorEnabled == nil then
            previousCursorEnabled = UserInput.MouseIconEnabled
        end
        UserInput.MouseIconEnabled = false
        positionResizeCursor(UserInput:GetMouseLocation())
        resizeCursor.Visible = true
    end
    local function restoreResizeCursor()
        resizeCursor.Visible = false
        if previousCursorEnabled ~= nil then
            UserInput.MouseIconEnabled = previousCursorEnabled
            previousCursorEnabled = nil
        end
    end

    oh.Events.WindowResizeEnter = resizeHandle.MouseEnter:Connect(function()
        resizeHovered = true
        updateResizeGrip()
        showResizeCursor()
    end)
    oh.Events.WindowResizeLeave = resizeHandle.MouseLeave:Connect(function()
        resizeHovered = false
        updateResizeGrip()
        if not resizing then
            restoreResizeCursor()
        end
    end)
    oh.Events.WindowResizeFocusReleased = UserInput.WindowFocusReleased:Connect(function()
        resizeHovered = false
        resizing = false
        updateResizeGrip()
        restoreResizeCursor()
        if oh.Events.WindowResizeEnd then
            oh.Events.WindowResizeEnd:Disconnect()
            oh.Events.WindowResizeEnd = nil
        end
    end)
    oh.Events.WindowResizeCursorCleanup = { Disconnect = restoreResizeCursor }

    local function setMaximized(value)
        if value == maximized then
            return
        end

        if value then
            restoreResizeCursor()
            restorePosition = base.Position
            restoreSize = base.Size
            local viewport = viewportSize()
            base.Position = UDim2.new(0, 0, 0, 0)
            base.Size = UDim2.new(0, viewport.X, 0, viewport.Y)
            VisualAssets.ApplyWindowIcon(maximize.Icon, "Restore")
            setShellMaximized(true)
            resizeHandle.Visible = false
        else
            local restoredSize = clampSize(Vector2.new(restoreSize.X.Offset, restoreSize.Y.Offset))
            base.Position = clampRestoredPosition(restorePosition, restoredSize)
            base.Size = UDim2.new(0, restoredSize.X, 0, restoredSize.Y)
            VisualAssets.ApplyWindowIcon(maximize.Icon, "Maximize")
            setShellMaximized(false)
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
            updateResizeGrip()
            showResizeCursor()
            resizeStart = input.Position
            resizeSize = base.AbsoluteSize

            if oh.Events.WindowResizeEnd then
                oh.Events.WindowResizeEnd:Disconnect()
            end

            oh.Events.WindowResizeEnd = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    updateResizeGrip()
                    if not resizeHovered then
                        restoreResizeCursor()
                    end
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

        if resizeCursor.Visible then
            positionResizeCursor(UserInput:GetMouseLocation())
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

    oh.Events.WindowExit = exit.MouseButton1Click:Connect(function()
        restoreResizeCursor()
        oh.Exit()
    end)

    oh.Events.WindowCollapse = collapse.MouseButton1Click:Connect(function()
        if collapsed then
            return
        end

        collapsed = true
        restoreResizeCursor()
        collapsedPosition = base.Position
        base.Visible = false
        open.Position = UDim2.new(0.5, 0, 0, -layout.LauncherSize - layout.WorkspaceInset)
        local showOpen = TweenService:Create(open, Theme.Motion, {
            Position = UDim2.new(0.5, 0, 0, layout.WorkspaceInset)
        })

        open.Visible = true
        showOpen:Play()
    end)

    oh.Events.WindowOpen = open.MouseButton1Click:Connect(function()
        if not collapsed then
            return
        end

        collapsed = false
        local destination
        if maximized then
            local viewport = viewportSize()
            destination = UDim2.new(0, 0, 0, 0)
            base.Size = UDim2.new(0, viewport.X, 0, viewport.Y)
        else
            local restoredSize = clampSize(base.AbsoluteSize)
            destination = clampRestoredPosition(collapsedPosition, restoredSize)
            base.Size = UDim2.new(0, restoredSize.X, 0, restoredSize.Y)
            collapsedPosition = destination
        end
        open.Visible = false
        base.Position = destination
        base.Visible = true
    end)

    oh.Events.WindowViewport = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if maximized then
            local viewport = viewportSize()
            base.Position = UDim2.new(0, 0, 0, 0)
            base.Size = UDim2.new(0, viewport.X, 0, viewport.Y)
        else
            local size = clampSize(base.AbsoluteSize)
            base.Position = clampRestoredPosition(base.Position, size)
            base.Size = UDim2.new(0, size.X, 0, size.Y)
            if collapsed then
                collapsedPosition = base.Position
            end
        end
        updateWorkspace()
    end)
end

return Window
