local fs = require("@lune/fs")

local previousOh = {
    Name = "ExistingHydroxide",
}
local environment = {
    oh = previousOh,
}
local requestedUrls = {}
local helperBundle = {
    closure = {},
    drawing = {},
    lifecycle = {},
    targeting = {},
}

getgenv = function()
    return environment
end
__helperBundle = helperBundle
game = {
    HttpGetAsync = function(_game, url)
        table.insert(requestedUrls, url)
        if url:find("modules/Helpers.lua", 1, true) then
            return [[
return {
    load = function(options)
        assert(options.sourceBaseUrl == "https://raw.githubusercontent.com/3xjn/hydroxide/dev/")
        assert(#options.modules == 4)
        return __helperBundle
    end,
}
]]
        end
        assert(url:find("examples/weapon_validation.lua", 1, true))
        return [[
assert(getgenv().oh == __helperBundle)
return "WeaponSession"
]]
    end,
}

local source = fs.readFile("weapons.lua")
local result = assert(loadstring(source, "weapons.lua"))()

assert(result == "WeaponSession")
assert(environment.oh == previousOh, "The headless launcher must restore an existing Hydroxide session")
assert(helperBundle.Resources and #helperBundle.Resources == 0)
assert(#requestedUrls == 2)

print("weapons-loader-contracts-ok")
