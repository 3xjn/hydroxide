# Actor State Registry Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build an authoritative Actor/Luau-state inventory that publishes reactive, cross-tool UI snapshots while keeping live Volt proxies behind a resolver boundary.

**Architecture:** `ReactiveState` provides a small observable-value primitive with immediate subscriptions and deterministic cleanup. `ActorStateRegistry` owns Volt `LuaStateProxy` and `Actor` references, publishes stable state/actor summaries through `ReactiveState`, and resolves stable IDs back to live objects only when a tool needs them. `ui/main.lua` installs the registry as `oh.State.ActorStates` before feature modules load, so every tool can subscribe without directly coupling to another tool.

**Tech Stack:** Luau, Lune behavioral contracts, Volt Actor APIs (`getactorstates`, `getluastate`, `on_actor_state_created`, `LuaStateProxy:GetActors`)

---

### Task 1: Behavioral contracts

**Files:**
- Create: `tests/actor_state_registry_contracts.luau`
- Modify: `scripts/check.sh`

**Step 1: Write a failing reactive-state contract**

Create a state value, subscribe with immediate delivery, set a replacement value, disconnect, and prove no later value is delivered.

**Step 2: Write a failing registry contract**

Use fake `LuaStateProxy`, `Actor`, and `VoltSignal` objects to verify:

- initial `getactorstates()` inventory is published;
- records are sorted by `state.Id`;
- multiple Actors can belong to one state;
- Actor IDs remain stable when a refresh changes ordering;
- snapshots contain summaries, not live state proxies;
- state and Actor IDs resolve back to live objects;
- `on_actor_state_created` refreshes the inventory;
- `Destroy()` disconnects the lifecycle event and subscribers.

**Step 3: Run the contract to verify it fails**

Run: `lune run tests/actor_state_registry_contracts.luau`

Expected: FAIL because `ReactiveState` and `ActorStateRegistry` do not exist.

### Task 2: Reactive state primitive

**Files:**
- Create: `modules/ReactiveState.lua`
- Test: `tests/actor_state_registry_contracts.luau`

**Step 1: Implement the minimal API**

Provide:

- `ReactiveState.new(initialValue)`
- `state:Get()`
- `state:Set(nextValue)`
- `state:Subscribe(callback, emitCurrent?)`
- subscription `:Disconnect()`
- `state:Destroy()`

`Set` publishes only replacement values, and `Destroy` permanently disconnects subscribers.

**Step 2: Run the focused contract**

Run: `lune run tests/actor_state_registry_contracts.luau`

Expected: the reactive-state section passes and registry construction still fails.

### Task 3: Actor state registry

**Files:**
- Create: `modules/ActorStateRegistry.lua`
- Test: `tests/actor_state_registry_contracts.luau`

**Step 1: Implement dependency-injected discovery**

Accept `GetActorStates`, `GetLuaState`, and `ActorStateCreated`. Call `GetActorStates` for the initial inventory and after lifecycle notifications.

**Step 2: Publish safe snapshots**

Publish:

```lua
{
    Revision = number,
    States = {
        {
            Id = number,
            IsActorState = boolean,
            Actors = {
                { Id = number, Name = string, FullName = string }
            }
        }
    }
}
```

Do not include `LuaStateProxy` or live Actor instances in the snapshot.

**Step 3: Retain resolver seams**

Expose `ResolveState(stateId)` and `ResolveActor(actorId)` for tools that explicitly need a live object. Maintain session-stable Actor IDs with a weak-key identity map.

**Step 4: Run the focused contract**

Run: `lune run tests/actor_state_registry_contracts.luau`

Expected: `actor-state-registry-contracts-ok`.

### Task 4: Hydroxide session integration

**Files:**
- Modify: `init.lua`
- Modify: `ui/main.lua`

**Step 1: Expose semantic Volt methods**

Add `getActorStates`, `getLuaState`, and `actorStateCreated` to Hydroxide’s resolved global methods.

**Step 2: Install shared UI state**

Before feature modules load, create:

```lua
oh.State = {
    ActorStates = ActorStateRegistry.new({
        GetActorStates = getActorStates,
        GetLuaState = getLuaState,
        ActorStateCreated = actorStateCreated,
    }),
}
```

Register the registry in `oh.Resources` so session exit disconnects the Volt event and subscribers.

**Step 3: Preserve graceful capability handling**

If the Actor APIs are unavailable, leave `oh.State.ActorStates` unset without disabling unrelated Hydroxide tools.

### Task 5: Verification

**Files:**
- Modify: `scripts/check.sh`

**Step 1: Typecheck pure modules**

Add `modules/ReactiveState.lua` and `modules/ActorStateRegistry.lua` to the existing `luau-lsp analyze` invocation.

**Step 2: Run focused behavioral verification**

Run: `lune run tests/actor_state_registry_contracts.luau`

Expected: `actor-state-registry-contracts-ok`.

**Step 3: Run the complete repository check**

Run: `./scripts/check.sh`

Expected: exit code `0`, including the new Actor-state contract.

**Step 4: Manual runtime gate**

When a live Volt-attached Roblox client is available, confirm the registry publishes active state IDs, groups shared Actors under the same state, reacts to a newly created Actor state, and disconnects on Hydroxide exit.
