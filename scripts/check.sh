#!/usr/bin/env bash
set -euo pipefail

repository_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repository_root"

for required_tool in curl sha256sum luau-lsp lune; do
    if ! command -v "$required_tool" >/dev/null 2>&1; then
        printf 'Missing required tool: %s\n' "$required_tool" >&2
        exit 1
    fi
done

roblox_types_commit="cfa5c378c6370f0eca852910e6fbdf8e4d8921c6"
roblox_types_sha256="3e504a7248e26614fed5a3e4206d11ef86dfcec14d3775098b1e18e4a1d8b1e1"
cache_root="${XDG_CACHE_HOME:-${LOCALAPPDATA:-${TMPDIR:-/tmp}}}/hydroxide/typecheck"
roblox_types="$cache_root/globalTypes-$roblox_types_commit.d.luau"

mkdir -p "$cache_root"

if [ ! -f "$roblox_types" ] || ! printf '%s  %s\n' "$roblox_types_sha256" "$roblox_types" | sha256sum --check --status; then
    curl --fail --location --silent --show-error \
        "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/$roblox_types_commit/scripts/globalTypes.d.luau" \
        --output "$roblox_types"
fi

printf '%s  %s\n' "$roblox_types_sha256" "$roblox_types" | sha256sum --check --status

definitions=(
    --platform roblox
    --definitions "@roblox=$roblox_types"
    --definitions "@volt=_Index/volt/volt.d.luau"
    --definitions "@hydroxide=types/hydroxide.d.luau"
)

luau-lsp analyze "${definitions[@]}" dev.lua local.lua tools/live-mcp/volt-agent.lua ui/prism.lua ui/controls/ContextMenu.lua ui/controls/FilterPopover.lua ui/controls/QueryBar.lua ui/remote_row_geometry.lua modules/InstancePath.lua modules/ScannerFilter.lua modules/ScannerResults.lua modules/ScriptScanner.lua modules/ModuleScanner.lua modules/ScriptBuilder.lua modules/ReactiveState.lua modules/ActorStateRegistry.lua modules/SignalSpy.lua modules/ScriptGraph.lua modules/Helpers.lua modules/Closure.lua modules/ThreadTrace.lua modules/Targeting.lua modules/Lifecycle.lua
printf 'ui-typecheck-ok\n'

set +e
invalid_output=$(luau-lsp analyze "${definitions[@]}" tests/typecheck/invalid_image_button_property.luau 2>&1)
invalid_status=$?
set -e

if [ "$invalid_status" -eq 0 ]; then
    printf 'Expected the invalid ImageButton property fixture to fail\n' >&2
    exit 1
fi

if ! grep -Fq "Key 'TextWrapped' not found in external type 'ImageButton'" <<<"$invalid_output"; then
    printf '%s\n' "$invalid_output" >&2
    printf 'The invalid fixture failed for an unexpected reason\n' >&2
    exit 1
fi

printf 'ui-negative-type-contract-ok\n'
lune run tests/ui_runtime_contracts.luau
lune run tests/window_geometry_contracts.luau
lune run tests/shutdown_runtime_contracts.luau
lune run tests/volt_compatibility_contracts.luau
lune run tests/script_builder_contracts.luau
lune run tests/dev_loader_contracts.luau
lune run tests/thread_trace_contracts.luau
lune run tests/helper_loader_contracts.luau
lune run tests/closure_module_contracts.luau
lune run tests/targeting_module_contracts.luau
lune run tests/lifecycle_module_contracts.luau
lune run tests/no_drawing_api_contracts.luau
lune run tests/actor_state_registry_contracts.luau
lune run tests/signal_spy_contracts.luau
lune run tests/instance_path_contracts.luau
lune run tests/scanner_filter_contracts.luau
lune run tests/scanner_inventory_contracts.luau
lune run tests/scanner_results_contracts.luau
lune run tests/script_graph_contracts.luau
lune run tests/remote_row_geometry_contracts.luau
lune run tests/prism_pipeline_contracts.luau
