local fs = require("@lune/fs")

local banned = {
    "Drawing.new",
    "DrawingImmediate",
    "DrawFont",
    "oh.drawing",
    "DrawingControls",
    "createSurface",
    "cleardrawcache",
    "getrenderproperty",
    "setrenderproperty",
    "isrenderobj",
}

local removedFiles = {
    "modules/Drawing.lua",
    "modules/DrawingControls.lua",
    "docs/drawing-surface.md",
    "examples/drawing_surface.lua",
    "examples/weapon_validation.lua",
    "examples/gun_validation.lua",
    "examples/knife_validation.lua",
    "weapons.lua",
}

local skipFiles = {
    ["tests/no_drawing_api_contracts.luau"] = true,
}

local function walk(path, files)
    for _, name in fs.readDir(path) do
        if name == ".git" or name == "node_modules" then
            continue
        end

        local child = if path == "." then name else path .. "/" .. name
        if fs.isDir(child) then
            walk(child, files)
        elseif name:match("%.lua$") or name:match("%.luau$") or name:match("%.md$") or name:match("%.sh$") then
            table.insert(files, child)
        end
    end
end

for _, path in removedFiles do
    assert(not fs.isFile(path), path .. " must stay deleted")
end

local helpersSource = fs.readFile("modules/Helpers.lua")
assert(not helpersSource:find("Drawing", 1, true), "Helpers must not load a Drawing module")
assert(not helpersSource:find("drawing", 1, true), "Helpers must not expose oh.drawing")
assert(not helpersSource:find("controls", 1, true), "Helpers must not load DrawingControls")

local files = {}
walk(".", files)

for _, path in files do
    if skipFiles[path] then
        continue
    end

    local source = fs.readFile(path)
    for _, token in banned do
        assert(not source:find(token, 1, true), path .. " must not use " .. token)
    end
end

print("no-drawing-api-contracts-ok")
