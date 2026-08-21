local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local RemoteSpy = {}
local Methods = import("modules/RemoteSpy")
local ClosureSpy = import("modules/ClosureSpy")
local ScriptBuilder = import("modules/ScriptBuilder")
local RemoteRowGeometry = import("ui/remote_row_geometry")
local Closure = import("objects/Closure")

if not hasMethods(Methods.RequiredMethods) then
    return RemoteSpy
end

local Prompt = import("ui/controls/Prompt")
local CheckBox = import("ui/controls/CheckBox")
local Dropdown = import("ui/controls/Dropdown")
local List, ListButton = import("ui/controls/List")
local QueryBar = import("ui/controls/QueryBar")
local MessageBox, MessageType = import("ui/controls/MessageBox")
local ContextMenu, ContextMenuButton = import("ui/controls/ContextMenu")
local TabSelector = import("ui/controls/TabSelector")
local VisualAssets = import("ui/assets")

local Runtime = import("ui/runtime")
local Base = Runtime.GetInterface().Base
local Assets = Runtime.GetTemplates().RemoteSpy

local Prompts = Base.Prompts
local Page = Base.Body.Pages.RemoteSpy

local RemoteList = Page.List
local ListFlags = RemoteList.Flags
local ListQuery = QueryBar.new(RemoteList.Query, {
    placeholder = "Type to filter...",
    action = "refresh",
})
local ListResults = RemoteList.Results.Clip.Content

local RemoteLogs = Page.Logs
local LogsButtons = RemoteLogs.Buttons
local LogsRemote = RemoteLogs.RemoteObject
local LogsBack = RemoteLogs.Back
local LogsResults = RemoteLogs.Results.Clip.Content

local RemoteConditions = Page.Conditions
local ConditionsRemote = RemoteConditions.RemoteObject
local ConditionsButtons = RemoteConditions.Buttons
local ConditionsResults = RemoteConditions.Results.Clip.Content
local ConditionsBack = RemoteConditions.Back

local NewRemoteCondition = Prompts.NewRemoteCondition
local NewConditionInner = NewRemoteCondition.Inner
local NewConditionButtons = NewConditionInner.Buttons
local NewConditionContent = NewConditionInner.Content
local NewConditionIndex = NewConditionContent.Index

local remotesViewing = Methods.RemotesViewing
local currentRemotes = Methods.CurrentRemotes

local icons = {
    type = "type",
    status = "status",
    valueType = "valueType",
    block = "block",
    unblock = "unblock",
    ignore = "ignore",
    unignore = "unignore",
    RemoteEvent = "RemoteEvent",
    RemoteFunction = "RemoteFunction",
    BindableEvent = "BindableEvent",
    BindableFunction = "BindableFunction"
}

local constants = {
    fadeLength = TweenInfo.new(0.15),
    textWidth = Vector2.new(1337420, 20),
    normalColor = Color3.new(1, 1, 1),
    blockedColor = Color3.fromRGB(170, 0, 0),
    ignoredColor = Color3.fromRGB(100, 100, 100)
}

local newRemoteCondition = Prompt.new(NewRemoteCondition)
local conditionStatus = Dropdown.new(NewConditionContent.Status)
local conditionType = Dropdown.new(NewConditionContent.Type)
local conditionValueType = Dropdown.new(NewConditionContent.ValueType)

local remoteList = List.new(ListResults, true)
local remoteLogs = List.new(LogsResults)
local remoteConditions = List.new(ConditionsResults, true)

local currentLogs = {}
local removed = {}

local selected = {
    logs = {},
    conditions = {}
}

local pathContext = ContextMenuButton.new(nil, "Get Remote Path")
local signalContext = ContextMenuButton.new(nil, "Inspect Signals")
local conditionContext = ContextMenuButton.new(nil, "Call Conditions")
local clearContext = ContextMenuButton.new(nil, "Clear Calls")
local ignoreContext = ContextMenuButton.new(nil, "Ignore Calls")
local blockContext = ContextMenuButton.new(nil, "Block Calls")
local removeContext = ContextMenuButton.new(nil, "Remove Log")

