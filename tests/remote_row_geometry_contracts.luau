local Geometry = require("../ui/remote_row_geometry")

local shortCount = Geometry.Resolve(9)
assert(shortCount.IconLeft == 8, "Remote icons must retain their dedicated leading region")
assert(shortCount.CallsLeft == 32, "Call counts must begin after the icon region")
assert(shortCount.CallsWidth == 36, "Short call counts must retain a stable readable width")
assert(shortCount.LabelLeft == 72, "Remote names must begin after the complete count region")

local wideCount = Geometry.Resolve(54)
assert(wideCount.CallsWidth == 64, "Large call counts must expand instead of clipping")
assert(wideCount.LabelLeft == 100, "Remote names must move after an expanded count region")
assert(
    wideCount.LabelLeft > wideCount.CallsLeft + wideCount.CallsWidth,
    "The remote name must never overlap the call count"
)

print("remote-row-geometry-contracts-ok")
