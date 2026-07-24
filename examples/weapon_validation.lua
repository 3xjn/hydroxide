local environment = getgenv()
local root = (environment.HydroxideConfig or {}).LocalRoot or "hydroxide/local"

local previous = environment.HydroxideWeaponValidation
if previous then
    previous:stop()
end

local oh = environment.oh
if
    not oh
    or not oh.closure
    or type(oh.closure.findUpvalue) ~= "function"
    or not oh.drawing
    or type(oh.drawing.createSurface) ~= "function"
    or not oh.lifecycle
    or type(oh.lifecycle.bindTools) ~= "function"
    or not oh.targeting
    or type(oh.targeting.nearestPlayer) ~= "function"
    or type(oh.targeting.observePlayers) ~= "function"
    or type(oh.targeting.predictIntercept) ~= "function"
then
    local helpersFile = root .. "/modules/Helpers.lua"
    local helpersChunk, compileError = loadstring(readfile(helpersFile), "modules/Helpers.lua")
    local Helpers = assert(helpersChunk, compileError)()
    oh = Helpers.load({
        localRoot = root,
        modules = {
            "closure",
            "drawing",
            "lifecycle",
            "targeting",
        },
    })
    oh.Resources = {}
end

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local colors = {
    accent = Color3.fromRGB(98, 214, 173),
    accentSurface = Color3.fromRGB(23, 53, 45),
    border = Color3.fromRGB(41, 50, 58),
    danger = Color3.fromRGB(230, 107, 110),
    elevated = Color3.fromRGB(21, 28, 35),
    hover = Color3.fromRGB(25, 33, 41),
    panel = Color3.fromRGB(17, 23, 29),
    secondary = Color3.fromRGB(167, 176, 184),
    text = Color3.fromRGB(243, 246, 247),
}
local optionNames = {
    "silentAim",
    "triggerBot",
    "wallbang",
}
local optionLabels = {
    silentAim = "Silent Aim",
    triggerBot = "Trigger Bot",
    wallbang = "Wallbang",
}
type Target = {
    part: BasePart,
    position: Vector3,
    visible: boolean,
}
local state = {
    activeWeapon = nil,
    bindings = {
        Gun = 0,
        Knife = 0,
    },
    blockedPlayers = 0,
    observations = {},
    target = nil,
    triggers = {
        Gun = 0,
        Knife = 0,
    },
    visiblePlayers = 0,
    settings = {
        fov = 180,
        maximumFov = 500,
        minimumFov = 40,
        silentAim = false,
        triggerBot = false,
        wallbang = false,
    },
    lastTrigger = {
        outcome = "idle",
    },
}
local surface = oh.drawing.createSurface({
    acceptProcessedInput = true,
})
local boxes = {}
local controls = {
    options = {},
}
local weaponTools = {
    Gun = {},
    Knife = {},
}
local nextTriggerAt = {
    Gun = 0,
    Knife = 0,
}
local triggerCooldown = {
    Gun = 2.5,
    Knife = 0.1,
}
local pendingTargets: {
    Gun: Target?,
    Knife: Target?,
} = {}
local queuedKnifeWallbang
local stopped = false
local panelCaptured = false
local captureAction = "HydroxideWeaponPanel"

local function setPanelCapture(captured)
    if panelCaptured == captured then
        return
    end
    panelCaptured = captured

    if captured then
        ContextActionService:BindActionAtPriority(
            captureAction,
            function()
                return Enum.ContextActionResult.Sink
            end,
            false,
            Enum.ContextActionPriority.High.Value + 100,
            Enum.UserInputType.MouseButton1,
            Enum.UserInputType.Touch
        )
    else
        ContextActionService:UnbindAction(captureAction)
    end
end

local function capture(node)
    node:on("pointerenter", function()
        setPanelCapture(true)
    end)
    node:on("pointerleave", function()
        setPanelCapture(false)
    end)
    return node
end