local scriptContext = ContextMenuButton.new(nil, "Generate Script")
local callingScriptContext = ContextMenuButton.new(nil, "Get Calling Script")
local spyClosureContext = ContextMenuButton.new(nil, "Spy Calling Function")
local repeatCallContext = ContextMenuButton.new(nil, "Repeat Call")
local viewAsHexContext = ContextMenuButton.new(nil, "Toggle String Hex View")

local removeConditionContext = ContextMenuButton.new(nil, "Remove Condition")

local pathContextSelected = ContextMenuButton.new(nil, "Get Paths")
local clearContextSelected = ContextMenuButton.new(nil, "Clear Calls")
local ignoreContextSelected = ContextMenuButton.new(nil, "Ignore Calls")
local blockContextSelected = ContextMenuButton.new(nil, "Block Calls")
local unignoreContextSelected = ContextMenuButton.new(nil, "Unignore Calls")
local unblockContextSelected = ContextMenuButton.new(nil, "Unblock Calls")
local removeContextSelected = ContextMenuButton.new(nil, "Remove Logs")

local removeConditionContextSelected = ContextMenuButton.new(nil, "Remove Conditions")

local remoteListMenu = ContextMenu.new({ pathContext, signalContext, conditionContext, clearContext, ignoreContext, blockContext, removeContext })
local remoteListMenuSelected = ContextMenu.new({ pathContextSelected, clearContextSelected, ignoreContextSelected, unignoreContextSelected, blockContextSelected, unblockContextSelected, removeContextSelected })
local remoteLogsMenu = ContextMenu.new({ scriptContext, callingScriptContext, spyClosureContext, repeatCallContext, viewAsHexContext })
local remoteConditionMenu = ContextMenu.new({ removeConditionContext })
local remoteConditionMenuSelected = ContextMenu.new({ removeConditionContextSelected })

local function checkCurrentIgnored()
    local selectedRemote = (selected.remoteLog or selected.logContext).Remote

    LogsButtons.Ignore.Label.Text = (selectedRemote.Ignored and "Unignore") or "Ignore"
    VisualAssets.ApplyGlyph(LogsButtons.Ignore.Icon, (selectedRemote.Ignored and icons.unignore) or icons.ignore)

    local newWidth = TextService:GetTextSize((selectedRemote.Ignored and "Unignore") or "Ignore", 18, "SourceSans", constants.textWidth).X + 30

    LogsButtons.Ignore.Size = UDim2.new(0, newWidth, 0, 20)
end

local function checkCurrentBlocked()
    local selectedRemote = selected.remoteLog.Remote

    LogsButtons.Block.Label.Text = (selectedRemote.Blocked and "Unblock") or "Block"
    VisualAssets.ApplyGlyph(LogsButtons.Block.Icon, (selectedRemote.Blocked and icons.unblock) or icons.block)

    local newWidth = TextService:GetTextSize((selectedRemote.Blocked and "Unblock") or "Block", 18, "SourceSans", constants.textWidth).X + 30

    LogsButtons.Block.Size = UDim2.new(0, newWidth, 0, 20)
end

local Condition = {}
function Condition.new(remote, status, index, value, type)
    local condition = {}
    local instance = Assets.ConditionPod:Clone() 
    local content = instance.Content
    local identifiers = instance.Identifiers
    local button = ListButton.new(instance, remoteConditions)
    local check = CheckBox.new(content.Toggle)
    local valueType = type or typeof(value)
    local branch = (status == "Ignore" and remote.IgnoredArgs[index]) or remote.BlockedArgs[index]

    condition.Branch = branch
    condition.Status = status
    condition.Index = index
    condition.Value = value
    condition.Type = type
    condition.Remote = remote
    condition.Enabled = true
    condition.Instance = instance
    condition.Button = button
    condition.Toggle = Condition.toggle
    condition.Remove = Condition.remove

    check:SetCallback(function()
        condition:Toggle()
    end)

    button:SetRightCallback(function()
        selected.condition = condition
    end)

    button:SetSelectedCallback(function()
        if not table.find(selected.conditions, condition) then
            table.insert(selected.conditions, condition)
        end
    end)
    
    if byType then
        instance.Identifiers.ByType.Visible = false
    end 
    
    identifiers.ByType.Visible = type ~= nil
    VisualAssets.ApplyGlyph(identifiers.Status, (status == "Ignore" and icons.ignore) or icons.block)
    VisualAssets.ApplyGlyph(identifiers.Status.Border, (status == "Ignore" and icons.ignore) or icons.block)

    content.Index.Text = index
    content.Label.Text = (type and valueType) or toString(value)
    content.Label.TextColor3 = oh.Constants.Syntax[valueType] or oh.Constants.Syntax["userdata"]
    VisualAssets.ApplyType(content.Type, valueType)

    return condition
