local RemoteRowGeometry = {}

local callsLeft = 32
local defaultCallsWidth = 36
local labelGap = 4

function RemoteRowGeometry.Resolve(measuredCallWidth)
    local callsWidth = math.max(defaultCallsWidth, measuredCallWidth + 10)
    local labelLeft = callsLeft + callsWidth + labelGap

    return {
        CallsLeft = callsLeft,
        CallsWidth = callsWidth,
        IconLeft = 8,
        LabelLeft = labelLeft,
        LabelRightPadding = 8,
    }
end

return RemoteRowGeometry
