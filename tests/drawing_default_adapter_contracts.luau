local fs = require("@lune/fs")

local function newSignal()
    local callbacks = {}
    local signal = {}

    function signal:Connect(callback)
        table.insert(callbacks, callback)
        return {
            Disconnect = function()
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

    return signal
end

local inputBegan = newSignal()
local inputChanged = newSignal()
local inputEnded = newSignal()
local userInputService = {
    InputBegan = inputBegan,
    InputChanged = inputChanged,
    InputEnded = inputEnded,
}
local guiService = {}
function guiService:GetGuiInset()
    return {
        X = 0,
        Y = 36,
    }
end

game = {
    GetService = function(_game, name)
        if name == "UserInputService" then
            return userInputService
        end
        if name == "GuiService" then
            return guiService
        end
        error("Unexpected service: " .. name)
    end,
}
Enum = {
    UserInputType = {
        MouseButton1 = "MouseButton1",
        MouseMovement = "MouseMovement",
        Touch = "Touch",
    },
}
Vector2 = {
    new = function(x, y)
        return {
            X = x,
            Y = y,
        }
    end,
}
Drawing = {
    new = function(kind)
        local object = {
            Kind = kind,
            Transparency = 1,
            Visible = false,
            ZIndex = 0,
            __OBJECT_EXISTS = true,
        }
        function object:Destroy()
            self.__OBJECT_EXISTS = false
        end
        return object
    end,
}
DrawingImmediate = {
    GetPaint = function()
        return newSignal()
    end,
}

local source = fs.readFile("modules/Drawing.lua")
local DrawingModule = assert(loadstring(source, "modules/Drawing.lua"))()
local surface = DrawingModule.createSurface()
local button = surface:create("Square", {
    Position = {
        X = 10,
        Y = 40,
    },
    Size = {
        X = 100,
        Y = 30,
    },
    Visible = true,
    ZIndex = 1,
})

local enters = 0
local clicks = 0
button:on("pointerenter", function()
    enters = enters + 1
end)
button:on("click", function()
    clicks = clicks + 1
end)

local mousePointUnderTopbar = {
    X = 20,
    Y = 10,
}
inputChanged:Fire({
    Position = mousePointUnderTopbar,
    UserInputType = Enum.UserInputType.MouseMovement,
}, false)
inputBegan:Fire({
    Position = mousePointUnderTopbar,
    UserInputType = Enum.UserInputType.MouseButton1,
}, true)
inputEnded:Fire({
    Position = mousePointUnderTopbar,
    UserInputType = Enum.UserInputType.MouseButton1,
}, true)

assert(enters == 1, "Hover must add Roblox's GUI inset before hit-testing Volt drawings")
assert(clicks == 1, "A topmost drawing must receive processed pointer clicks")

surface:destroy()
print("drawing-default-adapter-contracts-ok")