end

function Condition.toggle(condition)
    condition.Enabled = not condition.Enabled

    local index = condition.Index
    local value = condition.Value
    local remote = condition.Remote
    local ignoredArgs = remote.IgnoredArgs[index]
    local blockedArgs = remote.BlockedArgs[index]
    local argStatus = (condition.Status == "Ignore" and ignoredArgs) or blockedArgs

    if value then
        argStatus.values[value] = condition.Enabled or nil
    else
        argStatus.types[condition.Type] = condition.Enabled or nil
    end
end

function Condition.remove(condition)
    local branch = condition.Branch
    condition.Button:Remove()

    if condition.Value then
        branch.values[condition.Value] = nil
    else
        branch.types[condition.Type] = nil
    end
end

local function createConditions(remote)
    remoteConditions:Clear()

    RemoteList.Visible = false
    RemoteLogs.Visible = false
    RemoteConditions.Visible = true

    local remoteInstance = remote.Instance
    local remoteInstanceName = remoteInstance.Name
    local remoteClassName = remoteInstance.ClassName
    local nameLength = TextService:GetTextSize(remoteInstanceName, 18, "SourceSans", constants.textWidth).X + 20

    VisualAssets.ApplyGlyph(ConditionsRemote.Icon, icons[remoteClassName])
    ConditionsRemote.Label.Text = remoteInstanceName
    ConditionsRemote.Label.Size = UDim2.new(0, nameLength, 0, 20)
    ConditionsRemote.Position = UDim2.new(1, -nameLength, 0, 0)

    for index, arg in pairs(remote.IgnoredArgs) do
        for type in pairs(arg.types) do
            Condition.new(remote, "Ignore", index, nil, type)
        end

        for value in pairs(arg.values) do
            Condition.new(remote, "Ignore", index, value)
        end
    end

    for index, arg in pairs(remote.BlockedArgs) do
        for type in pairs(arg.types) do
            Condition.new(remote, "Block", index, nil, type)
        end

        for value in pairs(arg.values) do
            Condition.new(remote, "Block", index, value)
        end
    end
end

remoteList:BindContextMenu(remoteListMenu)
remoteList:BindContextMenuSelected(remoteListMenuSelected)
remoteLogs:BindContextMenu(remoteLogsMenu)
remoteConditions:BindContextMenu(remoteConditionMenu)
remoteConditions:BindContextMenuSelected(remoteConditionMenuSelected)

-- Log Objects
local Log = {}
local ArgsLog = {}

