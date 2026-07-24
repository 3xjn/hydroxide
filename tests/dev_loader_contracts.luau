local fs = require("@lune/fs")

local environment = {}
local requestedUrl
local importedAsset

getgenv = function()
    return environment
end
game = {
    HttpGetAsync = function(_game, url)
        requestedUrl = url
        return [[
import = function(asset)
    __importedAsset = asset
    return "HydroxideSession"
end
]]
    end,
}

local source = fs.readFile("dev.lua")
local result = assert(loadstring(source, "dev.lua"))()
importedAsset = __importedAsset

assert(environment.HydroxideConfig.Owner == "3xjn")
assert(environment.HydroxideConfig.Branch == "dev")
assert(environment.HydroxideConfig.Web == true)
assert(requestedUrl == "https://raw.githubusercontent.com/3xjn/hydroxide/dev/init.lua")
assert(importedAsset == "ui/main")
assert(result == "HydroxideSession")

print("dev-loader-contracts-ok")
