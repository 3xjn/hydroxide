local fs = require("@lune/fs")

local initSource = fs.readFile("init.lua")

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

print("shutdown-runtime-contracts-ok")
