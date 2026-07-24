local ScannerFilter = require("../modules/ScannerFilter")

local function fakeInstance(className, name)
    local value = {
        ClassName = className,
        Name = name,
    }

    function value:IsA(expectedClass)
        return self.ClassName == expectedClass
    end

    function value:GetDescendants()
        return {}
    end

    return value
end

local gameScript = fakeInstance("LocalScript", "DoorManager")
local robloxScript = fakeInstance("LocalScript", "PlayerScriptsLoader")
local executorScript = fakeInstance("LocalScript", "LocalTool")
local module = fakeInstance("ModuleScript", "Inventory")
local gameThread = {}
local executorThread = {}
local privileges = {
    [robloxScript] = true,
}

local function makeContext(values, constructor)
    return {
        GetScripts = function()
            return values
        end,
        GetScriptThread = function(value)
            if value == executorScript then
                return executorThread
            end
            return gameThread
        end,
        GetHiddenProperty = function(value, property)
            assert(property == "UnrestrictedRequireAllowed")
            return privileges[value] == true
        end,
        IsExecutorThread = function(thread)
            return thread == executorThread
        end,
        IsInstance = function()
            return true
        end,
        NewLocalScript = constructor,
        NewModuleScript = constructor,
    }
end

local imported = {
    ["modules/ScannerFilter"] = ScannerFilter,
    ["objects/LocalScript"] = { new = function(value) return value end },
    ["objects/ModuleScript"] = { new = function(value) return value end },
}
import = function(path)
    return imported[path]
end

local ScriptScanner = require("../modules/ScriptScanner")
local ModuleScanner = require("../modules/ModuleScanner")
local defaults = {
    ShowExecutor = false,
    ShowGame = true,
    ShowRoblox = false,
}

local constructedScripts = {}
local scriptResults = ScriptScanner.Scan("", defaults, makeContext({
    gameScript,
    robloxScript,
    executorScript,
    module,
}, function(value)
    table.insert(constructedScripts, value)
    return value
end))

assert(scriptResults[gameScript] == gameScript, "getscripts inventory must include game LocalScripts")
assert(scriptResults[robloxScript] == nil, "Roblox LocalScripts must be filtered before construction")
assert(scriptResults[executorScript] == nil, "Executor LocalScripts must be filtered before construction")
assert(scriptResults[module] == nil, "The script scanner must reject ModuleScripts")
assert(#constructedScripts == 1, "Only visible LocalScripts may be constructed")

local moduleResults = ModuleScanner.Scan("invent", defaults, makeContext({
    gameScript,
    module,
}, function(value)
    return value
end))
assert(moduleResults[module] == module, "The module scanner must use the shared getscripts inventory")
assert(moduleResults[gameScript] == nil, "The module scanner must reject LocalScripts")

local executorResults = ScriptScanner.Scan("", {
    ShowExecutor = true,
    ShowGame = false,
    ShowRoblox = false,
}, makeContext({
    gameScript,
    executorScript,
}, function(value)
    return value
end))
assert(executorResults[executorScript] == executorScript, "Executor filtering must use the owning script thread")
assert(executorResults[gameScript] == nil, "Executor-only mode must not include game threads")

print("scanner-inventory-contracts-ok")
