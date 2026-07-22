--!strict

-- This file is intentionally invalid. scripts/check.sh verifies that luau-lsp
-- rejects the same ImageButton property assignment that previously crashed the UI.
local button = Instance.new("ImageButton")
button.TextWrapped = false
