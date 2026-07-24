local fs = require("@lune/fs")
local Targeting = require("../modules/Targeting")

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

    function signal:Count()
        return #callbacks
    end

    return signal
end

local renderStepped = newSignal()
local playerRemoving = newSignal()
local createdNodes = {}
local installedHooks = {}
local restoredFunctions = {}
local originalCalls = {}
local knifePositionCalls = {}
local knifeDesktopCalls = 0
local bindWeaponsCallback
local lifecycleStopped = {}
local surfaceDestroyed = false
local toolCleanups = {
    Gun = {},
    Knife = {},
}
local capturedAction
local mousePosition = {
    X = 320,
    Y = 240,
}
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
function vectorMetatable.__index(value, key)
    if key == "Dot" then
        return function(_self, other)
            return value.X * other.X + value.Y * other.Y + value.Z * other.Z
        end
    end
end

local surface = {}
function surface:create(kind, properties, options)
    local node = {
        Kind = kind,
        Options = options,
        Handlers = {},
    }
    for property, value in pairs(properties) do
        node[property] = value
    end
    function node:on(eventName, callback)
        self.Handlers[eventName] = callback
    end
    function node:destroy()
        self.Destroyed = true
    end
    table.insert(createdNodes, node)
    return node
end
function surface:destroy()
    surfaceDestroyed = true
end

local targetPlayer = {
    Name = "VisibleTarget",
}
local blockedPlayer = {
    Name = "BlockedTarget",
}
local targetPosition = {
    X = 78,
    Y = 0,
    Z = 0,
}
setmetatable(targetPosition, vectorMetatable)
local targetPart = {
    AssemblyLinearVelocity = vector(10, 0, 0),
    Name = "UpperTorso",
    Size = vector(2, 4, 2),
    Parent = {
        FindFirstChild = function()
            return true
        end,
    },
}
local observations = {
    {
        player = targetPlayer,
        part = targetPart,
        position = targetPosition,
        bounds = {
            position = { X = 100, Y = 120 },
            size = { X = 40, Y = 80 },
        },
        screenDistance = 20,
        visible = true,
    },
    {
        player = blockedPlayer,
        part = targetPart,
        position = {
            X = 90,
            Y = 0,
            Z = 0,
        },
        bounds = {
            position = { X = 240, Y = 120 },
            size = { X = 40, Y = 80 },
        },
        screenDistance = 40,
        visible = false,
    },
}
setmetatable(observations[2].position, vectorMetatable)

local fakeOh = {
    Resources = {},
    closure = {},
    drawing = {
        createSurface = function()
            return surface
        end,
    },
    lifecycle = {},
    targeting = {},
}
function fakeOh.lifecycle.bindTools(matcher, callback)
    assert(type(matcher) == "function")
    bindWeaponsCallback = function(tool, scope)
        if matcher(tool) then
            callback(tool, scope)
        end
    end
    return {
        stop = function()
            lifecycleStopped.Weapons = true
            for _, weaponName in ipairs({ "Gun", "Knife" }) do
                for _, cleanup in ipairs(toolCleanups[weaponName]) do
                    cleanup()
                end
            end
        end,
    }
end
function fakeOh.targeting.observePlayers(options)
    assert(options.screenOrigin)
    return observations
end
function fakeOh.targeting.nearestPlayer(options)
    assert(options.maxScreenDistance)
    if options.includeBlocked then
        return observations[2]
    end
    return observations[1]
end
fakeOh.targeting.predictIntercept = Targeting.predictIntercept

local workspace
local gunShootCalls = 0
local shootLocalBeam = function(target, origin, tool)
    local raycastResult = installedHooks[workspace.Raycast](workspace, origin, target, {})
    table.insert(originalCalls, {
        target,
        origin,
        tool,
        raycastResult,
    })
end
local shoot = function()
    gunShootCalls = gunShootCalls + 1
    installedHooks[shootLocalBeam]("mouse-target", "origin", "tool")