function Log.new(remote)
    local log = {}
    local button = Assets.RemoteLog:Clone()
    local remoteInstance = remote.Instance
    local remoteInstanceName = remoteInstance.Name
    local remoteClassName = remoteInstance.ClassName
    local listButton = ListButton.new(button, remoteList)
    
    local normalAnimation = TweenService:Create(button.Label, constants.fadeLength, { TextColor3 = constants.normalColor })
    local blockAnimation = TweenService:Create(button.Label, constants.fadeLength, { TextColor3 = constants.blockedColor })
    local ignoreAnimation = TweenService:Create(button.Label, constants.fadeLength, { TextColor3 = constants.ignoredColor })

    button.Name = remoteInstanceName
    button.Label.Text = remoteInstanceName
    VisualAssets.ApplyGlyph(button.Icon, icons[remoteClassName])

    local function viewLogs()
        if selected.remoteLog then
            remoteLogs:Clear()
        end
        
        local nameLength = TextService:GetTextSize(remoteInstanceName, 18, "SourceSans", constants.textWidth).X + 20
        
        selected.remoteLog = log

        for _i, call in pairs(remote.Logs) do
            ArgsLog.new(log, call)
        end

        checkCurrentBlocked()
        checkCurrentIgnored()

        VisualAssets.ApplyGlyph(LogsRemote.Icon, icons[remoteClassName])
        LogsRemote.Label.Text = remoteInstanceName
        LogsRemote.Label.Size = UDim2.new(0, nameLength, 0, 20)
        LogsRemote.Position = UDim2.new(1, -nameLength, 0, 0)

        remoteLogs:Recalculate()
    end

    listButton:SetCallback(function()
        if selected.remoteLog ~= log then
            if #remote.Logs > 400 then
                MessageBox.Show("Warning",
                    "This remote seems to have a lot of calls, opening this may cause your game to freeze for a few seconds.\n\nContinue?",
                    MessageType.YesNo,
                    viewLogs)
            else
                viewLogs()
            end
        end

        RemoteList.Visible = false
        RemoteLogs.Visible = true
    end)

    listButton:SetRightCallback(function()
        ignoreContext:SetIcon((remote.Ignored and icons.unignore) or icons.ignore)
        ignoreContext:SetText((remote.Ignored and "Unignore Calls") or "Ignore Calls")
        blockContext:SetIcon((remote.Blocked and icons.unblock) or icons.block)
        blockContext:SetText((remote.Blocked and "Unblock Calls") or "Block Calls")

        selected.logContext = log
    end)

    listButton:SetSelectedCallback(function()
        if not table.find(selected.logs, log) then
            table.insert(selected.logs, log)
        end
    end)

    currentLogs[remoteInstance] = log

    log.Remote = remote
    log.Button = listButton
    log.BlockAnimation = blockAnimation
    log.IgnoreAnimation = ignoreAnimation
    log.NormalAnimation = normalAnimation
    log.NormalAnimation = normalAnimation
    log.Clear = Log.clear
    log.PlayBlock = Log.playBlock
    log.PlayIgnore = Log.playIgnore
    log.PlayNormal = Log.playNormal
    log.Adjust = Log.adjust
    log.IncrementCalls = Log.incrementCalls
    log.Decrementcalls = Log.decrementCalls
    log.Remove = Log.remove
    return log
end

local function createArg(instance, index, value)
    local arg = Assets.RemoteArg:Clone()
    local valueType = type(value)

    VisualAssets.ApplyType(arg.Icon, valueType)
    arg.Index.Text = index
    
    if valueType == "table" then
        arg.Label.Text = toString(value)
    else
        arg.Label.Text = dataToString(value)
    end
    
    arg.Label.TextColor3 = oh.Constants.Syntax[valueType]
    arg.Name = tostring(index)
    arg.Parent = instance.Contents

    return arg.AbsoluteSize.Y + 5
end

function ArgsLog.new(log, callInfo)
    local instance = Assets.CallPod:Clone()
    local args = callInfo.args

    if selected.remoteLog ~= log then
        instance.Visible = false
    end

    local button = ListButton.new(instance, remoteLogs)
    local height = 0

    if #args == 0 then
        height = height + createArg(instance, 1, nil)
    else
        for i = 1, #args do
            local v = args[i]
            height = height + createArg(instance, i, v)
        end
    end

    button:SetRightCallback(function()
        selected.args = callInfo.args
        selected.callingScript = callInfo.script
        selected.func = callInfo.func
        selected.callPodButton = button
    end)

    button.Instance.Size = button.Instance.Size + UDim2.new(0, 0, 0, height)

    return button 
end

function Log.playIgnore(log)
    log.IgnoreAnimation:Play()
end

function Log.playBlock(log)
    log.BlockAnimation:Play()
end

function Log.playNormal(log)
    log.NormalAnimation:Play()
end

