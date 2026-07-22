local fs = require("@lune/fs")

local initSource = fs.readFile("init.lua")
local contextMenuSource = fs.readFile("ui/controls/ContextMenu.lua")
local uiMainSource = fs.readFile("ui/main.lua")
local windowSource = fs.readFile("ui/window.lua")

assert(
    initSource:find("pcall(previousSession.Exit)", 1, true),
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
    initSource:find("local interface = session.Interface", 1, true),
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
assert(initSource:find("local installedMethods = {}", 1, true), "Shutdown must track every injected environment method")
assert(initSource:find("environment[name] = previousMethods[name].Value", 1, true), "Shutdown must restore injected environment methods")
assert(initSource:find("environment.oh = nil", 1, true), "Shutdown must clear the active Hydroxide session")
assert(
    not initSource:find('game:GetService("ScriptContext").Error', 1, true),
    "Hydroxide must not disable executor-wide ScriptContext error listeners that it cannot restore"
)
assert(windowSource:find('createControl(drag, "Exit"', 1, true), "The title bar must expose a distinct full-exit action")
assert(windowSource:find("oh.Events.WindowExit", 1, true), "The full-exit listener must be owned by the Hydroxide session")
assert(windowSource:find("oh.Exit()", 1, true), "The title-bar exit action must invoke full session cleanup")
assert(
    contextMenuSource:find("session.Events.ContextMenuInputEnded", 1, true),
    "The global context-menu input listener must be disconnected during shutdown"
)

print("shutdown-runtime-contracts-ok")