end
local handleDesktop = function()
    knifeDesktopCalls = knifeDesktopCalls + 1
end
local handlePosition = function(position)
    table.insert(knifePositionCalls, position)
end
local gunScript = {}
local knifeScript = {}
function fakeOh.closure.findUpvalue(script, predicate)
    local values = script == gunScript and {
        shootLocalBeam,
        shoot,
    } or {
        handleDesktop,
        handlePosition,
    }
    for _, value in ipairs(values) do
        if predicate(value) then
            return value
        end
    end
    return nil
end

local environment = {
    HydroxideConfig = {
        LocalRoot = "hydroxide/local",
    },
    oh = {
        closure = {},
        drawing = {},
        lifecycle = {},
        targeting = {},
    },
}
getgenv = function()
    return environment
end
local loaderReads = 0
__freshOh = fakeOh
readfile = function(path)
    if path == "hydroxide/local/examples/weapon_validation.lua" then
        return fs.readFile("examples/weapon_validation.lua")
    end
    assert(path == "hydroxide/local/modules/Helpers.lua")
    loaderReads = loaderReads + 1
    return [[
return {
    load = function(options)
        assert(options.localRoot == "hydroxide/local")
        assert(#options.modules == 4)
        return __freshOh
    end,
}
]]
end
local throwOrigin = vector(0, 0, 0)
local rightGripAttachment = {
    WorldCFrame = {
        Position = throwOrigin,
    },
}
local rightHand = {
    FindFirstChild = function(_hand, name)
        if name == "RightGripAttachment" then
            return rightGripAttachment
        end
    end,
}
local characterChildren = {}
local character = {
    FindFirstChild = function(_character, name)
        if name == "RightHand" then
            return rightHand
        end
    end,
    GetChildren = function()
        return characterChildren
    end,
}
workspace = {
    CurrentCamera = {
        ViewportSize = {
            X = 800,
            Y = 600,
        },
    },
    Raycast = function()
        return nil
    end,
    FindPartOnRayWithIgnoreList = function()
        return "WallPart", "WallPosition"
    end,
}
game = {
    GetService = function(_game, name)
        if name == "Players" then
            return {
                LocalPlayer = {
                    Character = character,
                },
                PlayerRemoving = playerRemoving,
            }
        elseif name == "RunService" then
            return {
                RenderStepped = renderStepped,
            }
        elseif name == "UserInputService" then
            return {
                GetMouseLocation = function()
                    return mousePosition
                end,
            }
        elseif name == "Workspace" then
            return workspace
        elseif name == "ContextActionService" then
            return {
                BindActionAtPriority = function(_service, actionName)
                    capturedAction = actionName
                end,
                UnbindAction = function(_service, actionName)
                    if capturedAction == actionName then
                        capturedAction = nil
                    end
                end,
            }
        end
        error("Unexpected service: " .. name)
    end,
}
Drawing = {
    Fonts = {
        Plex = 2,
    },
}
Enum = {
    ContextActionPriority = {
        High = {
            Value = 3000,
        },
    },
    ContextActionResult = {
        Sink = "Sink",
    },
    UserInputType = {
        MouseButton1 = "MouseButton1",
        Touch = "Touch",
    },
}
Color3 = {
    fromRGB = function(red, green, blue)
        return ("%d,%d,%d"):format(red, green, blue)
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
debug = {
    getupvalues = function(value)
        if value == handlePosition then
            return {
                [4] = false,
                [8] = false,
            }
        end
        return {}
    end,
    setupvalue = function()
        return nil
    end,
    getinfo = function(value)
        return {
            name = value == shootLocalBeam and "ShootLocalBeam"
                or value == shoot and "Shoot"
                or value == handleDesktop and "HandleThrowingLocal"
                or value == handlePosition and "HandleThrowingLocalOnMobile"
                or "",
        }
    end,
}
hookfunction = function(target, hook)
    installedHooks[target] = hook
    return target
end
restorefunction = function(target)
    restoredFunctions[target] = true
end

local source = fs.readFile("examples/gun_validation.lua")
local returnedSession = assert(loadstring(source, "examples/gun_validation.lua"))()
assert(loaderReads == 1, "A stale session must refresh through the headless helper loader")
local session = environment.HydroxideWeaponValidation
assert(session == returnedSession, "The weapon validation session must be replaceable")
assert(session.selectWeapon == nil and session.controls.tabs == nil, "Equipped weapons must replace manual tabs")
assert(type(session.setOption) == "function", "The panel toggles must update shared weapon policy")
assert(session.state.settings and session.state.weapons == nil, "Gun and Knife must share one settings contract")
assert(bindWeaponsCallback, "Weapons must use the respawn-safe capability binding")
assert(#fakeOh.Resources == 1, "Hydroxide shutdown must own the weapon validation resource")

local gunActivations = 0
local gunTool = {
    Name = "NebulaBlaster",
    Parent = character,
    IsA = function(_tool, className)
        return className == "Tool"
    end,
    WaitForChild = function(_tool, name)
        assert(name == "LocalScript")
        return gunScript
    end,
    FindFirstChildOfClass = function(_tool, className)
        assert(className == "LocalScript")
        return gunScript
    end,
}
function gunTool:Activate()
    gunActivations = gunActivations + 1
    error("Trigger Bot must invoke the live Shoot closure, not Tool:Activate()")
end
local spareGunTool = {
    Name = "UnskinnedBackup",
    Parent = {},
    IsA = gunTool.IsA,
    WaitForChild = gunTool.WaitForChild,
    FindFirstChildOfClass = gunTool.FindFirstChildOfClass,
}
local knifeTool = {
    Name = "RubyEdge",
    Parent = {},
    IsA = gunTool.IsA,
    FindFirstChild = function(_tool, name)
        if name == "Handle" then
            return {
                Position = throwOrigin,
            }
        end
    end,
    WaitForChild = function(_tool, name)
        assert(name == "LocalScript")
        return knifeScript
    end,
    FindFirstChildOfClass = function(_tool, className)
        assert(className == "LocalScript")
        return knifeScript
    end,
}

bindWeaponsCallback(gunTool, {
    add = function(cleanup)
        table.insert(toolCleanups.Gun, cleanup)
    end,
})
bindWeaponsCallback(spareGunTool, {
    add = function(cleanup)
        table.insert(toolCleanups.Gun, cleanup)
    end,
})
bindWeaponsCallback(knifeTool, {
    add = function(cleanup)
        table.insert(toolCleanups.Knife, cleanup)
    end,
})
assert(installedHooks[shootLocalBeam], "The live ShootLocalBeam function must be hooked")
assert(installedHooks[handleDesktop], "The desktop knife throw must be hooked")
assert(installedHooks[handlePosition], "The position-based knife throw must be hooked")

characterChildren = {
    gunTool,
}
renderStepped:Fire()
assert(session.state.activeWeapon == "Gun", "The equipped Gun must drive the live weapon label")
assert(session.controls.weapon.value.Text == "Gun")
assert(session.state.visiblePlayers == 1)
assert(session.state.blockedPlayers == 1)

local visibleBox
local blockedBox
local fovCircle
local sliderHit
for _, node in ipairs(createdNodes) do
    if node.Kind == "Circle" and node.Filled == false then
        fovCircle = node
    elseif node.Kind == "Square" and node.Position == observations[1].bounds.position then
        visibleBox = node
    elseif node.Kind == "Square" and node.Position == observations[2].bounds.position then
        blockedBox = node
    elseif node.Kind == "Square" and node.Handlers.pointerdown then
        sliderHit = node
    end
end
assert(fovCircle and fovCircle.Position.X == 320 and fovCircle.Position.Y == 240)
assert(visibleBox.Color == "98,214,173", "Visible players must use the Hydroxide accent")
assert(blockedBox.Color == "230,107,110", "Blocked players must use the Hydroxide danger color")
assert(sliderHit, "The FOV slider must have a pointer target")

sliderHit.Handlers.pointerenter()
assert(capturedAction == "HydroxideWeaponPanel", "The panel must prevent click-through weapon activation")
sliderHit.Handlers.pointerdown(sliderHit, {
    X = sliderHit.Position.X + sliderHit.Size.X,
    Y = sliderHit.Position.Y,
})
assert(session.state.settings.fov == session.state.settings.maximumFov)
sliderHit.Handlers.pointerleave()
assert(capturedAction == nil)

installedHooks[shootLocalBeam]("original-target", "origin", "tool")
assert(originalCalls[1][1] == "original-target", "Silent aim must be opt-in")

session:setOption("silentAim", true)
installedHooks[shootLocalBeam]("original-target", "origin", "tool")
assert(originalCalls[2][1] == targetPosition, "Gun silent aim must use the FOV target")

session:setOption("wallbang", true)
installedHooks[shootLocalBeam]("original-target", "origin", "tool")
assert(originalCalls[3][1] == observations[2].position, "Gun wallbang must admit blocked targets")
assert(originalCalls[3][4].Instance == targetPart, "Gun wallbang must confirm the selected body part")

session:setOption("triggerBot", true)
renderStepped:Fire()
assert(gunShootCalls == 1, "Silent trigger bot must invoke the game's live Shoot closure")
assert(gunActivations == 0, "Trigger bot must not depend on executor Tool:Activate behavior")
assert(session.state.lastTrigger.weapon == "Gun" and session.state.lastTrigger.outcome == "fired")

session:setOption("triggerBot", false)
knifeTool.Parent = character
gunTool.Parent = {}
characterChildren = {
    knifeTool,
}
renderStepped:Fire()
assert(session.state.activeWeapon == "Knife", "Swapping tools must update the live weapon automatically")
assert(session.controls.weapon.value.Text == "Knife")
assert(session.state.settings.silentAim == true, "Weapon swaps must retain shared settings")

mousePosition = {
    X = 110,
    Y = 130,
}
session:setOption("silentAim", false)
session:setOption("triggerBot", true)
renderStepped:Fire()
assert(#knifePositionCalls == 1, "Non-silent trigger bot must fire only over an enemy box")
assert(knifePositionCalls[1].X > targetPosition.X, "Knife trigger bot must lead a moving target")

session:setOption("silentAim", true)
session:setOption("wallbang", true)
installedHooks[handleDesktop]()
assert(
    knifePositionCalls[#knifePositionCalls].X > observations[2].position.X,
    "Knife silent aim and wallbang must share the predictive position-based throw path"
)
assert(knifeDesktopCalls == 0, "A directed knife throw must bypass the mouse-ray desktop path")
local passedPart = installedHooks[workspace.FindPartOnRayWithIgnoreList](workspace, {
    Direction = vector(40, 0, 0),
    Origin = vector(0, 0, 0),
}, {})
assert(passedPart == nil, "Knife wallbang must ignore geometry encountered before the predicted target")
local hitPart, hitPosition = installedHooks[workspace.FindPartOnRayWithIgnoreList](workspace, {
    Direction = vector(8, 0, 0),
    Origin = vector(98, 0, 0),
}, {})
assert(hitPart == targetPart and hitPosition.X > observations[2].position.X)

local labels = {}
for _, node in ipairs(createdNodes) do
    if node.Kind == "Text" then
        labels[node.Text] = true
    end
end
assert(labels.Weapon and labels.FOV)
assert(labels["Silent Aim"] and labels["Trigger Bot"] and labels.Wallbang)

session:stop()
assert(lifecycleStopped.Weapons)
assert(surfaceDestroyed)
assert(renderStepped:Count() == 0)
assert(restoredFunctions[shootLocalBeam])
assert(restoredFunctions[handleDesktop] and restoredFunctions[handlePosition])
assert(restoredFunctions[workspace.Raycast] and restoredFunctions[workspace.FindPartOnRayWithIgnoreList])

print("gun-validation-example-contracts-ok")
