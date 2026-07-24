local ReactiveState
if import then
    ReactiveState = import("modules/ReactiveState")
else
    ReactiveState = require("./ReactiveState")
end

local ActorStateRegistry = {}

local function actorFullName(actor)
    local succeeded, fullName = pcall(actor.GetFullName, actor)
    if succeeded then
        return fullName
    end

    return tostring(actor)
end

function ActorStateRegistry.new(options)
    assert(type(options.GetActorStates) == "function", "ActorStateRegistry requires GetActorStates")
    assert(type(options.GetLuaState) == "function", "ActorStateRegistry requires GetLuaState")
    assert(options.ActorStateCreated, "ActorStateRegistry requires ActorStateCreated")

    local snapshotState = ReactiveState.new({
        Revision = 0,
        States = {},
    })
    local stateById = {}
    local actorById = {}
    local actorIds = setmetatable({}, { __mode = "k" })
    local nextActorId = 0
    local destroyed = false
    local registry = {}

    local function actorId(actor)
        local id = actorIds[actor]
        if id then
            return id
        end

        nextActorId = nextActorId + 1
        actorIds[actor] = nextActorId
        return nextActorId
    end

    local function summarizeActors(stateProxy, activeActors)
        local succeeded, actors = pcall(stateProxy.GetActors, stateProxy)
        if not succeeded then
            actors = {}
        end

        local summaries = {}
        for _, actor in ipairs(actors) do
            local id = actorId(actor)
            activeActors[id] = actor
            table.insert(summaries, {
                Id = id,
                Name = actor.Name or tostring(actor),
                FullName = actorFullName(actor),
            })
        end

        table.sort(summaries, function(left, right)
            if left.FullName == right.FullName then
                return left.Id < right.Id
            end

            return left.FullName < right.FullName
        end)

        for _, summary in ipairs(summaries) do
            table.freeze(summary)
        end

        return table.freeze(summaries)
    end

    function registry:Refresh()
        if destroyed then
            return snapshotState:Get()
        end

        local nextStateById = {}
        local nextActorById = {}
        local states = {}

        for _, stateProxy in ipairs(options.GetActorStates()) do
            nextStateById[stateProxy.Id] = stateProxy
            table.insert(states, table.freeze({
                Id = stateProxy.Id,
                IsActorState = stateProxy.IsActorState,
                Actors = summarizeActors(stateProxy, nextActorById),
            }))
        end

        table.sort(states, function(left, right)
            return left.Id < right.Id
        end)

        stateById = nextStateById
        actorById = nextActorById

        local currentSnapshot = snapshotState:Get()
        local nextSnapshot = table.freeze({
            Revision = currentSnapshot.Revision + 1,
            States = table.freeze(states),
        })
        snapshotState:Set(nextSnapshot)
        return nextSnapshot
    end

    function registry:Get()
        return snapshotState:Get()
    end

    function registry:Subscribe(callback, emitCurrent)
        return snapshotState:Subscribe(callback, emitCurrent)
    end

    function registry:ResolveState(stateId)
        return stateById[stateId]
    end

    function registry:ResolveActor(id)
        return actorById[id]
    end

    function registry:ResolveTargetState(target)
        return options.GetLuaState(target)
    end

    registry:Refresh()

    local actorStateConnection = options.ActorStateCreated:Connect(function()
        registry:Refresh()
    end)

    function registry:Destroy()
        if destroyed then
            return
        end

        destroyed = true
        actorStateConnection:Disconnect()
        snapshotState:Destroy()
        stateById = {}
        actorById = {}
    end

    return registry
end

return ActorStateRegistry
