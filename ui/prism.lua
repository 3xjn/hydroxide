local Prism = {}

local artifact
local resolved = false

local function loadArtifact()
    if resolved then
        return artifact
    end

    resolved = true

    -- rbxtsc → ui/out is the compile artifact, not an executor module.
    -- import() always requests asset .. ".lua" from GitHub or LocalRoot, and
    -- this repo does not ship ui/dist/Hydroxide.lua (the optional executor blob).
    local ok, result = pcall(import, "ui/dist/Hydroxide")
    if ok and type(result) == "table" and type(result.mountHydroxide) == "function" then
        artifact = result
        return artifact
    end

    artifact = nil
    return nil
end

function Prism.available()
    return loadArtifact() ~= nil
end

function Prism.mount(parent, model)
    local loaded = loadArtifact()
    assert(loaded, "Hydroxide Prism artifact is not available")
    local handle = loaded.mountHydroxide(parent, model)
    table.insert(getgenv().oh.Resources, {
        Destroy = function()
            handle.destroy()
        end
    })
    return handle
end

return Prism
