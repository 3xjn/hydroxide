local ScannerFilter = {}

ScannerFilter.Category = {
    Executor = "Executor",
    Game = "Game",
    Roblox = "Roblox",
}

local defaultOptions = {
    ShowExecutor = false,
    ShowGame = true,
    ShowRoblox = false,
}

local function defaultContext()
    local environment = getgenv()
    local session = environment.oh
    return {
        GetHiddenProperty = session and session.Methods and session.Methods.getHiddenProperty,
    }
end

local function hasRobloxPrivilege(instance, context)
    if instance.ClassName == "CoreScript" then
        return true
    end

    local getHidden = context.GetHiddenProperty
    if not getHidden then
        return false
    end

    local success, unrestrictedRequire = pcall(
        getHidden,
        instance,
        "UnrestrictedRequireAllowed"
    )
    return success and unrestrictedRequire == true
end

local function descendantsOf(instance, context)
    if context.GetDescendants then
        return context.GetDescendants(instance)
    end

    local success, descendants = pcall(instance.GetDescendants, instance)
    return success and descendants or {}
end

function ScannerFilter.IsRobloxNative(instance, context)
    context = context or defaultContext()

    if hasRobloxPrivilege(instance, context) then
        return true
    end

    if instance.ClassName ~= "LocalScript" then
        return false
    end

    for _, descendant in ipairs(descendantsOf(instance, context)) do
        if hasRobloxPrivilege(descendant, context) then
            return true
        end
    end

    return false
end

function ScannerFilter.GetCategory(instance, context)
    context = context or defaultContext()

    if context.IsExecutor == true then
        return ScannerFilter.Category.Executor
    end

    if ScannerFilter.IsRobloxNative(instance, context) then
        return ScannerFilter.Category.Roblox
    end

    return ScannerFilter.Category.Game
end

function ScannerFilter.ShouldInclude(instance, options, context)
    options = options or defaultOptions
    local category = ScannerFilter.GetCategory(instance, context)

    if category == ScannerFilter.Category.Executor then
        return options.ShowExecutor == true
    end

    if category == ScannerFilter.Category.Roblox then
        return options.ShowRoblox == true
    end

    return options.ShowGame ~= false
end

return ScannerFilter
