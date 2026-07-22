local Geometry = {}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(value, maximum))
end

function Geometry.ClampSize(
    width,
    height,
    viewportWidth,
    viewportHeight,
    margin,
    minimumWidth,
    minimumHeight
)
    local availableWidth = math.max(0, viewportWidth - margin * 2)
    local availableHeight = math.max(0, viewportHeight - margin * 2)
    local clampedMinimumWidth = math.min(minimumWidth, availableWidth)
    local clampedMinimumHeight = math.min(minimumHeight, availableHeight)

    return clamp(width, clampedMinimumWidth, availableWidth),
        clamp(height, clampedMinimumHeight, availableHeight)
end

function Geometry.ClampRestoredPosition(x, y, width, height, viewportWidth, viewportHeight, margin)
    local maximumX = math.max(margin, viewportWidth - width - margin)
    local maximumY = math.max(margin, viewportHeight - height - margin)
    return clamp(x, margin, maximumX), clamp(y, margin, maximumY)
end

return Geometry
