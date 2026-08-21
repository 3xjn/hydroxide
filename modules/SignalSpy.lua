local ReactiveState
if import then
    ReactiveState = import("modules/ReactiveState")
else
    ReactiveState = require("./ReactiveState")
end

local SignalSpy = {}

local requiredMethods = {
    getConnections = true,
    getSignalArgumentsInfo = true,
}

local function fullName(instance)
    local succeeded, result = pcall(instance.GetFullName, instance)
    if succeeded then
        return result
    end

    return tostring(instance)
end

local function freezeArray(items)
    for _, item in ipairs(items) do
        table.freeze(item)
    end

    return table.freeze(items)
end

function SignalSpy.new(options)
    assert(type(options.GetEventsOfClass) == "function", "SignalSpy requires GetEventsOfClass")
    assert(type(options.GetConnections) == "function", "SignalSpy requires GetConnections")
    assert(type(options.GetSignalArgumentsInfo) == "function", "SignalSpy requires GetSignalArgumentsInfo")

    local snapshotState = ReactiveState.new(table.freeze({
        Revision = 0,
        Target = nil,
        Signals = table.freeze({}),
    }))
    local objectIds = setmetatable({}, { __mode = "k" })
    local nextObjectId = 0
    local targetById = {}
    local signalById = {}
    local connectionById = {}
    local functionByConnectionId = {}
    local threadByConnectionId = {}
    local scriptByConnectionId = {}
    local stateByConnectionId = {}
    local currentTarget
    local destroyed = false
    local registry = {}

    local function objectId(object)
        local id = objectIds[object]
        if id then
            return id
        end

        nextObjectId = nextObjectId + 1
        objectIds[object] = nextObjectId
        return nextObjectId
    end

    local function summarizeArguments(signal)
        local succeeded, result = pcall(options.GetSignalArgumentsInfo, signal)
        if not succeeded then
            return table.freeze({}), tostring(result)
        end

        local arguments = {}
        for index, argument in ipairs(result) do
            table.insert(arguments, {
                Index = index,
                Name = argument.Name or ("argument" .. index),
                Type = argument.Type or "any",
            })
        end

        return freezeArray(arguments), nil
    end

    local function resolveConnectionRelationship(
        connection,
        connectionId,
        nextThreadByConnectionId,
        nextScriptByConnectionId,
        nextStateByConnectionId
    )
        local thread = connection.Thread
        if thread == nil or type(options.GetScriptFromThread) ~= "function" then
            return nil, nil, false
        end

        nextThreadByConnectionId[connectionId] = thread

        local scriptSucceeded, script = pcall(options.GetScriptFromThread, thread)
        if not scriptSucceeded or script == nil then
            return nil, nil, false
        end

        nextScriptByConnectionId[connectionId] = script

        local state
        if type(options.GetLuaState) == "function" then
            local stateSucceeded, result = pcall(options.GetLuaState, script)
            if stateSucceeded then
                state = result
            end
        end

        if state ~= nil then
            nextStateByConnectionId[connectionId] = state
        end

        local stateId = state and state.Id or nil
        local actorStateKnown = false
        if stateId ~= nil and options.ActorStates then
            local knownSucceeded, knownState = pcall(options.ActorStates.ResolveState, options.ActorStates, stateId)
            actorStateKnown = knownSucceeded and knownState == state
        end

        return {
            Name = script.Name or tostring(script),
            FullName = fullName(script),
        }, stateId, actorStateKnown
    end

    local function summarizeConnections(
        signal,
        nextConnectionById,
        nextFunctionByConnectionId,
        nextThreadByConnectionId,
        nextScriptByConnectionId,
        nextStateByConnectionId
    )
        local succeeded, result = pcall(options.GetConnections, signal)
        if not succeeded then
            return table.freeze({}), tostring(result)
        end

        local connections = {}
        for index, connection in ipairs(result) do
            local connectionId = objectId(connection)
            nextConnectionById[connectionId] = connection

            local connectedFunction = connection.Function
            if connectedFunction ~= nil then
                nextFunctionByConnectionId[connectionId] = connectedFunction
            end

            local script, stateId, actorStateKnown = resolveConnectionRelationship(
                connection,
                connectionId,
                nextThreadByConnectionId,
                nextScriptByConnectionId,
                nextStateByConnectionId
            )

            table.insert(connections, {
                Id = connectionId,
                Index = index,
                Enabled = connection.Enabled == true,
                ForeignState = connection.ForeignState == true,
                LuaConnection = connection.LuaConnection == true,
                LuaWaitConnection = connection.LuaWaitConnection == true,
                HasFunction = connectedFunction ~= nil,
                HasThread = connection.Thread ~= nil,
                Script = script and table.freeze(script) or nil,
                StateId = stateId,
                ActorStateKnown = actorStateKnown,
            })
        end

        return freezeArray(connections), nil
    end

    local function collect(target)
        local nextTargetById = {}
        local nextSignalById = {}
        local nextConnectionById = {}
        local nextFunctionByConnectionId = {}
        local nextThreadByConnectionId = {}
        local nextScriptByConnectionId = {}
        local nextStateByConnectionId = {}
        local targetId = objectId(target)
        nextTargetById[targetId] = target
        local signals = {}

        local eventsSucceeded, events = pcall(options.GetEventsOfClass, target.ClassName)
        local discoveryError
        if not eventsSucceeded then
            discoveryError = tostring(events)
            events = {}
        end

        local seenNames = {}
        for _, reflectedEvent in ipairs(events) do
            local name = reflectedEvent.Name
            if name and not seenNames[name] then
                seenNames[name] = true

                local signalSucceeded, signal = pcall(function()
                    return target[name]
                end)
                local signalId
                local arguments = table.freeze({})
                local connections = table.freeze({})
                local argumentError
                local connectionError
                local accessError

                if signalSucceeded and signal ~= nil then
                    signalId = objectId(signal)
                    nextSignalById[signalId] = signal
                    arguments, argumentError = summarizeArguments(signal)
                    connections, connectionError = summarizeConnections(
                        signal,
                        nextConnectionById,
                        nextFunctionByConnectionId,
                        nextThreadByConnectionId,
                        nextScriptByConnectionId,
                        nextStateByConnectionId
                    )
                else
                    accessError = tostring(signal)
                end

                table.insert(signals, {
                    Id = signalId,
                    Name = name,
                    Owner = reflectedEvent.Owner or target.ClassName,
                    Arguments = arguments,
                    Connections = connections,
                    AccessError = accessError,
                    ArgumentError = argumentError,
                    ConnectionError = connectionError,
                })
            end
        end

        table.sort(signals, function(left, right)
            return left.Name < right.Name
        end)

        return {
            Target = table.freeze({
                Id = targetId,
                Name = target.Name or tostring(target),
                ClassName = target.ClassName,
                FullName = fullName(target),
            }),
            Signals = freezeArray(signals),
            DiscoveryError = discoveryError,
        }, {
            targetById = nextTargetById,
            signalById = nextSignalById,
            connectionById = nextConnectionById,
            functionByConnectionId = nextFunctionByConnectionId,
            threadByConnectionId = nextThreadByConnectionId,
            scriptByConnectionId = nextScriptByConnectionId,
            stateByConnectionId = nextStateByConnectionId,
        }
    end

    function registry:Summarize(target)
        assert(target ~= nil, "SignalSpy inspection requires an Instance")
        local snapshot = collect(target)
        return table.freeze({
            Revision = snapshotState:Get().Revision,
            Target = snapshot.Target,
            Signals = snapshot.Signals,
            DiscoveryError = snapshot.DiscoveryError,
        })
    end

    function registry:Inspect(target)
        if destroyed then
            return snapshotState:Get()
        end

        assert(target ~= nil, "SignalSpy inspection requires an Instance")
        currentTarget = target

        local snapshot, maps = collect(target)
        targetById = maps.targetById
        signalById = maps.signalById
        connectionById = maps.connectionById
        functionByConnectionId = maps.functionByConnectionId
        threadByConnectionId = maps.threadByConnectionId
        scriptByConnectionId = maps.scriptByConnectionId
        stateByConnectionId = maps.stateByConnectionId

        local nextSnapshot = table.freeze({
            Revision = snapshotState:Get().Revision + 1,
            Target = snapshot.Target,
            Signals = snapshot.Signals,
            DiscoveryError = snapshot.DiscoveryError,
        })
        snapshotState:Set(nextSnapshot)
        return nextSnapshot
    end

    function registry:Refresh()
        if currentTarget == nil then
            return snapshotState:Get()
        end

        return registry:Inspect(currentTarget)
    end

    function registry:Get()
        return snapshotState:Get()
    end

    function registry:Subscribe(callback, emitCurrent)
        return snapshotState:Subscribe(callback, emitCurrent)
    end

    function registry:ResolveTarget(targetId)
        return targetById[targetId]
    end

    function registry:ResolveSignal(signalId)
        return signalById[signalId]
    end

    function registry:ResolveConnection(connectionId)
        return connectionById[connectionId]
    end

    function registry:ResolveFunction(connectionId)
        return functionByConnectionId[connectionId]
    end

    function registry:ResolveThread(connectionId)
        return threadByConnectionId[connectionId]
    end

    function registry:ResolveScript(connectionId)
        return scriptByConnectionId[connectionId]
    end

    function registry:ResolveState(connectionId)
        return stateByConnectionId[connectionId]
    end

    function registry:Destroy()
        if destroyed then
            return
        end

        destroyed = true
        currentTarget = nil
        targetById = {}
        signalById = {}
        connectionById = {}
        functionByConnectionId = {}
        threadByConnectionId = {}
        scriptByConnectionId = {}
        stateByConnectionId = {}
        snapshotState:Destroy()
    end

    return registry
end

SignalSpy.RequiredMethods = requiredMethods
return SignalSpy
