local fs = require("@lune/fs")

local function newSignal()
    local callbacks = {}
    local signal = {}

    function signal:Connect(callback)
        table.insert(callbacks, callback)
        local connected = true

        return {
            Disconnect = function()
                if not connected then
                    return
                end

                connected = false
                local index = table.find(callbacks, callback)
                if index then
                    table.remove(callbacks, index)
                end
            end,
        }
    end

    function signal:Fire(...)
        for _, callback in ipairs(table.clone(callbacks)) do
            callback(...)
        end
    end

    function signal:Count()
        return #callbacks
    end

    return signal
end

local inputBegan = newSignal()
local inputChanged = newSignal()
local inputEnded = newSignal()
local paintSignal = newSignal()
local objects = {}
local immediate = {}

local function newObject(kind)
    local object = {
        Kind = kind,
        Visible = false,
        ZIndex = 0,
        Transparency = 1,
        __OBJECT_EXISTS = true,
    }

    function object:Destroy()
        self.__OBJECT_EXISTS = false
    end

    table.insert(objects, object)
    return object
end

local source = fs.readFile("modules/Drawing.lua")
local Drawing = assert(loadstring(source, "modules/Drawing.lua"))()
local drawing = Drawing.new({
    Connect = function(signal, callback)
        return signal:Connect(callback)
    end,
    ConnectPaint = function(zIndex, callback)
        assert(zIndex == 4)
        return paintSignal:Connect(function()
            callback(immediate)
        end)
    end,
    DestroyObject = function(object)
        object:Destroy()
    end,
    GetInputBegan = function()
        return inputBegan
    end,
    GetInputChanged = function()
        return inputChanged
    end,
    GetInputEnded = function()
        return inputEnded
    end,
    GetPosition = function(input)
        return input.Position
    end,
    IsPointerMovement = function(input)
        return input.Kind == "move"
    end,
    IsPrimaryPointer = function(input)
        return input.Kind == "primary"
    end,
    NewObject = newObject,
})

local probeCalls = {}
local probeDestroyCalls = 0
local capabilityDrawing = Drawing.new({
    DestroyObject = function(object)
        probeDestroyCalls += 1
        object:Destroy()
    end,
    NewObject = function(kind)
        probeCalls[kind] = (probeCalls[kind] or 0) + 1
        if kind == "Quad" then
            error("unsupported drawing primitive")
        end
        return newObject(kind)
    end,
})
assert(capabilityDrawing.supports("Square") == true)
assert(capabilityDrawing.supports("Quad") == false)
assert(capabilityDrawing.supports("Square") == true)
assert(probeCalls.Square == 1, "Drawing capability probes must be cached per primitive")
assert(probeDestroyCalls == 1, "Successful drawing capability probes must destroy their object")

local surface = drawing.createSurface()
local paintedWith
surface:paint(4, function(renderer)
    paintedWith = renderer
end)
paintSignal:Fire()
assert(paintedWith == immediate, "Immediate paint callbacks must receive the renderer adapter")

local events = {}
local bottom = surface:create("Square", {
    Position = { X = 10, Y = 10 },
    Size = { X = 100, Y = 100 },
    Visible = true,
    ZIndex = 1,
})
local top = surface:create("Square", {
    Position = { X = 30, Y = 30 },
    Size = { X = 100, Y = 100 },
    Visible = true,
    ZIndex = 2,
})

for _, eventName in ipairs({
    "pointerenter",
    "pointerleave",
    "pointerdown",
    "pointerup",
    "click",
    "drag",
}) do
    top:on(eventName, function()
        table.insert(events, eventName)
    end)
end

local bottomClicks = 0
bottom:on("click", function()
    bottomClicks = bottomClicks + 1
end)

inputChanged:Fire({
    Kind = "move",
    Position = { X = 50, Y = 50 },
})
inputBegan:Fire({
    Kind = "primary",
    Position = { X = 50, Y = 50 },
}, false)
inputChanged:Fire({
    Kind = "move",
    Position = { X = 70, Y = 75 },
})
inputEnded:Fire({
    Kind = "primary",
    Position = { X = 70, Y = 75 },
}, false)

