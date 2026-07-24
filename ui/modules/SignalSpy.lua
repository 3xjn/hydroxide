local SignalSpy = {}
local Methods = import("modules/SignalSpy")
local InstancePath = import("modules/InstancePath")

if not hasMethods(Methods.RequiredMethods) or not oh.State.SignalSpy then
    return SignalSpy
end

local ClosureSpy = import("modules/ClosureSpy")
local Closure = import("objects/Closure")
local List, ListButton = import("ui/controls/List")
local ContextMenu, ContextMenuButton = import("ui/controls/ContextMenu")
local MessageBox = import("ui/controls/MessageBox")
local TabSelector = import("ui/controls/TabSelector")
local VisualAssets = import("ui/assets")

local Runtime = import("ui/runtime")
local Page = Runtime.GetInterface().Base.Body.Pages.SignalSpy
local Assets = Runtime.GetTemplates().SignalSpy
local State = oh.State.SignalSpy
local Target = Page.Target
local TargetQuery = Page.TargetQuery
local TargetPath = TargetQuery.Path
local Inspect = TargetQuery.Inspect
local Query = Page.Query
local Search = Query.Search
local Refresh = Query.Refresh
local ResultsClip = Page.Results.Clip
local Results = ResultsClip.Content
local ResultStatus = ResultsClip.ResultStatus
local signalList = List.new(Results)
local selectedConnectionId

local spyClosureContext = ContextMenuButton.new(nil, "Spy Closure")
signalList:BindContextMenu(ContextMenu.new({ spyClosureContext }))

local function argumentSignature(arguments)
    local fields = {}
    for _, argument in ipairs(arguments) do
        table.insert(fields, argument.Name .. ": " .. argument.Type)
    end

    return "(" .. table.concat(fields, ", ") .. ")"
end

local function connectionFlags(connection)
    local flags = {}
    table.insert(flags, connection.Enabled and "enabled" or "disabled")

    if connection.LuaConnection then
        table.insert(flags, "lua")
    end
    if connection.LuaWaitConnection then
        table.insert(flags, "wait")
    end
    if connection.ForeignState then
        table.insert(flags, "foreign")
    end
    if connection.HasFunction then
        table.insert(flags, "closure")
    end

    return table.concat(flags, " · ")
end

local function connectionRelationship(connection)
    if connection.Script then
        if connection.StateId and connection.ActorStateKnown then
            return connection.Script.FullName .. "  →  Actor state #" .. connection.StateId
        elseif connection.StateId then
            return connection.Script.FullName .. "  →  Lua state #" .. connection.StateId
        end

        return connection.Script.FullName
    elseif connection.ForeignState then
        return "Foreign state · source unavailable"
    end

    return "Source unresolved"
end

local function matches(signal, query)
    if query == "" then
        return true
    end

    local searchable = signal.Name
        .. " "
        .. signal.Owner
        .. " "
        .. argumentSignature(signal.Arguments)
    return searchable:lower():find(query, 1, true) ~= nil
end

local function render(snapshot)
    signalList:Clear()
    selectedConnectionId = nil

    if snapshot.Target then
        Target:FindFirstChild("Name").Text = snapshot.Target.Name
        Target.Path.Text = snapshot.Target.FullName
    else
        Target:FindFirstChild("Name").Text = "No instance selected"
        Target.Path.Text = "Open an instance from another tool"
    end

    local query = Search.Text:lower()
    local renderedRows = 0

    for _, signal in ipairs(snapshot.Signals) do
        if matches(signal, query) then
            local signalButton = Assets.SignalLog:Clone()
            local signalListButton = ListButton.new(signalButton, signalList)
            local signature = argumentSignature(signal.Arguments)

            signalButton.Name = signal.Name
            signalButton:FindFirstChild("Name").Text = signal.Name
            signalButton.Signature.Text = signal.AccessError and "unavailable" or signature
            signalButton.Connections.Text = tostring(#signal.Connections)
            VisualAssets.ApplyGlyph(signalButton.Icon, "SignalSpy")
            signalListButton:SetRightCallback(function()
                selectedConnectionId = nil
            end)
            renderedRows = renderedRows + 1

            for _, connection in ipairs(signal.Connections) do
                local connectionButton = Assets.ConnectionLog:Clone()
                local connectionListButton = ListButton.new(connectionButton, signalList)
                connectionButton.Name = signal.Name .. ":" .. connection.Index
                connectionButton.Index.Text = "↳ #" .. connection.Index
                connectionButton.Flags.Text = connectionFlags(connection)
                connectionButton.Relationship.Text = connectionRelationship(connection)
                connectionListButton:SetRightCallback(function()
                    selectedConnectionId = connection.Id
                end)
                renderedRows = renderedRows + 1
            end
        end
    end

    if snapshot.DiscoveryError then
        ResultStatus.Text = "Signal discovery failed: " .. snapshot.DiscoveryError
    elseif not snapshot.Target then
        ResultStatus.Text = "Open an instance from Remote, Script, or Module Scanner"
    elseif renderedRows == 0 then
        ResultStatus.Text = query == "" and "No reflected events found" or "No matching events"
    end
    ResultStatus.Visible = renderedRows == 0
    signalList:Recalculate()
end

spyClosureContext:SetCallback(function()
    local connectedFunction = selectedConnectionId and State:ResolveFunction(selectedConnectionId)
    if not connectedFunction then
        MessageBox.Show("Closure unavailable", "Volt did not expose a Lua closure for this connection.")
        return
    end

    if TabSelector.SelectTab("ClosureSpy") then
        local closure = Closure.new(connectedFunction)
        local result = ClosureSpy.Hook.new(closure)

        if result == false then
            MessageBox.Show("Already hooked", "You are already spying " .. closure.Name)
        elseif result == nil then
            MessageBox.Show("Cannot hook", ('Cannot hook "%s" because there are no upvalues'):format(closure.Name))
        end
    end
end)

oh.Events.SignalSpySearch = Search:GetPropertyChangedSignal("Text"):Connect(function()
    render(State:Get())
end)

oh.Events.SignalSpyRefresh = Refresh.MouseButton1Click:Connect(function()
    State:Refresh()
end)

local function inspectPath()
    local instance, resolveError = InstancePath.Resolve(TargetPath.Text, {
        Game = game,
        Workspace = workspace,
        GetService = function(name)
            return game:GetService(name)
        end,
        GetMember = function(parent, name)
            return parent[name]
        end,
        IsInstance = function(value)
            return typeof(value) == "Instance"
        end,
    })

    if not instance then
        MessageBox.Show("Instance not found", resolveError)
        return
    end

    TargetPath.Text = getInstancePath(instance)
    State:Inspect(instance)
end

oh.Events.SignalSpyInspect = Inspect.MouseButton1Click:Connect(inspectPath)
oh.Events.SignalSpyTargetPath = TargetPath.FocusLost:Connect(function(returned)
    if returned then
        inspectPath()
    end
end)

function SignalSpy.Open(instance)
    TargetPath.Text = getInstancePath(instance)
    State:Inspect(instance)
    return TabSelector.SelectTab("SignalSpy")
end

oh.Tools = oh.Tools or {}
oh.Tools.SignalSpy = SignalSpy
oh.Events.SignalSpyState = State:Subscribe(render)

return SignalSpy