local panel = capture(surface:create("Square", {
    Color = colors.panel,
    Filled = true,
    Size = Vector2.new(236, 228),
    Transparency = 0.96,
    Visible = true,
    ZIndex = 100,
}))
local fovCircle = surface:create("Circle", {
    Color = colors.accent,
    Filled = false,
    NumSides = 96,
    Radius = state.settings.fov,
    Thickness = 1.5,
    Transparency = 0.8,
    Visible = true,
    ZIndex = 50,
}, {
    pointerEvents = false,
})
local fovTitle = surface:create("Text", {
    Color = colors.text,
    Font = Drawing.Fonts.Plex,
    Size = 15,
    Text = "FOV",
    Visible = true,
    ZIndex = 102,
}, {
    pointerEvents = false,
})
local weaponLabel = surface:create("Text", {
    Color = colors.text,
    Font = Drawing.Fonts.Plex,
    Size = 15,
    Text = "Weapon",
    Visible = true,
    ZIndex = 102,
}, {
    pointerEvents = false,
})
local weaponValue = surface:create("Text", {
    Center = true,
    Color = colors.accent,
    Font = Drawing.Fonts.Plex,
    Size = 14,
    Text = "No weapon",
    Visible = true,
    ZIndex = 102,
}, {
    pointerEvents = false,
})
controls.weapon = {
    label = weaponLabel,
    value = weaponValue,
}
local fovValue = surface:create("Text", {
    Center = true,
    Color = colors.secondary,
    Font = Drawing.Fonts.Plex,
    Size = 14,
    Text = "",
    Visible = true,
    ZIndex = 102,
}, {
    pointerEvents = false,
})
local sliderHit = capture(surface:create("Square", {
    Color = colors.panel,
    Filled = true,
    Size = Vector2.new(212, 32),
    Transparency = 0,
    Visible = true,
    ZIndex = 102,
}))
local sliderTrack = surface:create("Square", {
    Color = colors.border,
    Filled = true,
    Size = Vector2.new(212, 4),
    Visible = true,
    ZIndex = 103,
}, {
    pointerEvents = false,
})
local sliderFill = surface:create("Square", {
    Color = colors.accent,
    Filled = true,
    Visible = true,
    ZIndex = 104,
}, {
    pointerEvents = false,
})
local sliderKnob = surface:create("Circle", {
    Color = colors.text,
    Filled = true,
    NumSides = 32,
    Radius = 7,
    Visible = true,
    ZIndex = 105,
}, {
    pointerEvents = false,
})

for _, optionName in ipairs(optionNames) do
    local background = capture(surface:create("Square", {
        Color = colors.elevated,
        Filled = true,
        Size = Vector2.new(212, 36),
        Visible = true,
        ZIndex = 102,
    }))
    local label = surface:create("Text", {
        Color = colors.text,
        Font = Drawing.Fonts.Plex,
        Size = 14,
        Text = optionLabels[optionName],
        Visible = true,
        ZIndex = 103,
    }, {
        pointerEvents = false,
    })
    local value = surface:create("Text", {
        Center = true,
        Color = colors.secondary,
        Font = Drawing.Fonts.Plex,
        Size = 13,
        Text = "Off",
        Visible = true,
        ZIndex = 103,
    }, {
        pointerEvents = false,
    })
    controls.options[optionName] = {
        background = background,
        label = label,
        value = value,
    }
end

local sliderStartX = 0
local sliderWidth = 212

local function updateControlVisuals()
    local settings = state.settings
    controls.weapon.value.Text = state.activeWeapon or "No weapon"
    controls.weapon.value.Color = state.activeWeapon and colors.accent or colors.secondary
    for optionName, control in pairs(controls.options) do
        local enabled = settings[optionName]
        control.background.Color = enabled and colors.accentSurface or colors.elevated
        control.value.Color = enabled and colors.accent or colors.secondary
        control.value.Text = enabled and "On" or "Off"
    end

    local alpha = (settings.fov - settings.minimumFov) / (settings.maximumFov - settings.minimumFov)
    local knobX = sliderStartX + sliderWidth * alpha
    sliderFill.Size = Vector2.new(sliderWidth * alpha, 4)
    sliderKnob.Position = Vector2.new(knobX, sliderTrack.Position.Y + 2)
    fovValue.Text = ("%d px"):format(math.round(settings.fov))
    fovCircle.Radius = settings.fov
end

