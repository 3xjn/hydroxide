local ScannerResults = {}

local function fullName(instance)
    local success, value = pcall(instance.GetFullName, instance)
    return success and value or instance.Name
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
