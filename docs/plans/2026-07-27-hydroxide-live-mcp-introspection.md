# Hydroxide Live MCP Introspection Implementation Plan

**Goal:** Add target-aware Roblox script search, closure inspection, and reversible
constant/upvalue mutation to the existing live MCP bridge.

**Architecture:** Keep the authenticated MCP-to-Volt bridge unchanged and extend its typed
request protocol. MCP tools always send an explicit game, Actor, or Lua-state target. The Volt
agent maintains a periodically refreshed script/source index, resolves each target through Volt's
Lua-state APIs, exposes bounded serialized debug metadata, and retains original primitive values
behind mutation IDs until a guarded restore succeeds.

**Tech Stack:** Bun, TypeScript, Zod, MCP SDK, Luau, Volt debug/script/Actor APIs.

---

### Task 1: Lock the MCP request contract

**Files:**
- Create: `tools/live-mcp/tests/introspection-tools.test.ts`
- Modify: `tools/live-mcp/src/protocol.ts`
- Modify: `tools/live-mcp/src/tools.ts`

1. Add failing in-memory MCP tests for search, inspection, mutation, restoration, and target
   forwarding.
2. Run `bun test tests/introspection-tools.test.ts` and confirm the tools are initially absent.
3. Add typed Zod inputs with a discriminated game/Actor/state target and register the tools.
4. Re-run the focused test and `bun run typecheck`.

### Task 2: Build the live script index

**Files:**
- Modify: `tools/live-mcp/volt-agent.lua`

1. Fix canonical service paths to use stable service class names.
2. Add metadata/source cache entries, initial inventory scan, instance/Actor-state dirty signals,
   and periodic rescan fallback.
3. Add ranked token/text search with bounded line-numbered snippets and index statistics.
4. Preserve existing list/read behavior while making both target-aware.

### Task 3: Add structured runtime inspection and reversible mutation

**Files:**
- Modify: `tools/live-mcp/volt-agent.lua`

1. Resolve script closures and nested `ProtoProxy` values through a prototype index path.
2. Return JSON-safe `debug.getinfo`, constants, root upvalues, and immediate nested-prototype
   metadata.
3. Add compare-before-set primitive constant/upvalue mutation that returns a mutation ID.
4. Add guarded restore using the retained native original value, verifying the restored value
   before retiring the mutation ID.
5. Keep generic eval available and add the same target selector, using a communication channel
   for Actor/state execution.

### Task 4: Verify through the real surfaces

**Files:**
- Modify: `tools/live-mcp/README.md`

1. Run focused tests, type checking, linting, and the live-MCP test suite.
2. Reload the Volt auto-execute agent safely against a temporary known-token daemon.
3. Search live code, inspect a closure, mutate a harmless primitive in a disposable closure or
   selected safe script, verify it, restore it, and verify the original.
4. Restore the client to its original daemon configuration and document the tools and safety
   workflow.
