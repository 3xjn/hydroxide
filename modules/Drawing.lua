local NativeDrawing = Drawing
local DrawingModule = {}

local supportedEvents = {
    click = true,
    drag = true,
    pointerdown = true,
    pointerenter = true,
    pointerleave = true,
    pointermove = true,
    pointerup = true,
}

local function defaultContext()
    local GuiService = game:GetService("GuiService")
    local UserInputService = game:GetService("UserInputService")

    return {
        Connect = function(signal, callback)
            return signal:Connect(callback)
        end,
        DestroyObject = function(object)
            object:Destroy()
        end,
        GetInputBegan = function()
            return UserInputService.InputBegan
        end,
        GetInputChanged = function()
            return UserInputService.InputChanged
        end,
        GetInputEnded = function()
            return UserInputService.InputEnded
        end,
        GetPosition = function(input)
            local topLeftInset = GuiService:GetGuiInset()
            return Vector2.new(
                input.Position.X + topLeftInset.X,
                input.Position.Y + topLeftInset.Y
            )
        end,
        IsPointerMovement = function(input)
            return input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
        end,
        IsPrimaryPointer = function(input)
            return input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
        end,
        ConnectPaint = function(zIndex, callback)
            return DrawingImmediate.GetPaint(zIndex):Connect(function()
                callback(DrawingImmediate)
            end)
        end,
        NewObject = function(kind)
            return NativeDrawing.new(kind)
        end,
    }
end

