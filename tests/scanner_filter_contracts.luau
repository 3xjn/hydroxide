local ScannerFilter = require("../modules/ScannerFilter")

local function instance(className, name, parent)
    local value = {
        ClassName = className,
        Name = name,
        Parent = parent,
        Children = {},
    }

    if parent then
        table.insert(parent.Children, value)
    end

    return value
end

local function descendants(root)
    local values = {}

    local function visit(current)
        for _, child in ipairs(current.Children) do
            table.insert(values, child)
            visit(child)
        end
    end

    visit(root)
    return values
end

local privileges = {}
local context = {
    GetDescendants = descendants,
    GetHiddenProperty = function(value, property)
        assert(property == "UnrestrictedRequireAllowed")
        return privileges[value] == true
    end,
}

local gameRoot = instance("DataModel", "game")
local playerScripts = instance("PlayerScripts", "PlayerScripts", gameRoot)
local namedPlayerModule = instance("Folder", "PlayerModule", playerScripts)
local customModule = instance("ModuleScript", "CustomCamera", namedPlayerModule)
local nativePlayerModule = instance("ModuleScript", "PlayerModule", playerScripts)
local nativeCamera = instance("ModuleScript", "CameraModule", nativePlayerModule)
local nativeSounds = instance("LocalScript", "RbxCharacterSounds", playerScripts)
local nativeSoundLibrary = instance("ModuleScript", "AtomicBinding", nativeSounds)
local customAnimate = instance("LocalScript", "Animate", gameRoot)
local coreScript = instance("CoreScript", "CoreGuiRoot", gameRoot)

privileges[nativePlayerModule] = true
privileges[nativeCamera] = true
privileges[nativeSoundLibrary] = true

assert(
    ScannerFilter.IsRobloxNative(nativePlayerModule, context),
    "A module with Roblox's unrestricted-require privilege must be recognized"
)
assert(
    ScannerFilter.IsRobloxNative(nativeSounds, context),
    "A Roblox wrapper LocalScript must inherit the evidence from its privileged module"
)
assert(ScannerFilter.IsRobloxNative(coreScript, context), "CoreScript is a Roblox-only instance class")
assert(
    not ScannerFilter.IsRobloxNative(customModule, context),
    "Folder names and ancestry must not classify game-authored modules as Roblox code"
)
assert(
    not ScannerFilter.IsRobloxNative(customAnimate, context),
    "A familiar default name alone must not hide a game-authored script"
)

local defaults = {
    ShowExecutor = false,
    ShowGame = true,
    ShowRoblox = false,
}
assert(not ScannerFilter.ShouldInclude(nativeCamera, defaults, context), "Roblox code must be hidden by default")
assert(ScannerFilter.ShouldInclude(customModule, defaults, context), "Game code must be visible by default")
assert(
    not ScannerFilter.ShouldInclude(customModule, defaults, {
        GetDescendants = descendants,
        GetHiddenProperty = context.GetHiddenProperty,
        IsExecutor = true,
    }),
    "Executor code must be hidden by default"
)
assert(
    ScannerFilter.ShouldInclude(nativeCamera, {
        ShowExecutor = false,
        ShowGame = true,
        ShowRoblox = true,
    }, context),
    "The Roblox option must reveal Roblox code"
)
assert(
    ScannerFilter.ShouldInclude(customModule, {
        ShowExecutor = true,
        ShowGame = false,
        ShowRoblox = false,
    }, {
        GetDescendants = descendants,
        GetHiddenProperty = context.GetHiddenProperty,
        IsExecutor = true,
    }),
    "The executor option must reveal executor code independently"
)
assert(
    not ScannerFilter.ShouldInclude(customModule, {
        ShowExecutor = false,
        ShowGame = false,
        ShowRoblox = true,
    }, context),
    "The game option must independently hide game code"
)

print("scanner-filter-contracts-ok")