local function setOption(optionName, enabled)
    assert(optionLabels[optionName], "Unknown weapon option: " .. tostring(optionName))
    state.settings[optionName] = enabled == true
    if optionName == "wallbang" and not state.settings.wallbang then
        queuedKnifeWallbang = nil
    end
    updateControlVisuals()
end

for optionName, control in pairs(controls.options) do
    control.background:on("click", function()
        setOption(optionName, not state.settings[optionName])
    end)
end

local function layoutPanel()
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    local x = math.max(24, camera.ViewportSize.X - 260)
    local y = 24
    panel.Position = Vector2.new(x, y)

    controls.weapon.label.Position = Vector2.new(x + 12, y + 16)
    controls.weapon.value.Position = Vector2.new(x + 184, y + 16)
    fovTitle.Position = Vector2.new(x + 12, y + 48)
    fovValue.Position = Vector2.new(x + 190, y + 48)
    sliderStartX = x + 12
    sliderHit.Position = Vector2.new(x + 12, y + 64)
    sliderTrack.Position = Vector2.new(x + 12, y + 78)
    sliderFill.Position = sliderTrack.Position

    for index, optionName in ipairs(optionNames) do
        local control = controls.options[optionName]
        local rowY = y + 96 + (index - 1) * 40
        control.background.Position = Vector2.new(x + 12, rowY)
        control.label.Position = Vector2.new(x + 24, rowY + 9)
        control.value.Position = Vector2.new(x + 190, rowY + 9)
    end
    updateControlVisuals()
end

local function setFovFromPoint(point)
    local settings = state.settings
    local alpha = math.clamp((point.X - sliderStartX) / sliderWidth, 0, 1)
    settings.fov = settings.minimumFov + (settings.maximumFov - settings.minimumFov) * alpha
    updateControlVisuals()
end

sliderHit:on("pointerdown", function(_node, point)
    setFovFromPoint(point)
end)
sliderHit:on("drag", function(_node, point)
    setFovFromPoint(point)
end)
layoutPanel()

local function ensureBox(player)
    local box = boxes[player]
    if box then
        return box
    end

    box = surface:create("Square", {
        Color = colors.danger,
        Filled = false,
        Thickness = 1.5,
        Visible = false,
        ZIndex = 40,
    }, {
        pointerEvents = false,
    })
    boxes[player] = box
    return box
end

local function pointInside(point, bounds)
    return point.X >= bounds.position.X
        and point.Y >= bounds.position.Y
        and point.X <= bounds.position.X + bounds.size.X
        and point.Y <= bounds.position.Y + bounds.size.Y
end

local function targetAllowed(settings, observation)
    return observation.position ~= nil and (observation.visible or settings.wallbang)
end

local function currentTarget()
    local settings = state.settings
    return oh.targeting.nearestPlayer({
        includeBlocked = settings.wallbang,
        maxScreenDistance = settings.fov,
        screenOrigin = UserInputService:GetMouseLocation(),
    })
end

local function hoveredTarget()
    local settings = state.settings
    local mousePosition = UserInputService:GetMouseLocation()
    local nearest

    for _, observation in ipairs(state.observations) do
        if
            observation.bounds
            and pointInside(mousePosition, observation.bounds)
            and targetAllowed(settings, observation)
            and (not nearest or observation.screenDistance < nearest.screenDistance)
        then
            nearest = observation
        end
    end

    return nearest
end

local directedGunRaycast
local directedKnifeRaycast
local originalRaycast
originalRaycast = hookfunction(Workspace.Raycast, function(self, origin, direction, params)
    if self == Workspace and directedGunRaycast then
        return {
            Instance = directedGunRaycast.part,
            Position = directedGunRaycast.position,
        }
    end
    return originalRaycast(self, origin, direction, params)
end)

