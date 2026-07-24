local InstancePath = require("../modules/InstancePath")

local function node(name)
    return {
        Name = name,
        Members = {},
    }
end

local game = node("game")
local workspace = node("workspace")
local players = node("Players")
local localPlayer = node("Asher")
local playerScripts = node("PlayerScripts")
local doorManager = node("DoorManager")
local unusual = node("Door Manager")

game.Members.Workspace = workspace
game.Members.Players = players
workspace.Members["Door Manager"] = unusual
players.Members.LocalPlayer = localPlayer
localPlayer.Members.PlayerScripts = playerScripts
playerScripts.Members.DoorManager = doorManager

local options = {
    Game = game,
    Workspace = workspace,
    GetService = function(name)
        return game.Members[name]
    end,
    GetMember = function(parent, name)
        return parent.Members[name]
    end,
    IsInstance = function(value)
        return type(value) == "table" and value.Members ~= nil
    end,
}

local resolved = assert(InstancePath.Resolve(
    'game:GetService("Players").LocalPlayer.PlayerScripts.DoorManager',
    options
))
assert(resolved == doorManager, "GetService and member traversal must resolve an exact instance")

assert(
    InstancePath.Resolve("game.Players.LocalPlayer.PlayerScripts.DoorManager", options) == doorManager,
    "Dot paths must resolve service properties and descendants"
)
assert(
    InstancePath.Resolve('workspace["Door Manager"]', options) == unusual,
    "Bracket syntax must resolve names that are not identifiers"
)
assert(
    InstancePath.Resolve("workspace", options) == workspace,
    "The workspace root must be directly inspectable"
)

local missing, missingError = InstancePath.Resolve("workspace.Missing", options)
assert(missing == nil and missingError:find("Missing", 1, true), "Missing segments must return a useful error")

local unsupported, unsupportedError = InstancePath.Resolve("os.clock()", options)
assert(
    unsupported == nil and unsupportedError:find('begin with "game" or "workspace"', 1, true),
    "Arbitrary expressions must not execute"
)

print("instance-path-contracts-ok")
