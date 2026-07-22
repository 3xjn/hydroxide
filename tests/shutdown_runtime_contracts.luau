local fs = require("@lune/fs")

local initSource = fs.readFile("init.lua")
local uiMainSource = fs.readFile("ui/main.lua")

assert(
    initSource:find("pcall(oh.Exit)", 1, true),
    "A failed previous-session cleanup must not abort the next Hydroxide startup"
)
assert(
    initSource:find("restoreFunction(hook)", 1, true),
    "Hook cleanup must use Volt's restorefunction instead of reverse-hooking"
)
assert(
    not initSource:find("hookFunction(hook, original)", 1, true),
    "Reverse-hook cleanup can fail when the original closure has more upvalues"
)
assert(
    initSource:find("local interface = oh.Interface", 1, true),
    "Shutdown must destroy the directly owned interface even when the import cache is unavailable"
)
assert(
    uiMainSource:find("destroyPreviousInterfaces(interfaceParent)", 1, true),
    "Startup must remove orphaned Hydroxide interfaces left by an older failed shutdown"
)
assert(
    uiMainSource:find('Interface.Name = "Hydroxide"', 1, true),
    "The live interface needs a stable identity for single-instance ownership"
)

print("shutdown-runtime-contracts-ok")
