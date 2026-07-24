local environment = getgenv()
local root = (environment.HydroxideConfig or {}).LocalRoot or "hydroxide/local"
local file = root .. "/examples/weapon_validation.lua"
local chunk, compileError = loadstring(readfile(file), "weapon_validation.lua")
return assert(chunk, compileError)()
