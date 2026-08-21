#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
shopt -s extglob nullglob

defs=(
	--platform roblox
	--definitions "@roblox=types/roblox.d.luau"
	--definitions "@volt=_Index/volt/volt.d.luau"
	--definitions "@hydroxide=types/hydroxide.d.luau"
)

luau-lsp analyze "${defs[@]}" \
	dev.lua \
	local.lua \
	tools/live-mcp/volt-agent.lua \
	ui/prism.lua \
	ui/remote_row_geometry.lua \
	ui/controls/{ContextMenu,FilterPopover,QueryBar}.lua \
	modules/!(ClosureSpy|ConstantScanner|RemoteSpy|UpvalueScanner).lua

set +e
invalid=$(luau-lsp analyze "${defs[@]}" tests/typecheck/invalid_image_button_property.luau 2>&1)
status=$?
set -e
if [ "$status" -eq 0 ] || ! grep -Fq "Key 'TextWrapped' not found in external type 'ImageButton'" <<<"$invalid"; then
	printf '%s\n' "$invalid" >&2
	exit 1
fi

for t in tests/*_contracts.luau; do
	lune run "$t"
done
