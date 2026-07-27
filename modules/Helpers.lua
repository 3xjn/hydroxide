local Helpers = {}

local moduleFiles = {
    closure = "Closure",
    controls = "DrawingControls",
    drawing = "Drawing",
    lifecycle = "Lifecycle",
    remote = "Remote",
    targeting = "Targeting",
}

function Helpers.load(options)
    options = options or {}

    local cache = {}
    local importModule = options.import
    local localRoot = options.localRoot
    local sourceBaseUrl = options.sourceBaseUrl

    assert(
        importModule or localRoot or sourceBaseUrl,
        "Hydroxide helpers require import, localRoot, or sourceBaseUrl"
    )

    local function load(name)
        local fileName = assert(moduleFiles[name], "Unknown Hydroxide helper module: " .. tostring(name))

        if cache[name] ~= nil then
            return cache[name]
        end

        local asset = "modules/" .. fileName
        local module

        if importModule then
            module = importModule(asset)
        else
            local file = asset .. ".lua"
            local source

            if localRoot then
                local readFile = options.readFile or readfile
                source = assert(readFile, "Local Hydroxide helpers require readfile")(localRoot .. "/" .. file)
            else
                local httpGet = options.httpGet or function(url)
                    return game:HttpGetAsync(url)
                end
                source = httpGet(sourceBaseUrl .. file)
            end

            local loadString = options.loadString or loadstring
            local chunk, compileError = loadString(source, file)
            module = assert(chunk, compileError)()
        end

        cache[name] = assert(module, "Hydroxide helper module returned nil: " .. name)
        return module
    end

    local oh = {
        constants = options.constants or {},
        state = options.state,
    }

    oh.load = function(name)
        local module = load(name)
        oh[name] = module
        return module
    end

    for _index, name in ipairs(options.modules or {}) do
        oh.load(name)
    end

    return oh
end

function Helpers.attach(session, options)
    assert(type(session) == "table", "Hydroxide helpers require a session")
    options = options or {}
    options.constants = options.constants or session.Constants or session.constants
    options.state = options.state or session.State or session.state
    options.modules = options.modules or {
        "closure",
        "drawing",
        "lifecycle",
        "targeting",
    }

    local helpers = Helpers.load(options)
    for _, name in ipairs(options.modules) do
        session[name] = helpers[name]
    end
    session.constants = helpers.constants
    session.state = helpers.state
    session.load = helpers.load
    return session
end

return Helpers
