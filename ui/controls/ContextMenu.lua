local Runtime = import("ui/runtime")
local VisualAssets = import("ui/assets")
local Assets = Runtime.GetTemplates().Controls
local Storage = Runtime.GetContextMenus()

local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local client = Players.LocalPlayer
local mouse = client:GetMouse()

local ContextMenuButton = {}
local ContextMenu = {}

local currentContextMenu
local constants = {
    fadeLength = TweenInfo.new(0.15),
    textWidth = Vector2.new(1337420, 20)
}

local function actionGlyph(text)
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

function ContextMenuButton.new(_icon, text)
    local contextMenuButton = {}
    local instance = Assets.ContextMenuButton:Clone()
    local label = instance.Label

    local enterAnimation = TweenService:Create(label, constants.fadeLength, { TextTransparency = 0 })
    local leaveAnimation = TweenService:Create(label, constants.fadeLength, { TextTransparency = 0.2 })

    label.Text = text
    VisualAssets.ApplyGlyph(instance.Icon, actionGlyph(text))

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

function ContextMenuButton.setIcon(contextMenuButton, _newIcon)
    VisualAssets.ApplyGlyph(contextMenuButton.Instance.Icon, actionGlyph(contextMenuButton.Instance.Label.Text))
end

function ContextMenuButton.setText(contextMenuButton, newText)
    contextMenuButton.Instance.Label.Text = newText
    VisualAssets.ApplyGlyph(contextMenuButton.Instance.Icon, actionGlyph(newText))
end

function ContextMenuButton.setCallback(contextMenuButton, callback)
    if not contextMenuButton.Callback then
        contextMenuButton.Callback = callback
    end
end

function ContextMenu.new(contextMenuButtons)
    local contextMenu = {}
    local instance = Assets.ContextMenu:Clone()
    local instanceWidth = 0
    local instanceHeight = 0

    instance.Parent = Storage
    
    for _i, contextMenuButton in pairs(contextMenuButtons) do
        local buttonInstance = contextMenuButton.Instance
        local textWidth = TextService:GetTextSize(buttonInstance.Label.Text, 18, "SourceSans", constants.textWidth).X

        buttonInstance.Parent = instance.List
        buttonInstance.Label.TextWrapped = false

        local buttonWidth = buttonInstance.Icon.Size.X.Offset + textWidth + 32
        
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

function ContextMenu.add(contextMenu, contextMenuButton)
    table.insert(contextMenu.Buttons, contextMenuButton)
end

function ContextMenu.show(contextMenu)
    if currentContextMenu then
        currentContextMenu:Hide()
    end

    local instance = contextMenu.Instance

    instance.Visible = true
    instance.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
    
    contextMenu.Visible = true
    currentContextMenu = contextMenu
end

function ContextMenu.hide(contextMenu)
    contextMenu.Visible = false
    contextMenu.Instance.Visible = false
end

UserInput.InputEnded:Connect(function(input)
    if currentContextMenu and input.UserInputType == Enum.UserInputType.MouseButton1 then
        currentContextMenu:Hide()
        currentContextMenu = nil
    end
end)

return ContextMenu, ContextMenuButton