function Log.adjust(log)
    local remoteClassName = log.Remote.Instance.ClassName
    local logInstance = log.Button.Instance
    local logIcon = logInstance.Icon

    local measuredCallWidth = TextService:GetTextSize(
        logInstance.Calls.Text,
        18,
        "SourceSans",
        constants.textWidth
    ).X
    local geometry = RemoteRowGeometry.Resolve(measuredCallWidth)

    logInstance.Calls.Position = UDim2.new(0, geometry.CallsLeft, 0, 0)
    logInstance.Calls.Size = UDim2.new(0, geometry.CallsWidth, 1, 0)
    logIcon.Position = UDim2.new(0, geometry.IconLeft, 0.5, (remoteClassName == "RemoteEvent" and -9) or -7)
    logInstance.Label.Position = UDim2.new(0, geometry.LabelLeft, 0, 0)
    logInstance.Label.Size = UDim2.new(
        1,
        -(geometry.LabelLeft + geometry.LabelRightPadding),
        1,
        0
    )
end

function Log.clear(log)
    local logInstance = log.Button.Instance

    log.Remote:Clear()

    if selected.remoteLog == log then
        remoteLogs:Clear()
    end

    logInstance.Calls.Text = 0
    log:Adjust()
end

function Log.incrementCalls(log, callInfo)
    local buttonInstance = log.Button.Instance
    local remote = log.Remote
    local calls = remote.Calls

    buttonInstance.Calls.Text = (calls < 10000 and calls) or "..."

    log:Adjust()
    
    if selected.remoteLog == log then
        ArgsLog.new(log, callInfo)
        remoteLogs:Recalculate()
    end
end

function Log.decrementCalls(log, args)
    local buttonInstance = log.Button.Instance
    local remote = log.Remote
    local calls = remote.Calls

    remote:DecrementCalls(args)
    buttonInstance.Calls.Text = (calls < 10000 and calls) or "..."
    log:Adjust()
end

function Log.remove(log)
    local remoteInstance = log.Remote.Instance

    log.Button:Remove()
    currentLogs[remoteInstance] = nil
    removed[remoteInstance] = true
end

-- UI Functionality

local function refreshLogs()
    for remoteInstance, log in pairs(currentLogs) do
        log.Button.Instance.Visible = remotesViewing[remoteInstance.ClassName]
    end

    remoteList:Recalculate()
end

for _i,flag in pairs(ListFlags:GetChildren()) do
    if flag:IsA("GuiButton") and remotesViewing[flag.Name] ~= nil then
        local check = CheckBox.new(flag)

        check:SetCallback(function(enabled)
            remotesViewing[flag.Name] = enabled
            refreshLogs()
        end)
    end
end

ListQuery:OnSubmit(function(text)
    for remoteInstance, log in pairs(currentLogs) do
        local instance = log.Button.Instance
        instance.Visible = not (instance.Visible and not remoteInstance.Name:lower():find(text, 1, true))
    end

    remoteList:Recalculate()
    ListQuery:SetText("")
end)
ListQuery:OnAction(function()
    refreshLogs()
end)

LogsBack.MouseButton1Click:Connect(function()
    RemoteLogs.Visible = false
    RemoteList.Visible = true
end)

LogsButtons.Ignore.MouseButton1Click:Connect(function()
    local selectedRemote = selected.remoteLog.Remote

    selectedRemote:Ignore()

    checkCurrentIgnored()

    if selectedRemote.Blocked then
        selected.remoteLog:PlayBlock()
    elseif selectedRemote.Ignored then
        selected.remoteLog:PlayIgnore()
    else
        selected.remoteLog:PlayNormal()
    end
end)

LogsButtons.Block.MouseButton1Click:Connect(function()
    local selectedRemote = selected.remoteLog.Remote

    selectedRemote:Block()

    checkCurrentBlocked()

    if selectedRemote.Blocked then
        selected.remoteLog:PlayBlock()
    elseif selectedRemote.Ignored then
        selected.remoteLog:PlayIgnore()
    else
        selected.remoteLog:PlayNormal()
    end
end)

LogsButtons.Clear.MouseButton1Click:Connect(function()
    selected.remoteLog:Clear()
end)

LogsButtons.Conditions.MouseButton1Click:Connect(function()
    selected.conditionLog = selected.logContext or selected.remoteLog

    createConditions(selected.conditionLog.Remote)
end)

ConditionsBack.MouseButton1Click:Connect(function()
    RemoteConditions.Visible = false

    if selected.remoteLog then
        RemoteLogs.Visible = true
    else
        RemoteList.Visible = true
    end
end)

