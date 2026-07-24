local Helpers = require("../modules/Helpers")

local importedCount = 0
local importedClosure = {}
local constants = {
    sourceMode = "runtime",
}
local state = {}
local oh = Helpers.load({
    constants = constants,
    import = function(asset)
        importedCount = importedCount + 1
        assert(asset == "modules/Closure")
        return importedClosure
    end,
    modules = { "closure" },
    state = state,
})

assert(oh.constants == constants, "Configuration values must be explicit under oh.constants")
assert(oh.state == state, "Live values must be explicit under oh.state")
assert(oh.closure == importedClosure, "Runtime helpers must resolve through Hydroxide import")
assert(oh.closure == importedClosure, "Runtime helper access must be stable")
assert(importedCount == 1, "Runtime helpers must cache each imported module")

local drawingAsset
local importedDrawing = {}
local drawingOh = Helpers.load({
    import = function(asset)
        drawingAsset = asset
        return importedDrawing
    end,
    modules = { "drawing" },
})
assert(drawingOh.drawing == importedDrawing, "Drawing must use the lowercase oh.drawing consumer interface")
assert(drawingAsset == "modules/Drawing", "Drawing must resolve through the shared helper loader")

local attachedSession = {
    Constants = {
        Source = "full-session",
    },
}
local attachedAssets = {}
Helpers.attach(attachedSession, {
    import = function(asset)
        attachedAssets[asset] = true
        return {
            Asset = asset,
        }
    end,
    modules = { "drawing", "lifecycle", "targeting" },
})
assert(attachedSession.drawing.Asset == "modules/Drawing")
assert(attachedSession.lifecycle.Asset == "modules/Lifecycle")
assert(attachedSession.targeting.Asset == "modules/Targeting")
assert(attachedSession.constants == attachedSession.Constants)
assert(type(attachedSession.load) == "function")

local loadedFile
local localOh = Helpers.load({
    localRoot = "hydroxide/local",
    readFile = function(file)
        loadedFile = file
        return "return { Source = 'local' }"
    end,
    loadString = loadstring,
    modules = { "closure" },
})
assert(localOh.closure.Source == "local", "Local helpers must execute workspace source")
assert(
    loadedFile == "hydroxide/local/modules/Closure.lua",
    "Local helpers must resolve beneath the configured Volt workspace root"
)

local requestedUrl
local webOh = Helpers.load({
    sourceBaseUrl = "https://raw.githubusercontent.com/green-hat/Hydroxide/dev/",
    httpGet = function(url)
        requestedUrl = url
        return "return { Source = 'web' }"
    end,
    loadString = loadstring,
    modules = { "closure" },
})
assert(webOh.closure.Source == "web", "Web helpers must execute configured fork source")
assert(
    requestedUrl == "https://raw.githubusercontent.com/green-hat/Hydroxide/dev/modules/Closure.lua",
    "Web helpers must resolve beneath the configured fork and branch"
)

local invalidNameSucceeded = pcall(oh.load, "../Closure")
assert(not invalidNameSucceeded, "Only named Hydroxide helper modules may be loaded")

local missingSourceSucceeded = pcall(Helpers.load, {})
assert(not missingSourceSucceeded, "A helper bundle must declare a real source adapter")

print("helper-loader-contracts-ok")