local function pointInPolygon(point, vertices)
    local inside = false
    local previous = vertices[#vertices]

    for _, current in ipairs(vertices) do
        if
            (current.Y > point.Y) ~= (previous.Y > point.Y)
            and point.X
                < (previous.X - current.X) * (point.Y - current.Y) / (previous.Y - current.Y) + current.X
        then
            inside = not inside
        end
        previous = current
    end

    return inside
end

local function distanceToSegment(point, from, to)
    local segmentX = to.X - from.X
    local segmentY = to.Y - from.Y
    local lengthSquared = segmentX * segmentX + segmentY * segmentY
    if lengthSquared == 0 then
        local deltaX = point.X - from.X
        local deltaY = point.Y - from.Y
        return math.sqrt(deltaX * deltaX + deltaY * deltaY)
    end

    local projection = math.clamp(
        ((point.X - from.X) * segmentX + (point.Y - from.Y) * segmentY) / lengthSquared,
        0,
        1
    )
    local closestX = from.X + projection * segmentX
    local closestY = from.Y + projection * segmentY
    local deltaX = point.X - closestX
    local deltaY = point.Y - closestY
    return math.sqrt(deltaX * deltaX + deltaY * deltaY)
end

function DrawingModule.new(context)
    context = context or defaultContext()
    local getProperty = context.GetProperty or function(object, property)
        return object[property]
    end
    local setProperty = context.SetProperty or function(object, property, value)
        object[property] = value
    end
    local function objectExists(object)
        local success, exists = pcall(getProperty, object, "__OBJECT_EXISTS")
        return not success or exists ~= false
    end
    local drawing = {}
    local supportedKinds = {}

    function drawing.supports(kind)
        local cached = supportedKinds[kind]
        if cached ~= nil then
            return cached
        end

        local object
        local success = pcall(function()
            object = context.NewObject(kind)
        end)
        local supported = success and object ~= nil
        if object then
            pcall(context.DestroyObject, object)
        end
        supportedKinds[kind] = supported
        return supported
    end

    function drawing.createSurface(options)
        options = options or {}

        local records = {}
        local orderedNodes = {}
        local connections = {}
        local nextOrder = 0
        local hovered
        local pressed
        local lastPointer
        local destroyed = false
        local surface = {}
        local nodeMethods = {}

        local function emit(node, eventName, point, input, delta)
            local record = records[node]
            if not record then
                return
            end

            for _, callback in ipairs(table.clone(record.events[eventName] or {})) do
                callback(node, point, input, delta)
            end
        end

        local function contains(node, point)
            local record = records[node]
            if
                not record
                or record.pointerEvents == false
                or not objectExists(record.object)
            then
                return false
            end
            if getProperty(record.object, "Visible") ~= true then
                return false
            end

            if record.hitTest then
                return record.hitTest(node, point)
            end

            local object = record.object
            if record.kind == "Square" or record.kind == "Image" then
                local position = getProperty(object, "Position")
                local size = getProperty(object, "Size")
                return position
                    and size
                    and point.X >= position.X
                    and point.Y >= position.Y
                    and point.X <= position.X + size.X
                    and point.Y <= position.Y + size.Y
            elseif record.kind == "Text" then
                local position = getProperty(object, "Position")
                local size = getProperty(object, "TextBounds")
                if not position or not size then
                    return false
                end
                if getProperty(object, "Center") or getProperty(object, "Centered") then
                    position = {
                        X = position.X - size.X / 2,
                        Y = position.Y,
                    }
                end
                return point.X >= position.X
                    and point.Y >= position.Y
                    and point.X <= position.X + size.X
                    and point.Y <= position.Y + size.Y
            elseif record.kind == "Circle" then
                local position = getProperty(object, "Position")
                local radius = getProperty(object, "Radius")
                if not position or not radius then
                    return false
                end
                local deltaX = point.X - position.X
                local deltaY = point.Y - position.Y
                return deltaX * deltaX + deltaY * deltaY <= radius * radius
            elseif record.kind == "Line" then
                local from = getProperty(object, "From")
                local to = getProperty(object, "To")
                local thickness = getProperty(object, "Thickness") or 1
                return from and to and distanceToSegment(point, from, to) <= math.max(thickness / 2, 2)
            elseif record.kind == "Triangle" then
                local vertices = {
                    getProperty(object, "PointA"),
                    getProperty(object, "PointB"),
                    getProperty(object, "PointC"),
                }
                return vertices[1] and vertices[2] and vertices[3] and pointInPolygon(point, vertices) or false
            elseif record.kind == "Quad" then
                local vertices = {
                    getProperty(object, "PointA"),
                    getProperty(object, "PointB"),
                    getProperty(object, "PointC"),
                    getProperty(object, "PointD"),
                }
                return vertices[1]
                    and vertices[2]
                    and vertices[3]
                    and vertices[4]
                    and pointInPolygon(point, vertices)
                    or false
            end

            return false
        end

        local function topNodeAt(point)
            local best
            local bestZIndex = -math.huge
            local bestOrder = -math.huge

            for _, node in ipairs(orderedNodes) do
                local record = records[node]
                if record and contains(node, point) then
                    local zIndex = getProperty(record.object, "ZIndex") or 0
                    if zIndex > bestZIndex or zIndex == bestZIndex and record.order > bestOrder then
                        best = node
                        bestZIndex = zIndex
                        bestOrder = record.order
                    end
                end
            end

            return best
        end

        local function updateHover(point, input)
            local nextHovered = topNodeAt(point)
            if nextHovered ~= hovered then
                if hovered then
                    emit(hovered, "pointerleave", point, input)
                end
                hovered = nextHovered
                if hovered then
                    emit(hovered, "pointerenter", point, input)
                end
            end
            if hovered then
                emit(hovered, "pointermove", point, input)
            end
        end

        local function removeNode(node)
            local record = records[node]
            if not record then
                return
            end

            if hovered == node then
                hovered = nil
            end
            if pressed == node then
                pressed = nil
            end
            records[node] = nil

            local index = table.find(orderedNodes, node)
            if index then
                table.remove(orderedNodes, index)
            end
            context.DestroyObject(record.object)
        end

        function nodeMethods:on(eventName, callback)
            assert(supportedEvents[eventName], "Unknown drawing event: " .. tostring(eventName))
            assert(type(callback) == "function", "Drawing event handler must be a function")

            local record = assert(records[self], "Drawing node has been destroyed")
            local handlers = record.events[eventName]
            if not handlers then
                handlers = {}
                record.events[eventName] = handlers
            end
            table.insert(handlers, callback)

            local connected = true
            return {
                Disconnect = function()
                    if not connected then
                        return
                    end
                    connected = false

                    local index = table.find(handlers, callback)
                    if index then
                        table.remove(handlers, index)
                    end
                end,
            }
        end

        function nodeMethods:set(properties)
            local record = assert(records[self], "Drawing node has been destroyed")
            for property, value in pairs(properties) do
                setProperty(record.object, property, value)
            end
            return self
        end

        function nodeMethods:contains(point)
            return contains(self, point)
        end

        function nodeMethods:destroy()
            removeNode(self)
        end

        nodeMethods.Destroy = nodeMethods.destroy
        nodeMethods.Remove = nodeMethods.destroy

        function surface:create(kind, properties, nodeOptions)
            assert(not destroyed, "Drawing surface has been destroyed")

            nextOrder = nextOrder + 1
            local object = context.NewObject(kind)
            local node = {}
            records[node] = {
                events = {},
                hitTest = nodeOptions and nodeOptions.hitTest,
                kind = kind,
                object = object,
                order = nextOrder,
                pointerEvents = not nodeOptions or nodeOptions.pointerEvents ~= false,
            }
            table.insert(orderedNodes, node)

            setmetatable(node, {
                __index = function(_, property)
                    if property == "raw" then
                        return object
                    end
                    if nodeMethods[property] then
                        return nodeMethods[property]
                    end
                    return getProperty(object, property)
                end,
                __newindex = function(_, property, value)
                    setProperty(object, property, value)
                end,
            })

            node:set(properties or {})
            return node
        end

        function surface:hitTest(point)
            return topNodeAt(point)
        end

        function surface:paint(zIndex, callback)
            assert(not destroyed, "Drawing surface has been destroyed")
            assert(context.ConnectPaint, "Immediate drawing is unavailable in this adapter")
            assert(type(callback) == "function", "Drawing paint callback must be a function")

            local connection = context.ConnectPaint(zIndex, callback)
            table.insert(connections, connection)
            return connection
        end

        function surface:destroy()
            if destroyed then
                return
            end
            destroyed = true

            for _, connection in ipairs(connections) do
                connection:Disconnect()
            end
            table.clear(connections)

            for index = #orderedNodes, 1, -1 do
                removeNode(orderedNodes[index])
            end
        end

        table.insert(connections, context.Connect(context.GetInputBegan(), function(input, gameProcessed)
            if destroyed or gameProcessed and options.respectGameProcessedInput then
                return
            end
            if not context.IsPrimaryPointer(input) then
                return
            end

            local point = context.GetPosition(input)
            lastPointer = point
            updateHover(point, input)
            pressed = topNodeAt(point)
            if pressed then
                emit(pressed, "pointerdown", point, input)
            end
        end))

        table.insert(connections, context.Connect(context.GetInputChanged(), function(input)
            if destroyed or not context.IsPointerMovement(input) then
                return
            end

            local point = context.GetPosition(input)
            local delta
            if lastPointer then
                delta = {
                    X = point.X - lastPointer.X,
                    Y = point.Y - lastPointer.Y,
                }
            end
            lastPointer = point
            updateHover(point, input)
            if pressed then
                emit(pressed, "drag", point, input, delta)
            end
        end))

        table.insert(connections, context.Connect(context.GetInputEnded(), function(input, gameProcessed)
            if destroyed or not context.IsPrimaryPointer(input) then
                return
            end

            local point = context.GetPosition(input)
            local released = pressed
            pressed = nil
            if released then
                emit(released, "pointerup", point, input)
                if
                    (not gameProcessed or not options.respectGameProcessedInput)
                    and topNodeAt(point) == released
                then
                    emit(released, "click", point, input)
                end
            end
            updateHover(point, input)
        end))

        return surface
    end

    return drawing
end

local defaultDrawing
local function getDefaultDrawing()
    if not defaultDrawing then
        defaultDrawing = DrawingModule.new()
    end
    return defaultDrawing
end

DrawingModule.createSurface = function(...)
    return getDefaultDrawing().createSurface(...)
end
DrawingModule.supports = function(...)
    return getDefaultDrawing().supports(...)
end

return DrawingModule