local function rayFollowsKnifePath(ray, queued)
    local rayDirection = ray.Direction
    local plannedDirection = queued.position - queued.origin
    local rayLengthSquared = rayDirection:Dot(rayDirection)
    local plannedLengthSquared = plannedDirection:Dot(plannedDirection)
    if rayLengthSquared <= 1e-6 or plannedLengthSquared <= 1e-6 then
        return false
    end

    local alignment = rayDirection:Dot(plannedDirection)
    if alignment <= 0 or alignment * alignment < rayLengthSquared * plannedLengthSquared * 0.96 then
        return false
    end

    local fromOrigin = ray.Origin - queued.origin
    local progress = fromOrigin:Dot(plannedDirection) / plannedLengthSquared
    if progress < -0.05 or progress > 1.1 then
        return false
    end

    local pathPoint = queued.origin + plannedDirection * math.clamp(progress, 0, 1)
    local lateralOffset = ray.Origin - pathPoint
    return lateralOffset:Dot(lateralOffset) <= 16
end

local function rayReachesKnifeTarget(ray, target)
    local direction = ray.Direction
    local lengthSquared = direction:Dot(direction)
    if lengthSquared <= 1e-6 then
        return false
    end

    local offset = target.position - ray.Origin
    local progress = math.clamp(offset:Dot(direction) / lengthSquared, 0, 1)
    local closest = ray.Origin + direction * progress
    local distance = target.position - closest
    local size = target.part and target.part.Size
    local radius = size and math.max(size.X, size.Y, size.Z) / 2 + 1 or 3
    return distance:Dot(distance) <= radius * radius
end

local originalFindPartOnRay
originalFindPartOnRay = hookfunction(Workspace.FindPartOnRayWithIgnoreList, function(self, ray, ignore, ...)
    if self == Workspace and directedKnifeRaycast then
        return directedKnifeRaycast.part, directedKnifeRaycast.position
    end
    if self == Workspace and queuedKnifeWallbang then
        local queued = queuedKnifeWallbang
        if os.clock() > queued.expiresAt then
            queuedKnifeWallbang = nil
        elseif rayFollowsKnifePath(ray, queued) then
            if rayReachesKnifeTarget(ray, queued) then
                queuedKnifeWallbang = nil
                return queued.part, queued.position
            end
            return nil
        end
    end
    return originalFindPartOnRay(self, ray, ignore, ...)
end)

local function withDirectedRaycast(kind, target, callback)
    if target and not target.visible and state.settings.wallbang then
        if kind == "Gun" then
            directedGunRaycast = target
        else
            directedKnifeRaycast = target
        end
    end

    local results = table.pack(pcall(callback))
    directedGunRaycast = nil
    directedKnifeRaycast = nil
    if not results[1] then
        error(results[2], 0)
    end
    return table.unpack(results, 2, results.n)
end

local adapters: { [string]: any } = {
    Gun = {},
    Knife = {},
}
local weaponClassifications = {}
local lifecycleSession

local function findNamedClosure(localScript, name)
    return oh.closure.findUpvalue(localScript, function(value)
        return type(value) == "function" and debug.getinfo(value).name == name
    end)
end

local function classifyTool(tool)
    local localScript = tool:FindFirstChildOfClass("LocalScript")
    if not localScript then
        return nil
    end

    local shootLocalBeam = findNamedClosure(localScript, "ShootLocalBeam")
    local shoot = findNamedClosure(localScript, "Shoot")
    if shootLocalBeam and shoot then
        return {
            kind = "Gun",
            localScript = localScript,
            shoot = shoot,
            shootLocalBeam = shootLocalBeam,
        }
    end

    local handleDesktop = findNamedClosure(localScript, "HandleThrowingLocal")
    local handlePosition = findNamedClosure(localScript, "HandleThrowingLocalOnMobile")
    if handleDesktop and handlePosition then
        return {
            handleDesktop = handleDesktop,
            handlePosition = handlePosition,
            kind = "Knife",
            localScript = localScript,
        }
    end

    return nil
end

