# Drawing surface

`oh.drawing` turns Volt's render-only Drawing API into a scoped surface that can
own persistent objects, immediate paint callbacks, pointer routing, hit-testing,
Z-order, and cleanup.

```lua
local Helpers = loadstring(readfile("hydroxide/local/modules/Helpers.lua"))()
local oh = Helpers.load({
    localRoot = "hydroxide/local",
    modules = { "drawing" },
})

local surface = oh.drawing.createSurface()
local button = surface:create("Square", {
    Position = Vector2.new(24, 24),
    Size = Vector2.new(140, 36),
    Color = Color3.fromRGB(42, 46, 58),
    Filled = true,
    Visible = true,
    ZIndex = 10,
})

button:on("click", function()
    print("clicked")
end)

surface:paint(0, function(immediate)
    immediate.Line(
        Vector2.new(0, 0),
        workspace.CurrentCamera.ViewportSize,
        Color3.fromRGB(255, 255, 255),
        0.2,
        1
    )
end)

surface:destroy()
```

## Responsibility

The surface owns display and input mechanics:

- persistent Drawing objects and property proxying;
- immediate per-frame painting;
- primitive-aware hit-testing;
- topmost-node pointer routing;
- pointer pass-through for decorative overlays;
- hover, press, release, click, and drag events;
- per-surface destruction without clearing another script's drawings.

Feature actions and live values remain outside the surface. A scanner decides
what a click means; the drawing surface only decides which node received it.

## Roblox interaction

Drawing objects are overlays, not Roblox `Instance` or `GuiObject` values. They
do not receive native GUI events, participate in layout, claim focus, block
click-through, or set `gameProcessedEvent`.

The surface observes real user input through `UserInputService`. Volt's input
functions such as `mouse1click` and `keypress` simulate input and are not used
as event sources. Pointer input reaches the topmost drawing by default even
when Roblox also processed it; set `respectGameProcessedInput = true` when a
surface should yield to native UI instead.

Complex controls should use a hybrid seam:

- `ContextActionService` when an open surface must deliberately capture or sink
  game controls;
- a native `TextBox` bridge for keyboard focus, IME, selection, and clipboard
  behavior;
- native selection/accessibility support for controller and screen-reader
  parity.

## Next depth

The old BetterDrawingApi added property proxying, viewport-relative `UDim2`
conversion, and TweenService compatibility by globally hooking
`TweenService.Create`. The useful ideas should return behind local seams:

1. layout nodes with anchors, scale/offset sizing, clipping, and viewport
   invalidation;
2. a local animation scheduler for numbers, vectors, and colors;
3. focus and modal input capture;
4. native text-entry and accessibility adapters;
5. theme and reactive-state bindings.

Global TweenService hooks and global `cleardrawcache()` are intentionally not
part of the surface because they mutate behavior or drawings owned by unrelated
scripts.
