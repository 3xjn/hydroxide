local Geometry = require("../ui/window_geometry")
local fs = require("@lune/fs")

local width, height = Geometry.ClampSize(1120, 680, 800, 500, 16, 720, 420)
assert(width == 768 and height == 468, "A restored window must clamp to the shrunken viewport")

local x, y = Geometry.ClampRestoredPosition(400, 200, width, height, 800, 500, 16)
assert(x == 16 and y == 16, "A restored window must remain fully visible after the viewport shrinks")

local stableX, stableY = Geometry.ClampRestoredPosition(320, 180, 1120, 680, 1920, 1080, 16)
assert(stableX == 320 and stableY == 180, "Valid restored bounds must not move")

local narrowWidth, narrowHeight = Geometry.ClampSize(1120, 680, 600, 360, 16, 720, 420)
assert(narrowWidth == 568 and narrowHeight == 328, "Small viewports must override the normal minimum size")

local windowSource = fs.readFile("ui/window.lua")
assert(
    windowSource:find("base.Position = clampRestoredPosition(restorePosition, restoredSize)", 1, true),
    "Restoring from maximized state must use the tested position clamp"
)

print("window-geometry-contracts-ok")
