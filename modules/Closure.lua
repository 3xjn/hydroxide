local Closure = {}

local placeholderUserdataConstant = {}

local function defaultContext()
    local environment = getgenv()
    local resolvedIsExecutorClosure = isexecutorclosure
        or environment.checkclosure
        or environment.is_synapse_function
        or environment.issentinelclosure
        or environment.is_sirhurt_closure
        or environment.iselectronfunction
        or environment.istempleclosure

    return {
        GetConstants = debug.getconstants or environment.getconstants or environment.getconsts,
        GetEnvironment = getfenv,
        GetGc = getgc or environment.get_gc_objects,
        GetInfo = debug.getinfo or environment.getinfo,
        GetProtos = debug.getprotos or environment.getprotos,
        GetScriptClosure = getscriptclosure or environment.getscriptclosure,
        GetUpvalue = debug.getupvalue or environment.getupvalue or environment.getupval,
        GetUpvalues = debug.getupvalues or environment.getupvalues or environment.getupvals,
        IsExecutorClosure = resolvedIsExecutorClosure,
        IsLClosure = islclosure
            or environment.is_l_closure
            or (iscclosure and function(value)
                return not iscclosure(value)
            end),
    }
end

local function requireMethod(context, name)
    return assert(context[name], "Closure helper requires " .. name)
end

function Closure.new(context)
    context = context or defaultContext()

    local helper = {
        placeholderUserdataConstant = context.PlaceholderUserdataConstant or placeholderUserdataConstant,
    }

    function helper.isGameClosure(value)
        if type(value) ~= "function" then
            return false
        end

        local isLClosure = requireMethod(context, "IsLClosure")
        local isExecutorClosure = requireMethod(context, "IsExecutorClosure")
        return isLClosure(value) and not isExecutorClosure(value)
    end

    function helper.forEachGameClosure(visitor)
        local getGc = requireMethod(context, "GetGc")

        for _index, value in pairs(getGc()) do
            if helper.isGameClosure(value) and visitor(value) == false then
                return
            end
        end
    end

    local function matchesConstants(closure, expected)
        if not expected then
            return true
        end

        local getConstants = requireMethod(context, "GetConstants")
        local constants = getConstants(closure)

        for index, value in pairs(expected) do
            if constants[index] ~= value and value ~= helper.placeholderUserdataConstant then
                return false
            end
        end

        return true
    end

    local function matchesScript(closure, expected)
        local getEnvironment = requireMethod(context, "GetEnvironment")
        local succeeded, environment = pcall(getEnvironment, closure)
        if not succeeded or type(environment) ~= "table" then
            return false
        end

        local parentScript = rawget(environment, "script")
        if expected ~= nil then
            return parentScript == expected
        end

        return parentScript == nil or parentScript.Parent == nil
    end

    function helper.searchClosure(script, name, upvalueIndex, constants)
        local getInfo = requireMethod(context, "GetInfo")
        local getUpvalue = requireMethod(context, "GetUpvalue")
        local found

        helper.forEachGameClosure(function(closure)
            if not matchesScript(closure, script) then
                return
            end

            if not pcall(getUpvalue, closure, upvalueIndex) then
                return
            end

            local closureName = getInfo(closure).name
            local hasNamedMatch = name and name ~= "Unnamed function" and closureName == name
            local hasUnnamedMatch = not name or name == "Unnamed function"

            if (hasNamedMatch or hasUnnamedMatch) and matchesConstants(closure, constants) then
                found = closure
                return false
            end

            return nil
        end)

        return found
    end

    function helper.searchClosures(script, queries)
        local getInfo = requireMethod(context, "GetInfo")
        local getUpvalue = requireMethod(context, "GetUpvalue")
        local found = {}
        local remaining = 0
        for _key in pairs(queries or {}) do
            remaining += 1
        end

        helper.forEachGameClosure(function(closure)
            if not matchesScript(closure, script) then
                return
            end
            local closureName = getInfo(closure).name
            for key, query in pairs(queries or {}) do
                if found[key] == nil
                    and (not query.name or query.name == closureName)
                    and (not query.upvalueIndex or pcall(getUpvalue, closure, query.upvalueIndex))
                    and matchesConstants(closure, query.constants)
                then
                    found[key] = closure
                    remaining -= 1
                end
            end
            if remaining == 0 then
                return false
            end
            return nil
        end)
        return found
    end

    function helper.findStringConstants(script, pattern)
        local getConstants = requireMethod(context, "GetConstants")
        local getProtos = requireMethod(context, "GetProtos")
        local getScriptClosure = requireMethod(context, "GetScriptClosure")
        local results = {}
        local seenTargets = {}
        local seenValues = {}
        local succeeded, root = pcall(getScriptClosure, script)

        if not succeeded or type(root) == "string" then
            return results
        end

        local function visit(target)
            if seenTargets[target] then
                return
            end
            seenTargets[target] = true

            local constantsSucceeded, constants = pcall(getConstants, target)
            if constantsSucceeded then
                for _index, value in pairs(constants) do
                    if
                        type(value) == "string"
                        and value:match(pattern)
                        and not seenValues[value]
                    then
                        seenValues[value] = true
                        table.insert(results, value)
                    end
                end
            end

            local protosSucceeded, protos = pcall(getProtos, target)
            if protosSucceeded then
                for _index, proto in pairs(protos) do
                    visit(proto)
                end
            end
        end

        visit(root)
        return results
    end

    function helper.findUpvalue(script, predicate)
        local getUpvalues = requireMethod(context, "GetUpvalues")
        local found

        helper.forEachGameClosure(function(closure)
            if not matchesScript(closure, script) then
                return
            end

            local succeeded, upvalues = pcall(getUpvalues, closure)
            if not succeeded then
                return
            end

            for index, value in pairs(upvalues) do
                if predicate(value, index, closure) then
                    found = value
                    return false
                end
            end

            return nil
        end)

        return found
    end

    return helper
end

local defaultHelper
local function getDefaultHelper()
    if not defaultHelper then
        defaultHelper = Closure.new()
    end

    return defaultHelper
end

Closure.placeholderUserdataConstant = placeholderUserdataConstant
Closure.isGameClosure = function(...)
    return getDefaultHelper().isGameClosure(...)
end
Closure.forEachGameClosure = function(...)
    return getDefaultHelper().forEachGameClosure(...)
end
Closure.findStringConstants = function(...)
    return getDefaultHelper().findStringConstants(...)
end
Closure.findUpvalue = function(...)
    return getDefaultHelper().findUpvalue(...)
end
Closure.searchClosure = function(...)
    return getDefaultHelper().searchClosure(...)
end
Closure.searchClosures = function(...)
    return getDefaultHelper().searchClosures(...)
end

return Closure
