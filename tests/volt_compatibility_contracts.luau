local fs = require("@lune/fs")

local initSource = fs.readFile("init.lua")
local auxiliarySource = fs.readFile("ohaux.lua")
local closureSpySource = fs.readFile("modules/ClosureSpy.lua")
local closureSpyUiSource = fs.readFile("ui/modules/ClosureSpy.lua")

assert(
    initSource:find("local resolvedIsExecutorClosure = isexecutorclosure", 1, true),
    "Volt's canonical isexecutorclosure must be preferred before compatibility fallbacks"
)
assert(
    initSource:find("local resolvedGetThreadIdentity = getthreadidentity", 1, true),
    "Volt's canonical getthreadidentity must be preferred before compatibility fallbacks"
)
assert(
    initSource:find("local resolvedSetThreadIdentity = setthreadidentity", 1, true),
    "Volt's canonical setthreadidentity must be preferred before compatibility fallbacks"
)
assert(
    initSource:find("getThreadIdentity = resolvedGetThreadIdentity", 1, true)
        and initSource:find("getContext = resolvedGetThreadIdentity", 1, true),
    "Hydroxide must expose the canonical thread-identity name and retain its legacy internal alias"
)
assert(
    initSource:find("setThreadIdentity = resolvedSetThreadIdentity", 1, true)
        and initSource:find("setContext = resolvedSetThreadIdentity", 1, true),
    "Hydroxide must expose the canonical thread-identity setter and retain its legacy internal alias"
)
assert(
    initSource:find("getMenv = getsenv or getmenv", 1, true),
    "Documented getsenv must be preferred for ModuleScript environments"
)
assert(not initSource:find("PROTOSMASHER_LOADED", 1, true), "ProtoSmasher-specific runtime behavior must be removed")
assert(
    auxiliarySource:find("isexecutorclosure or", 1, true),
    "Standalone auxiliary searches must prefer Volt's closure-origin API"
)
assert(
    closureSpySource:find('["getThreadIdentity"] = true', 1, true)
        and closureSpySource:find('["setThreadIdentity"] = true', 1, true),
    "Closure Spy must require the canonical Hydroxide thread-identity methods"
)
assert(
    closureSpyUiSource:find("getThreadIdentity()", 1, true)
        and closureSpyUiSource:find("setThreadIdentity(7)", 1, true),
    "Closure Spy UI must use the canonical thread-identity methods"
)

print("volt-compatibility-contracts-ok")
