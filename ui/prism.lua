local Prism = {}

function Prism.mount(parent, model)
    local loaded = import("ui/dist/Hydroxide")
    assert(type(loaded) == "table" and type(loaded.mountHydroxide) == "function", "Hydroxide Prism artifact must export mountHydroxide")
    local handle = loaded.mountHydroxide(parent, model)
    table.insert(getgenv().oh.Resources, {
        Destroy = function()
            handle.destroy()
        end
    })
    return handle
end

return Prism
