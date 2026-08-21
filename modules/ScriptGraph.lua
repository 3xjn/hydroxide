local ScannerResults
if import then
    ScannerResults = import("modules/ScannerResults")
else
    ScannerResults = require("./ScannerResults")
end

local ScriptGraph = {}

local function defaultContext()
    local environment = getgenv()
    local session = environment.oh
    local methods = session and session.Methods or {}
    return {
        GetInfo = methods.getInfo or environment.getInfo or getinfo,
        GetInstancePath = environment.getInstancePath,
        ToString = environment.toString or tostring,
        GetEnvironment = getfenv,
        IsInstance = function(value)
            return typeof(value) == "Instance"
        end,
    }
end

local function loadClosureSpy()
    if import then
        return import("modules/ClosureSpy")
    end

    return nil
end

local function liveOptions()
    local session = getgenv().oh
    local state = session and (session.State or session.state)
    local remotes
    if session and session.Api and session.Api.RemoteSpy then
        remotes = session.Api.RemoteSpy.CurrentRemotes
    elseif import then
        remotes = import("modules/RemoteSpy").CurrentRemotes
    end

    local closureSpy = loadClosureSpy()
    return {
        Context = defaultContext(),
        SignalSpy = state and state.SignalSpy,
        Remotes = remotes,
        ClosureSpy = closureSpy,
        ListHooks = closureSpy and closureSpy.List,
        GetScript = closureSpy and closureSpy.GetScript,
    }
end

local function isScannerResult(value)
    return type(value) == "table" and value.Instance ~= nil
end

local function asScannerResult(container, options)
    if isScannerResult(container) then
        return container
    end

    local newScript = options.NewScript
    if not newScript and import then
        local isModule = container.ClassName == "ModuleScript"
            or (container.IsA and container:IsA("ModuleScript"))
        if isModule then
            newScript = import("objects/ModuleScript").new
        else
            newScript = import("objects/LocalScript").new
        end
    end

    assert(newScript, "ScriptGraph.Describe requires a scanner result or NewScript")
    return newScript(container)
end

function ScriptGraph.CallsFrom(scriptInstance, remotes)
    local matches = {}
    remotes = remotes or {}

    for instance, remote in pairs(remotes) do
        local calls = {}
        for _, call in ipairs(remote.Logs or {}) do
            if call.script == scriptInstance then
                table.insert(calls, call)
            end
        end

        if #calls > 0 then
            table.insert(matches, {
                Remote = remote,
                Instance = instance,
                Calls = calls,
            })
        end
    end

    return matches
end

function ScriptGraph.DescribeCall(call, context)
    context = context or defaultContext()
    local script = call.script
    local func = call.func
    return {
        Script = script,
        ScriptPath = script and context.GetInstancePath and context.GetInstancePath(script) or nil,
        Function = func,
        FunctionName = func and ScannerResults.ClosureName(func, context) or nil,
        Args = call.args,
    }
end

function ScriptGraph.HooksFor(scriptInstance, options)
    options = options or liveOptions()
    local context = options.Context or defaultContext()
    local closureSpy = options.ClosureSpy
    local listHooks = options.ListHooks or (closureSpy and closureSpy.List) or function()
        return {}
    end
    local getScript = options.GetScript or (closureSpy and closureSpy.GetScript)
    local matches = {}

    if not getScript then
        return matches
    end

    for _, hook in ipairs(listHooks()) do
        local owner = getScript(hook.Closure, context)
        if owner == scriptInstance then
            table.insert(matches, hook)
        end
    end

    return matches
end

function ScriptGraph.Describe(container, options)
    options = options or liveOptions()
    local context = options.Context or defaultContext()
    container = asScannerResult(container, options)
    local instance = container.Instance
    local script = ScannerResults.Describe(container, context)
    local signals
    local signalSpy = options.SignalSpy
    if signalSpy and signalSpy.Summarize then
        signals = signalSpy:Summarize(instance)
    end

    local remoteCalls = {}
    for _, match in ipairs(ScriptGraph.CallsFrom(instance, options.Remotes or {})) do
        local describedCalls = {}
        for _, call in ipairs(match.Calls) do
            table.insert(describedCalls, ScriptGraph.DescribeCall(call, context))
        end

        local remoteInstance = match.Instance
        table.insert(remoteCalls, {
            Remote = match.Remote,
            Instance = remoteInstance,
            Name = remoteInstance and remoteInstance.Name or nil,
            ClassName = remoteInstance and remoteInstance.ClassName or nil,
            Path = remoteInstance and context.GetInstancePath and context.GetInstancePath(remoteInstance) or nil,
            Calls = describedCalls,
        })
    end

    local closureHooks = {}
    for _, hook in ipairs(ScriptGraph.HooksFor(instance, options)) do
        local callers = {}
        for _, call in ipairs(hook.Logs or {}) do
            table.insert(callers, ScriptGraph.DescribeCall(call, context))
        end

        table.insert(closureHooks, {
            Hook = hook,
            Name = hook.Closure and hook.Closure.Name or nil,
            Callers = callers,
        })
    end

    return {
        Script = script,
        Signals = signals,
        RemoteCalls = remoteCalls,
        ClosureHooks = closureHooks,
    }
end

return ScriptGraph
