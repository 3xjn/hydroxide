local ScriptGraph = require("../modules/ScriptGraph")
local ClosureSpy = require("../modules/ClosureSpy")

local function instance(name, className, path)
    return {
        Name = name,
        ClassName = className,
        Path = path,
        GetFullName = function()
            return path
        end,
    }
end

local door = instance("DoorManager", "LocalScript", "Players.LocalPlayer.PlayerScripts.DoorManager")
local movement = instance("Movement", "LocalScript", "Players.LocalPlayer.PlayerScripts.Movement")
local throwEvent = instance("ThrowEvent", "RemoteEvent", "ReplicatedStorage.ThrowEvent")
local function onThrow() end
local function unnamedProto() end
local linkedPart = instance("Door", "Part", "Workspace.Door")

local context = {
    GetInfo = function(value)
        if value == onThrow then
            return { name = "onThrow" }
        end
        return { name = "" }
    end,
    GetInstancePath = function(value)
        return value.Path
    end,
    ToString = tostring,
    GetEnvironment = function(value)
        if value == onThrow then
            return { script = door }
        end
        return {}
    end,
    IsInstance = function(value)
        return type(value) == "table" and value.ClassName ~= nil
    end,
}

local container = {
    Instance = door,
    Protos = {
        [1] = onThrow,
        [2] = unnamedProto,
    },
    Constants = {
        [1] = "ThrowEvent",
    },
    Environment = {
        script = door,
        part = linkedPart,
    },
}

local remotes = {
    [throwEvent] = {
        Logs = {
            {
                script = door,
                func = onThrow,
                args = { "token" },
            },
            {
                script = movement,
                func = unnamedProto,
                args = { false },
            },
        },
    },
}

local hook = {
    Target = onThrow,
    Closure = {
        Name = "onThrow",
        Data = onThrow,
    },
    Logs = {
        {
            script = movement,
            args = { 1 },
        },
    },
}

local signalReads = 0
local signalSpy = {
    Summarize = function(_self, target)
        signalReads = signalReads + 1
        assert(target == door, "Signal summary must use the script instance, not a decompile dump")
        return {
            Target = { Name = door.Name, FullName = door.Path },
            Signals = {
                {
                    Name = "AncestryChanged",
                    Connections = {
                        {
                            Script = { FullName = movement.Path },
                            HasFunction = true,
                        },
                    },
                },
            },
        }
    end,
    Inspect = function()
        error("Script graph reads must not steal the Signal Spy UI target")
    end,
}

local fromDoor = ScriptGraph.CallsFrom(door, remotes)
assert(#fromDoor == 1, "Remote Spy logs must be queryable by calling script")
assert(fromDoor[1].Instance == throwEvent, "CallsFrom must keep the live remote")
assert(#fromDoor[1].Calls == 1, "Only calls from the requested script may be returned")
assert(fromDoor[1].Calls[1].func == onThrow, "The calling function must remain attached to the call")

local describedCall = ScriptGraph.DescribeCall(fromDoor[1].Calls[1], context)
assert(describedCall.ScriptPath == door.Path, "Remote callers must expose a canonical script path")
assert(describedCall.FunctionName == "onThrow", "Remote callers must name the live calling closure")

assert(ClosureSpy.GetScript({ Data = onThrow }, context) == door, "A closure must resolve back to its owning script")
assert(ClosureSpy.GetScriptPath({ Data = onThrow }, context) == door.Path, "Get Script Path must use the same closure-to-script link as the UI")

local recorded = {
    Logs = {},
    Ignored = false,
    AreArgsIgnored = function()
        return false
    end,
}
log(recorded, movement, "fired")
assert(recorded.Logs[1].script == movement, "Closure Spy must keep calling scripts on the hook")
assert(recorded.Logs[1].args[1] == "fired", "Closure Spy must keep call arguments on the hook")

local graph = ScriptGraph.Describe(container, {
    Context = context,
    SignalSpy = signalSpy,
    Remotes = remotes,
    GetScript = ClosureSpy.GetScript,
    ListHooks = function()
        return { hook }
    end,
})

assert(graph.Script.Path == door.Path, "The graph must start from the Script Scanner path")
assert(graph.Script.Protos[1].Value == onThrow, "Script protos must stay live so Spy Closure can hook them")
assert(graph.Signals.Signals[1].Connections[1].Script.FullName == movement.Path, "Signal connections must name the linked script")
assert(signalReads == 1, "Signal discovery must run once for a graph read")
assert(#graph.RemoteCalls == 1 and graph.RemoteCalls[1].Path == throwEvent.Path, "The graph must list remotes this script has called")
assert(graph.RemoteCalls[1].Calls[1].Function == onThrow, "Remote edges must keep the calling closure")
assert(#graph.ClosureHooks == 1 and graph.ClosureHooks[1].Name == "onThrow", "Hooked closures owned by the script must be listed")
assert(graph.ClosureHooks[1].Callers[1].ScriptPath == movement.Path, "Hook logs must expose who called the script's closure")

local isolated = ScriptGraph.Describe(container, {
    Context = context,
    Remotes = {},
    ListHooks = function()
        return {}
    end,
})
assert(isolated.Signals == nil, "A missing Signal Spy must not invent signal edges")
assert(#isolated.RemoteCalls == 0 and #isolated.ClosureHooks == 0, "Empty spy state must produce empty link lists")

print("script-graph-contracts-ok")