ConditionsButtons.New.MouseButton1Click:Connect(function()
    newRemoteCondition:Show()
end)

NewConditionButtons.Add.MouseButton1Click:Connect(function()
    if not conditionStatus.Selected then
        return MessageBox.Show("Error", "Invalid condition status", MessageType.OK)
    end

    local status = conditionStatus.Selected.Name
    local type = conditionType.Selected.Name
    local valueType = conditionValueType.Selected.Name
    local value = NewConditionContent.Value.Input.Text

    if status ~= "Ignore" and status ~= "Block" then
        MessageBox.Show("Error", "Invalid condition status", MessageType.OK)
    elseif not oh.Constants.Types[type] and not isUserdata(type) then
        MessageBox.Show("Error", "Invalid condition type", MessageType.OK)
    elseif valueType ~= "Value" and valueType ~= "Type" then
        MessageBox.Show("Error", "Invalid condition value association", MessageType.OK)
    elseif valueType == "Value" then
        if type == "string" then
            value = toString(value)
        elseif type == "number" then
            value = tonumber(value)

            if not value then
                return MessageBox.Show("Error", "Your input does not match the type you selected", MessageType.OK)
            end
        elseif type == "boolean" then
            if value == "true" then
                value = true
            elseif value == "false" then
                value = false
            else
                return MessageBox.Show("Error", "Your input does not match the type you selected", MessageType.OK)
            end
        else 
            local success, result = pcall(loadstring("return " .. value))

            if valueType == "Value" then
                if not success then
                    return MessageBox.Show("Error", "There was an error interpreting your input value", MessageType.OK)
                elseif typeof(result) ~= type then
                    return MessageBox.Show("Error", "Your input does not match the type you selected", MessageType.OK)
                else
                    value = result
                end
            end
        end
    else
        value = type
    end

    local selectedRemote = selected.conditionLog.Remote
    local argIndex = tonumber(NewConditionIndex.Value.Input.Text)
    local byType = valueType == "Type"

    if status == "Block" then
        selectedRemote:BlockArg(argIndex, value, byType)
    else
        selectedRemote:IgnoreArg(argIndex, value, byType)
    end

    if byType then
        Condition.new(selectedRemote, status, argIndex, nil, value)
    else
        Condition.new(selectedRemote, status, argIndex, value)
    end

    newRemoteCondition:Hide()
end)

NewConditionButtons.Cancel.MouseButton1Click:Connect(function()
    newRemoteCondition:Hide()
end)

NewConditionIndex.Add.MouseButton1Click:Connect(function()
    local newIndex = tonumber(NewConditionIndex.Value.Input.Text) + 1
    NewConditionIndex.Value.Input.Text = newIndex
end)

NewConditionIndex.Sub.MouseButton1Click:Connect(function()
    local newIndex = tonumber(NewConditionIndex.Value.Input.Text) - 1
    NewConditionIndex.Value.Input.Text = (newIndex <= 0 and 1) or newIndex
end)

NewConditionIndex.Value.Input.FocusLost:Connect(function()
    local newIndex = tonumber(NewConditionIndex.Value.Input.Text)

    if not newIndex or newIndex <= 0 then
        NewConditionIndex.Value.Input.Text = 1
    end
end)

pathContext:SetCallback(function()
    local selectedInstance = selected.logContext.Remote.Instance
    local oldStatus = oh.getStatus()

    oh.setStatus("Copying " .. selectedInstance.Name .. "'s path")
    setClipboard(getInstancePath(selectedInstance))
    wait(0.25)
    oh.setStatus(oldStatus)
end)

signalContext:SetCallback(function()
    local signalSpy = oh.Tools and oh.Tools.SignalSpy
    if signalSpy and selected.logContext then
        signalSpy.Open(selected.logContext.Remote.Instance)
    end
end)

conditionContext:SetCallback(function()
    selected.conditionLog = selected.logContext or selected.remoteLog

    createConditions(selected.conditionLog.Remote)
end)

clearContext:SetCallback(function()
    selected.logContext:Clear()
end)

