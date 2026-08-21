#!/usr/bin/env bash
set -euo pipefail

repository_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repository_root"

if [ -z "${PRISM_ROOT:-}" ]; then
	if [ -d "../prism/src/lib" ]; then
		PRISM_ROOT=$(cd ../prism && pwd)
	elif [ -d "/tmp/refs/prism/src/lib" ]; then
		PRISM_ROOT=/tmp/refs/prism
	else
		prism_checkout=$(mktemp -d)
		git clone --depth 1 --branch master https://github.com/3xjn/prism.git "$prism_checkout"
		PRISM_ROOT=$prism_checkout
	fi
	export PRISM_ROOT
fi

if [ ! -f "$PRISM_ROOT/src/lib/index.ts" ]; then
	printf 'PRISM_ROOT does not look like a Prism checkout: %s\n' "$PRISM_ROOT" >&2
	exit 1
fi

node scripts/build_menu.cjs
printf 'hydroxide-ui-build-ok\n'
