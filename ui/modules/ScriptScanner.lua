local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local ScriptScanner = {}
local Closure = import("objects/Closure")
local ClosureSpy = import("modules/ClosureSpy")
local Methods = import("modules/ScriptScanner")
local ScannerResults = import("modules/ScannerResults")

if not hasMethods(Methods.RequiredMethods) then
    return ScriptScanner
end

local List, ListButton = import("ui/controls/List")
local QueryBar = import("ui/controls/QueryBar")
local FilterPopover = import("ui/controls/FilterPopover")
local MessageBox, MessageType = import("ui/controls/MessageBox")
local ContextMenu, ContextMenuButton = import("ui/controls/ContextMenu")
local TabSelector = import("ui/controls/TabSelector")
local VisualAssets = import("ui/assets")

local Runtime = import("ui/runtime")
local Page = Runtime.GetInterface().Base.Body.Pages.ScriptScanner
local Assets = Runtime.GetTemplates().ScriptScanner

local ScriptList = Page.List
local ScriptInfo = Page.Info

local ListQuery = QueryBar.new(ScriptList.Query, {
    placeholder = "Filter scripts...",
    action = "refresh",
    filter = true,
})
local ListFilter = FilterPopover.new(ListQuery, "ScriptScannerFilterPopoverInput")
local ListResults = ScriptList.Results.Clip.Content

local InfoScript = ScriptInfo.ScriptObject
local InfoBack = ScriptInfo.Back
local InfoOptions = ScriptInfo.Options.Clip.Content
local InfoSections = ScriptInfo.Sections

local InfoSource = InfoSections.Source
local InfoEnvironment = InfoSections.Environment
local InfoProtos = InfoSections.Protos
local InfoConstants = InfoSections.Constants

local SourceQuery = InfoSource.Query
local SourceResultsClip = InfoSource.Results.Clip
local SourceResultsStatus = SourceResultsClip.ResultStatus
local SourceResults = SourceResultsClip.Content

local EnvironmentQuery = InfoEnvironment.Query
local EnvironmentResultsClip = InfoEnvironment.Results.Clip
local EnvironmentResultsStatus = EnvironmentResultsClip.ResultStatus
local EnvironmentResults = EnvironmentResultsClip.Content

local ConstantsQuery = InfoConstants.Query
local ConstantsResultsClip = InfoConstants.Results.Clip
local ConstantsResultsStatus = ConstantsResultsClip.ResultStatus
local ConstantsResults = ConstantsResultsClip.Content

local ProtosQuery = InfoProtos.Query
local ProtosResultsClip = InfoProtos.Results.Clip
local ProtosResultsStatus = ProtosResultsClip.ResultStatus
local ProtosResults = ProtosResultsClip.Content

local scriptList = List.new(ListResults)
local protosList = List.new(ProtosResults)
local constantsList = List.new(ConstantsResults)
local environmentList = List.new(EnvironmentResults)
local sourceList = List.new(SourceResults)

local scriptLogs = {}
local selected = {}
local currentQuery = ""
local icons = {
    LocalScript = "LocalScript"
}

local constants = {
    fadeLength = TweenInfo.new(0.15),
    textWidth = Vector2.new(133742069, 20)
}

local pathContext = ContextMenuButton.new(nil, "Get Script Path")
local signalContext = ContextMenuButton.new(nil, "Inspect Signals")
scriptList:BindContextMenu(ContextMenu.new({ pathContext, signalContext }))

local inspectProtoContext = ContextMenuButton.new(nil, "Inspect Closure")
local copyProtoNameContext = ContextMenuButton.new(nil, "Copy Function Name")
protosList:BindContextMenu(ContextMenu.new({ inspectProtoContext, copyProtoNameContext }))

local copyConstantContext = ContextMenuButton.new(nil, "Copy Literal Value")
constantsList:BindContextMenu(ContextMenu.new({ copyConstantContext }))