ignoreContext:SetCallback(function()
    local selectedRemote = selected.logContext.Remote

    selected.logContext.Remote:Ignore()

    checkCurrentIgnored()

    if selectedRemote.Blocked then
        selected.logContext:PlayBlock()
    elseif selectedRemote.Ignored then
        selected.logContext:PlayIgnore()
    else
        selected.logContext:PlayNormal()
    end
end)

blockContext:SetCallback(function()
    local selectedRemote = selected.logContext.Remote

    selected.logContext.Remote:Block()

    checkCurrentBlocked()
    
    if selectedRemote.Blocked then
        selected.logContext:PlayBlock()
    elseif selectedRemote.Ignored then
        selected.logContext:PlayIgnore()
    else
        selected.logContext:PlayNormal()
    end
end)

removeContext:SetCallback(function()
    selected.logContext:Remove()
end)

pathContextSelected:SetCallback(function()
    local paths = ""

    for _i, log in pairs(selected.logs) do
        paths = paths .. getInstancePath(log.Remote.Instance) .. '\n'
    end

    setClipboard(paths)
    selected.logs = {}
end)

ignoreContextSelected:SetCallback(function()
    for _i, log in pairs(selected.logs) do
        local remote = log.Remote

        remote:Ignore()

        if remote.Blocked then
            log:PlayBlock()
        elseif remote.Ignored then
            log:PlayIgnore()
        end
    end

    selected.logs = {}
end)

unignoreContextSelected:SetCallback(function()
    for _i, log in pairs(selected.logs) do
        local remote = log.Remote

        if remote.Ignored then
            remote:Ignore()
        end

        if remote.Blocked then
            log:PlayBlock()
        else
            log:PlayNormal()
        end
    end

    selected.logs = {}
end)

blockContextSelected:SetCallback(function()
    for _i, log in pairs(selected.logs) do
        local remote = log.Remote

        if remote.Blocked then
            remote:Block()
        end

        if remote.Blocked then
            log:PlayBlock()
        elseif remote.Ignored then
            log:PlayIgnore()
        end
    end

    selected.logs = {}
end)

unblockContextSelected:SetCallback(function()
    for _i, log in pairs(selected.logs) do
        local remote = log.Remote

        remote:Unblock()

        if remote.Ignored then
            log:PlayIgnore()
        else
            log:PlayNormal()
        end
    end

    selected.logs = {}
end)

clearContextSelected:SetCallback(function()
    for _i, log in pairs(selected.logs) do
        log:Clear()
    end

    selected.logs = {}
end)

removeContextSelected:SetCallback(function()
    for _i, log in pairs(selected.logs) do
        log:Remove()
    end

    remoteList:Recalculate()
    selected.logs = {}
end)

scriptContext:SetCallback(function()
    local selectedRemote = selected.remoteLog.Remote.Instance
    local remoteClassName = selectedRemote.ClassName
    local remotePath = getInstancePath(selectedRemote)
    local method

    if remoteClassName == "RemoteEvent" then
        method = "FireServer"
    elseif remoteClassName == "RemoteFunction" then
        method = "InvokeServer"
    elseif remoteClassName == "BindableEvent" then
        method = "Fire"
    elseif remoteClassName == "BindableFunction" then
        method = "Invoke"
    end

    local oldStatus = oh.getStatus()
    oh.setStatus("Generating RemoteSpy Pseudocode ...")

    local arguments = {}
    for _index, selectedArgument in ipairs(selected.args) do
        local value = selectedArgument
        local valueType = type(value)
        local robloxValueType = typeof(value)
        local variableName = robloxValueType:sub(1, 1):upper() .. robloxValueType:sub(2)

        if valueType == "userdata" or valueType == "vector" then
            value = (typeof(value) == "Instance" and getInstancePath(value)) or userdataValue(value)
        elseif valueType == "table" then
            value = tableToString(value)
        elseif valueType == "string" then
            value = dataToString(value)
        else
            value = toString(value)
        end

        table.insert(arguments, {
            TypeName = variableName,
            Value = value,
        })
    end

    setClipboard(ScriptBuilder.RemoteCall({
        SourceRepositoryUrl = oh.Constants.SourceRepositoryUrl,
        RemotePath = remotePath,
        Method = method,
        Arguments = arguments,
    }))

    wait(0.25)
    oh.setStatus(oldStatus)
end)

