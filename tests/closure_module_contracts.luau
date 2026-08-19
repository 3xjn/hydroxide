local Closure = require("../modules/Closure")
local Helpers = require("../modules/Helpers")

local targetScript = { Parent = {} }
local otherScript = { Parent = {} }
local orphanedScript = { Parent = nil }

local function targetClosure() end
local function otherClosure() end
local function executorClosure() end
local function cClosure() end
local function nestedClosure() end

local environments = {
    [targetClosure] = { script = targetScript },
    [otherClosure] = { script = otherScript },
    [executorClosure] = { script = targetScript },
    [cClosure] = { script = targetScript },
}
local names = {
    [targetClosure] = "Shoot",
    [otherClosure] = "Shoot",
}
local constants = {
    [targetClosure] = { "ThrowEvent", 250, "token-parent" },
    [nestedClosure] = { "token-nested", "token-parent" },
    [otherClosure] = { "ThrowEvent", 250, "token-parent" },
}
local upvalueCounts = {
    [targetClosure] = 4,
    [otherClosure] = 4,
}
local expectedUpvalue = {
    FireServer = function() end,
}
local upvalueLists = {
    [targetClosure] = { "ignored", expectedUpvalue },
    [otherClosure] = { "other" },
}

local placeholder = {}
local helper = Closure.new({
    GetConstants = function(value)
        return constants[value]
    end,
    GetEnvironment = function(value)
        return environments[value]
    end,
    GetGc = function()
        return { 42, targetClosure, executorClosure, cClosure, otherClosure }
    end,
    GetInfo = function(value)
        return { name = names[value] }
    end,
    GetProtos = function(value)
        return value == targetClosure and { nestedClosure } or {}
    end,
    GetScriptClosure = function(script)
        if script == targetScript then
            return targetClosure
        end
        return "script closure unavailable"
    end,
    GetUpvalue = function(value, index)
        if index > upvalueCounts[value] then
            error("upvalue does not exist")
        end
        return nil
    end,
    GetUpvalues = function(value)
        return upvalueLists[value]
    end,
    IsExecutorClosure = function(value)
        return value == executorClosure
    end,
    IsLClosure = function(value)
        assert(type(value) == "function", "non-functions must be rejected before closure inspection")
        return value ~= cClosure
    end,
    PlaceholderUserdataConstant = placeholder,
})

local visited = {}
helper.forEachGameClosure(function(value)
    table.insert(visited, value)
end)
assert(#visited == 2, "Only non-executor Luau closures may enter the programmatic inventory")
assert(visited[1] == targetClosure and visited[2] == otherClosure, "Closure inventory must preserve getgc order")

local stringConstants = helper.findStringConstants(targetScript, "^token%-")
assert(#stringConstants == 2, "String discovery must recursively inspect nested protos and deduplicate values")
assert(
    stringConstants[1] == "token-parent" and stringConstants[2] == "token-nested",
    "String discovery must preserve closure traversal order"
)
assert(
    #helper.findStringConstants(otherScript, "^token%-") == 0,
    "An unavailable script closure must produce no guessed constants"
)

local foundUpvalue = helper.findUpvalue(targetScript, function(value, index, closure)
    return closure == targetClosure and index == 2 and value == expectedUpvalue
end)
assert(foundUpvalue == expectedUpvalue, "Upvalue discovery must combine script ownership and a live predicate")
assert(
    helper.findUpvalue(otherScript, function(value)
        return value == expectedUpvalue
    end) == nil,
    "Upvalue discovery must not cross script ownership"
)

local found = helper.searchClosure(targetScript, "Shoot", 4, {
    [1] = "ThrowEvent",
    [2] = placeholder,
})
assert(found == targetClosure, "Closure search must combine script, name, upvalue, and constant evidence")

local gcTraversals = 0
local batchHelper = Closure.new({
    GetConstants = function(value)
        return constants[value]
    end,
    GetEnvironment = function(value)
        return environments[value]
    end,
    GetGc = function()
        gcTraversals += 1
        return { targetClosure, otherClosure }
    end,
    GetInfo = function(value)
        return { name = names[value] }
    end,
    GetUpvalue = function(value, index)
        if index > upvalueCounts[value] then
            error("upvalue does not exist")
        end
    end,
    IsExecutorClosure = function()
        return false
    end,
    IsLClosure = function()
        return true
    end,
})
local batch = batchHelper.searchClosures(targetScript, {
    shoot = { name = "Shoot", upvalueIndex = 4 },
    missing = { name = "Reload", upvalueIndex = 1 },
})
assert(batch.shoot == targetClosure and batch.missing == nil)
assert(gcTraversals == 1, "Batch closure search must traverse getgc once")

assert(
    helper.searchClosure(targetScript, "Shoot", 5, constants[targetClosure]) == nil,
    "Closure search must reject a missing upvalue"
)
assert(
    helper.searchClosure(targetScript, "Reload", 4, constants[targetClosure]) == nil,
    "Closure search must reject the wrong function name"
)
assert(
    helper.searchClosure(otherScript, "Shoot", 4, constants[targetClosure]) == otherClosure,
    "Closure search must distinguish scripts with otherwise identical closure evidence"
)

environments[otherClosure] = { script = orphanedScript }
assert(
    helper.searchClosure(nil, "Shoot", 4, constants[targetClosure]) == otherClosure,
    "A nil script search must support orphaned script closures"
)

local function scannerClosure(value)
    return {
        Constants = {},
        Data = value,
        Upvalues = {},
    }
end

local imported = {
    ["objects/Closure"] = { new = scannerClosure },
    ["objects/Constant"] = { new = function(closure, index, value)
        return { Closure = closure, Index = index, Value = value }
    end },
    ["objects/Upvalue"] = { new = function(closure, index, value)
        return { Closure = closure, Index = index, Value = value }
    end },
    ["modules/Helpers"] = Helpers,
    ["modules/Closure"] = Closure,
}
import = function(path)
    return imported[path]
end

getGc = function()
    return { targetClosure, executorClosure }
end
getInfo = function()
    return { name = "Shoot" }
end
getConstants = function()
    return { "needle" }
end
getUpvalues = function()
    return { "needle" }
end
isExecutorClosure = function(value)
    return value == executorClosure
end
isLClosure = function()
    return true
end

local UpvalueScanner = require("../modules/UpvalueScanner")
local ConstantScanner = require("../modules/ConstantScanner")
local upvalueResults = UpvalueScanner.Scan("needle", false)
local constantResults = ConstantScanner.Scan("needle")

assert(upvalueResults[targetClosure] ~= nil, "Upvalue Scanner must retain matching game closures")
assert(upvalueResults[executorClosure] == nil, "Upvalue Scanner must exclude executor closures through the helper")
assert(constantResults[targetClosure] ~= nil, "Constant Scanner must retain matching game closures")
assert(constantResults[executorClosure] == nil, "Constant Scanner must exclude executor closures through the helper")

print("closure-module-contracts-ok")