local copyEnvironmentContext = ContextMenuButton.new(nil, "Copy Environment Value")
local copyEnvironmentPathContext = ContextMenuButton.new(nil, "Copy Linked Instance Path")
local inspectEnvironmentSignalsContext = ContextMenuButton.new(nil, "Inspect Linked Signals")
environmentList:BindContextMenu(ContextMenu.new({ copyEnvironmentContext, copyEnvironmentPathContext, inspectEnvironmentSignalsContext }))

local copySourcePathContext = ContextMenuButton.new(nil, "Copy Script Path")
local inspectSourceSignalsContext = ContextMenuButton.new(nil, "Inspect Script Signals")
sourceList:BindContextMenu(ContextMenu.new({ copySourcePathContext, inspectSourceSignalsContext }))

pathContext:SetCallback(function()
    local description = ScannerResults.Describe(selected.logContext.LocalScript)
    local selectedInstance = description.Instance

    setClipboard(description.Path)
    MessageBox.Show("Success", ("%s's path was copied to your clipboard."):format(selectedInstance.Name), MessageType.OK)
end)

signalContext:SetCallback(function()
    local signalSpy = oh.Tools and oh.Tools.SignalSpy
    if signalSpy and selected.logContext then
        signalSpy.Open(selected.logContext.LocalScript.Instance)
    end
end)

local function copyValue(value, description)
    setClipboard(toString(value))
    MessageBox.Show("Success", description .. " was copied to your clipboard.", MessageType.OK)
end

local function openSignalSpy(instance)
    local signalSpy = oh.Tools and oh.Tools.SignalSpy
    if signalSpy then
        signalSpy.Open(instance)
    end
end

local function requireSelectedInstance(value)
    if typeof(value) == "Instance" then
        return value
    end

    MessageBox.Show("No linked instance", "This value is not a Roblox instance.", MessageType.OK)
end

inspectProtoContext:SetCallback(function()
    local proto = selected.proto
    if not proto or not TabSelector.SelectTab("ClosureSpy") then
        return
    end

    local closure = Closure.new(proto.Value)
    local result = ClosureSpy.Hook.new(closure)

    if result == false then
        MessageBox.Show("Already hooked", "You are already spying " .. closure.Name, MessageType.OK)
    elseif result == nil then
        MessageBox.Show("Cannot hook", ('Cannot hook "%s" because there are no upvalues'):format(closure.Name), MessageType.OK)
    end
end)

copyProtoNameContext:SetCallback(function()
    local proto = selected.proto
    if proto then
        copyValue(proto.Name or ScannerResults.ClosureName(proto.Value), "Function name")
    end
end)

copyConstantContext:SetCallback(function()
    local constant = selected.constant
    if constant then
        copyValue(constant.Value, "Literal value")
    end
end)

copyEnvironmentContext:SetCallback(function()
    local environment = selected.environment
    if environment then
        copyValue(environment.Value, "Environment value")
    end
end)

copyEnvironmentPathContext:SetCallback(function()
    local environment = selected.environment
    if environment and environment.Path then
        copyValue(environment.Path, "Instance path")
        return
    end

    local instance = environment and requireSelectedInstance(environment.Value)
    if instance then
        copyValue(getInstancePath(instance), "Instance path")
    end
end)

inspectEnvironmentSignalsContext:SetCallback(function()
    local environment = selected.environment
    local instance = environment and requireSelectedInstance(environment.Value)
    if instance then
        openSignalSpy(instance)
    end
end)

copySourcePathContext:SetCallback(function()
    local source = selected.source
    if source then
        copyValue(source.Path or getInstancePath(source.Instance), "Script path")
    end
end)

inspectSourceSignalsContext:SetCallback(function()
    local source = selected.source
    if source then
        openSignalSpy(source.Instance)
    end
end)

