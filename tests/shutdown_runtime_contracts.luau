local fs = require("@lune/fs")

local initSource = fs.readFile("init.lua")
local closureSpySource = fs.readFile("modules/ClosureSpy.lua")
local contextMenuSource = fs.readFile("ui/controls/ContextMenu.lua")
local uiMainSource = fs.readFile("ui/main.lua")
local windowSource = fs.readFile("ui/window.lua")

assert(
    initSource:find("pcall(previousSession.Exit)", 1, true),
    "A failed previous-session cleanup must not abort the next Hydroxide startup"
)
assert(
    initSource:find("restoreFunction(target)", 1, true),
    "Hook cleanup must use Volt's restorefunction instead of reverse-hooking"
)
assert(
    not initSource:find("hookFunction(hook, original)", 1, true),
    "Reverse-hook cleanup can fail when the original closure has more upvalues"
)
assert(closureSpySource:find("hook.Target = data", 1, true), "Closure Spy must retain the function actually passed to hookfunction")
assert(closureSpySource:find("oh.Hooks[data] = data", 1, true), "Closure Spy hooks must be owned by session cleanup")
assert(
    closureSpySource:find("restoreFunction(hook.Target)", 1, true),
    "Explicit Closure Spy removal must restore the hooked target"
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
assert(windowSource:find('createControl(drag, "Exit"', 1, true), "The fallback title bar must expose a distinct full-exit action")
assert(windowSource:find("oh.Events.WindowExit", 1, true), "The fallback full-exit listener must be owned by the Hydroxide session")
assert(windowSource:find("oh.Exit()", 1, true), "The fallback title-bar exit action must invoke full session cleanup")
assert(uiMainSource:find("onClose", 1, true), "Prism Window must receive onClose so Hydroxide can still exit")
assert(
    contextMenuSource:find("session.Events.ContextMenuInputEnded", 1, true),
    "The global context-menu input listener must be disconnected during shutdown"
)

print("shutdown-runtime-contracts-ok")
