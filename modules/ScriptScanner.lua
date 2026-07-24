local ScriptScanner = {}
local LocalScript = import("objects/LocalScript")
local ScannerFilter = import("modules/ScannerFilter")

local requiredMethods = {
    ["getSenv"] = true,
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
        NewLocalScript = LocalScript.new,
    }
end

local function scan(query, options, context)
    local scripts = {}
    query = (query or ""):lower()
    context = context or defaultContext()

    for _index, script in pairs(context.GetScripts()) do
        if
            context.IsInstance(script)
            and script:IsA("LocalScript")
            and script.Name:lower():find(query, 1, true)
        then
            local scriptThread = context.GetScriptThread(script)
            local filterContext = {
                GetHiddenProperty = context.GetHiddenProperty,
                IsExecutor = scriptThread ~= nil and context.IsExecutorThread(scriptThread),
            }

            if ScannerFilter.ShouldInclude(script, options, filterContext) then
                local success, result = pcall(context.NewLocalScript, script)
                if success then
                    scripts[script] = result
                end
            end
        end
    end

    return scripts
end

ScriptScanner.RequiredMethods = requiredMethods
ScriptScanner.Scan = scan
return ScriptScanner