local function createProto(index, value, functionName)
    local instance = Assets.ProtoPod:Clone()
    local information = instance.Information
    functionName = functionName or ScannerResults.ClosureName(value)
    local indexWidth = TextService:GetTextSize(index, 18, "SourceSans", constants.textWidth).X + 8

    if functionName == "Unnamed function" then
        information.Label.TextColor3 = oh.Constants.Syntax["unnamed_function"]
    end
    
    information.Index.Text = index
    information.Label.Text = functionName

    information.Index.Size = UDim2.new(0, indexWidth, 0, 20)
    information.Label.Size = UDim2.new(1, -(indexWidth + 20), 1, 0)
    information.Icon.Position = UDim2.new(0, indexWidth, 0, 2)
    information.Label.Position = UDim2.new(0, indexWidth + 20, 0, 0)

    local listButton = ListButton.new(instance, protosList)
    listButton:SetRightCallback(function()
        selected.proto = { Index = index, Value = value, Name = functionName }
    end)
end

local function createConstant(index, value, described)
    local instance = Assets.ConstantPod:Clone()
    local information = instance.Information
    local valueType = type(value)
    local indexWidth = TextService:GetTextSize(index, 18, "SourceSans", constants.textWidth).X + 8    

    information.Index.Text = index

    information.Index.Size = UDim2.new(0, indexWidth, 0, 20)
    information.Label.Size = UDim2.new(1, -(indexWidth + 20), 1, 0)
    information.Icon.Position = UDim2.new(0, indexWidth, 0, 2)
    information.Label.Position = UDim2.new(0, indexWidth + 20, 0, 0)

    if valueType == "function" then
        local functionName = described and described.Name or ScannerResults.ClosureName(value)

        if functionName == "Unnamed function" then
            information.Label.TextColor3 = oh.Constants.Syntax["unnamed_function"]
        end
        
        information.Label.Text = functionName
    else
        information.Label.Text = described and described.Text or toString(value)
    end
    
    local listButton = ListButton.new(instance, constantsList)
    listButton:SetRightCallback(function()
        selected.constant = { Index = index, Value = value }
    end)
end

local function createValueEntry(list, index, value, onRightClick)
    local instance = Assets.ConstantPod:Clone()
    local information = instance.Information
    local indexText = toString(index)
    local indexWidth = TextService:GetTextSize(indexText, 18, "SourceSans", constants.textWidth).X + 8

    information.Index.Text = indexText
    information.Label.Text = toString(value)
    VisualAssets.ApplyType(information.Icon, type(value))

    information.Index.Size = UDim2.new(0, indexWidth, 0, 20)
    information.Label.Size = UDim2.new(1, -(indexWidth + 20), 1, 0)
    information.Icon.Position = UDim2.new(0, indexWidth, 0, 2)
    information.Label.Position = UDim2.new(0, indexWidth + 20, 0, 0)

    local listButton = ListButton.new(instance, list)
    listButton:SetRightCallback(onRightClick)
end

local function createEnvironment(key, value, described)
    createValueEntry(environmentList, key, value, function()
        selected.environment = described or { Key = key, Value = value }
    end)
end

local function createSource(scriptInstance, path)
    createValueEntry(sourceList, "Path", path, function()
        selected.source = { Instance = scriptInstance, Path = path }
    end)
end

local function filterDetailList(list, query)
    local normalizedQuery = query:lower()

    for instance in pairs(list.Buttons) do
        local information = instance.Information
        local entryText = (information.Index.Text .. " " .. information.Label.Text):lower()
        instance.Visible = entryText:find(normalizedQuery, 1, true) ~= nil
    end

    list:Recalculate()
end

local function bindDetailFilter(host, list)
    local query = QueryBar.new(host, { placeholder = host:GetAttribute("Placeholder"), action = false })
    query:OnChange(function(text)
        filterDetailList(list, text)
    end)
    query:OnSubmit(function(text)
        filterDetailList(list, text)
    end)
end

bindDetailFilter(ProtosQuery, protosList)
bindDetailFilter(ConstantsQuery, constantsList)
bindDetailFilter(EnvironmentQuery, environmentList)
bindDetailFilter(SourceQuery, sourceList)

-- Log Object
local Log = {}

