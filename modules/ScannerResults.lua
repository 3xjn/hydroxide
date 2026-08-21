local ScannerResults = {}

local function fullName(instance)
    local success, value = pcall(instance.GetFullName, instance)
    return success and value or instance.Name
end

local function defaultContext()
    local environment = getgenv()
    local session = environment.oh
    local methods = session and session.Methods or {}
    return {
        GetInfo = methods.getInfo or environment.getInfo or getinfo,
        GetInstancePath = environment.getInstancePath,
        ToString = environment.toString or tostring,
        IsInstance = function(value)
            return typeof(value) == "Instance"
        end,
    }
end

local function sortedKeys(map)
    local keys = {}
    for key in pairs(map) do
        table.insert(keys, key)
    end

    table.sort(keys, function(left, right)
        local leftNumber = tonumber(left)
        local rightNumber = tonumber(right)
        if leftNumber and rightNumber then
            return leftNumber < rightNumber
        end

        return tostring(left) < tostring(right)
    end)

    return keys
end

function ScannerResults.ClosureName(value, context)
    context = context or defaultContext()
    if type(value) ~= "function" then
        return nil
    end

    local succeeded, info = pcall(context.GetInfo, value)
    local name = succeeded and info and info.name or ""
    if name == "" then
        return "Unnamed function"
    end

    return name
end

function ScannerResults.Describe(result, context)
    context = context or defaultContext()
    local instance = result.Instance
    local getPath = context.GetInstancePath
    local path = instance and (getPath and getPath(instance) or fullName(instance)) or nil

    local protos = {}
    for _, index in ipairs(sortedKeys(result.Protos or {})) do
        local value = result.Protos[index]
        table.insert(protos, {
            Index = index,
            Value = value,
            Name = ScannerResults.ClosureName(value, context),
        })
    end

    local constants = {}
    for _, index in ipairs(sortedKeys(result.Constants or {})) do
        local value = result.Constants[index]
        local valueType = type(value)
        table.insert(constants, {
            Index = index,
            Value = value,
            Name = valueType == "function" and ScannerResults.ClosureName(value, context) or nil,
            Text = valueType == "function" and ScannerResults.ClosureName(value, context)
                or (context.ToString and context.ToString(value) or tostring(value)),
        })
    end

    local environment = {}
    for _, key in ipairs(sortedKeys(result.Environment or {})) do
        local value = result.Environment[key]
        local isInstance = context.IsInstance and context.IsInstance(value) or false
        table.insert(environment, {
            Key = key,
            Value = value,
            Text = context.ToString and context.ToString(value) or tostring(value),
            IsInstance = isInstance,
            Path = isInstance and getPath and getPath(value) or nil,
        })
    end

    return {
        Result = result,
        Instance = instance,
        Name = instance and instance.Name or nil,
        ClassName = instance and instance.ClassName or nil,
        Path = path,
        Protos = protos,
        Constants = constants,
        Environment = environment,
    }
end

function ScannerResults.Sorted(results)
    local sorted = {}

    for _instance, result in pairs(results) do
        table.insert(sorted, result)
    end

    table.sort(sorted, function(left, right)
        local leftInstance = left.Instance
        local rightInstance = right.Instance
        local leftName = leftInstance.Name:lower()
        local rightName = rightInstance.Name:lower()

        if leftName ~= rightName then
            return leftName < rightName
        end

        return fullName(leftInstance):lower() < fullName(rightInstance):lower()
    end)

    return sorted
end

return ScannerResults
