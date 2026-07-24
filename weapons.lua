local environment = assert(getgenv, "<OH> ~ Your exploit is not supported")()
local sourceBaseUrl = "https://raw.githubusercontent.com/3xjn/hydroxide/dev/"

local function download(path)
    local source = game:HttpGetAsync(sourceBaseUrl .. path)
    local chunk, compileError = loadstring(source, path)
    return assert(chunk, compileError)
end

local Helpers = download("modules/Helpers.lua")()
local helpers = Helpers.load({
    sourceBaseUrl = sourceBaseUrl,
    modules = {
        "closure",
        "drawing",
        "lifecycle",
        "targeting",
    },
    constants = {
        sourceMode = "web",
        sourceRepositoryUrl = "https://github.com/3xjn/hydroxide",
    },
})
helpers.Resources = {}

local weaponChunk = download("examples/weapon_validation.lua")
local previousOh = environment.oh
environment.oh = helpers
local results = table.pack(pcall(weaponChunk))
environment.oh = previousOh

if not results[1] then
    error(results[2], 0)
end
return table.unpack(results, 2, results.n)