function Log.new(localScript, layoutOrder)
    local log = {}
    local scriptInstance = localScript.Instance
    local button = Assets.ScriptLog:Clone()
    local listButton = ListButton.new(button, scriptList)
    local scriptName = scriptInstance.Name

    button.Name = scriptName
    button.LayoutOrder = layoutOrder
    button:FindFirstChild("Name").Text = scriptName
    button.Protos.Text = #localScript.Protos
    button.Constants.Text = #localScript.Constants

    listButton:SetCallback(function()
        if selected.scriptLog ~= log then
            protosList:Clear()
            constantsList:Clear()
            environmentList:Clear()
            sourceList:Clear()
            
            ScriptList.Visible = false
            ScriptInfo.Visible = true

            local nameLength = TextService:GetTextSize(scriptName, 18, "SourceSans", constants.textWidth).X + 20
            
            VisualAssets.ApplyGlyph(InfoScript.Icon, icons.LocalScript)
            InfoScript.Label.Text = scriptName
            InfoScript.Label.Size = UDim2.new(0, nameLength, 0, 20)
            InfoScript.Position = UDim2.new(1, -nameLength, 0, 0)

            local description = ScannerResults.Describe(localScript)
            log.Description = description

            for _, proto in ipairs(description.Protos) do
                createProto(proto.Index, proto.Value, proto.Name)
            end 

            for _, constant in ipairs(description.Constants) do
                createConstant(constant.Index, constant.Value, constant)
            end

            for _, environment in ipairs(description.Environment) do
                createEnvironment(environment.Key, environment.Value, environment)
            end

            createSource(scriptInstance, description.Path)

            protosList:Recalculate()
            constantsList:Recalculate()
            environmentList:Recalculate()
            sourceList:Recalculate()

            selected.scriptLog = log
        end
    end)

    listButton:SetRightCallback(function()
        selected.logContext = log
    end)

    scriptLogs[scriptInstance] = log

    log.LocalScript = localScript
    log.Button = listButton
    return log
end

-- UI Functionality

local function addScripts(query)
    currentQuery = query or currentQuery
    scriptList:Clear()
    scriptLogs = {}

    local results = ScannerResults.Sorted(Methods.Scan(currentQuery, oh.State.ScannerFilters:Get()))
    for layoutOrder, localScript in ipairs(results) do
        Log.new(localScript, layoutOrder)
    end

    scriptList:Recalculate()
end

ListQuery:OnSubmit(function(text)
    addScripts(text)
end)
ListQuery:OnAction(function()
    addScripts(currentQuery)
end)

ListFilter:SetCallback(function(filters)
    oh.State.ScannerFilters:Set(filters)
end)

oh.Events.ScriptScannerFilterState = oh.State.ScannerFilters:Subscribe(function(filters)
    ListFilter:SetValues(filters, false)
    addScripts(currentQuery)
end)

InfoBack.MouseButton1Click:Connect(function()
    ScriptInfo.Visible = false
    ScriptList.Visible = true
end)

local selectedSection = InfoProtos
local selectedSectionButton = InfoOptions.Protos
local animationCache = {}

for _i, sectionButton in pairs(InfoOptions:GetChildren()) do
    if sectionButton:IsA("TextButton") then
        local label = sectionButton.Label
        local enterAnimation = TweenService:Create(label, constants.fadeLength, { TextTransparency = 0 })
        local leaveAnimation = TweenService:Create(label, constants.fadeLength, { TextTransparency = 0.2 })

        sectionButton.MouseButton1Click:Connect(function()
            local section = InfoSections:FindFirstChild(sectionButton.Name)
            animationCache[selectedSectionButton].leave:Play()
            
            selectedSection.Visible = false
            section.Visible = true
            
            selectedSection = section
            selectedSectionButton = sectionButton

        end)

        sectionButton.MouseEnter:Connect(function()
            if selectedSectionButton ~= sectionButton then
                enterAnimation:Play()
            end
        end)

        sectionButton.MouseLeave:Connect(function()
            if selectedSectionButton ~= sectionButton then
                leaveAnimation:Play()
            end
        end)

        animationCache[sectionButton] = {
            enter = enterAnimation,
            leave = leaveAnimation
        }
    end
end

return ScriptScanner
