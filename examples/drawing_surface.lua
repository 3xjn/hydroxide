local environment = getgenv()
local root = (environment.HydroxideConfig or {}).LocalRoot or "hydroxide/local"
local Helpers = loadstring(readfile(root .. "/modules/Helpers.lua"))()
local oh = Helpers.load({
    localRoot = root,
    modules = { "drawing" },
})

local previous = environment.HydroxideDrawingExample
if previous then
    previous:destroy()
end

local surface = oh.drawing.createSurface()
environment.HydroxideDrawingExample = surface

surface:create("Square", {
    Position = Vector2.new(24, 24),
    Size = Vector2.new(236, 104),
    Color = Color3.fromRGB(17, 19, 25),
    Filled = true,
    Visible = true,
    ZIndex = 10,
})

surface:create("Text", {
    Position = Vector2.new(40, 38),
    Text = "Hydroxide drawing surface",
    Font = Drawing.Fonts.Plex,
    Size = 16,
    Color = Color3.fromRGB(235, 237, 243),
    Visible = true,
    ZIndex = 11,
})

local button = surface:create("Square", {
    Position = Vector2.new(40, 76),
    Size = Vector2.new(204, 36),
    Color = Color3.fromRGB(51, 57, 72),
    Filled = true,
    Visible = true,
    ZIndex = 11,
})

surface:create("Text", {
    Position = Vector2.new(142, 85),
    Text = "Click me",
    Font = Drawing.Fonts.Plex,
    Size = 15,
    Center = true,
    Color = Color3.fromRGB(235, 237, 243),
    Visible = true,
    ZIndex = 12,
}, {
    pointerEvents = false,
})

button:on("pointerenter", function(node)
    node.Color = Color3.fromRGB(65, 74, 96)
end)
button:on("pointerleave", function(node)
    node.Color = Color3.fromRGB(51, 57, 72)
end)
button:on("click", function(node)
    node.Color = Color3.fromRGB(77, 171, 128)
    print("[Hydroxide Drawing]", "clicked")
end)
