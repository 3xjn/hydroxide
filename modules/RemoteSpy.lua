local RemoteSpy = {}
local Remote = import("objects/Remote")
local ThreadTrace = import("modules/ThreadTrace")

local requiredMethods = {
    ["checkCaller"] = true,
    ["newCClosure"] = true,
    ["hookFunction"] = true,
    ["isReadOnly"] = true,
    ["setReadOnly"] = true,
    ["getInfo"] = true,
    ["getMetatable"] = true,
    ["setClipboard"] = true,
    ["getNamecallMethod"] = true,
    ["getCallingScript"] = true,
}

local remoteMethods = {
    FireServer = true,
    InvokeServer = true,
    Fire = true,
    Invoke = true
}

local remotesViewing = {
    RemoteEvent = true,
    RemoteFunction = false,
    BindableEvent = false,
    BindableFunction = false
}

local methodHooks = {
    RemoteEvent = Instance.new("RemoteEvent").FireServer,
    RemoteFunction = Instance.new("RemoteFunction").InvokeServer,
    BindableEvent = Instance.new("BindableEvent").Fire,
    BindableFunction = Instance.new("BindableFunction").Invoke
}

local currentRemotes = {}

local remoteDataEvent = Instance.new("BindableEvent")
table.insert(oh.Resources, remoteDataEvent)
local eventSet = false

local function connectEvent(callback)
    oh.Events.RemoteSpyData = remoteDataEvent.Event:Connect(callback)

    if not eventSet then
        eventSet = true
    end
end

local pcall = pcall

local function checkPermission(instance)
    if (instance.ClassName) then end
end

local function getFunctionFromThread(thread)
    if not thread or not debug.info then
        return nil
    end

    return ThreadTrace.resolveFunction(thread, {
        GetStackFunction = function(value, level)
            return debug.info(value, level, "f")
        end,
        IsExecutorClosure = isExecutorClosure,
        IsLClosure = isLClosure,
    })
end

local function inspectCall(instance, vargs, callingScript, callingFunction, emit)
    local remote = currentRemotes[instance]

    if not remote then
        remote = Remote.new(instance)
        currentRemotes[instance] = remote
    end

    local remoteIgnored = remote.Ignored
    local argsIgnored = remote:AreArgsIgnored(vargs)

    if eventSet and not remoteIgnored and not argsIgnored then
        local call = {
            script = callingScript,
            args = vargs,
            func = callingFunction
        }

        remote:IncrementCalls(call)
        emit(instance, call)
    end

    return remote.Blocked or remote:AreArgsBlocked(vargs)
end

local useOthHooks = type(othHook) == "function"
    and type(othUnhook) == "function"

if useOthHooks then
    local hookedTargets = {}
    local originalBindableFire

    local function emit(instance, call)
        originalBindableFire(remoteDataEvent, instance, call)
    end

    for className, target in pairs(methodHooks) do
        local originalMethod
        originalMethod = othHook(target, function(...)
            local instance = ...

            if typeof(instance) ~= "Instance" then
                return originalMethod(...)
            end

            local success = pcall(checkPermission, instance)
            if not success then
                return originalMethod(...)
            end

            if instance.ClassName == className
                and remotesViewing[instance.ClassName]
                and instance ~= remoteDataEvent then
                local originalThread = getOriginalThread and getOriginalThread()
                local callingScript = originalThread
                    and getScriptFromThread
                    and getScriptFromThread(originalThread)
                    or nil
                local callingFunction = getFunctionFromThread(originalThread)
                local vargs = {select(2, ...)}

                if inspectCall(instance, vargs, callingScript, callingFunction, emit) then
                    return
                end
            end

            return originalMethod(...)
        end)

        if className == "BindableEvent" then
            originalBindableFire = originalMethod
        end

        table.insert(hookedTargets, target)
    end

    local hookResource = {}

    function hookResource:Destroy()
        local failedTarget

        for _index, target in ipairs(hookedTargets) do
            if not othUnhook(target) then
                failedTarget = failedTarget or target
            end
        end

        table.clear(hookedTargets)
        assert(not failedTarget, "Failed to remove an OTH Remote Spy hook")
    end

    table.insert(oh.Resources, hookResource)
else
    local namecallTarget = getMetatable(game).__namecall
    local nmcTrampoline
    nmcTrampoline = hookMetaMethod(game, "__namecall", function(...)
        local instance = ...

        if typeof(instance) ~= "Instance" then
            return nmcTrampoline(...)
        end

        local method = getNamecallMethod()

        if method == "fireServer" then
            method = "FireServer"
        elseif method == "invokeServer" then
            method = "InvokeServer"
        end

        if remotesViewing[instance.ClassName]
            and instance ~= remoteDataEvent
            and remoteMethods[method] then
            local vargs = {select(2, ...)}
            local blocked = inspectCall(
                instance,
                vargs,
                getCallingScript(),
                getInfo(3).func,
                function(remoteInstance, call)
                    remoteDataEvent.Fire(remoteDataEvent, remoteInstance, call)
                end
            )

            if blocked then
                return
            end
        end

        return nmcTrampoline(...)
    end)
    oh.Hooks[nmcTrampoline] = namecallTarget

    for className, target in pairs(methodHooks) do
        local originalMethod
        originalMethod = hookFunction(target, newCClosure(function(...)
            local instance = ...

            if typeof(instance) ~= "Instance" then
                return originalMethod(...)
            end

            local success = pcall(checkPermission, instance)
            if not success then
                return originalMethod(...)
            end

            if instance.ClassName == className
                and remotesViewing[instance.ClassName]
                and instance ~= remoteDataEvent then
                local vargs = {select(2, ...)}
                local blocked = inspectCall(
                    instance,
                    vargs,
                    getCallingScript(),
                    getInfo(3).func,
                    function(remoteInstance, call)
                        remoteDataEvent:Fire(remoteInstance, call)
                    end
                )

                if blocked then
                    return
                end
            end

            return originalMethod(...)
        end))

        oh.Hooks[originalMethod] = target
    end
end

local ScriptGraph = import("modules/ScriptGraph")

function RemoteSpy.CallsFrom(scriptInstance, remotes)
    return ScriptGraph.CallsFrom(scriptInstance, remotes or currentRemotes)
end

function RemoteSpy.DescribeCall(call, context)
    return ScriptGraph.DescribeCall(call, context)
end

RemoteSpy.RemotesViewing = remotesViewing
RemoteSpy.CurrentRemotes = currentRemotes
RemoteSpy.ConnectEvent = connectEvent
RemoteSpy.RequiredMethods = requiredMethods
return RemoteSpy