local function bindGun(tool, scope, classification)
    weaponTools.Gun[tool] = true
    scope.add(function()
        weaponTools.Gun[tool] = nil
        adapters.Gun[tool] = nil
    end)

    local shootLocalBeam = classification.shootLocalBeam
    local shoot = classification.shoot

    local originalShootLocalBeam
    originalShootLocalBeam = hookfunction(shootLocalBeam, function(target, origin, activeTool, ...)
        local extras = table.pack(...)
        local selected = pendingTargets.Gun
        pendingTargets.Gun = nil
        if not selected and state.settings.silentAim then
            selected = currentTarget()
        end
        if selected then
            target = selected.position
        end
        return withDirectedRaycast("Gun", selected, function()
            return originalShootLocalBeam(target, origin, activeTool, table.unpack(extras, 1, extras.n))
        end)
    end)

    scope.add(function()
        restorefunction(shootLocalBeam)
    end)
    adapters.Gun[tool] = {
        fire = shoot,
    }
    state.bindings.Gun = state.bindings.Gun + 1
    print("[Hydroxide Weapons]", "Gun", "installed", state.bindings.Gun)
end

local function booleanUpvalues(target)
    local values = {}
    for index, value in pairs(debug.getupvalues(target)) do
        if type(value) == "boolean" then
            values[index] = value
        end
    end
    return values
end

local function bindKnife(tool, scope, classification)
    weaponTools.Knife[tool] = true
    scope.add(function()
        weaponTools.Knife[tool] = nil
        adapters.Knife[tool] = nil
    end)

    local handleDesktop = classification.handleDesktop
    local handlePosition = classification.handlePosition

    local function throwOrigin()
        local character = Players.LocalPlayer.Character
        local rightHand = character and character:FindFirstChild("RightHand")
        local attachment = rightHand and rightHand:FindFirstChild("RightGripAttachment")
        if attachment then
            return attachment.WorldCFrame.Position
        end
        local handle = tool:FindFirstChild("Handle")
        return handle and handle.Position
    end

    local function predictTarget(target)
        local origin = throwOrigin()
        local velocity = target.part and target.part.AssemblyLinearVelocity
        if not origin or not velocity then
            return target
        end

        local position, flightTime = oh.targeting.predictIntercept(origin, target.position, velocity, 78)
        local predicted = table.clone(target)
        predicted.position = position
        predicted.flightTime = flightTime
        return predicted
    end

    local originalPosition
    local function throwAt(target, forceReady)
        target = predictTarget(target)
        if not target.visible and state.settings.wallbang then
            local origin = throwOrigin()
            if origin then
                queuedKnifeWallbang = {
                    expiresAt = os.clock() + 7,
                    origin = origin,
                    part = target.part,
                    position = target.position,
                }
            end
        end
        local savedBooleans
        if forceReady then
            savedBooleans = booleanUpvalues(originalPosition)
            for index in pairs(savedBooleans) do
                debug.setupvalue(originalPosition, index, true)
            end
        end

        local results = table.pack(pcall(function()
            return withDirectedRaycast("Knife", target, function()
                return originalPosition(target.position)
            end)
        end))

        if savedBooleans then
            for index, value in pairs(savedBooleans) do
                debug.setupvalue(originalPosition, index, value)
            end
        end
        if not results[1] then
            error(results[2], 0)
        end
        return table.unpack(results, 2, results.n)
    end

    originalPosition = hookfunction(handlePosition, function(position, ...)
        local extras = table.pack(...)
        local selected = pendingTargets.Knife
        pendingTargets.Knife = nil
        if not selected and state.settings.silentAim then
            selected = currentTarget()
        end
        if selected then
            selected = predictTarget(selected)
            if not selected.visible and state.settings.wallbang then
                local origin = throwOrigin()
                if origin then
                    queuedKnifeWallbang = {
                        expiresAt = os.clock() + 7,
                        origin = origin,
                        part = selected.part,
                        position = selected.position,
                    }
                end
            end
            position = selected.position
        end
        return withDirectedRaycast("Knife", selected, function()
            return originalPosition(position, table.unpack(extras, 1, extras.n))
        end)
    end)

    local originalDesktop
    originalDesktop = hookfunction(handleDesktop, function(...)
        local selected = pendingTargets.Knife
        pendingTargets.Knife = nil
        if not selected and state.settings.silentAim then
            selected = currentTarget()
        end
        if selected then
            return throwAt(selected, false)
        end
        return originalDesktop(...)
    end)

    adapters.Knife[tool] = {
        fire = function(target)
            return throwAt(target, true)
        end,
    }
    scope.add(function()
        restorefunction(handleDesktop)
        restorefunction(handlePosition)
    end)
    state.bindings.Knife = state.bindings.Knife + 1
    print("[Hydroxide Weapons]", "Knife", "installed", state.bindings.Knife)
