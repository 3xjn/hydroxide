local environment = assert(getgenv, "<OH> ~ Your exploit is not supported")()
local configuration = environment.HydroxideConfig or {}

configuration.Web = false
configuration.LocalRoot = configuration.LocalRoot or "hydroxide/local"
configuration.Branch = configuration.Branch or "dev"
environment.HydroxideConfig = configuration

loadstring(readfile(configuration.LocalRoot .. "/init.lua"), "init.lua")()
return import("ui/main")
