local Lifecycle = {}

local function defaultContext()
    local Players = game:GetService("Players")

    return {
        Connect = function(signal, callback)
            return signal:Connect(callback)
        end,
        GetBackpack = function(player)
            return player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack")
        end,
        GetCharacter = function(player)
            return player.Character
        end,
        GetCharacterAdded = function(player)
            return player.CharacterAdded
        end,
        GetChildAdded = function(container)
            return container.ChildAdded
        end,
        GetChildren = function(container)
            return container:GetChildren()
        end,
        GetDestroying = function(instance)
            return instance.Destroying
        end,
        GetLocalPlayer = function()
            return Players.LocalPlayer
        end,
        IsTool = function(instance)
            return instance:IsA("Tool")
        end,
    }
end

local function newScope(context)
    local cleanups = {}
    local stopped = false
    local scope = {}

    function scope.add(cleanup)
        if stopped then
            cleanup()
            return cleanup
        end

        table.insert(cleanups, cleanup)
        return cleanup
    end

    function scope.connect(signal, callback)
        local connection = context.Connect(signal, callback)
        scope.add(function()
            connection:Disconnect()
        end)
        return connection
    end

    function scope.stop()
        if stopped then
            return
        end

        stopped = true
        for index = #cleanups, 1, -1 do
            pcall(cleanups[index])
        end
        table.clear(cleanups)
    end

    return scope
end

function Lifecycle.new(context)
    context = context or defaultContext()

    local lifecycle = {}

    function lifecycle.bindTools(matches, callback)
        local player = context.GetLocalPlayer()
        local sessionScope = newScope(context)
        local characterScope
        local toolScopes = {}

        local function clearTools()
            for tool, scope in pairs(toolScopes) do
                scope.stop()
                toolScopes[tool] = nil
            end
        end

        local function bind(tool)
            if toolScopes[tool] or not context.IsTool(tool) or not matches(tool) then
                return
            end

            local scope = newScope(context)
            toolScopes[tool] = scope
            callback(tool, scope)

            local destroying = context.GetDestroying and context.GetDestroying(tool)
            if destroying then
                scope.connect(destroying, function()
                    scope.stop()
                    toolScopes[tool] = nil
                end)
            end
        end

        local function watch(container, scope)
            if not container then
                return
            end

            for _index, child in ipairs(context.GetChildren(container)) do
                bind(child)
            end
            scope.connect(context.GetChildAdded(container), bind)
        end

        local function rebind(character)
            if characterScope then
                characterScope.stop()
            end
            clearTools()

            characterScope = newScope(context)
            watch(context.GetBackpack(player), characterScope)
            watch(character, characterScope)
        end

        sessionScope.connect(context.GetCharacterAdded(player), rebind)
        rebind(context.GetCharacter(player))

        local stopSession = sessionScope.stop
        function sessionScope.stop()
            if characterScope then
                characterScope.stop()
                characterScope = nil
            end
            clearTools()
            stopSession()
        end

        return sessionScope
    end

    function lifecycle.bindTool(toolName, callback)
        return lifecycle.bindTools(function(tool)
            return tool.Name == toolName
        end, callback)
    end

    return lifecycle
end

local defaultLifecycle
local function getDefaultLifecycle()
    if not defaultLifecycle then
        defaultLifecycle = Lifecycle.new()
    end

    return defaultLifecycle
end

Lifecycle.bindTool = function(...)
    return getDefaultLifecycle().bindTool(...)
end
Lifecycle.bindTools = function(...)
    return getDefaultLifecycle().bindTools(...)
end

return Lifecycle
