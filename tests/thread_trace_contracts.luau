local ThreadTrace = require("../modules/ThreadTrace")

local thread = coroutine.create(function() end)
local executorClosure = function() end
local gameClosure = function() end
local checkedCandidates = {}
local stack = {
    "PotassiumSourceMetadata",
    executorClosure,
    gameClosure,
}

local resolved = ThreadTrace.resolveFunction(thread, {
    GetStackFunction = function(value, level)
        assert(value == thread)
        return stack[level]
    end,
    IsExecutorClosure = function(candidate)
        assert(type(candidate) == "function", "Executor predicates must only receive functions")
        table.insert(checkedCandidates, candidate)
        return candidate == executorClosure
    end,
    IsLClosure = function(candidate)
        assert(type(candidate) == "function", "Closure predicates must only receive functions")
        return true
    end,
})

assert(resolved == gameClosure, "Tracing must skip metadata and executor closures")
assert(#checkedCandidates == 2)

local predicateCalls = 0
local metadataOnly = ThreadTrace.resolveFunction(thread, {
    GetStackFunction = function(_thread, level)
        if level == 1 then
            return "source"
        end
        return nil
    end,
    IsExecutorClosure = function()
        predicateCalls = predicateCalls + 1
        return false
    end,
})
assert(metadataOnly == nil)
assert(predicateCalls == 0, "Non-functions must never reach closure predicates")

print("thread-trace-contracts-ok")
