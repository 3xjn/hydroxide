local Assets = {}

local cellSize = Vector2.new(64, 64)
local assetDirectory = "hydroxide/assets/" .. oh.Constants.SourceBranch .. "/ui-v1/"
local pngSignature = "\137PNG\r\n\26\n"
local loaded

local icons = {
    Home = Vector2.new(0, 0),
    RemoteSpy = Vector2.new(64, 0),
    ClosureSpy = Vector2.new(128, 0),
    ScriptScanner = Vector2.new(192, 0),
    ModuleScanner = Vector2.new(0, 64),
    UpvalueScanner = Vector2.new(64, 64),
    ConstantScanner = Vector2.new(128, 64)
}

local remoteIcons = {
    RemoteEvent = Vector2.new(0, 0),
    RemoteFunction = Vector2.new(64, 0),
    BindableEvent = Vector2.new(128, 0),
    BindableFunction = Vector2.new(192, 0),
    Refresh = Vector2.new(0, 64),
    Filter = Vector2.new(64, 64)
}

local windowIcons = {
    Collapse = Vector2.new(0, 0),
    Maximize = Vector2.new(64, 0),
    Restore = Vector2.new(128, 0),
    Exit = Vector2.new(192, 0),
    Resize = Vector2.new(0, 64)
}

local glyphs = {
    type = "ConstantScanner",
    status = "RemoteSpy",
    valueType = "ConstantScanner",
    block = "ConstantScanner",
    unblock = "ConstantScanner",
    ignore = "RemoteSpy",
    unignore = "RemoteSpy",
    LocalScript = "ScriptScanner",
    ModuleScript = "ModuleScanner",
    ScriptObject = "ScriptScanner",
    RemoteObject = "RemoteSpy",
    ClosureObject = "ClosureSpy",
    Ignore = "RemoteSpy",
    Block = "RemoteSpy",
    Clear = "ConstantScanner",
    Conditions = "RemoteSpy",
    New = "ConstantScanner",
    ["function"] = "ClosureSpy",
    ["table"] = "UpvalueScanner",
    ["string"] = "ConstantScanner",
    ["number"] = "ConstantScanner",
    ["boolean"] = "ConstantScanner",
    ["userdata"] = "ConstantScanner",
    ["vector"] = "ConstantScanner",
    ["integral"] = "ConstantScanner",
    ["thread"] = "ClosureSpy",
    ["nil"] = "ConstantScanner"
}

local function requireMethod(name)
    local method = oh.Methods[name]
    assert(method, "Hydroxide's new interface requires Volt's " .. name .. " filesystem method")
    return method
end

local function installAsset(fileName)
    local isFile = requireMethod("isFile")
    local readFile = requireMethod("readFile")
    local writeFile = requireMethod("writeFile")
    local getCustomAsset = requireMethod("getCustomAsset")
    local path = assetDirectory .. fileName

    if oh.Constants.IsDevelopment or not isFile(path) then
        local success, contents = pcall(game.HttpGetAsync, game, oh.Constants.AssetBaseUrl .. fileName)
        assert(success, "Hydroxide could not download " .. fileName .. ": " .. tostring(contents))
        assert(type(contents) == "string" and #contents > 8, "Hydroxide downloaded an invalid " .. fileName)
        writeFile(path, contents)
    end

    assert(isFile(path), "Hydroxide could not write " .. path .. " to Volt's workspace")

    local contents = readFile(path)
    assert(type(contents) == "string" and contents:sub(1, #pngSignature) == pngSignature, path .. " is not a valid PNG asset")

    local success, contentUrl = pcall(getCustomAsset, path)
    assert(success, "Hydroxide could not load " .. path .. " with getcustomasset: " .. tostring(contentUrl))
    assert(type(contentUrl) == "string" and contentUrl ~= "", "getcustomasset returned an invalid URL for " .. path)
    return contentUrl
end

function Assets.Load()
    if loaded then
        return loaded
    end

    loaded = {
        Atlas = installAsset("hydroxide-icons.png"),
        RemoteAtlas = installAsset("hydroxide-remote-icons.png"),
        WindowAtlas = installAsset("hydroxide-window-icons.png"),
        ResizeCursor = installAsset("hydroxide-resize-cursor.png"),
        Logo = installAsset("hydroxide-logo.png")
    }

    return loaded
end

function Assets.ApplyRemoteIcon(image, name)
    assert(image and (image:IsA("ImageLabel") or image:IsA("ImageButton")), "ApplyRemoteIcon requires an image instance")

    local offset = remoteIcons[name]
    assert(offset, "Hydroxide has no generated Remote Spy icon named " .. tostring(name))

    image.Image = Assets.Load().RemoteAtlas
    image.ImageRectOffset = offset
    image.ImageRectSize = cellSize
    image.ScaleType = Enum.ScaleType.Fit
end

function Assets.ApplyWindowIcon(image, name)
    assert(image and (image:IsA("ImageLabel") or image:IsA("ImageButton")), "ApplyWindowIcon requires an image instance")

    local offset = windowIcons[name]
    assert(offset, "Hydroxide has no generated window icon named " .. tostring(name))

    image.Image = Assets.Load().WindowAtlas
    image.ImageRectOffset = offset
    image.ImageRectSize = cellSize
    image.ScaleType = Enum.ScaleType.Fit
end

function Assets.ApplyIcon(image, name)
    assert(image and (image:IsA("ImageLabel") or image:IsA("ImageButton")), "ApplyIcon requires an image instance")

    local offset = icons[name]
    assert(offset, "Hydroxide has no generated icon named " .. tostring(name))

    image.Image = Assets.Load().Atlas
    image.ImageRectOffset = offset
    image.ImageRectSize = cellSize
    image.ScaleType = Enum.ScaleType.Fit
end

function Assets.ApplyLogo(image)
    assert(image and (image:IsA("ImageLabel") or image:IsA("ImageButton")), "ApplyLogo requires an image instance")

    image.Image = Assets.Load().Logo
    image.ImageRectOffset = Vector2.new(0, 0)
    image.ImageRectSize = Vector2.new(0, 0)
    image.ImageColor3 = Color3.fromRGB(255, 255, 255)
    image.ScaleType = Enum.ScaleType.Fit
end

function Assets.ApplyGlyph(image, name)
    if remoteIcons[name] then
        return Assets.ApplyRemoteIcon(image, name)
    end

    if windowIcons[name] then
        return Assets.ApplyWindowIcon(image, name)
    end

    local iconName = glyphs[name] or (icons[name] and name) or "ConstantScanner"
    Assets.ApplyIcon(image, iconName)
end

function Assets.ApplyType(image, valueType)
    Assets.ApplyGlyph(image, valueType)
end

Assets.Icons = icons
Assets.RemoteIcons = remoteIcons
Assets.WindowIcons = windowIcons
return Assets
