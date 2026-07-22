local TweenService = game:GetService("TweenService")

local TabSelector = {}
local Theme = import("ui/theme")

local Base = import("ui/runtime").GetInterface().Base
local Tabs = Base.Tabs.Container
local Pages = Base.Body.Pages

local MessageBox, MessageType = import("ui/controls/MessageBox")

local requiredMethods = {
    ConstantScanner = import("modules/ConstantScanner").RequiredMethods,
    UpvalueScanner = import("modules/UpvalueScanner").RequiredMethods,
    ScriptScanner = import("modules/ScriptScanner").RequiredMethods,
    ModuleScanner = import("modules/ModuleScanner").RequiredMethods,
    ClosureSpy = import("modules/ClosureSpy").RequiredMethods,
    RemoteSpy = import("modules/RemoteSpy").RequiredMethods
}

local constants = {
    fadeLength = Theme.Motion,
    tabSelected = Theme.Colors.Rail,
    iconSelected = Theme.Colors.Accent,
    tabHovered = Theme.Colors.Hover,
    iconHovered = Theme.Colors.SecondaryText,
    tabUnselected = Theme.Colors.Rail,
    iconUnselected = Theme.Colors.MutedText
}

local selectedTab 
local selectedPage = Pages.Home

local function methodsCheck(methods)
    local globalMethods = oh.Methods
    local missingMethods = ""

    for methodName in pairs(methods) do
        if not globalMethods[methodName] then
            missingMethods = missingMethods .. methodName .. ", "
        end
    end

    return (missingMethods ~= "" and missingMethods:sub(1, -3)) or nil
end

local animationCache = {}
local function selectTab(tabName)
    local methodsFound = requiredMethods[tabName]
    local missingMethods = methodsFound and methodsCheck(methodsFound)

    if missingMethods then
        return MessageBox.Show(
            "Your exploit does not support this section",
            "The following functions are missing from your exploit: " .. missingMethods,
            MessageType.OK
        )
    end

    local tab = Tabs:FindFirstChild(tabName)
    local page = Pages:FindFirstChild(tabName)

    if selectedTab then
        local tabAnimation = animationCache[selectedTab]
        tabAnimation.unselected:Play()
        tabAnimation.iconUnselected:Play()
        selectedTab.Selection.Visible = false
    end

    selectedPage.Visible = false
    page.Visible = true
    tab.BackgroundColor3 = constants.tabSelected
    tab.Icon.ImageColor3 = constants.iconSelected
    tab.Selection.Visible = true

    oh.setStatus(page.Name:sub(1, 1) .. page.Name:sub(2):gsub('%u', function(c) return ' ' .. c end))
    
    selectedTab = tab
    selectedPage = page
    return true
end

for _i, tab in pairs(Tabs:GetChildren()) do
    if tab:IsA("ImageButton") then
        local hovered = TweenService:Create(tab, constants.fadeLength, { BackgroundColor3 = constants.tabHovered })
        local unselected = TweenService:Create(tab, constants.fadeLength, { BackgroundColor3 = constants.tabUnselected })
        local iconHovered = TweenService:Create(tab.Icon, constants.fadeLength, { ImageColor3 = constants.iconHovered })
        local iconUnselected = TweenService:Create(tab.Icon, constants.fadeLength, { ImageColor3 = constants.iconUnselected })

        animationCache[tab] = {
            hovered = hovered,
            unselected = unselected,
            iconHovered = iconHovered,
            iconUnselected = iconUnselected
        }

        tab.MouseButton1Click:Connect(function()
            if selectedTab ~= tab and Tabs:FindFirstChild(tab.Name) then
                selectTab(tab.Name)
            end
        end)

        tab.MouseEnter:Connect(function()
            if selectedPage ~= Pages:FindFirstChild(tab.Name) then
                hovered:Play()
                iconHovered:Play()
            end
        end)

        tab.MouseLeave:Connect(function()
            if selectedPage ~= Pages:FindFirstChild(tab.Name) then
                unselected:Play()
                iconUnselected:Play()
            end
        end)
    end
end

selectedTab = Tabs.Home
selectedTab.BackgroundColor3 = constants.tabSelected
selectedTab.Icon.ImageColor3 = constants.iconSelected
selectedTab.Selection.Visible = true

TabSelector.SelectTab = selectTab
return TabSelector
