--!strict

local Runtime = import("ui/runtime")
local VisualAssets = import("ui/assets")

local Assets = Runtime.GetTemplates().Controls :: Folder
local Storage = Runtime.GetContextMenus() :: Frame

local contextMenuButtonTemplate = Assets:FindFirstChild("ContextMenuButton")
assert(contextMenuButtonTemplate and contextMenuButtonTemplate:IsA("ImageButton"), "ContextMenuButton must be an ImageButton")

local contextMenuTemplate = Assets:FindFirstChild("ContextMenu")
assert(contextMenuTemplate and contextMenuTemplate:IsA("Frame"), "ContextMenu must be a Frame")

local function getButtonIcon(button: ImageButton): ImageLabel
    local icon = button:FindFirstChild("Icon")
    assert(icon and icon:IsA("ImageLabel"), "ContextMenuButton.Icon must be an ImageLabel")
    return icon
end

local function getButtonLabel(button: ImageButton): TextLabel
    local label = button:FindFirstChild("Label")
    assert(label and label:IsA("TextLabel"), "ContextMenuButton.Label must be a TextLabel")
    return label
end

local function getContextMenuList(contextMenu: Frame): Frame
    local list = contextMenu:FindFirstChild("List")
    assert(list and list:IsA("Frame"), "ContextMenu.List must be a Frame")
    return list
end

local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local client = Players.LocalPlayer
local mouse = client:GetMouse()

type ContextMenuButtonState = {
    Instance: ImageButton,
    [string]: any
}

local ContextMenuButton: any = {}
local ContextMenu: any = {}

local currentContextMenu: any = nil
local constants = {
    fadeLength = TweenInfo.new(0.15),
    textWidth = Vector2.new(1337420, 20)
}

local function actionGlyph(text: string): string
    if text:find("Script") then
        return "ScriptScanner"
    elseif text:find("Closure") or text:find("Function") then
        return "ClosureSpy"
    elseif text:find("Upvalue") or text:find("Element") then
        return "UpvalueScanner"
    elseif text:find("Remote") or text:find("Call") or text:find("Condition") then
        return "RemoteSpy"
    elseif text:find("Constant") then
        return "ConstantScanner"
    end

    return "ModuleScanner"
end

function ContextMenuButton.new(_icon: any, text: string): ContextMenuButtonState
    local contextMenuButton: any = {}
    local instance = contextMenuButtonTemplate:Clone()
    local icon = getButtonIcon(instance)
    local label = getButtonLabel(instance)

    local enterAnimation = TweenService:Create(label, constants.fadeLength, { TextTransparency = 0 })
    local leaveAnimation = TweenService:Create(label, constants.fadeLength, { TextTransparency = 0.2 })

    label.Text = text
    VisualAssets.ApplyGlyph(icon, actionGlyph(text))

    instance.MouseButton1Click:Connect(function()
        if contextMenuButton.Callback then
            contextMenuButton.Callback()
        end
    end)

    instance.MouseEnter:Connect(function()
        enterAnimation:Play()
    end)

    instance.MouseLeave:Connect(function()
        leaveAnimation:Play()
    end)

    contextMenuButton.Instance = instance
    contextMenuButton.SetIcon = ContextMenuButton.setIcon
    contextMenuButton.SetText = ContextMenuButton.setText
    contextMenuButton.SetCallback = ContextMenuButton.setCallback
    return contextMenuButton
end

function ContextMenuButton.setIcon(contextMenuButton: ContextMenuButtonState, _newIcon: any)
    local instance = contextMenuButton.Instance
    VisualAssets.ApplyGlyph(getButtonIcon(instance), actionGlyph(getButtonLabel(instance).Text))
end

function ContextMenuButton.setText(contextMenuButton: ContextMenuButtonState, newText: string)
    local instance = contextMenuButton.Instance
    getButtonLabel(instance).Text = newText
    VisualAssets.ApplyGlyph(getButtonIcon(instance), actionGlyph(newText))
end

function ContextMenuButton.setCallback(contextMenuButton: ContextMenuButtonState, callback: () -> ())
    if not contextMenuButton.Callback then
        contextMenuButton.Callback = callback
    end
end

function ContextMenu.new(contextMenuButtons: { ContextMenuButtonState })
    local contextMenu: any = {}
    local instance = contextMenuTemplate:Clone()
    local list = getContextMenuList(instance)
    local instanceWidth = 0
    local instanceHeight = 0

    instance.Parent = Storage
    
    for _i, contextMenuButton in pairs(contextMenuButtons) do
        local buttonInstance = contextMenuButton.Instance
        local label = getButtonLabel(buttonInstance)
        local icon = getButtonIcon(buttonInstance)
        local textWidth = TextService:GetTextSize(label.Text, 18, Enum.Font.SourceSans, constants.textWidth).X

        buttonInstance.Parent = list
        label.TextWrapped = false

        local buttonWidth = icon.Size.X.Offset + textWidth + 32
        
        if buttonWidth > instanceWidth then
            instanceWidth = buttonWidth
        end

        instanceHeight = instanceHeight + buttonInstance.Size.Y.Offset
    end
    
    instance.Size = UDim2.new(0, instanceWidth, 0, instanceHeight)
    instance.Visible = false
    
    contextMenu.Instance = instance
    contextMenu.Visible = false
    contextMenu.Buttons = {}
    contextMenu.Show = ContextMenu.show
    contextMenu.Hide = ContextMenu.hide
    return contextMenu
end

function ContextMenu.add(contextMenu: any, contextMenuButton: ContextMenuButtonState)
    table.insert(contextMenu.Buttons, contextMenuButton)
end

function ContextMenu.show(contextMenu: any)
    if currentContextMenu then
        currentContextMenu:Hide()
    end

    local instance = contextMenu.Instance

    instance.Visible = true
    instance.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
    
    contextMenu.Visible = true
    currentContextMenu = contextMenu
end

function ContextMenu.hide(contextMenu: any)
    contextMenu.Visible = false
    contextMenu.Instance.Visible = false
end

local session = getgenv().oh
session.Events.ContextMenuInputEnded = UserInput.InputEnded:Connect(function(input)
    if currentContextMenu and input.UserInputType == Enum.UserInputType.MouseButton1 then
        currentContextMenu:Hide()
        currentContextMenu = nil
    end
end)

return ContextMenu, ContextMenuButton
