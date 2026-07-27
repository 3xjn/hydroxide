local fs = require("@lune/fs")

local created = {}
local surface = {}

function surface:create(kind, properties, options)
    local node = {
        kind = kind,
        options = options,
        properties = properties,
    }
    function node:on(eventName, callback)
        self.eventName = eventName
        self.callback = callback
    end
    table.insert(created, node)
    return node
end

local source = fs.readFile("modules/DrawingControls.lua")
local DrawingControls = assert(loadstring(source, "modules/DrawingControls.lua"))()
local controls = DrawingControls.new(surface)

local card = controls:card({
    background = { Color = "panel" },
    border = { Color = "border", Filled = false },
})
assert(card.background.kind == "Square" and card.border.kind == "Square")
assert(card.background.options.pointerEvents == false and card.border.options.pointerEvents == false)

local text = controls:text({ Text = "Status" })
assert(text.kind == "Text" and text.options.pointerEvents == false)

local clicks = 0
local button = controls:button({
    background = { Size = "target" },
    onClick = function()
        clicks += 1
    end,
})
assert(button.kind == "Square" and button.options.pointerEvents == true)
assert(button.eventName == "click")
button.callback()
assert(clicks == 1, "Drawing buttons must retain the supplied click hook")

local inputs = 0
local slider = controls:slider({
    hit = { Size = "target" },
    track = { Size = "track" },
    fill = { Size = "fill" },
    knob = { Radius = 6 },
    onInput = function()
        inputs += 1
    end,
})
assert(slider.hit.options.pointerEvents == true)
assert(slider.track.options.pointerEvents == false and slider.fill.options.pointerEvents == false)
assert(slider.knob.kind == "Circle")
slider.hit.callback()
assert(inputs == 1, "Drawing sliders must retain their input hook")

print("drawing-controls-contracts-ok")
