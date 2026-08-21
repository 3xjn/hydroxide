local Prism = {}

local artifact

local function loadArtifact()
    if artifact then
        return artifact
    end

    -- rbxtsc → ui/out is the compile artifact. This repo does not ship a patched Wax blob.
    artifact = import("ui/dist/Hydroxide")
    assert(type(artifact) == "table" and type(artifact.mountHydroxide) == "function", "Hydroxide Prism artifact must export mountHydroxide")
    return artifact
end

function Prism.mount(parent, model)
    local handle = loadArtifact().mountHydroxide(parent, model)
    table.insert(getgenv().oh.Resources, {
        Destroy = function()
            handle.destroy()
        end
    })
    return handle
end

return Prism
