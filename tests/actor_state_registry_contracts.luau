local ReactiveState = require("../modules/ReactiveState")
local ActorStateRegistry = require("../modules/ActorStateRegistry")

local state = ReactiveState.new({ Count = 1 })
local deliveredCounts = {}
local subscription = state:Subscribe(function(snapshot)
    table.insert(deliveredCounts, snapshot.Count)
end)

state:Set({ Count = 2 })
subscription:Disconnect()
state:Set({ Count = 3 })

assert(#deliveredCounts == 2, "Reactive state must deliver the current value and subsequent replacements")
assert(deliveredCounts[1] == 1 and deliveredCounts[2] == 2, "Reactive state deliveries must retain their order")
assert(state:Get().Count == 3, "Reactive state must retain the latest replacement")

local actorStateCreated = {
    Callback = nil,
    Connected = false,
}

function actorStateCreated:Connect(callback)
    self.Callback = callback
    self.Connected = true

    local signal = self
    return {
        Disconnect = function()
            signal.Connected = false
            signal.Callback = nil
        end,
    }
end

function actorStateCreated:Fire(actor)
    if self.Callback then
        self.Callback(actor)
    end
end

local function actor(name, fullName)
    return {
        Name = name,
        GetFullName = function()
            return fullName
        end,
    }
end

local function luaState(id, actors)
    return {
        Id = id,
        IsActorState = true,
        GetActors = function()
            return actors
        end,
    }
end

local movementActor = actor("Movement", "Workspace.Actors.Movement")
local combatActor = actor("Combat", "Workspace.Actors.Combat")
local effectsActor = actor("Effects", "Workspace.Actors.Effects")

local sharedStateActors = { combatActor, movementActor }
local state20 = luaState(20, sharedStateActors)
local state10 = luaState(10, { effectsActor })
local activeStates = { state20, state10 }
local stateForTarget = {
    [movementActor] = state20,
    [combatActor] = state20,
    [effectsActor] = state10,
}
local inventoryReads = 0

local registry = ActorStateRegistry.new({
    GetActorStates = function()
        inventoryReads = inventoryReads + 1
        return activeStates
    end,
    GetLuaState = function(target)
        return stateForTarget[target]
    end,
    ActorStateCreated = actorStateCreated,
})

assert(inventoryReads == 1, "Registry construction must inventory active Actor states once")
assert(actorStateCreated.Connected, "Registry construction must observe newly available Actor states")

local snapshot = registry:Get()
assert(snapshot.Revision == 1, "Initial inventory must publish the first revision")
assert(#snapshot.States == 2, "Initial inventory must contain every active Actor state")
assert(snapshot.States[1].Id == 10 and snapshot.States[2].Id == 20, "State snapshots must be sorted by stable state ID")
assert(#snapshot.States[2].Actors == 2, "One Lua state must retain all associated Actors")
assert(
    table.isfrozen(snapshot)
        and table.isfrozen(snapshot.States)
        and table.isfrozen(snapshot.States[2])
        and table.isfrozen(snapshot.States[2].Actors),
    "Published registry snapshots must be immutable"
)
assert(snapshot.States[2].Proxy == nil, "Snapshots must not expose live LuaStateProxy objects")
assert(snapshot.States[2].Actors[1].Instance == nil, "Snapshots must not expose live Actor instances")

local actorIdsByName = {}
for _, stateSummary in ipairs(snapshot.States) do
    for _, actorSummary in ipairs(stateSummary.Actors) do
        actorIdsByName[actorSummary.Name] = actorSummary.Id
    end
end

assert(
    registry:ResolveState(20) == state20,
    "Stable state IDs must resolve to the live LuaStateProxy only through the registry"
)
assert(
    registry:ResolveActor(actorIdsByName.Movement) == movementActor,
    "Stable Actor IDs must resolve to the live Actor only through the registry"
)
assert(
    registry:ResolveTargetState(movementActor) == state20,
    "Tools must be able to resolve an Actor or script target through Volt getluastate"
)

sharedStateActors = { movementActor, combatActor }
state20.GetActors = function()
    return sharedStateActors
end
activeStates = { state10, state20 }
registry:Refresh()

local refreshed = registry:Get()
local refreshedIdsByName = {}
for _, stateSummary in ipairs(refreshed.States) do
    for _, actorSummary in ipairs(stateSummary.Actors) do
        refreshedIdsByName[actorSummary.Name] = actorSummary.Id
    end
end

assert(refreshed.Revision == 2, "Manual refresh must publish a replacement snapshot")
assert(
    refreshedIdsByName.Movement == actorIdsByName.Movement
        and refreshedIdsByName.Combat == actorIdsByName.Combat,
    "Actor IDs must remain stable when discovery order changes"
)

local networkActor = actor("Network", "Workspace.Actors.Network")
local state30 = luaState(30, { networkActor })
stateForTarget[networkActor] = state30
activeStates = { state30, state20, state10 }

local deliveredRevisions = {}
local registrySubscription = registry:Subscribe(function(nextSnapshot)
    table.insert(deliveredRevisions, nextSnapshot.Revision)
end)

actorStateCreated:Fire(networkActor)
local createdSnapshot = registry:Get()

assert(inventoryReads == 3, "Actor-state lifecycle notifications must refresh the authoritative inventory")
assert(createdSnapshot.Revision == 3, "A newly available Actor state must publish a new revision")
assert(createdSnapshot.States[3].Id == 30, "A newly available Actor state must enter the sorted snapshot")
assert(
    deliveredRevisions[1] == 2 and deliveredRevisions[2] == 3,
    "Registry subscribers must receive the current snapshot and reactive replacements"
)

registrySubscription:Disconnect()
registry:Destroy()
actorStateCreated:Fire(networkActor)

assert(not actorStateCreated.Connected, "Registry destruction must disconnect Volt lifecycle observation")
assert(inventoryReads == 3, "Destroyed registries must no longer react to Actor-state lifecycle events")

state:Destroy()
local deliveriesAfterDestroy = 0
state:Subscribe(function()
    deliveriesAfterDestroy = deliveriesAfterDestroy + 1
end)
state:Set({ Count = 4 })
assert(deliveriesAfterDestroy == 0, "Destroyed reactive state must reject later subscriptions and publications")

print("actor-state-registry-contracts-ok")
