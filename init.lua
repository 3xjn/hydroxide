local environment = assert(getgenv, "<OH> ~ Your exploit is not supported")()

if oh then
    local exited, exitError = pcall(oh.Exit)
    if not exited then
        warn("<OH> ~ Previous session cleanup was incomplete: " .. tostring(exitError))
    end
end

local web = true
local configuration = environment.HydroxideConfig or {}
local user = configuration.Owner or "3xjn"
local branch = configuration.Branch or "master"
local sourceBaseUrl = "https://raw.githubusercontent.com/" .. user .. "/Hydroxide/" .. branch .. "/"
local importCache = {}

assert(branch == "master" or branch == "dev", "<OH> ~ Branch must be either 'master' or 'dev'")

local function hasMethods(methods)
    for name in pairs(methods) do
        if not environment[name] then
            return false
        end
    end

    return true
end

local function useMethods(module)
    for name, method in pairs(module) do
        if method then
            environment[name] = method
        end
    end
end

if Window and PROTOSMASHER_LOADED then
    getgenv().get_script_function = nil
end

local globalMethods = {
    checkCaller = checkcaller,
    newCClosure = newcclosure,
    hookFunction = hookfunction or detour_function,
    restoreFunction = restorefunction,
    getGc = getgc or get_gc_objects,
    getInfo = debug.getinfo or getinfo,
    getSenv = getsenv,
    getMenv = getmenv or getsenv,
    getContext = getthreadcontext or get_thread_context or (syn and syn.get_thread_identity),
    getConnections = get_signal_cons or getconnections,
    getScriptClosure = getscriptclosure or get_script_function,
    getNamecallMethod = getnamecallmethod or get_namecall_method,
    getCallingScript = getcallingscript or get_calling_script,
    getLoadedModules = getloadedmodules or get_loaded_modules,
    getConstants = debug.getconstants or getconstants or getconsts,
    getUpvalues = debug.getupvalues or getupvalues or getupvals,
    getProtos = debug.getprotos or getprotos,
    getStack = debug.getstack or getstack,
    getConstant = debug.getconstant or getconstant or getconst,
    getUpvalue = debug.getupvalue or getupvalue or getupval,
    getProto = debug.getproto or getproto,
    getMetatable = getrawmetatable or debug.getmetatable,
    getHui = get_hidden_gui or gethui,
    setClipboard = setclipboard or writeclipboard,
    setConstant = debug.setconstant or setconstant or setconst,
    setContext = setthreadcontext or set_thread_context or (syn and syn.set_thread_identity),
    setUpvalue = debug.setupvalue or setupvalue or setupval,
    setStack = debug.setstack or setstack,
    setReadOnly = setreadonly or (make_writeable and function(table, readonly) if readonly then make_readonly(table) else make_writeable(table) end end),
    isLClosure = islclosure or is_l_closure or (iscclosure and function(closure) return not iscclosure(closure) end),
    isReadOnly = isreadonly or is_readonly,
    isXClosure = is_synapse_function or issentinelclosure or is_protosmasher_closure or is_sirhurt_closure or iselectronfunction or istempleclosure or checkclosure,
    hookMetaMethod = hookmetamethod or (hookfunction and function(object, method, hook) return hookfunction(getMetatable(object)[method], hook) end),
    readFile = readfile,
    writeFile = writefile,
    makeFolder = makefolder,
    isFolder = isfolder,
    isFile = isfile,
    getCustomAsset = getcustomasset,
}

if PROTOSMASHER_LOADED then
    globalMethods.getConstant = function(closure, index)
        return globalMethods.getConstants(closure)[index]
    end
end

local oldGetUpvalue = globalMethods.getUpvalue
local oldGetUpvalues = globalMethods.getUpvalues

globalMethods.getUpvalue = function(closure, index)
    if type(closure) == "table" then
        return oldGetUpvalue(closure.Data, index)
    end

    return oldGetUpvalue(closure, index)
end

globalMethods.getUpvalues = function(closure)
    if type(closure) == "table" then
        return oldGetUpvalues(closure.Data)
    end

    return oldGetUpvalues(closure)
end

environment.hasMethods = hasMethods
environment.oh = {
    Events = {},
    Hooks = {},
    Cache = importCache,
    Methods = globalMethods,
    Constants = {
        AssetBaseUrl = sourceBaseUrl .. "assets/ui/",
        IsDevelopment = branch == "dev",
        SourceBaseUrl = sourceBaseUrl,
        SourceBranch = branch,
        Types = {
            ["nil"] = true,
            table = true,
            string = true,
            number = true,
            boolean = true,
            userdata = true,
            vector = true,
            ["function"] = true,
            ["thread"] = true,
            ["integral"] = true
        },
        Syntax = {
            ["nil"] = Color3.fromRGB(244, 135, 113),
            table = Color3.fromRGB(225, 225, 225),
            string = Color3.fromRGB(225, 150, 85),
            number = Color3.fromRGB(170, 225, 127),
            boolean = Color3.fromRGB(127, 200, 255),
            userdata = Color3.fromRGB(225, 225, 225),
            vector = Color3.fromRGB(225, 225, 225),
            ["function"] = Color3.fromRGB(225, 225, 225),
            ["thread"] = Color3.fromRGB(225, 225, 225),
            ["unnamed_function"] = Color3.fromRGB(175, 175, 175)
        }
    },
    Exit = function()
        local cleanupErrors = {}
        local function cleanup(label, callback)
            local cleaned, cleanupError = pcall(callback)
            if not cleaned then
                table.insert(cleanupErrors, label .. ": " .. tostring(cleanupError))
            end
        end

        for name, event in pairs(oh.Events) do
            cleanup("event " .. tostring(name), function()
                event:Disconnect()
            end)
        end

        for original, hook in pairs(oh.Hooks) do
            local hookType = type(hook)
            if hookType == "function" then
                cleanup("hook " .. tostring(original), function()
                    restoreFunction(hook)
                end)
            elseif hookType == "table" then
                cleanup("hook " .. tostring(original), function()
                    restoreFunction(hook.Closure.Data)
                end)
            end
        end

        local interface = oh.Interface

        if interface then
            cleanup("interface", function()
                interface:Destroy()
            end)
            oh.Interface = nil
        end

        for _index, cleanupError in ipairs(cleanupErrors) do
            warn("<OH> ~ Cleanup warning: " .. cleanupError)
        end

        return #cleanupErrors == 0, cleanupErrors
    end
}