assert(table.concat(events, ",") == "pointerenter,pointerdown,drag,pointerup,click")
assert(bottomClicks == 0, "Only the topmost visible node should receive a click")

top.Visible = false
assert(top.Visible == false, "Drawing properties must proxy through the node")
surface:create("Square", {
    Position = { X = 10, Y = 10 },
    Size = { X = 100, Y = 100 },
    Visible = true,
    ZIndex = 20,
}, {
    pointerEvents = false,
})
inputBegan:Fire({
    Kind = "primary",
    Position = { X = 50, Y = 50 },
}, false)
inputEnded:Fire({
    Kind = "primary",
    Position = { X = 50, Y = 50 },
}, false)
assert(bottomClicks == 1, "Hidden nodes must not intercept input")

inputBegan:Fire({
    Kind = "primary",
    Position = { X = 50, Y = 50 },
}, true)
inputEnded:Fire({
    Kind = "primary",
    Position = { X = 50, Y = 50 },
}, true)
assert(bottomClicks == 2, "A topmost drawing must receive processed pointer input by default")

local respectingSurface = drawing.createSurface({
    respectGameProcessedInput = true,
})
local respectingClicks = 0
local respectingButton = respectingSurface:create("Square", {
    Position = { X = 300, Y = 10 },
    Size = { X = 100, Y = 40 },
    Visible = true,
    ZIndex = 1,
})
respectingButton:on("click", function()
    respectingClicks = respectingClicks + 1
end)
inputBegan:Fire({
    Kind = "primary",
    Position = { X = 320, Y = 20 },
}, true)
inputEnded:Fire({
    Kind = "primary",
    Position = { X = 320, Y = 20 },
}, true)
assert(respectingClicks == 0, "A drawing surface must be able to yield to Roblox-processed input")
respectingSurface:destroy()

local circleClicks = 0
local circle = surface:create("Circle", {
    Position = { X = 200, Y = 200 },
    Radius = 25,
    Visible = true,
    ZIndex = 3,
})
circle:on("click", function()
    circleClicks = circleClicks + 1
end)
inputBegan:Fire({
    Kind = "primary",
    Position = { X = 220, Y = 200 },
}, false)
inputEnded:Fire({
    Kind = "primary",
    Position = { X = 220, Y = 200 },
}, false)
assert(circleClicks == 1, "Circle hit-testing must use its radius")

local potassiumSurface = Drawing.new({
    Connect = function(signal, callback)
        return signal:Connect(callback)
    end,
    DestroyObject = function(object)
        object:Destroy()
    end,
    GetInputBegan = function()
        return inputBegan
    end,
    GetInputChanged = function()
        return inputChanged
    end,
    GetInputEnded = function()
        return inputEnded
    end,
    GetPosition = function(input)
        return input.Position
    end,
    GetProperty = function(object, property)
        if property == "__OBJECT_EXISTS" then
            error("invalid drawing property __OBJECT_EXISTS")
        end
        return object[property]
    end,
    IsPointerMovement = function(input)
        return input.Kind == "move"
    end,
    IsPrimaryPointer = function(input)
        return input.Kind == "primary"
    end,
    NewObject = newObject,
}).createSurface()
local potassiumButton = potassiumSurface:create("Square", {
    Position = { X = 400, Y = 400 },
    Size = { X = 100, Y = 40 },
    Visible = true,
    ZIndex = 1,
})
assert(
    potassiumSurface:hitTest({ X = 420, Y = 420 }) == potassiumButton,
    "Hit-testing must tolerate executors without Volt's __OBJECT_EXISTS property"
)
potassiumSurface:destroy()

surface:destroy()
for _, object in ipairs(objects) do
    assert(object.__OBJECT_EXISTS == false, "Destroying a surface must destroy only its tracked drawings")
end
assert(inputBegan:Count() == 0)
assert(inputChanged:Count() == 0)
assert(inputEnded:Count() == 0)
assert(paintSignal:Count() == 0)

print("drawing-module-contracts-ok")