end

local function bindWeapon(tool, scope)
    local classification = weaponClassifications[tool] or classifyTool(tool)
    if not classification then
        return
    end

    scope.add(function()
        weaponClassifications[tool] = nil
    end)
    if classification.kind == "Gun" then
        bindGun(tool, scope, classification)
    else
        bindKnife(tool, scope, classification)
    end
end

lifecycleSession = oh.lifecycle.bindTools(function(tool)
    local classification = classifyTool(tool)
    if not classification then
        return false
    end
    weaponClassifications[tool] = classification
    return true
end, bindWeapon)

local function equippedWeapon()
    local character = Players.LocalPlayer.Character
    if not character then
        return nil, nil
    end

    for _index, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            if weaponTools.Gun[tool] then
                return "Gun", tool
            elseif weaponTools.Knife[tool] then
                return "Knife", tool
            end
        end
    end
    return nil, nil
end

local function runTriggerBot(weaponName, tool, now)
    local settings = state.settings
    if
        not settings.triggerBot
        or not tool
        or panelCaptured
        or now < nextTriggerAt[weaponName]
    then
        return
    end

    local target = settings.silentAim and currentTarget() or hoveredTarget()
    if not target then
        state.lastTrigger = {
            outcome = "no-target",
            weapon = weaponName,
        }
        return
    end

    local adapter = adapters[weaponName][tool]
    if not adapter then
        state.lastTrigger = {
            outcome = "unavailable",
            weapon = weaponName,
        }
        return
    end

    nextTriggerAt[weaponName] = now + triggerCooldown[weaponName]
    state.triggers[weaponName] = state.triggers[weaponName] + 1
    state.lastTrigger = {
        outcome = "fired",
        weapon = weaponName,
    }
    if weaponName == "Gun" then
        pendingTargets.Gun = target
        adapter.fire()
    else
        adapter.fire(target)
    end
end

local renderConnection = RunService.RenderStepped:Connect(function()
    local activeTool
    state.activeWeapon, activeTool = equippedWeapon()
    layoutPanel()

    local mousePosition = UserInputService:GetMouseLocation()
    fovCircle.Position = mousePosition
    local seen = {}
    local visiblePlayers = 0
    local blockedPlayers = 0
    local observations = oh.targeting.observePlayers({
        screenOrigin = mousePosition,
    })

    for _, observation in ipairs(observations) do
        local box = ensureBox(observation.player)
        seen[observation.player] = true
        box.Position = observation.bounds.position
        box.Size = observation.bounds.size
        box.Visible = true

        if observation.visible then
            visiblePlayers = visiblePlayers + 1
            box.Color = colors.accent
        else
            blockedPlayers = blockedPlayers + 1
            box.Color = colors.danger
        end
    end

    for player, box in pairs(boxes) do
        if not seen[player] then
            box.Visible = false
        end
    end

    state.observations = observations
    state.visiblePlayers = visiblePlayers
    state.blockedPlayers = blockedPlayers
    state.target = state.activeWeapon and currentTarget() or nil

    local now = os.clock()
    if state.activeWeapon then
        runTriggerBot(state.activeWeapon, activeTool, now)
    end
end)

local playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
    local box = boxes[player]
    if box then
        box:destroy()
        boxes[player] = nil
    end
end)

local session = {
    controls = controls,
    state = state,
}

function session:setOption(optionName, enabled)
    setOption(optionName, enabled)
end

function session:stop()
    if stopped then
        return
    end
    stopped = true

    setPanelCapture(false)
    lifecycleSession.stop()
    restorefunction(Workspace.Raycast)
    restorefunction(Workspace.FindPartOnRayWithIgnoreList)
    renderConnection:Disconnect()
    playerRemovingConnection:Disconnect()
    surface:destroy()

    if environment.HydroxideWeaponValidation == self then
        environment.HydroxideWeaponValidation = nil
    end
end

session.Destroy = session.stop
environment.HydroxideWeaponValidation = session
table.insert(oh.Resources, session)
print("[Hydroxide Weapons]", "ready")
return session
