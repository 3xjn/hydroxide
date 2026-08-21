#!/usr/bin/env bash
set -euo pipefail

repository_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repository_root/ui"

if [ -d "$repository_root/../prism/src/lib" ]; then
	npm install --no-save "file:$repository_root/../prism"
else
	npm install
fi

npm run build
npm run bundle
printf 'hydroxide-ui-build-ok\n'
