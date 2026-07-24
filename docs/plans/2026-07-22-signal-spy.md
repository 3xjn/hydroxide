# Signal Spy Implementation Plan

## Goal

Add a first-class Signal Spy that makes Roblox event relationships easy to follow during authorized testing:

`Instance -> RBXScriptSignal -> connection -> closure/script -> Lua state/Actor`

The feature must use Volt's documented signal APIs, share immutable reactive snapshots with the rest of the UI, preserve live runtime objects behind resolver methods, and never use RakNet.

## Runtime contract

- Discover an Instance's events through `ReflectionService:GetEventsOfClass`.
- Read each accessible `RBXScriptSignal` and inspect it with Volt's `getconnections`.
- Read parameter names and types with Volt's `getsignalargumentsinfo`.
- Represent inaccessible event properties and API failures as per-signal errors instead of aborting the inspection.
- Publish snapshots that contain only display-safe metadata and stable IDs.
- Keep signals, connection objects, functions, threads, scripts, and Lua state proxies in private resolver maps.
- Resolve a connection's script from its thread when `getscriptfromthread` is available.
- Resolve its Lua state from that script when `getLuaState` is available.
- Link the resulting state ID to the existing Actor state registry when present.
- Treat `ForeignState` as a connection attribute, not proof that the state is discoverable.

## UI contract

- Add a branded `SignalSpy` page and tab using the existing compact Hydroxide visual language.
- Other tools hand an Instance to Signal Spy through a shared `Open(instance)` seam.
- Show the inspected target, event signature, connection count, and useful connection flags.
- Offer `Spy Closure` only when Volt exposes an accessible connection function.
- `Spy Closure` opens the selected function in Closure Spy through the existing tab/hook flow.
- Empty and unavailable states must explain the next useful action without an additional tutorial surface.

## Behavioral tests

- Discovers inherited and declared reflected events.
- Continues when one event cannot be indexed.
- Captures argument names/types and connection flags.
- Keeps live runtime values out of snapshots while resolvers return the originals.
- Produces stable IDs across refreshes for the same target and connection objects.
- Resolves thread -> script -> Lua state -> Actor state relationships when supported.
- Does not invent an Actor relationship for a foreign or otherwise unresolved connection.
- Publishes a new immutable snapshot when the inspected target changes.

## Validation

- Run the focused Signal Spy behavioral suite.
- Run Luau type analysis and the full repository check.
- Exercise the real rendered page if a Volt-attached Roblox surface is available; otherwise record that runtime-only visual QA remains.
