local Targeting = {}

local partNames = {
    "Head",
    "UpperTorso",
    "Torso",
    "LowerTorso",
    "HumanoidRootPart",
    "LeftUpperArm",
    "RightUpperArm",
    "LeftLowerArm",
    "RightLowerArm",
    "LeftUpperLeg",
    "RightUpperLeg",
    "LeftLowerLeg",
    "RightLowerLeg",
    "LeftHand",
    "RightHand",
    "LeftFoot",
    "RightFoot",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
}

local function getRaycastIgnore(localPlayer, options)
    local ignored = {}
    local seen = {}

    local function add(instance)
        if instance and not seen[instance] then
            seen[instance] = true
            table.insert(ignored, instance)
        end
    end

    add(localPlayer.Character)
    if options and options.raycastIgnore then
        for _index, instance in pairs(options.raycastIgnore) do
            add(instance)
        end
    end

    return ignored
end

function Targeting.getCharacterHitboxParts(character)
    local parts = {}
    for _index, child in ipairs(character:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(parts, child)
        end
    end
    return parts
end

function Targeting.predictIntercept(origin, targetPosition, targetVelocity, projectileSpeed)
    assert(projectileSpeed > 0, "Projectile speed must be positive")

    local offset = targetPosition - origin
    local a = targetVelocity:Dot(targetVelocity) - projectileSpeed * projectileSpeed
    local b = 2 * offset:Dot(targetVelocity)
    local c = offset:Dot(offset)
    local interceptTime

    if math.abs(a) < 1e-6 then
        if math.abs(b) >= 1e-6 then
            local candidate = -c / b
            if candidate > 0 then
                interceptTime = candidate
            end
        end
    else
        local discriminant = b * b - 4 * a * c
        if discriminant >= 0 then
            local root = math.sqrt(discriminant)
            local first = (-b - root) / (2 * a)
            local second = (-b + root) / (2 * a)
            if first > 0 and second > 0 then
                interceptTime = math.min(first, second)
            elseif first > 0 then
                interceptTime = first
            elseif second > 0 then
                interceptTime = second
            end
        end
    end

    interceptTime = interceptTime or math.sqrt(c) / projectileSpeed
    return targetPosition + targetVelocity * interceptTime, interceptTime
end

local function defaultContext()
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local sampleOffsets = {
        Vector3.zero,
        Vector3.new(0.35, 0, 0),
        Vector3.new(-0.35, 0, 0),
        Vector3.new(0, 0.35, 0),
        Vector3.new(0, -0.35, 0),
    }

    local function isEligible(localPlayer, player, character)
        if player == localPlayer or not character then
            return false
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            return false
        end

        local localGame = localPlayer:GetAttribute("Game")
        local playerGame = player:GetAttribute("Game")
        if (localGame ~= nil or playerGame ~= nil) and playerGame ~= localGame then
            return false
        end

        local localTeam = localPlayer:GetAttribute("Team") or localPlayer.Team
        local playerTeam = player:GetAttribute("Team") or player.Team
        return localTeam == nil or playerTeam == nil or playerTeam ~= localTeam
    end

    local function projectPart(camera, part)
        local halfSize = part.Size / 2
        local minimumX = math.huge
        local minimumY = math.huge
        local maximumX = -math.huge
        local maximumY = -math.huge
        local projected = false
        local localCorners = {
            Vector3.new(-halfSize.X, -halfSize.Y, -halfSize.Z),
            Vector3.new(halfSize.X, -halfSize.Y, -halfSize.Z),
            Vector3.new(halfSize.X, halfSize.Y, -halfSize.Z),
            Vector3.new(-halfSize.X, halfSize.Y, -halfSize.Z),
            Vector3.new(-halfSize.X, -halfSize.Y, halfSize.Z),
            Vector3.new(halfSize.X, -halfSize.Y, halfSize.Z),
            Vector3.new(halfSize.X, halfSize.Y, halfSize.Z),
            Vector3.new(-halfSize.X, halfSize.Y, halfSize.Z),
        }
        local projectedCorners = {}
        local allCornersProjected = true

        for index, localPoint in ipairs(localCorners) do
            local worldPoint = part.CFrame:PointToWorldSpace(localPoint)
            local viewportPoint = camera:WorldToViewportPoint(worldPoint)
            if viewportPoint.Z > 0 then
                projected = true
                minimumX = math.min(minimumX, viewportPoint.X)
                minimumY = math.min(minimumY, viewportPoint.Y)
                maximumX = math.max(maximumX, viewportPoint.X)
                maximumY = math.max(maximumY, viewportPoint.Y)
                projectedCorners[index] = Vector2.new(viewportPoint.X, viewportPoint.Y)
            else
                allCornersProjected = false
            end
        end

        if not projected then
            return nil
        end

        local viewportSize = camera.ViewportSize
        minimumX = math.max(minimumX, 0)
        minimumY = math.max(minimumY, 0)
        maximumX = math.min(maximumX, viewportSize.X)
        maximumY = math.min(maximumY, viewportSize.Y)
        if maximumX <= minimumX or maximumY <= minimumY then
            return nil
        end

        local bounds = {
            position = Vector2.new(minimumX, minimumY),
            size = Vector2.new(maximumX - minimumX, maximumY - minimumY),
        }

        return bounds, allCornersProjected and projectedCorners or nil
    end

    local function getVisibleAim(localPlayer, character, options)
        local camera = Workspace.CurrentCamera
        if not camera then
            return nil, {}
        end

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = getRaycastIgnore(localPlayer, options)
        raycastParams.IgnoreWater = true

        local origin = camera:GetRenderCFrame().Position
        local bestPart
        local bestPosition
        local bestVisibleSamples = 0
        local bodyParts = {}

        for _index, partName in ipairs(partNames) do
            local part = character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                local visibleSamples = 0
                local visiblePosition = Vector3.zero

                for _sampleIndex, offset in ipairs(sampleOffsets) do
                    local localPoint = Vector3.new(
                        part.Size.X * offset.X,
                        part.Size.Y * offset.Y,
                        part.Size.Z * offset.Z
                    )
                    local worldPoint = part.CFrame:PointToWorldSpace(localPoint)
                    local viewportPoint, onScreen = camera:WorldToViewportPoint(worldPoint)

                    if onScreen and viewportPoint.Z > 0 then
                        local raycastResult = Workspace:Raycast(origin, worldPoint - origin, raycastParams)
                        if not raycastResult or raycastResult.Instance:IsDescendantOf(character) then
                            visibleSamples = visibleSamples + 1
                            visiblePosition = visiblePosition + worldPoint
                        end
                    end
                end

                local bounds, corners = projectPart(camera, part)
                if bounds and partName ~= "HumanoidRootPart" then
                    table.insert(bodyParts, {
                        bounds = bounds,
                        corners = corners,
                        name = partName,
                        part = part,
                        visibility = visibleSamples / #sampleOffsets,
                        visible = visibleSamples > 0,
                    })
                end

                if visibleSamples > bestVisibleSamples then
                    bestPart = part
                    bestPosition = visiblePosition / visibleSamples
                    bestVisibleSamples = visibleSamples
                end
            end
        end

        if not bestPart then
            return nil, bodyParts
        end

        local viewportPoint = camera:WorldToViewportPoint(bestPosition)
        return {
                part = bestPart,
                position = bestPosition,
                screenPosition = Vector2.new(viewportPoint.X, viewportPoint.Y),
                visibility = bestVisibleSamples / #sampleOffsets,
            },
            bodyParts
    end

    local function getDistance(localPlayer, character, position)
        local localCharacter = localPlayer.Character
        local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
        local targetRoot = character:FindFirstChild("HumanoidRootPart")

        if localRoot and targetRoot then
            return (targetRoot.Position - localRoot.Position).Magnitude
        end

        local camera = Workspace.CurrentCamera
        return camera and (position - camera:GetRenderCFrame().Position).Magnitude or math.huge
    end

    local function getPlayerObservation(localPlayer, _player, character, options)
        options = options or {}
        local camera = Workspace.CurrentCamera
        if not camera then
            return nil
        end

        local hitboxParts = Targeting.getCharacterHitboxParts(character)
        if #hitboxParts == 0 then
            return nil
        end

        local minimumX = math.huge
        local minimumY = math.huge
        local maximumX = -math.huge
        local maximumY = -math.huge
        local projected = false

        for _index, part in ipairs(hitboxParts) do
            local halfSize = part.Size / 2
            for x = -1, 1, 2 do
                for y = -1, 1, 2 do
                    for z = -1, 1, 2 do
                        local worldPoint = part.CFrame:PointToWorldSpace(Vector3.new(
                            halfSize.X * x,
                            halfSize.Y * y,
                            halfSize.Z * z
                        ))
                        local viewportPoint = camera:WorldToViewportPoint(worldPoint)
                        if viewportPoint.Z > 0 then
                            projected = true
                            minimumX = math.min(minimumX, viewportPoint.X)
                            minimumY = math.min(minimumY, viewportPoint.Y)
                            maximumX = math.max(maximumX, viewportPoint.X)
                            maximumY = math.max(maximumY, viewportPoint.Y)
                        end
                    end
                end
            end
        end

        if not projected then
            return nil
        end

        local viewportSize = camera.ViewportSize
        minimumX = math.max(minimumX, 0)
        minimumY = math.max(minimumY, 0)
        maximumX = math.min(maximumX, viewportSize.X)
        maximumY = math.min(maximumY, viewportSize.Y)
        if maximumX <= minimumX or maximumY <= minimumY then
            return nil
        end

        local aim, bodyParts = getVisibleAim(localPlayer, character, options)
        local fallbackPart
        local fallbackPosition
        local fallbackScreenPosition
        local fallbackScreenDistance = math.huge

        if not aim then
            for _index, partName in ipairs(partNames) do
                local part = character:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    local viewportPoint, onScreen = camera:WorldToViewportPoint(part.Position)
                    if onScreen and viewportPoint.Z > 0 then
                        local screenPosition = Vector2.new(viewportPoint.X, viewportPoint.Y)
                        local screenDistance = 0
                        if options.screenOrigin then
                            screenDistance = (screenPosition - options.screenOrigin).Magnitude
                        end
                        if not fallbackPart or screenDistance < fallbackScreenDistance then
                            fallbackPart = part
                            fallbackPosition = part.Position
                            fallbackScreenPosition = screenPosition
                            fallbackScreenDistance = screenDistance
                        end
                    end
                end
            end
        end

        local worldPosition = aim and aim.position or fallbackPosition or hitboxParts[1].Position
        local center = camera:WorldToViewportPoint(worldPosition)

        return {
            bodyParts = bodyParts,
            bounds = {
                position = Vector2.new(minimumX, minimumY),
                size = Vector2.new(maximumX - minimumX, maximumY - minimumY),
            },
            distance = getDistance(localPlayer, character, worldPosition),
            part = aim and aim.part or fallbackPart,
            position = aim and aim.position or fallbackPosition,
            screenPosition = aim and aim.screenPosition
                or fallbackScreenPosition
                or Vector2.new(center.X, center.Y),
            visibility = aim and aim.visibility or 0,
            visible = aim ~= nil,
        }
    end

    return {
        GetCharacter = function(player)
            return player.Character
        end,
        GetDistance = getDistance,
        GetLocalPlayer = function()
            return Players.LocalPlayer
        end,
        GetPlayers = function()
            return Players:GetPlayers()
        end,
        GetPlayerObservation = getPlayerObservation,
        GetVisibleAim = getVisibleAim,
        IsEligible = isEligible,
    }
end

function Targeting.new(context)
    context = context or defaultContext()

    local targeting = {}

    local function getScreenDistance(origin, position)
        if not origin or not position then
            return nil
        end

        local deltaX = position.X - origin.X
        local deltaY = position.Y - origin.Y
        return math.sqrt(deltaX * deltaX + deltaY * deltaY)
    end

    local function isPlayerEligible(options, localPlayer, player, character)
        if options.isEligible then
            return options.isEligible(player, character)
        end

        return context.IsEligible(localPlayer, player, character)
    end

    local function observeCharacter(localPlayer, character, options)
        local getPlayerObservation = assert(
            context.GetPlayerObservation,
            "Targeting observations require GetPlayerObservation"
        )
        local source = getPlayerObservation(localPlayer, nil, character, options)
        if not source or options.maxDistance and source.distance and source.distance > options.maxDistance then
            return nil
        end

        local observation = {}
        for key, value in pairs(source) do
            observation[key] = value
        end
        observation.character = character
        observation.screenDistance = getScreenDistance(options.screenOrigin, source.screenPosition)
        return observation
    end

    function targeting.observeCharacter(character, options)
        options = options or {}
        return observeCharacter(context.GetLocalPlayer(), character, options)
    end

    function targeting.observePlayers(options)
        options = options or {}

        local localPlayer = context.GetLocalPlayer()
        local observed = {}

        for _index, player in ipairs(context.GetPlayers()) do
            local character = context.GetCharacter(player)
            if isPlayerEligible(options, localPlayer, player, character) then
                local observation = observeCharacter(localPlayer, character, options)
                if observation then
                    observation.player = player
                    table.insert(observed, observation)
                end
            end
        end

        return observed
    end

    function targeting.nearestVisiblePlayer(options)
        options = options or {}

        local localPlayer = context.GetLocalPlayer()
        local nearest

        for _index, player in ipairs(context.GetPlayers()) do
            local character = context.GetCharacter(player)
            if isPlayerEligible(options, localPlayer, player, character) then
                local aim = context.GetVisibleAim(localPlayer, character, options)
                if aim then
                    local distance = context.GetDistance(localPlayer, character, aim.position)
                    local aimScreenDistance = getScreenDistance(options.screenOrigin, aim.screenPosition)
                    local metric = aimScreenDistance or distance
                    if (not options.maxDistance or distance <= options.maxDistance)
                        and (not options.maxScreenDistance
                            or aimScreenDistance and aimScreenDistance <= options.maxScreenDistance)
                        and (not nearest or metric < nearest.metric)
                    then
                        nearest = {
                            character = character,
                            distance = distance,
                            metric = metric,
                            part = aim.part,
                            player = player,
                            position = aim.position,
                            screenDistance = aimScreenDistance,
                            screenPosition = aim.screenPosition,
                            visibility = aim.visibility,
                        }
                    end
                end
            end
        end

        return nearest
    end

    function targeting.nearestObservation(observations, options)
        options = options or {}
        local nearest

        for _index, observation in ipairs(observations) do
            if observation.position and (observation.visible or options.includeBlocked) then
                local metric = observation.screenDistance or observation.distance or math.huge
                if
                    (not options.maxScreenDistance
                        or observation.screenDistance
                            and observation.screenDistance <= options.maxScreenDistance)
                    and (not nearest or metric < nearest.metric)
                then
                    observation.metric = metric
                    nearest = observation
                end
            end
        end

        return nearest
    end

    function targeting.nearestPlayer(options)
        options = options or {}
        return targeting.nearestObservation(targeting.observePlayers(options), options)
    end

    return targeting
end

local defaultTargeting
local function getDefaultTargeting()
    if not defaultTargeting then
        defaultTargeting = Targeting.new()
    end

    return defaultTargeting
end

Targeting.nearestVisiblePlayer = function(...)
    return getDefaultTargeting().nearestVisiblePlayer(...)
end
Targeting.nearestPlayer = function(...)
    return getDefaultTargeting().nearestPlayer(...)
end
Targeting.nearestObservation = function(...)
    return getDefaultTargeting().nearestObservation(...)
end
Targeting.observeCharacter = function(...)
    return getDefaultTargeting().observeCharacter(...)
end
Targeting.observePlayers = function(...)
    return getDefaultTargeting().observePlayers(...)
end

return Targeting
