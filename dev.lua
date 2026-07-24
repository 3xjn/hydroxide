local environment = assert(getgenv, "<OH> ~ Your exploit is not supported")()
local configuration = environment.HydroxideConfig or {}

configuration.Owner = "3xjn"
configuration.Branch = "dev"
configuration.Web = true
environment.HydroxideConfig = configuration

local url = "https://raw.githubusercontent.com/3xjn/hydroxide/dev/init.lua"
local source = game:HttpGetAsync(url)
local chunk, compileError = loadstring(source, "init.lua")
assert(chunk, compileError)()

return import("ui/main")
