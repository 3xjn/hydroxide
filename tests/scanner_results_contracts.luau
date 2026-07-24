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

print("scanner-results-contracts-ok")
