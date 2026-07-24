local TextService = game:GetService("TextService")

local Tooltip = {}
local Theme = import("ui/theme")

local Base = import("ui/runtime").GetInterface().Base
local Surface = Base.Tooltip
local Label = Surface.Label

function Tooltip.Show(target, text)
    Label.Text = text

    local textWidth = TextService:GetTextSize(text, Label.TextSize, Label.Font, Vector2.new(220, Theme.Layout.TooltipHeight)).X
    local width = math.ceil(textWidth) + 20
    local targetPosition = target.AbsolutePosition - Base.AbsolutePosition
    local targetSize = target.AbsoluteSize
    local x = math.clamp(
        targetPosition.X + math.floor((targetSize.X - width) / 2),
        Theme.Layout.TooltipOffset,
        Base.AbsoluteSize.X - width - Theme.Layout.TooltipOffset
    )
    local y = targetPosition.Y - Theme.Layout.TooltipHeight - Theme.Layout.TooltipOffset

    if y < Theme.Layout.TitleBarHeight + Theme.Layout.TooltipOffset then
        y = targetPosition.Y + targetSize.Y + Theme.Layout.TooltipOffset
    end

    Surface.Size = UDim2.new(0, width, 0, Theme.Layout.TooltipHeight)
    Surface.Position = UDim2.new(0, x, 0, y)
    Surface.Visible = true
end

function Tooltip.Hide()
    Surface.Visible = false
end

return Tooltip
