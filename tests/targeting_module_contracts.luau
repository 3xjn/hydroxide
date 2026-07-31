local Targeting = require("../modules/Targeting")

assert(type(Targeting.observePlayers) == "function", "The default targeting module must expose observations")

local bodyPart = {
    IsA = function(_part, className)
        return className == "BasePart"
    end,
}
local nestedAccessory = {
    IsA = function()
        return false
    end,
}
local hitboxParts = Targeting.getCharacterHitboxParts({
    GetChildren = function()
        return {
            bodyPart,
            nestedAccessory,
        }
    end,
})
assert(#hitboxParts == 1 and hitboxParts[1] == bodyPart, "Hitboxes must use direct character body parts only")

local vectorMetatable = {}
local function vector(x, y, z)
    return setmetatable({
        X = x,
        Y = y,
        Z = z,
    }, vectorMetatable)
end
function vectorMetatable.__add(left, right)
    return vector(left.X + right.X, left.Y + right.Y, left.Z + right.Z)
end
function vectorMetatable.__sub(left, right)
    return vector(left.X - right.X, left.Y - right.Y, left.Z - right.Z)
end
function vectorMetatable.__mul(left, right)
    if type(left) == "number" then
        return vector(left * right.X, left * right.Y, left * right.Z)
    end
    return vector(left.X * right, left.Y * right, left.Z * right)
end
function vectorMetatable.__div(left, right)
    return vector(left.X / right, left.Y / right, left.Z / right)
end
function vectorMetatable.__index(value, key)
    if key == "Dot" then
        return function(_self, other)
            return value.X * other.X + value.Y * other.Y + value.Z * other.Z
        end
    elseif key == "Magnitude" then
        return math.sqrt(value.X * value.X + value.Y * value.Y + value.Z * value.Z)
    end
end

local predicted, flightTime = Targeting.predictIntercept(
    vector(0, 0, 0),
    vector(78, 0, 0),
    vector(10, 0, 0),
    78
)
assert(math.abs(flightTime - 78 / 68) < 1e-6, "Prediction must solve the moving-target intercept time")
assert(math.abs(predicted.X - (78 + 10 * flightTime)) < 1e-6, "Prediction must lead the moving target")

local localPlayer = {
    Name = "Local",
}
local hiddenPlayer = {
    Name = "Hidden",
}
local farPlayer = {
    Name = "Far",
}
local nearPlayer = {
    Name = "Near",
}
local ineligiblePlayer = {
    Name = "Friendly",
}

local characters = {
    [hiddenPlayer] = { Name = "HiddenCharacter" },
    [farPlayer] = { Name = "FarCharacter" },
    [nearPlayer] = { Name = "NearCharacter" },
    [ineligiblePlayer] = { Name = "FriendlyCharacter" },
}
local distances = {
    [characters[farPlayer]] = 90,
    [characters[nearPlayer]] = 30,
    [characters[ineligiblePlayer]] = 45,
}
local visibleAims = {
    [characters[farPlayer]] = {
        part = "Head",
        position = "FarPosition",
        screenPosition = { X = 20, Y = 0 },
        visibility = 1,
    },
    [characters[nearPlayer]] = {
        part = "UpperTorso",
        position = "NearPosition",
        screenPosition = { X = 100, Y = 0 },
        visibility = 0.8,
    },
    [characters[ineligiblePlayer]] = {
        part = "Head",
        position = "FriendlyPosition",
        screenPosition = { X = 15, Y = 0 },
        visibility = 1,
    },
}
local observations = {
    [characters[hiddenPlayer]] = {
        bounds = "HiddenBounds",
        part = "HiddenHead",
        position = "HiddenPosition",
        screenPosition = { X = 5, Y = 0 },
        visible = false,
    },
    [characters[farPlayer]] = {
        bounds = "FarBounds",
        visible = true,
    },
    [characters[nearPlayer]] = {
        bodyParts = {
            { name = "Head", visible = true },
            { name = "UpperTorso", visible = false },
        },
        bounds = "NearBounds",
        visible = true,
    },
    [characters[ineligiblePlayer]] = {
        bounds = "FriendlyBounds",
        visible = true,
    },
}
local eligibilityChecks = 0
local targeting = Targeting.new({
    GetCharacter = function(player)
        return characters[player]
    end,
    GetDistance = function(_localPlayer, character)
        return distances[character]
    end,
    GetLocalPlayer = function()
        return localPlayer
    end,
    GetPlayers = function()
        return {
            localPlayer,
            hiddenPlayer,
            farPlayer,
            nearPlayer,
            ineligiblePlayer,
        }
    end,
    GetVisibleAim = function(_localPlayer, character)
        return visibleAims[character]
    end,
    GetPlayerObservation = function(_localPlayer, _player, character)
        return observations[character]
    end,
    IsEligible = function(_localPlayer, player)
        eligibilityChecks = eligibilityChecks + 1
        return player ~= localPlayer and player ~= ineligiblePlayer
    end,
})

local nearest = targeting.nearestVisiblePlayer()
assert(nearest, "A visible eligible target must be selected")
assert(nearest.player == nearPlayer, "The nearest visible eligible player must win")
assert(nearest.character == characters[nearPlayer], "The target must retain its character")
assert(nearest.part == "UpperTorso", "The target must retain its most visible body part")
assert(nearest.position == "NearPosition", "The target must retain the visible aim position")
assert(nearest.visibility == 0.8, "The target must expose its visibility score")
assert(nearest.distance == 30, "The target must expose its measured distance")
assert(eligibilityChecks == 5, "Every player must pass through the eligibility policy")

local screenNearest = targeting.nearestVisiblePlayer({
    screenOrigin = { X = 0, Y = 0 },
    maxScreenDistance = 50,
})
assert(screenNearest and screenNearest.player == farPlayer, "FOV targeting must prefer screen-space proximity")
assert(screenNearest.screenDistance == 20)

local outsideFov = targeting.nearestVisiblePlayer({
    screenOrigin = { X = 0, Y = 0 },
    maxScreenDistance = 10,
})
assert(outsideFov == nil, "Visible players outside the FOV must be rejected")

local observed = targeting.observePlayers()
assert(#observed == 3, "Every eligible on-screen player must be observed")
assert(observed[1].player == hiddenPlayer and observed[1].visible == false)
assert(observed[2].player == farPlayer and observed[2].bounds == "FarBounds")
assert(observed[3].player == nearPlayer and observed[3].character == characters[nearPlayer])
assert(
    #observed[3].bodyParts == 2 and observed[3].bodyParts[1].visible == true,
    "Targeting observations must preserve per-body-part visibility"
)

local observedCharacter = targeting.observeCharacter(characters[hiddenPlayer], {
    screenOrigin = { X = 0, Y = 0 },
})
assert(observedCharacter.character == characters[hiddenPlayer])
assert(observedCharacter.bounds == "HiddenBounds")
assert(observedCharacter.screenDistance == 5)

local genericNearest = targeting.nearestObservation({
    {
        position = "FarGenericPosition",
        screenDistance = 30,
        visible = true,
    },
    {
        position = "NearGenericPosition",
        screenDistance = 5,
        visible = true,
    },
}, {
    maxScreenDistance = 10,
})
assert(
    genericNearest and genericNearest.position == "NearGenericPosition",
    "Generic model observations must use the same screen-space selection policy as players"
)

local scoped = targeting.observePlayers({
    isEligible = function(player)
        return player == nearPlayer
    end,
})
assert(#scoped == 1 and scoped[1].player == nearPlayer, "Callers must be able to scope eligible targets")

local overrideObserved = targeting.observePlayers({
    isEligible = function(player)
        return player == ineligiblePlayer
    end,
})
assert(
    #overrideObserved == 1 and overrideObserved[1].player == ineligiblePlayer,
    "A caller eligibility policy must replace the default team policy"
)

local overrideNearest = targeting.nearestVisiblePlayer({
    isEligible = function(player)
        return player == ineligiblePlayer
    end,
})
assert(
    overrideNearest and overrideNearest.player == ineligiblePlayer,
    "Nearest targeting must honor a caller policy that admits a default-ineligible player"
)

local wallbangNearest = targeting.nearestPlayer({
    includeBlocked = true,
    maxScreenDistance = 10,
    screenOrigin = { X = 0, Y = 0 },
})
assert(wallbangNearest and wallbangNearest.player == hiddenPlayer)
assert(wallbangNearest.position == "HiddenPosition")

local visiblePolicy = targeting.nearestPlayer({
    includeBlocked = false,
    maxScreenDistance = 10,
    screenOrigin = { X = 0, Y = 0 },
})
assert(visiblePolicy == nil, "Blocked targets must remain excluded unless wallbang is enabled")

local limited = targeting.nearestVisiblePlayer({
    maxDistance = 20,
})
assert(limited == nil, "Targets beyond the requested distance must be rejected")

visibleAims[characters[nearPlayer]] = nil
local fallback = targeting.nearestVisiblePlayer()
assert(fallback and fallback.player == farPlayer, "Hidden players must be skipped instead of blocking other targets")

visibleAims[characters[farPlayer]] = nil
assert(targeting.nearestVisiblePlayer() == nil, "No visible eligible player must return nil")

local localCharacter = {
    FindFirstChild = function()
        return nil
    end,
}
local defaultLocalPlayer = {
    Character = localCharacter,
    GetAttribute = function()
        return nil
    end,
}
local targetPart = {
    Position = vector(10, 10, 10),
    Size = vector(2, 2, 2),
}
targetPart.CFrame = {
    PointToWorldSpace = function(_cframe, point)
        return targetPart.Position + point
    end,
}
targetPart.IsA = function(_part, className)
    return className == "BasePart"
end
local targetCharacter = {
    FindFirstChild = function(_character, name)
        if name == "Head" then
            return targetPart
        end
        return nil
    end,
    FindFirstChildOfClass = function(_character, className)
        if className == "Humanoid" then
            return {
                Health = 100,
            }
        end
        return nil
    end,
    GetChildren = function()
        return {
            targetPart,
        }
    end,
}
local targetPlayer = {
    Character = targetCharacter,
    GetAttribute = function()
        return nil
    end,
}
local defaultPlayers = {
    LocalPlayer = defaultLocalPlayer,
    GetPlayers = function()
        return {
            defaultLocalPlayer,
            targetPlayer,
        }
    end,
}
local raycastCalls = {}
local defaultWorkspace = {
    CurrentCamera = {
        ViewportSize = {
            X = 1000,
            Y = 1000,
        },
        GetRenderCFrame = function()
            return {
                Position = vector(0, 0, 0),
            }
        end,
        WorldToViewportPoint = function(_camera, point)
            return {
                X = point.X + 100,
                Y = point.Y + 100,
                Z = 10,
            }, true
        end,
    },
    Raycast = function(_workspace, _origin, _direction, params)
        table.insert(raycastCalls, params.FilterDescendantsInstances)
        return nil
    end,
}

Vector2 = {
    new = function(x, y)
        return {
            X = x,
            Y = y,
        }
    end,
}
Vector3 = {
    new = vector,
    zero = vector(0, 0, 0),
}
Enum = {
    RaycastFilterType = {
        Exclude = "Exclude",
    },
}
RaycastParams = {
    new = function()
        return {}
    end,
}
game = {
    GetService = function(_game, name)
        if name == "Players" then
            return defaultPlayers
        elseif name == "Workspace" then
            return defaultWorkspace
        end
        error("Unexpected service: " .. name)
    end,
}

local function assertRaycastFilters(expectedIgnore)
    assert(#raycastCalls == 5, "One body part must retain the five-sample visibility budget")
    for _index, filter in ipairs(raycastCalls) do
        assert(filter[1] == localCharacter, "The local character must always remain excluded")
        assert(#filter == #expectedIgnore + 1, "The visibility filter must contain only unique exclusions")
        for index, ignored in ipairs(expectedIgnore) do
            assert(filter[index + 1] == ignored, "Caller exclusions must be merged into visibility raycasts")
        end
    end
end

raycastCalls = {}
local defaultObservation = Targeting.observeCharacter(targetCharacter)
assert(defaultObservation and defaultObservation.visible, "Default observation behavior must remain visible")
assertRaycastFilters({})

local ignoredAccessory = {}
local ignoredEffect = {}
local callerIgnore = {
    [1] = ignoredAccessory,
    [2] = ignoredAccessory,
    [4] = ignoredEffect,
}
local raycastOptions = {
    raycastIgnore = callerIgnore,
}

raycastCalls = {}
local ignoredObservation = Targeting.observeCharacter(targetCharacter, raycastOptions)
assert(ignoredObservation and ignoredObservation.visible, "Raycast exclusions must not change projection")
assertRaycastFilters({
    ignoredAccessory,
    ignoredEffect,
})
assert(callerIgnore[1] == ignoredAccessory and callerIgnore[2] == ignoredAccessory)
assert(callerIgnore[3] == nil and callerIgnore[4] == ignoredEffect)
local callerIgnoreKeyCount = 0
for _key in pairs(callerIgnore) do
    callerIgnoreKeyCount = callerIgnoreKeyCount + 1
end
assert(callerIgnoreKeyCount == 3, "Targeting must not mutate the caller's raycastIgnore list")

raycastCalls = {}
local defaultObservedPlayers = Targeting.observePlayers(raycastOptions)
assert(#defaultObservedPlayers == 1 and defaultObservedPlayers[1].player == targetPlayer)
assertRaycastFilters({
    ignoredAccessory,
    ignoredEffect,
})

raycastCalls = {}
local defaultNearest = Targeting.nearestPlayer(raycastOptions)
assert(defaultNearest and defaultNearest.player == targetPlayer)
assertRaycastFilters({
    ignoredAccessory,
    ignoredEffect,
})

raycastCalls = {}
local defaultVisibleNearest = Targeting.nearestVisiblePlayer(raycastOptions)
assert(defaultVisibleNearest and defaultVisibleNearest.player == targetPlayer)
assertRaycastFilters({
    ignoredAccessory,
    ignoredEffect,
})

raycastCalls = {}
local selectionOnly = Targeting.nearestObservation({
    {
        distance = 10,
        position = vector(10, 10, 10),
        visible = true,
    },
}, raycastOptions)
assert(selectionOnly and selectionOnly.distance == 10)
assert(#raycastCalls == 0, "Generic observation selection must never consume visibility raycasts")

print("targeting-module-contracts-ok")
