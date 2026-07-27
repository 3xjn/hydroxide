local DrawingControls = {}
DrawingControls.__index = DrawingControls

local function createNode(surface, kind, properties, interactive)
    return surface:create(kind, properties, {
        pointerEvents = interactive == true,
    })
end

function DrawingControls.new(surface)
    assert(surface and type(surface.create) == "function", "Drawing controls require a drawing surface")

    return setmetatable({
        surface = surface,
    }, DrawingControls)
end

function DrawingControls:card(options)
    assert(type(options) == "table", "Drawing card options must be a table")
    assert(type(options.background) == "table", "Drawing cards require background properties")
    assert(type(options.border) == "table", "Drawing cards require border properties")

    return {
        background = createNode(self.surface, "Square", options.background, false),
        border = createNode(self.surface, "Square", options.border, false),
    }
end

function DrawingControls:text(properties, interactive)
    assert(type(properties) == "table", "Drawing text properties must be a table")
    return createNode(self.surface, "Text", properties, interactive)
end

function DrawingControls:button(options)
    assert(type(options) == "table", "Drawing button options must be a table")
    assert(type(options.background) == "table", "Drawing buttons require background properties")

    local button = createNode(self.surface, "Square", options.background, true)
    if type(options.onClick) == "function" then
        button:on("click", options.onClick)
    end

    return button
end

function DrawingControls:slider(options)
    assert(type(options) == "table", "Drawing slider options must be a table")
    assert(type(options.hit) == "table", "Drawing sliders require hit properties")
    assert(type(options.track) == "table", "Drawing sliders require track properties")
    assert(type(options.fill) == "table", "Drawing sliders require fill properties")
    assert(type(options.knob) == "table", "Drawing sliders require knob properties")

    local slider = {
        hit = createNode(self.surface, "Square", options.hit, true),
        track = createNode(self.surface, "Square", options.track, false),
        fill = createNode(self.surface, "Square", options.fill, false),
        knob = createNode(self.surface, "Circle", options.knob, false),
    }
    if type(options.onInput) == "function" then
        slider.hit:on("pointerdown", options.onInput)
        slider.hit:on("drag", options.onInput)
    end
    return slider
end

return DrawingControls
