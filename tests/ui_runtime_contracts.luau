local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local contextMenuSource = fs.readFile("ui/controls/ContextMenu.lua")
local mainSource = fs.readFile("ui/main.lua")

local imageButton = roblox.Instance.new("ImageButton")
local label = roblox.Instance.new("TextLabel")

local imageButtonAcceptsTextWrapped = pcall(function()
    imageButton.TextWrapped = false
end)
local labelAcceptsTextWrapped = pcall(function()
    label.TextWrapped = false
end)

assert(not imageButtonAcceptsTextWrapped, "ImageButton unexpectedly accepted TextWrapped")
assert(labelAcceptsTextWrapped, "TextLabel must accept TextWrapped")
assert(
    contextMenuSource:find("buttonInstance.Label.TextWrapped = false", 1, true),
    "Context menu wrapping must be configured on the row label"
)
assert(
    not contextMenuSource:find("buttonInstance.TextWrapped = false", 1, true),
    "Context menu rows are ImageButtons and cannot receive TextWrapped"
)
assert(
    not contextMenuSource:find("buttonInstance.Icon.AbsoluteSize", 1, true),
    "Context menu width must not depend on pre-parent AbsoluteSize"
)
assert(
    not contextMenuSource:find("buttonInstance.AbsoluteSize", 1, true),
    "Context menu height must not depend on pre-parent AbsoluteSize"
)

assert(mainSource:find("local moduleLoaders = {", 1, true), "Feature modules must have independent loader boundaries")
assert(mainSource:find("oh.LoadErrors = failures", 1, true), "Feature load errors must remain inspectable")
assert(
    not mainSource:find("Interface:Destroy()", 1, true),
    "A feature-module load error must not destroy the Hydroxide interface"
)

print("ui-runtime-contracts-ok")
