local ModuleScanner = {}
local Methods = import("modules/ModuleScanner")
local ScannerResults = import("modules/ScannerResults")

if not hasMethods(Methods.RequiredMethods) then
    return ModuleScanner
end

local List, ListButton = import("ui/controls/List")
local FilterPopover = import("ui/controls/FilterPopover")
local MessageBox, MessageType = import("ui/controls/MessageBox")
local ContextMenu, ContextMenuButton = import("ui/controls/ContextMenu")

local Runtime = import("ui/runtime")
local Page = Runtime.GetInterface().Base.Body.Pages.ModuleScanner
local Assets = Runtime.GetTemplates().ModuleScanner

local Query = Page.Query
local Search = Query.Search
local Refresh = Query.Refresh
local Filter = FilterPopover.new(Query, "ModuleScannerFilterPopoverInput")
local Results = Page.Results.Clip.Content

local moduleList = List.new(Results)
local moduleLogs = {}
local selectedLog
local currentQuery = ""

local pathContext = ContextMenuButton.new(nil, "Get Module Path")
local signalContext = ContextMenuButton.new(nil, "Inspect Signals")
moduleList:BindContextMenu(ContextMenu.new({ pathContext, signalContext }))

pathContext:SetCallback(function()
    local selectedInstance = selectedLog.ModuleScript.Instance

    setClipboard(getInstancePath(selectedInstance))
    MessageBox.Show("Success", ("%s's path was copied to your clipboard."):format(selectedInstance.Name), MessageType.OK)
end)

signalContext:SetCallback(function()
    local signalSpy = oh.Tools and oh.Tools.SignalSpy
    if signalSpy and selectedLog then
        signalSpy.Open(selectedLog.ModuleScript.Instance)
    end
end)

-- Log Object

local Log = {}

function Log.new(moduleScript, layoutOrder)
    local log = {}
    local moduleInstance = moduleScript.Instance
    local button = Assets.ModuleLog:Clone()
    local listButton = ListButton.new(button, moduleList)
    
    button.Name = moduleInstance.Name
    button.LayoutOrder = layoutOrder
    button:FindFirstChild("Name").Text = moduleInstance.Name
    button.Protos.Text = #moduleScript.Protos
    button.Constants.Text = #moduleScript.Constants

    listButton:SetRightCallback(function()
        selectedLog = log
    end)

    moduleLogs[moduleInstance] = log

    log.ModuleScript = moduleScript
    log.Button = listButton
    return log
end

-- UI Functionality

local function addModules(query)
    currentQuery = query or currentQuery
    moduleList:Clear()
    moduleLogs = {}

    local results = ScannerResults.Sorted(Methods.Scan(currentQuery, oh.State.ScannerFilters:Get()))
    for layoutOrder, moduleScript in ipairs(results) do
        Log.new(moduleScript, layoutOrder)
    end

    moduleList:Recalculate()
end

Search.FocusLost:Connect(function(returned)
    if returned then
        addModules(Search.Text)
    end
end)

Refresh.MouseButton1Click:Connect(function()
    addModules(currentQuery)
end)

Filter:SetCallback(function(filters)
    oh.State.ScannerFilters:Set(filters)
end)

oh.Events.ModuleScannerFilterState = oh.State.ScannerFilters:Subscribe(function(filters)
    Filter:SetValues(filters, false)
    addModules(currentQuery)
end)

return ModuleScanner
