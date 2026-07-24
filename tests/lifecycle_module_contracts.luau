local Lifecycle = require("../modules/Lifecycle")

local function newSignal()
    local callbacks = {}
    local signal = {}

    function signal:Connect(callback)
        callbacks[callback] = true
        local connection = {}

        function connection:Disconnect()
            callbacks[callback] = nil
        end

        return connection
    end

    function signal:Fire(...)
        local snapshot = {}
        for callback in pairs(callbacks) do
            table.insert(snapshot, callback)
        end
        for _index, callback in ipairs(snapshot) do
            callback(...)
        end
    end

    function signal:Count()
        local count = 0
        for _callback in pairs(callbacks) do
            count = count + 1
        end
        return count
    end

    return signal
end

local function newContainer(name)
    return {
        Name = name,
        ChildAdded = newSignal(),
        Children = {},
    }
end

local function addChild(container, child)
    table.insert(container.Children, child)
    container.ChildAdded:Fire(child)
end

local function newTool(name)
    return {
        Name = name,
        Destroying = newSignal(),
        IsTool = true,
    }
end

local function contains(items, expected)
    for _index, item in ipairs(items) do
        if item == expected then
            return true
        end
    end

    return false
end

local backpack = newContainer("Backpack")
local firstCharacter = newContainer("FirstCharacter")
local secondCharacter = newContainer("SecondCharacter")
local player = {
    Backpack = backpack,
    Character = firstCharacter,
    CharacterAdded = newSignal(),
}
local boundTools = {}
local cleanedTools = {}
local lifecycle = Lifecycle.new({
    Connect = function(signal, callback)
        return signal:Connect(callback)
    end,
    GetBackpack = function(currentPlayer)
        return currentPlayer.Backpack
    end,
    GetCharacter = function(currentPlayer)
        return currentPlayer.Character
    end,
    GetCharacterAdded = function(currentPlayer)
        return currentPlayer.CharacterAdded
    end,
    GetChildAdded = function(container)
        return container.ChildAdded
    end,
    GetChildren = function(container)
        return container.Children
    end,
    GetDestroying = function(instance)
        return instance.Destroying
    end,
    GetLocalPlayer = function()
        return player
    end,
    IsTool = function(instance)
        return instance.IsTool == true
    end,
})

local firstTool = newTool("DefaultKnife")
local ignoredTool = newTool("DefaultGun")
addChild(backpack, firstTool)
addChild(backpack, ignoredTool)

local session = lifecycle.bindTool("DefaultKnife", function(tool, scope)
    table.insert(boundTools, tool)
    scope.add(function()
        table.insert(cleanedTools, tool)
    end)
end)

assert(#boundTools == 1 and boundTools[1] == firstTool, "Existing matching backpack tools must bind")
assert(backpack.ChildAdded:Count() == 1, "The backpack must be watched for replacement tools")
assert(firstCharacter.ChildAdded:Count() == 1, "The current character must be watched for equipped tools")

addChild(firstCharacter, firstTool)
assert(#boundTools == 1, "Moving the same tool between backpack and character must not double-bind it")

local replacementTool = newTool("DefaultKnife")
addChild(backpack, replacementTool)
assert(#boundTools == 2 and boundTools[2] == replacementTool, "New matching tools must bind")

replacementTool.Destroying:Fire()
assert(cleanedTools[#cleanedTools] == replacementTool, "Destroying a tool must clean its scope")

player.Character = secondCharacter
player.CharacterAdded:Fire(secondCharacter)
assert(firstCharacter.ChildAdded:Count() == 0, "Respawn must disconnect the old character watcher")
assert(secondCharacter.ChildAdded:Count() == 1, "Respawn must watch the new character")
assert(#cleanedTools >= 2, "Respawn must clean scopes from the previous character")

local respawnedTool = newTool("DefaultKnife")
addChild(secondCharacter, respawnedTool)
assert(boundTools[#boundTools] == respawnedTool, "A respawned tool must bind without rerunning the script")

session.stop()
assert(player.CharacterAdded:Count() == 0, "Stopping the session must disconnect respawn handling")
assert(backpack.ChildAdded:Count() == 0, "Stopping the session must disconnect backpack handling")
assert(secondCharacter.ChildAdded:Count() == 0, "Stopping the session must disconnect character handling")
assert(contains(cleanedTools, respawnedTool), "Stopping the session must clean the active tool scope")

session.stop()

local matchedSkins = {}
local skinSession = lifecycle.bindTools(function(tool)
    return tool.Name:find("Skin", 1, true) ~= nil
end, function(tool)
    table.insert(matchedSkins, tool)
end)
local skinnedTool = newTool("RubySkin")
local unrelatedTool = newTool("Lantern")
addChild(secondCharacter, skinnedTool)
addChild(secondCharacter, unrelatedTool)
assert(#matchedSkins == 1 and matchedSkins[1] == skinnedTool, "Generic tool binding must support capability matchers")
skinSession.stop()

print("lifecycle-module-contracts-ok")
