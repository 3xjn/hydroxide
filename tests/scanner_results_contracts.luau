local ScannerResults = require("../modules/ScannerResults")

local function result(name, path)
    local instance = {
        Name = name,
    }

    function instance:GetFullName()
        return path
    end

    return {
        Instance = instance,
    }
end

local door = result("DoorManager", "Players.LocalPlayer.PlayerScripts.DoorManager")
local inventory = result("inventory", "ReplicatedStorage.Shared.inventory")
local loading = result("LoadingIndicator", "Players.LocalPlayer.PlayerScripts.LoadingIndicator")
local npc = result("NPCDisplayManager", "Players.LocalPlayer.PlayerScripts.NPCDisplayManager")
local sharedInventory = result("inventory", "ReplicatedStorage.Other.inventory")

local sorted = ScannerResults.Sorted({
    [npc.Instance] = npc,
    [sharedInventory.Instance] = sharedInventory,
    [door.Instance] = door,
    [loading.Instance] = loading,
    [inventory.Instance] = inventory,
})

assert(sorted[1] == door, "Scanner results must sort names alphabetically")
assert(sorted[2] == sharedInventory, "Matching names must use their full path as a stable tie-breaker")
assert(sorted[3] == inventory, "Matching names must remain deterministic")
assert(sorted[4] == loading, "Alphabetical ordering must be case-insensitive")
assert(sorted[5] == npc, "All scanner results must participate in sorting")

local function protoA() end
local function protoB() end
local linkedPart = {
    Name = "Door",
    ClassName = "Part",
}

local described = ScannerResults.Describe({
    Instance = door.Instance,
    Protos = {
        [2] = protoB,
        [1] = protoA,
    },
    Constants = {
        [1] = "ThrowEvent",
        [2] = protoB,
    },
    Environment = {
        shared = 15,
        script = linkedPart,
    },
}, {
    GetInfo = function(value)
        if value == protoA then
            return { name = "onTouched" }
        end
        return { name = "" }
    end,
    GetInstancePath = function(value)
        if value == door.Instance then
            return "game:GetService(\"Players\").LocalPlayer.PlayerScripts.DoorManager"
        end
        if value == linkedPart then
            return "workspace.Door"
        end
        return value.Name
    end,
    ToString = tostring,
    IsInstance = function(value)
        return value == linkedPart
    end,
})

assert(described.Name == "DoorManager", "Describe must retain the script name the UI shows")
assert(
    described.Path == "game:GetService(\"Players\").LocalPlayer.PlayerScripts.DoorManager",
    "Describe must expose the canonical instance path"
)
assert(described.Protos[1].Index == 1 and described.Protos[1].Value == protoA, "Protos must stay in index order")
assert(described.Protos[1].Name == "onTouched", "Proto names must use getInfo like the Script Scanner")
assert(described.Protos[2].Name == "Unnamed function", "Anonymous protos must keep the UI's unnamed label")
assert(described.Constants[1].Text == "ThrowEvent", "Literal constants must remain readable")
assert(described.Constants[2].Name == "Unnamed function", "Function constants must use the same closure labels")
assert(described.Environment[1].Key == "script" or described.Environment[2].Key == "script", "Environment keys must survive")

local scriptEnv
for _, entry in ipairs(described.Environment) do
    if entry.Key == "script" then
        scriptEnv = entry
    end
end
assert(scriptEnv.IsInstance and scriptEnv.Path == "workspace.Door", "Instance environment values must carry inspectable paths")
assert(scriptEnv.Value == linkedPart, "Describe must keep live objects for later Spy Closure / Inspect Signals")

print("scanner-results-contracts-ok")