callingScriptContext:SetCallback(function()
    local oldStatus = oh.getStatus()
    local description = Methods.DescribeCall({
        script = selected.callingScript,
        func = selected.func,
        args = selected.args,
    })

    oh.setStatus("Copying " .. selected.callingScript.Name .. "'s path")
    setClipboard(description.ScriptPath)
    wait(0.25)
    oh.setStatus(oldStatus)
end)

local SpyHook = ClosureSpy.Hook
spyClosureContext:SetCallback(function()
    if TabSelector.SelectTab("ClosureSpy") then
        local selectedClosure = Closure.new(selected.func)
        local result = SpyHook.new(selectedClosure)

        if result == false then
            MessageBox.Show("Already hooked", "You are already spying " .. selectedClosure.Name)
        elseif result == nil then
            MessageBox.Show("Cannot hook", ('Cannot hook "%s" because there are no upvalues'):format(selectedClosure.Name))
        end
    end
end)

repeatCallContext:SetCallback(function()
    local remoteInstance = selected.remoteLog.Remote.Instance
    local remoteClassName = remoteInstance.ClassName
    local method 

    if remoteClassName == "RemoteEvent" then
        method = "FireServer"
    elseif remoteClassName == "RemoteFunction" then
        method = "InvokeServer"
    elseif remoteClassName == "BindableEvent" then
        method = "Fire"
    elseif remoteClassName == "BindableFunction" then
        method = "Invoke"
    end

    local oldStatus = oh.getStatus()
    oh.setStatus("Recalling " .. remoteInstance.Name)

    remoteInstance[method](remoteInstance, unpack(selected.args))

    wait(0.25)

    oh.setStatus(oldStatus)
end)

viewAsHexContext:SetCallback(function()
    selected.callPodButton.hexViewEnabled = not selected.callPodButton.hexViewEnabled
    if not selected.callPodButton.oldStrings then
        selected.callPodButton.oldStrings = {}
    end

    for idx, arg in pairs(selected.args) do
        if type(arg) == "string" then
            local textObject = selected.callPodButton.Instance.Contents[tostring(idx)].Label
            if selected.callPodButton.hexViewEnabled then
                selected.callPodButton.oldStrings[idx] = arg
                local hexString = ""
                for i = 1, #arg do
                    hexString = hexString .. string.format("%02X ", arg:byte(i, i))
                end
                textObject.Text = hexString
            else
                textObject.Text = dataToString(selected.callPodButton.oldStrings[idx])
            end
        end
    end
end)

removeConditionContext:SetCallback(function()
    selected.condition:Remove()
    selected.condition = nil
end)

removeConditionContextSelected:SetCallback(function()
    for _i, condition in pairs(selected.conditions) do
        condition:Remove()
    end

    selected.conditions = {}
end)

conditionStatus:SetCallback(function(_dropdown, selected)
    local iconCondition = (selected.Name == "Ignore" and icons.ignore) or icons.block
    local icon = NewConditionContent.Status.Icon 

    VisualAssets.ApplyGlyph(icon, iconCondition)
    VisualAssets.ApplyGlyph(icon.Border, iconCondition)
end)

conditionType:SetCallback(function(_dropdown, selected)
    local icon = NewConditionContent.Type.Icon 
    VisualAssets.ApplyType(icon, selected.Name)
    VisualAssets.ApplyType(icon.Border, selected.Name)
end)

conditionValueType:SetCallback(function(_dropdown, selected)
    local iconCondition = (selected.Name == "Type" and icons.type) or "valueType"
    local icon = NewConditionContent.ValueType.Icon 

    VisualAssets.ApplyGlyph(icon, iconCondition)
    VisualAssets.ApplyGlyph(icon.Border, iconCondition)
end)

Methods.ConnectEvent(function(remoteInstance, callInfo)
    if not removed[remoteInstance] then
        local remote = currentRemotes[remoteInstance]
        local log = currentLogs[remoteInstance] or Log.new(remote)

        log:IncrementCalls(callInfo)
    end
end)

return RemoteSpy