if getConnections then 
    for __, connection in pairs(getConnections(game:GetService("ScriptContext").Error)) do

        local conn = getrawmetatable(connection)
        local old = conn and conn.__index
        
        if PROTOSMASHER_LOADED ~= nil then setwriteable(conn) else setReadOnly(conn, false) end
        
        if old then
            conn.__index = newcclosure(function(t, k)
                if k == "Connected" then
                    return true
                end
                return old(t, k)
            end)
        end

        if PROTOSMASHER_LOADED ~= nil then
            setReadOnly(conn)
            connection:Disconnect()
        else
            setReadOnly(conn, true)
            connection:Disable()
        end
    end
end

useMethods(globalMethods)

local HttpService = game:GetService("HttpService")
local sourceInfo = HttpService:JSONDecode(game:HttpGetAsync("https://api.github.com/repos/" .. user .. "/hydroxide/commits/" .. branch))
local sourceVersion = assert(sourceInfo.sha, "Hydroxide could not resolve the " .. branch .. " branch version")

if readFile and writeFile then
    local hasFolderFunctions = (isFolder and makeFolder) ~= nil
    local cacheRoot = "hydroxide/user/" .. user .. "/" .. branch
    local versionFile = (hasFolderFunctions and cacheRoot .. "/__version.txt") or ("__oh_" .. user .. "_" .. branch .. "_version.txt")
    local ran, result = pcall(readFile, versionFile)

    if branch == "dev" or not ran or sourceVersion ~= result then
        if hasFolderFunctions then
            local function createFolder(path)
                if not isFolder(path) then
                    makeFolder(path)
                end
            end

            createFolder("hydroxide")
            createFolder("hydroxide/user")
            createFolder("hydroxide/user/" .. user)
            createFolder(cacheRoot)
            createFolder(cacheRoot .. "/methods")
            createFolder(cacheRoot .. "/modules")
            createFolder(cacheRoot .. "/objects")
            createFolder(cacheRoot .. "/ui")
            createFolder(cacheRoot .. "/ui/controls")
            createFolder(cacheRoot .. "/ui/modules")
        end

        function environment.import(asset)
            if importCache[asset] then
                return unpack(importCache[asset])
            end

            local assets

            if web then
                if readFile and writeFile then
                    local file = (hasFolderFunctions and cacheRoot .. '/' .. asset .. ".lua") or ("hydroxide-" .. user .. '-' .. branch .. '-' .. asset:gsub('/', '-') .. ".lua")
                    local content

                    if (isFile and not isFile(file)) or not importCache[asset] then
                        content = game:HttpGetAsync(sourceBaseUrl .. asset .. ".lua")
                        writeFile(file, content)
                    else
                        local ran, result = pcall(readFile, file)

                        if (not ran) or not importCache[asset] then
                            content = game:HttpGetAsync(sourceBaseUrl .. asset .. ".lua")
                            writeFile(file, content)
                        else
                            content = result
                        end
                    end

                    assets = { loadstring(content, asset .. '.lua')() }
                else
                    assets = { loadstring(game:HttpGetAsync(sourceBaseUrl .. asset .. ".lua"), asset .. '.lua')() }
                end
            else
                assets = { loadstring(readFile("hydroxide/" .. asset .. ".lua"), asset .. '.lua')() }
            end

            importCache[asset] = assets
            return unpack(assets)
        end

        writeFile(versionFile, sourceVersion)
    elseif ran and sourceVersion == result then
        function environment.import(asset)
            if importCache[asset] then
                return unpack(importCache[asset])
            end

            local assets
            if web then
                local file = (hasFolderFunctions and cacheRoot .. '/' .. asset .. ".lua") or ("hydroxide-" .. user .. '-' .. branch .. '-' .. asset:gsub('/', '-') .. ".lua")
                local ran, result = pcall(readFile, file)
                local content

                if not ran then
                    content = game:HttpGetAsync(sourceBaseUrl .. asset .. ".lua")
                    writeFile(file, content)
                else
                    content = result
                end

                assets = { loadstring(content, asset .. '.lua')() }
            else
                assets = { loadstring(readFile("hydroxide/" .. asset .. ".lua"), asset .. '.lua')() }
            end

            importCache[asset] = assets
            return unpack(assets)
        end

    end

    useMethods({ import = environment.import })
end

useMethods(import("methods/string"))
useMethods(import("methods/table"))
useMethods(import("methods/userdata"))
useMethods(import("methods/environment"))

--import("ui/main")
