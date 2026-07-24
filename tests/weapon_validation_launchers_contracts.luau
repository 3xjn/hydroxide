local fs = require("@lune/fs")

local loadedPaths = {}
local session = {
    Name = "WeaponValidation",
}
local environment = {
    HydroxideConfig = {
        LocalRoot = "hydroxide/local",
    },
}

getgenv = function()
    return environment
end
readfile = function(path)
    table.insert(loadedPaths, path)
    return "return __weaponValidationSession"
end
__weaponValidationSession = session

local gunChunk = assert(loadstring(fs.readFile("examples/gun_validation.lua"), "gun_validation.lua"))
local knifeChunk = assert(loadstring(fs.readFile("examples/knife_validation.lua"), "knife_validation.lua"))

assert(gunChunk() == session, "The gun launcher must execute the shared weapon validator")
assert(knifeChunk() == session, "The knife launcher must execute the shared weapon validator")
assert(loadedPaths[1] == "hydroxide/local/examples/weapon_validation.lua")
assert(loadedPaths[2] == "hydroxide/local/examples/weapon_validation.lua")

print("weapon-validation-launchers-contracts-ok")
