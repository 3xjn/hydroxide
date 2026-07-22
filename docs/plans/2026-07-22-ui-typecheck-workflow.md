# UI Type-Check Workflow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make invalid Roblox UI property assignments fail locally and in CI before executor-based visual QA.

**Architecture:** Keep executor QA as the final integration layer, but move API-shape mistakes into a deterministic pre-push check. A pinned Luau LSP analyzes the redesigned context-menu source against pinned Roblox API definitions plus Hydroxide's dynamic-import boundary types; the same command also runs the existing Lune runtime contracts.

**Tech Stack:** Luau, luau-lsp, Lune, Rokit, GitHub Actions

---

### Task 1: Lock the failure mode

**Files:**
- Create: `tests/typecheck/invalid_image_button_property.luau`
- Create: `types/hydroxide.d.luau`

**Step 1: Add a negative fixture**

Create a strict Luau fixture that assigns `TextWrapped` to an `ImageButton`.

**Step 2: Run the checker and verify red**

Run: `luau-lsp analyze` with the pinned Roblox definitions.

Expected: non-zero exit with a diagnostic naming `TextWrapped` and `ImageButton`.

**Step 3: Add Hydroxide boundary types**

Declare the custom `import` function, then validate dynamic template children at the source boundary so cloned rows remain statically known as `ImageButton` values.

### Task 2: Type-check the real context menu

**Files:**
- Modify: `ui/controls/ContextMenu.lua`

**Step 1: Enable strict checking**

Add `--!strict` and annotate the dynamic runtime boundary.

**Step 2: Keep UI-specific values typed**

Ensure cloned row instances remain `ImageButton` values through sizing and property assignments, while named children are narrowed with runtime class assertions.

**Step 3: Run the checker and verify green**

Expected: the corrected `label.TextWrapped` source exits zero.

**Step 4: Toggle the original bad line**

Temporarily change it to `buttonInstance.TextWrapped`, capture the expected static error, then restore the corrected child assignment and confirm green again.

### Task 3: Make verification one command

**Files:**
- Create: `rokit.toml`
- Create: `scripts/check.sh`
- Modify: `types/README.md`

**Step 1: Pin tools**

Pin `luau-lsp` and `lune` through Rokit.

**Step 2: Build the verification command**

Download the matching Roblox definitions from a commit-pinned URL, verify their SHA-256 hash, analyze the real context-menu source, assert that the negative fixture fails for the expected reason, and run the existing runtime contracts.

**Step 3: Document the local workflow**

Document `rokit install` for first-time setup and `bash scripts/check.sh` as the single pre-push command.

### Task 4: Enforce the same check in CI

**Files:**
- Create: `.github/workflows/verify.yml`

**Step 1: Install the pinned Rokit toolchain**

Use the released setup-rokit action on Ubuntu.

**Step 2: Run the repository command**

Run `bash scripts/check.sh` for pushes to `dev` and `master`, and for pull requests targeting either branch.

**Step 3: Verify the workflow matches local behavior**

Review the workflow diff and run the same script locally.

### Task 5: Regression and handoff

**Files:**
- Test: `tests/ui_runtime_contracts.luau`

**Step 1: Run the complete verification command**

Expected output includes a successful real-source type-check, a recognized negative type fixture, and `ui-runtime-contracts-ok`.

**Step 2: Parse every Lua source file**

Run the repository-wide syntax parser used by the redesign work.

**Step 3: Inspect only intended changes**

Confirm no temporary fixtures, downloaded definitions, or debug artifacts remain.

**Step 4: Commit and push**

Commit the workflow as one atomic change and push `dev`.
