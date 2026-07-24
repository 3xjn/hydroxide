# Volt Compatibility, Signals, and Actors Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Modernize Hydroxide's Volt compatibility seam, make hook cleanup follow Volt's documented lifecycle, and define evidence-backed designs for Signal inspection and Actor-state coverage without using RakNet.

**Architecture:** Resolve canonical Volt APIs once in `init.lua`, retain narrowly scoped fallbacks for older naming conventions, and expose semantic Hydroxide method names to modules. Keep `ohaux.lua` standalone but mirror the same executor-closure resolver because generated scripts can run without an active Hydroxide session. Signal and Actor work will build on explicit signal references and Lua-state identifiers rather than passing foreign functions between states.

**Tech Stack:** Luau, Volt executor API, Lune source-contract tests, luau-lsp

---

### Task 1: Lock the compatibility behavior

**Files:**
- Create: `tests/volt_compatibility_contracts.luau`
- Modify: `scripts/check.sh`

**Step 1: Write the failing source contract**

Assert that `init.lua` resolves `isexecutorclosure`, `getthreadidentity`, and `setthreadidentity` before legacy fallbacks; retains the old Hydroxide method aliases; and contains no ProtoSmasher-specific branches.

**Step 2: Add auxiliary-search coverage**

Assert that `ohaux.lua` uses `isexecutorclosure` as its canonical closure-origin test and retains legacy fallbacks for standalone generated scripts.

**Step 3: Add the contract to the repository check**

Run: `lune run tests/volt_compatibility_contracts.luau`

Expected: FAIL before the implementation because canonical Volt resolution is missing.

### Task 2: Modernize the Volt compatibility seam

**Files:**
- Modify: `init.lua:44-91`
- Modify: `modules/ScriptScanner.lua:4-20`
- Modify: `modules/UpvalueScanner.lua:5-40`
- Modify: `modules/ConstantScanner.lua:5-35`
- Modify: `ohaux.lua:3-10`

**Step 1: Resolve canonical closure classification**

Create one `isExecutorClosure` value that prefers `isexecutorclosure` and falls back to legacy executor spellings. Expose `isXClosure` as a compatibility alias to the same function.

**Step 2: Resolve canonical thread identity**

Prefer `getthreadidentity` and `setthreadidentity`, retain legacy spellings as fallbacks, and expose both the clearer Hydroxide names and the old `getContext`/`setContext` aliases.

**Step 3: Keep ModuleScript environment compatibility**

Prefer documented `getsenv` for `getMenv`, then fall back to legacy `getmenv` only when necessary.

**Step 4: Remove extinct executor branches**

Delete ProtoSmasher-only global mutation, constant lookup, and calling-script stack-depth behavior.

**Step 5: Use the semantic closure method in scanners**

Change scanner requirements and call sites from `isXClosure` to `isExecutorClosure` while keeping the alias available for external compatibility.

**Step 6: Run the compatibility contract**

Expected: `volt-compatibility-contracts-ok`.

### Task 3: Make closure hooks restorable

**Files:**
- Modify: `modules/ClosureSpy.lua:40-100`
- Modify: `tests/shutdown_runtime_contracts.luau`

**Step 1: Write the failing lifecycle contract**

Assert that a Closure Spy hook retains its actual target and registers that target with the session-owned hook registry.

**Step 2: Store the hook target**

Keep the function passed to `hookfunction` as `hook.Target`; do not substitute the original-function reference returned by Volt.

**Step 3: Register and unregister ownership**

Register the target in `oh.Hooks` so session shutdown calls `restorefunction(target)`. Make explicit hook removal restore the same target and remove it from the registry.

**Step 4: Run shutdown contracts**

Expected: `shutdown-runtime-contracts-ok`.

### Task 4: Correct the relevant Volt declarations

**Files:**
- Modify: `_Index/volt/volt.d.luau`

**Step 1: Correct closure and environment declarations**

Update `filtergc`, `getscriptclosure`, and `getluastate` from their current official API pages.

**Step 2: Separate connection types**

Retain the small connection returned by `VoltSignal`, and add the documented rich RBX signal connection shape returned by `getconnections`.

**Step 3: Correct Actor declarations**

Model `on_actor_state_created` as a `VoltSignal`, and correct `LuaStateProxy:Execute` and `run_on_actor` to accept source strings plus varargs and return no values.

**Step 4: Remove RakNet from the project-local declaration surface**

Hydroxide policy forbids RakNet, so omit its types and global declaration from this repository even though Volt exposes it.

**Step 5: Run the type-check and syntax checks**

Run: `bash scripts/check.sh`

Expected: all source contracts and the real UI type-check pass.

### Task 5: Research Signal discovery and Actor-state use

**Files:**
- No runtime files in this task

**Step 1: Verify signal discovery constraints**

Use official Volt and Roblox/Luau sources to determine whether RBXScriptSignals can be enumerated directly, discovered through GC-visible userdata, or must be resolved from known class event metadata.

**Step 2: Define a Signal inspection boundary**

Specify how an Instance/event name becomes a signal reference, how `getconnections` results are represented, and how `ForeignState` routes to Actor-state inspection.

**Step 3: Define practical Actor coverage**

Explain how Roblox Actors divide scripts into separate Luau states and identify concrete authorized game-testing cases where state-local signal or closure inspection reveals behavior hidden from the main state.

**Step 4: Record uncertainties explicitly**

Do not treat undocumented memory layout or cross-state object behavior as established fact.

### Task 6: Regression and handoff

**Files:**
- Test: `tests/volt_compatibility_contracts.luau`
- Test: `tests/shutdown_runtime_contracts.luau`
- Test: `tests/ui_runtime_contracts.luau`

**Step 1: Run the complete repository check**

Run: `bash scripts/check.sh`

Expected: every type-check and Lune contract passes.

**Step 2: Inspect the focused diff**

Confirm that unrelated existing edits in `DESIGN.md`, `tests/ui_runtime_contracts.luau`, and `ui/window.lua` remain untouched.

**Step 3: Commit only when requested**

Stage and commit the compatibility, declaration, and contract files as one focused change after user approval.
