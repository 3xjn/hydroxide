local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Prism = import("ui/prism")
local Theme = import("ui/theme")

local List = {}
local ListButton = {}

local lists = {}
local ctrlHeld = false
local constants = {
    tweenTime = TweenInfo.new(0.15),
    selected = Theme.Colors.AccentSurface,
    deselected = Theme.Colors.Elevated
}

local function textOf(instance)
    if instance and (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")) then
        return instance.Text
    end
    return nil
end

local function childText(instance, name)
    local child = instance:FindFirstChild(name, true)
    return textOf(child)
end

local function describeRow(instance, selected)
    local title = childText(instance, "Name") or childText(instance, "Label") or childText(instance, "Index") or instance.Name
    local subtitle = childText(instance, "Signature") or childText(instance, "Flags") or childText(instance, "Value") or childText(instance, "Relationship")
    if subtitle == title then
        subtitle = childText(instance, "Path")
    end
    local meta = childText(instance, "Calls") or childText(instance, "Connections")
    if not meta then
        local protos = childText(instance, "Protos")
        local constantsText = childText(instance, "Constants")
        if protos or constantsText then
            meta = table.concat({ protos or "0", constantsText or "0" }, " / ")
        end
    end
    local indent = 0
    if string.find(instance.Name, "Connection", 1, true) or string.sub(tostring(childText(instance, "Index") or ""), 1, 1) == "↳" then
        indent = 1
    end
    return {
        id = tostring(instance),
        title = title,
        subtitle = subtitle,
        meta = meta,
        selected = selected == true,
        indent = indent,
        visible = instance.Visible,
    }
end

local function selectedSet(list)
    local selected = {}
    if list.Selected then
        for _, listButton in pairs(list.Selected) do
            selected[listButton] = true
        end
    end
    return selected
end

local function sync(list)
    if not list.Handle then
        return
    end
    local selected = selectedSet(list)
    local rows = {}
    for _, instance in ipairs(list.Order) do
        local listButton = list.Buttons[instance]
        if listButton and instance.Parent then
            table.insert(rows, describeRow(instance, selected[listButton] == true))
        end
    end
    list.Handle.update({
        kind = "list",
        rows = rows,
        emptyText = list.EmptyText,
        onPress = function(id)
            for instance, listButton in pairs(list.Buttons) do
                if tostring(instance) == id then
                    if not ctrlHeld and listButton.Callback then
                        listButton.Callback()
                    elseif list.MultiClickEnabled and ctrlHeld then
                        if not list.Selected then
                            list.Selected = {}
                        end
                        if listButton.SelectedCallback then
                            listButton.SelectedCallback()
                        end
                        local foundButton = table.find(list.Selected, listButton)
                        if not foundButton then
                            table.insert(list.Selected, listButton)
                        else
                            table.remove(list.Selected, foundButton)
                        end
                        sync(list)
                    end
                    return
                end
            end
        end,
        onRightPress = function(id)
            for instance, listButton in pairs(list.Buttons) do
                if tostring(instance) == id then
                    if not ctrlHeld and listButton.RightCallback then
                        listButton.RightCallback()
                    end
                    if list.BoundContextMenuSelected and list.Selected then
                        list.BoundContextMenuSelected:Show()
                    elseif list.BoundContextMenu and not list.Selected then
                        list.BoundContextMenu:Show()
                    end
                    return
                end
            end
        end,
    })
    list.Dirty = false
end

local function storageFor(host)
    local parent = host.Parent
    local storage = parent and parent:FindFirstChild("RowStorage")
    if storage then
        return storage
    end
    storage = Instance.new("Folder")
    storage.Name = "RowStorage"
    storage.Parent = parent or host
    return storage
end

local function scrollingHost(instance)
    if instance:IsA("ScrollingFrame") then
        return instance
    end

    local existing = instance:FindFirstChild("ListContent")
    if existing and existing:IsA("ScrollingFrame") then
        return existing
    end

    local content = Instance.new("ScrollingFrame")
    content.Name = "ListContent"
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.CanvasSize = UDim2.new(0, 0, 0, 15)
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = Theme.Colors.MutedText
    content.Parent = instance

    local layout = Instance.new("UIListLayout")
    layout.Name = "Layout"
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = content
    return content
end

function List.new(instance, multiClick)
    local list = {}
    list.Buttons = {}
    list.Clear = List.clear
    list.Recalculate = List.recalculate
    list.BindContextMenu = List.bindContextMenu
    list.BindContextMenuSelected = List.bindContextMenuSelected
    list.MultiClickEnabled = multiClick

    list.Order = {}
    list.Instance = instance
    list.Storage = storageFor(instance)
    list.Handle = Prism.mount(instance, { kind = "list", rows = {} })

    table.insert(lists, list)
    return list
end

local function watch(instance, list)
    instance:GetPropertyChangedSignal("Visible"):Connect(function()
        list.Dirty = true
    end)
    instance.DescendantAdded:Connect(function(descendant)
        list.Dirty = true
        if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
            descendant:GetPropertyChangedSignal("Text"):Connect(function()
                list.Dirty = true
            end)
        end
    end)
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
            descendant:GetPropertyChangedSignal("Text"):Connect(function()
                list.Dirty = true
            end)
        end
    end
end

function ListButton.new(instance, list)
    local listButton = {}
    list.Buttons[instance] = listButton
    listButton.List = list
    listButton.Instance = instance
    listButton.SetCallback = ListButton.setCallback
    listButton.SetRightCallback = ListButton.setRightCallback
    listButton.SetSelectedCallback = ListButton.setSelectedCallback
    listButton.Remove = ListButton.remove

    if list.Handle then
        table.insert(list.Order, instance)
        instance.Parent = list.Storage
        watch(instance, list)
        list.Dirty = true
        return listButton
    end

    local listInstance = list.Instance
    if instance.Visible then
        listInstance.CanvasSize = listInstance.CanvasSize + UDim2.new(0, 0, 0, instance.AbsoluteSize.Y + 5)
    end

    instance.Parent = listInstance
    instance.MouseButton1Click:Connect(function()
        if not ctrlHeld and listButton.Callback then
            listButton.Callback()
        elseif list.MultiClickEnabled and ctrlHeld then
            if not list.Selected then
                list.Selected = {}
            end

            if listButton.SelectedCallback then
                listButton.SelectedCallback()
            end

            local foundButton = table.find(list.Selected, listButton)

            if not foundButton then
                table.insert(list.Selected, listButton)
                listButton.SelectAnimation:Play()
            else
                table.remove(list.Selected, foundButton)
                listButton.DeselectAnimation:Play()
            end
        end
    end)

    instance.MouseButton2Click:Connect(function()
        if not ctrlHeld and listButton.RightCallback then
            listButton.RightCallback()
        end
    end)

    listButton.SelectAnimation = TweenService:Create(instance, constants.tweenTime, { BackgroundColor3 = constants.selected })
    listButton.DeselectAnimation = TweenService:Create(instance, constants.tweenTime, { BackgroundColor3 = constants.deselected })
    return listButton
end

function List.clear(list)
    if list.Handle then
        for instance in pairs(list.Buttons) do
            instance:Destroy()
        end
        list.Buttons = {}
        list.Order = {}
        list.Selected = nil
        sync(list)
        return
    end

    local instance = list.Instance
    for _i, listButton in pairs(instance:GetChildren()) do
        if listButton:IsA("ImageButton") then
            listButton:Destroy()
        end
    end

    instance.CanvasSize = UDim2.new(0, 0, 0, 15)
    list.Buttons = {}
    list.Selected = nil
end

function List.recalculate(list)
    if list.Handle then
        sync(list)
        return
    end

    local newHeight = 15
    for instance in pairs(list.Buttons) do
        if instance.Visible then
            newHeight = newHeight + instance.AbsoluteSize.Y + 5
        end
    end
    list.Instance.CanvasSize = UDim2.new(0, 0, 0, newHeight)
end

function List.bindContextMenu(list, contextMenu)
    if list.Handle then
        list.BoundContextMenu = contextMenu
        sync(list)
        return
    end

    if not list.BoundContextMenu then
        local function showContextMenu()
            if not list.Selected then
                contextMenu:Show()
            end
        end

        list.Instance.ChildAdded:Connect(function(instance)
            instance.MouseButton2Click:Connect(showContextMenu)
        end)

        list.BoundContextMenu = contextMenu
    end
end

function List.bindContextMenuSelected(list, contextMenu)
    if list.Handle then
        list.BoundContextMenuSelected = contextMenu
        sync(list)
        return
    end

    if not list.BoundContextMenuSelected then
        local function showContextMenu()
            if list.Selected then
                contextMenu:Show()
            end
        end

        list.Instance.ChildAdded:Connect(function(instance)
            instance.MouseButton2Click:Connect(showContextMenu)
        end)

        list.BoundContextMenuSelected = contextMenu
    end
end

function ListButton.setCallback(listButton, callback)
    listButton.Callback = callback
end

function ListButton.setRightCallback(listButton, callback)
    listButton.RightCallback = callback
end

function ListButton.setSelectedCallback(listButton, callback)
    listButton.SelectedCallback = callback
end

function ListButton.remove(listButton)
    local list = listButton.List
    local instance = listButton.Instance

    if list.Handle then
        list.Buttons[instance] = nil
        for index, ordered in ipairs(list.Order) do
            if ordered == instance then
                table.remove(list.Order, index)
                break
            end
        end
        instance:Destroy()
        sync(list)
        return
    end

    local listInstance = list.Instance
    listInstance.CanvasSize = listInstance.CanvasSize - UDim2.new(0, 0, 0, instance.AbsoluteSize.Y + 5)
    list.Buttons[instance] = nil
    instance:Destroy()
end

oh.Events.ListInputBegan = UserInput.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftControl then
        ctrlHeld = true
    elseif not ctrlHeld and input.UserInputType == Enum.UserInputType.MouseButton1 then
        for _i, list in pairs(lists) do
            if list.Selected then
                if list.Handle then
                    list.Selected = nil
                    list.Dirty = true
                else
                    for _k, listButton in pairs(list.Selected) do
                        listButton.DeselectAnimation:Play()
                    end
                    list.Selected = nil
                end
            end
        end
    end
end)

oh.Events.ListInputEnded = UserInput.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftControl then
        ctrlHeld = false
    end
end)

oh.Events.ListPrismSync = RunService.Heartbeat:Connect(function()
    for _i, list in pairs(lists) do
        if list.Dirty then
            sync(list)
        end
    end
end)

return List, ListButton
