local SignalSpy = require("../modules/SignalSpy")

local function instance(name, className, path)
    return {
        Name = name,
        ClassName = className,
        GetFullName = function()
            return path
        end,
    }
end

local changedSignal = {}
local touchedSignal = {}
local inaccessibleReads = 0
local target = setmetatable(instance("Target", "Part", "Workspace.Target"), {
    __index = function(self, key)
        if key == "Changed" then
            return changedSignal
        elseif key == "Touched" then
            return touchedSignal
        elseif key == "UnsafeEvent" then
            inaccessibleReads = inaccessibleReads + 1
            error("event is not scriptable")
        end

        return rawget(self, key)
    end,
})

local sourceScript = instance("Movement", "LocalScript", "Players.LocalPlayer.PlayerScripts.Movement")
local thread = coroutine.create(function() end)
local closure = function() end
local connection = {
    Enabled = true,
    ForeignState = false,
    LuaConnection = true,
    LuaWaitConnection = false,
    Function = closure,
    Thread = thread,
}
local foreignConnection = {
    Enabled = false,
    ForeignState = true,
    LuaConnection = false,
    LuaWaitConnection = false,
}
local actorState = {
    Id = 42,
}
local actorStates = {
    ResolveState = function(_, stateId)
        if stateId == actorState.Id then
            return actorState
        end
    end,
}
local eventInventoryReads = 0

local registry = SignalSpy.new({
    GetEventsOfClass = function(className)
        assert(className == "Part", "Signal discovery must use the target class")
        eventInventoryReads = eventInventoryReads + 1
        return {
            { Name = "Touched", Owner = "BasePart" },
            { Name = "Changed", Owner = "Instance" },
            { Name = "Touched", Owner = "BasePart" },
            { Name = "UnsafeEvent", Owner = "Part" },
        }
    end,
    GetConnections = function(signal)
        if signal == touchedSignal then
            return { connection, foreignConnection }
        end

        return {}
    end,
    GetSignalArgumentsInfo = function(signal)
        if signal == touchedSignal then
            return {
                { Name = "otherPart", Type = "BasePart" },
            }
        end

        return {}
    end,
    GetScriptFromThread = function(value)
        assert(value == thread, "Connection relationships must start from the reported thread")
        return sourceScript
    end,
    GetLuaState = function(script)
        assert(script == sourceScript, "Lua state resolution must use the connection's script")
        return actorState
    end,
    ActorStates = actorStates,
})

local deliveredRevisions = {}
local subscription = registry:Subscribe(function(snapshot)
    table.insert(deliveredRevisions, snapshot.Revision)
end)

local snapshot = registry:Inspect(target)
assert(eventInventoryReads == 1, "Inspection must enumerate reflected events once")
assert(inaccessibleReads == 1, "Inspection must attempt each reflected event once")
assert(snapshot.Revision == 1, "The first inspection must publish revision one")
assert(snapshot.Target.Name == "Target" and snapshot.Target.FullName == "Workspace.Target", "Target metadata must be useful")
assert(#snapshot.Signals == 3, "Duplicate inherited event metadata must be collapsed")
assert(
    snapshot.Signals[1].Name == "Changed"
        and snapshot.Signals[2].Name == "Touched"
        and snapshot.Signals[3].Name == "UnsafeEvent",
    "Signals must be sorted by name"
)

local touched = snapshot.Signals[2]
assert(touched.Owner == "BasePart", "Signal summaries must retain the reflected owner class")
assert(#touched.Arguments == 1, "Signal argument metadata must be published")
assert(
    touched.Arguments[1].Name == "otherPart" and touched.Arguments[1].Type == "BasePart",
    "Signal argument names and types must survive discovery"
)
assert(#touched.Connections == 2, "Every signal connection must be summarized")

local localSummary = touched.Connections[1]
assert(localSummary.Enabled and localSummary.LuaConnection, "Connection status flags must be preserved")
assert(localSummary.HasFunction and localSummary.HasThread, "Accessible closure and thread relationships must be advertised")
assert(localSummary.Script.FullName == sourceScript:GetFullName(), "Resolved script metadata must be published")
assert(localSummary.StateId == 42 and localSummary.ActorStateKnown, "Resolved Lua states must link to Actor inventory")
assert(localSummary.Function == nil and localSummary.Thread == nil, "Snapshots must not expose live connection internals")
assert(registry:ResolveConnection(localSummary.Id) == connection, "Connection IDs must resolve to live connections")
assert(registry:ResolveFunction(localSummary.Id) == closure, "Closure resolution must stay behind the registry")
assert(registry:ResolveThread(localSummary.Id) == thread, "Thread resolution must stay behind the registry")
assert(registry:ResolveScript(localSummary.Id) == sourceScript, "Script resolution must stay behind the registry")
assert(registry:ResolveState(localSummary.Id) == actorState, "Lua state resolution must stay behind the registry")
assert(registry:ResolveSignal(touched.Id) == touchedSignal, "Signal IDs must resolve to live RBXScriptSignals")
assert(registry:ResolveTarget(snapshot.Target.Id) == target, "Target IDs must resolve to the live Instance")

local foreignSummary = touched.Connections[2]
assert(foreignSummary.ForeignState, "ForeignState must be retained as a connection clue")
assert(
    foreignSummary.StateId == nil and not foreignSummary.ActorStateKnown,
    "ForeignState alone must never invent a Lua or Actor state relationship"
)

local inaccessible = snapshot.Signals[3]
assert(inaccessible.AccessError ~= nil, "An inaccessible event must publish its own error")
assert(#inaccessible.Connections == 0, "One inaccessible event must not abort the rest of discovery")
assert(
    table.isfrozen(snapshot)
        and table.isfrozen(snapshot.Target)
        and table.isfrozen(snapshot.Signals)
        and table.isfrozen(touched)
        and table.isfrozen(touched.Arguments)
        and table.isfrozen(touched.Connections),
    "Signal Spy snapshots must be immutable"
)

local originalConnectionId = localSummary.Id
local refreshed = registry:Refresh()
assert(refreshed.Revision == 2, "Refresh must publish a replacement snapshot")
assert(
    refreshed.Signals[2].Connections[1].Id == originalConnectionId,
    "Stable connection objects must keep their IDs across refreshes"
)
assert(
    deliveredRevisions[1] == 0 and deliveredRevisions[2] == 1 and deliveredRevisions[3] == 2,
    "Subscribers must receive the initial state and every inspection replacement"
)

subscription:Disconnect()
registry:Destroy()
assert(registry:Inspect(target).Revision == 2, "Destroyed registries must reject later inspections")

print("signal-spy-contracts-ok")
