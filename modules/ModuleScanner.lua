local ModuleScanner = {}
local ModuleScript = import("objects/ModuleScript")
local ScannerFilter = import("modules/ScannerFilter")

local requiredMethods = {
    ["getMenv"] = true,
    ["getProtos"] = true,
    ["getConstants"] = true,
    ["getScriptClosure"] = true,
    ["getScripts"] = true,
    ["getScriptThread"] = true,
    ["isExecutorThread"] = true,
}

local function defaultContext()
    local methods = getgenv().oh.Methods
    return {
        GetScripts = methods.getScripts,
        GetScriptThread = methods.getScriptThread,
        GetHiddenProperty = methods.getHiddenProperty,
        IsInstance = function(value)
            return typeof(value) == "Instance"
        end,
        IsExecutorThread = methods.isExecutorThread,
        NewModuleScript = ModuleScript.new,
    }
end

local function scan(query, options, context)
    local modules = {}
    query = (query or ""):lower()

    context = context or defaultContext()
    for _index, module in pairs(context.GetScripts()) do
        if
            context.IsInstance(module)
            and module:IsA("ModuleScript")
            and module.Name:lower():find(query, 1, true)
        then
            local scriptThread = context.GetScriptThread(module)
            local filterContext = {
                GetHiddenProperty = context.GetHiddenProperty,
                IsExecutor = scriptThread ~= nil and context.IsExecutorThread(scriptThread),
            }

            if ScannerFilter.ShouldInclude(module, options, filterContext) then
                local success, result = pcall(context.NewModuleScript, module)
                if success then
                    modules[module] = result
                end
            end
        end
    end

    return modules
end

ModuleScanner.Scan = scan
ModuleScanner.RequiredMethods = requiredMethods
return ModuleScanner
