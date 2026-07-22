local Theme = import("ui/theme")

local Runtime = {}
local cached

local function create(className, name, parent, properties)
    local instance = Instance.new(className)
    instance.Name = name

    for property, value in pairs(properties or {}) do
        instance[property] = value
    end

    instance.Parent = parent
    return instance
end

local function addCorner(instance, radius)
    local corner = instance:FindFirstChild("HydroxideCorner")
    if not corner then
        corner = create("UICorner", "HydroxideCorner", instance)
    end
    corner.CornerRadius = UDim.new(0, radius or 5)
    return corner
end

local function addStroke(instance, color)
    local stroke = instance:FindFirstChild("HydroxideStroke")
    if not stroke then
        stroke = create("UIStroke", "HydroxideStroke", instance)
    end
    stroke.Color = color or Theme.Colors.Border
    stroke.Thickness = 1
    return stroke
end

local function addPadding(instance, left, right, top, bottom)
    return create("UIPadding", "Padding", instance, {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or left or 0)
    })
end

local function frame(name, parent, properties)
    properties = properties or {}
    properties.BackgroundColor3 = properties.BackgroundColor3 or Theme.Colors.Panel
    properties.BorderSizePixel = 0
    return create("Frame", name, parent, properties)
end

local function label(name, parent, text, properties)
    properties = properties or {}
    properties.BackgroundTransparency = properties.BackgroundTransparency or 1
    properties.BorderSizePixel = 0
    properties.Font = properties.Font or Enum.Font.Gotham
    properties.Text = text or ""
    properties.TextColor3 = properties.TextColor3 or Theme.Colors.Text
    properties.TextSize = properties.TextSize or 14
    return create("TextLabel", name, parent, properties)
end

local function textButton(name, parent, text, properties)
    properties = properties or {}
    properties.AutoButtonColor = false
    properties.BackgroundColor3 = properties.BackgroundColor3 or Theme.Colors.Elevated
    properties.BorderSizePixel = 0
    properties.Font = properties.Font or Enum.Font.Gotham
    properties.Text = text or ""
    properties.TextColor3 = properties.TextColor3 or Theme.Colors.Text
    properties.TextSize = properties.TextSize or 14
    local button = create("TextButton", name, parent, properties)
    addCorner(button, 5)
    addStroke(button)
    return button
end

local function image(name, parent, properties)
    properties = properties or {}
    properties.BackgroundTransparency = properties.BackgroundTransparency or 1
    properties.BorderSizePixel = 0
    properties.ScaleType = properties.ScaleType or Enum.ScaleType.Fit
    return create("ImageLabel", name, parent, properties)
end

local function imageButton(name, parent, properties)
    properties = properties or {}
    properties.AutoButtonColor = false
    properties.BackgroundColor3 = properties.BackgroundColor3 or Theme.Colors.Elevated
    properties.BorderSizePixel = 0
    properties.Image = properties.Image or ""
    local button = create("ImageButton", name, parent, properties)
    addCorner(button, 5)
    addStroke(button)
    return button
end

local function listLayout(parent, padding, horizontal)
    return create("UIListLayout", "Layout", parent, {
        FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
        HorizontalAlignment = horizontal and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, padding or 6)
    })
end

local function scrollingContent(parent, name)
    local contentOffset = Theme.Layout.QueryHeight + 8
    local results = frame(name or "Results", parent, {
        Position = UDim2.new(0, 0, 0, contentOffset),
        Size = UDim2.new(1, 0, 1, -contentOffset),
        BackgroundTransparency = 1
    })
    local clip = frame("Clip", results, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    })
    local content = create("ScrollingFrame", "Content", clip, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Colors.MutedText
    })
    listLayout(content, 6)
    return results, clip, content
end

local function queryBar(parent, placeholder, buttonSearch)
    local queryHeight = Theme.Layout.QueryHeight
    local query = frame("Query", parent, {
        Size = UDim2.new(1, 0, 0, queryHeight),
        BackgroundTransparency = 1
    })

    if buttonSearch then
        local input = create("TextBox", "Query", query, {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, -104, 0, queryHeight),
            BackgroundColor3 = Theme.Colors.Elevated,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Font = Enum.Font.Code,
            PlaceholderColor3 = Theme.Colors.MutedText,
            PlaceholderText = placeholder,
            Text = "",
            TextColor3 = Theme.Colors.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        addCorner(input, 5)
        addStroke(input)
        addPadding(input, 12, 12, 0, 0)
        textButton("Search", query, "Search", {
            Position = UDim2.new(1, -92, 0, 0),
            Size = UDim2.new(0, 92, 0, queryHeight),
            BackgroundColor3 = Theme.Colors.AccentSurface,
            TextColor3 = Theme.Colors.Accent
        })
    else
        local search = create("TextBox", "Search", query, {
            Size = UDim2.new(1, -44, 0, queryHeight),
            BackgroundColor3 = Theme.Colors.Elevated,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Font = Enum.Font.Code,
            PlaceholderColor3 = Theme.Colors.MutedText,
            PlaceholderText = placeholder,
            Text = "",
            TextColor3 = Theme.Colors.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        addCorner(search, 5)
        addStroke(search)
        addPadding(search, 12, 12, 0, 0)
        textButton("Refresh", query, "↻", {
            Position = UDim2.new(1, -36, 0, 0),
            Size = UDim2.new(0, 36, 0, queryHeight),
            TextSize = 18
        })
    end

    return query
end

local function actionButton(parent, name, text)
    local button = textButton(name, parent, "", {
        Size = UDim2.new(0, 112, 0, 32)
    })
    image("Icon", button, {
        Position = UDim2.new(0, 8, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16)
    })
    label("Label", button, text, {
        Position = UDim2.new(0, 30, 0, 0),
        Size = UDim2.new(1, -38, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    return button
end

local function objectLabel(parent, name)
    local object = frame(name, parent, {
        Size = UDim2.new(0, 180, 0, 32),
        BackgroundTransparency = 1
    })
    image("Icon", object, {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, 0, 0.5, -10)
    })
    label("Label", object, "", {
        Position = UDim2.new(0, 26, 0, 0),
        Size = UDim2.new(1, -26, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    return object
end

local function checkbox(parent, name, text, enabled)
    local root = frame(name, parent, {
        Size = UDim2.new(0, 136, 0, 32),
        BackgroundTransparency = 1
    })
    local toggle = textButton("Toggle", root, "", {
        Position = UDim2.new(0, 0, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = Theme.Colors.Elevated
    })
    label("Label", toggle, enabled and "✓" or "", {
        Size = UDim2.new(1, 0, 1, 0),
        TextColor3 = Theme.Colors.Accent,
        TextSize = 14
    })
    label("Text", root, text, {
        Position = UDim2.new(0, 28, 0, 0),
        Size = UDim2.new(1, -28, 1, 0),
        TextColor3 = Theme.Colors.SecondaryText,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    return root
end

local function dropdown(parent, name, options)
    local root = frame(name, parent, {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Colors.Elevated
    })
    addCorner(root, 5)
    addStroke(root)
    label("Label", root, options[1] or "Select", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -72, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local icon = image("Icon", root, {
        Position = UDim2.new(1, -58, 0.5, -9),
        Size = UDim2.new(0, 18, 0, 18)
    })
    image("Border", icon, { Size = UDim2.new(1, 0, 1, 0) })
    textButton("Collapse", root, "⌄", {
        Position = UDim2.new(1, -36, 0, 0),
        Size = UDim2.new(0, 36, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = Theme.Colors.SecondaryText
    })
    local selection = frame("Selection", root, {
        Position = UDim2.new(0, 0, 1, 6),
        Size = UDim2.new(1, 0, 0, math.max(36, #options * 32)),
        BackgroundColor3 = Theme.Colors.Elevated,
        Visible = false,
        ZIndex = 80
    })
    addCorner(selection, 5)
    addStroke(selection)
    local clip = frame("Clip", selection, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 })
    local list = frame("List", clip, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 })
    listLayout(list, 0)
    for index, option in ipairs(options) do
        textButton(option, list, option, {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            LayoutOrder = index,
            TextXAlignment = Enum.TextXAlignment.Left
        })
    end
    return root
end

local function scannerPage(pages, name, placeholder, buttonSearch)
    local page = frame(name, pages, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Colors.Panel,
        Visible = false
    })
    addPadding(page, Theme.Layout.PagePadding)
    queryBar(page, placeholder, buttonSearch)
    scrollingContent(page)
    return page
end

local function spySubview(page, name, objectName)
    local view = frame(name, page, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false
    })
    textButton("Back", view, "‹ Back", {
        Size = UDim2.new(0, 88, 0, 32),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    objectLabel(view, objectName).Position = UDim2.new(1, -180, 0, 0)
    local buttons = frame("Buttons", view, {
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1
    })
    listLayout(buttons, 8, true)
    if name == "Logs" then
        actionButton(buttons, "Ignore", "Ignore")
        actionButton(buttons, "Block", "Block")
        actionButton(buttons, "Clear", "Clear")
        actionButton(buttons, "Conditions", "Conditions")
    else
        actionButton(buttons, "New", "New condition")
    end
    local results = scrollingContent(view)
    results.Position = UDim2.new(0, 0, 0, 80)
    results.Size = UDim2.new(1, 0, 1, -80)
    return view
end

local function spyPage(pages, name, objectName, withFlags)
    local page = frame(name, pages, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Colors.Panel,
        Visible = false
    })
    addPadding(page, Theme.Layout.PagePadding)
    local list = frame("List", page, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 })
    local contentOffset = Theme.Layout.QueryHeight + 8
    local queryOffset = 0
    if withFlags then
        local flags = frame("Flags", list, { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1 })
        listLayout(flags, 8, true)
        for _, flag in ipairs({ "RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction" }) do
            checkbox(flags, flag, flag, true)
        end
        queryOffset = 40
    end
    local query = queryBar(list, "Type to filter...", false)
    query.Position = UDim2.new(0, 0, 0, queryOffset)
    local results = scrollingContent(list)
    results.Position = UDim2.new(0, 0, 0, queryOffset + contentOffset)
    results.Size = UDim2.new(1, 0, 1, -(queryOffset + contentOffset))
    spySubview(page, "Logs", objectName)
    spySubview(page, "Conditions", objectName)
    return page
end

local function infoSection(parent, name)
    local section = frame(name, parent, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = name == "Protos"
    })
    queryBar(section, "Filter " .. name:lower() .. "...", false)
    local _, clip = scrollingContent(section)
    label("ResultStatus", clip, "No results", {
        Size = UDim2.new(1, 0, 0, 32),
        TextColor3 = Theme.Colors.MutedText,
        Visible = false
    })
    return section
end

local function scriptPage(pages)
    local page = frame("ScriptScanner", pages, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Colors.Panel,
        Visible = false
    })
    addPadding(page, Theme.Layout.PagePadding)
    local list = frame("List", page, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 })
    queryBar(list, "Filter scripts...", false)
    scrollingContent(list)

    local info = frame("Info", page, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false })
    textButton("Back", info, "‹ Back", { Size = UDim2.new(0, 88, 0, 32), BackgroundTransparency = 1 })
    objectLabel(info, "ScriptObject").Position = UDim2.new(1, -180, 0, 0)
    local options = frame("Options", info, { Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 })
    local optionsClip = frame("Clip", options, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 })
    local optionsContent = frame("Content", optionsClip, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 })
    listLayout(optionsContent, 8, true)
    for _, option in ipairs({ "Protos", "Constants", "Environment", "Source" }) do
        local button = textButton(option, optionsContent, "", { Size = UDim2.new(0, 112, 0, 32) })
        label("Label", button, option, { Size = UDim2.new(1, 0, 1, 0), TextTransparency = option == "Protos" and 0 or 0.2 })
    end
    local sections = frame("Sections", info, { Position = UDim2.new(0, 0, 0, 84), Size = UDim2.new(1, 0, 1, -84), BackgroundTransparency = 1 })
    for _, section in ipairs({ "Protos", "Constants", "Environment", "Source" }) do
        infoSection(sections, section)
    end
    return page
end

local function promptShell(prompts, name, title)
    local prompt = frame(name, prompts, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 420, 0, 360),
        BackgroundColor3 = Theme.Colors.Panel,
        Visible = false,
        ZIndex = 70
    })
    addCorner(prompt, 7)
    addStroke(prompt)
    label("Title", prompt, title, { Position = UDim2.new(0, 20, 0, 12), Size = UDim2.new(1, -40, 0, 32), TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left })
    local inner = frame("Inner", prompt, { Position = UDim2.new(0, 20, 0, 56), Size = UDim2.new(1, -40, 1, -76), BackgroundTransparency = 1 })
    local content = frame("Content", inner, { Size = UDim2.new(1, 0, 1, -48), BackgroundTransparency = 1 })
    local buttons = frame("Buttons", inner, { Position = UDim2.new(0, 0, 1, -40), Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 })
    return prompt, inner, content, buttons
end

local function inputField(parent, name, y)
    local root = frame(name, parent, { Position = UDim2.new(0, 0, 0, y), Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 })
    local input = create("TextBox", "Input", root, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Colors.Elevated,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.Code,
        Text = "",
        TextColor3 = Theme.Colors.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    addCorner(input, 5)
    addStroke(input)
    addPadding(input, 12, 12, 0, 0)
    return root
end

local function conditionPrompt(prompts, name, title)
    local prompt, _, content, buttons = promptShell(prompts, name, title)
    local index = frame("Index", content, { Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 })
    local indexValue = inputField(index, "Value", 0)
    indexValue.Size = UDim2.new(1, -80, 1, 0)
    indexValue.Input.Text = "1"
    textButton("Add", index, "+", { Position = UDim2.new(1, -72, 0, 0), Size = UDim2.new(0, 36, 0, 36) })
    textButton("Sub", index, "−", { Position = UDim2.new(1, -36, 0, 0), Size = UDim2.new(0, 36, 0, 36) })
    dropdown(content, "Status", { "Ignore", "Block" }).Position = UDim2.new(0, 0, 0, 48)
    dropdown(content, "Type", { "string", "number", "boolean", "table", "function", "userdata" }).Position = UDim2.new(0, 0, 0, 96)
    dropdown(content, "ValueType", { "Value", "Type" }).Position = UDim2.new(0, 0, 0, 144)
    inputField(content, "Value", 192)
    textButton("Add", buttons, "Add condition", { Position = UDim2.new(1, -208, 0, 0), Size = UDim2.new(0, 128, 0, 36), BackgroundColor3 = Theme.Colors.AccentSurface, TextColor3 = Theme.Colors.Accent })
    textButton("Cancel", buttons, "Cancel", { Position = UDim2.new(1, -72, 0, 0), Size = UDim2.new(0, 72, 0, 36) })
    return prompt
end

local function modifyPrompt(prompts, name, title, indexName)
    local prompt, inner, content, buttons = promptShell(prompts, name, title)
    local index = frame("Index", content, { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1 })
    label(indexName, index, "", { Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Left })
    dropdown(content, "Type", { "string", "number", "boolean", "table", "function", "userdata" }).Position = UDim2.new(0, 0, 0, 48)
    inputField(content, "Value", 96)
    local setCancel = frame("SetCancel", buttons, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 })
    textButton("Set", setCancel, "Set", { Position = UDim2.new(1, -152, 0, 0), Size = UDim2.new(0, 72, 0, 36), BackgroundColor3 = Theme.Colors.AccentSurface, TextColor3 = Theme.Colors.Accent })
    textButton("Cancel", setCancel, "Cancel", { Position = UDim2.new(1, -72, 0, 0), Size = UDim2.new(0, 72, 0, 36) })
    return prompt
end

local function rowTemplate(parent, name, height)
    return imageButton(name, parent, {
        Size = UDim2.new(1, -2, 0, height or 32),
        BackgroundColor3 = Theme.Colors.Elevated,
        Visible = true
    })
end

local function borderImage(parent)
    return image("Border", parent, { Size = UDim2.new(1, 0, 1, 0), ImageTransparency = 1 })
end

local function basicValueRow(parent, name)
    local row = rowTemplate(parent, name, 28)
    borderImage(row)
    label("Index", row, "", { Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0, 48, 1, 0), Font = Enum.Font.Code, TextColor3 = Theme.Colors.SecondaryText })
    image("Icon", row, { Position = UDim2.new(0, 60, 0.5, -8), Size = UDim2.new(0, 16, 0, 16) })
    label("Value", row, "", { Position = UDim2.new(0, 84, 0, 0), Size = UDim2.new(1, -92, 1, 0), Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Left })
    return row
end

local function buildTemplates(interface)
    local templates = frame("Templates", interface, { Visible = false, BackgroundTransparency = 1 })
    local controls = create("Folder", "Controls", templates)
    local contextButton = rowTemplate(controls, "ContextMenuButton", 34)
    image("Icon", contextButton, { Position = UDim2.new(0, 8, 0.5, -8), Size = UDim2.new(0, 16, 0, 16) })
    label("Label", contextButton, "", { Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(1, -40, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 0.2 })
    local contextMenu = frame("ContextMenu", controls, { BackgroundColor3 = Theme.Colors.Elevated, Visible = false, ZIndex = 90 })
    addCorner(contextMenu, 5)
    addStroke(contextMenu)
    local contextList = frame("List", contextMenu, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 })
    listLayout(contextList, 0)

    local remote = create("Folder", "RemoteSpy", templates)
    local remoteLog = rowTemplate(remote, "RemoteLog", 34)
    image("Icon", remoteLog, { Position = UDim2.new(0, 8, 0.5, -9), Size = UDim2.new(0, 18, 0, 18) })
    label("Calls", remoteLog, "0", { Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(0, 36, 1, 0), Font = Enum.Font.Code, TextColor3 = Theme.Colors.SecondaryText })
    label("Label", remoteLog, "", { Position = UDim2.new(0, 72, 0, 0), Size = UDim2.new(1, -80, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
    local remoteCall = rowTemplate(remote, "CallPod", 28)
    local remoteContents = frame("Contents", remoteCall, { Position = UDim2.new(0, 0, 0, 28), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 })
    listLayout(remoteContents, 5)
    local remoteArg = frame("RemoteArg", remote, { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 })
    image("Icon", remoteArg, { Position = UDim2.new(0, 8, 0.5, -8), Size = UDim2.new(0, 16, 0, 16) })
    label("Index", remoteArg, "", { Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(0, 36, 1, 0), Font = Enum.Font.Code })
    label("Label", remoteArg, "", { Position = UDim2.new(0, 72, 0, 0), Size = UDim2.new(1, -80, 1, 0), Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Left })

    local closure = create("Folder", "ClosureSpy", templates)
    local closureLog = rowTemplate(closure, "ClosureLog", 34)
    label("Name", closureLog, "", { Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -176, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
    local info = frame("Information", closureLog, { Position = UDim2.new(1, -168, 0, 0), Size = UDim2.new(0, 160, 1, 0), BackgroundTransparency = 1 })
    for index, field in ipairs({ "Protos", "Upvalues", "Constants" }) do
        label(field, info, "0", { Position = UDim2.new(0, (index - 1) * 52, 0, 0), Size = UDim2.new(0, 48, 1, 0), Font = Enum.Font.Code, TextColor3 = Theme.Colors.SecondaryText })
    end
    local closureCall = rowTemplate(closure, "CallPod", 28)
    local closureContents = frame("Contents", closureCall, { Position = UDim2.new(0, 0, 0, 28), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 })
    listLayout(closureContents, 5)
    local arg = remoteArg:Clone()
    arg.Name = "Arg"
    arg.Parent = closure

    local function conditionTemplate(parent)
        local condition = rowTemplate(parent, "ConditionPod", 34)
        local content = frame("Content", condition, { Size = UDim2.new(1, -72, 1, 0), BackgroundTransparency = 1 })
        local toggle = textButton("Toggle", content, "", { Position = UDim2.new(0, 6, 0.5, -10), Size = UDim2.new(0, 20, 0, 20) })
        label("Label", toggle, "✓", { Size = UDim2.new(1, 0, 1, 0), TextColor3 = Theme.Colors.Accent })
        label("Index", content, "", { Position = UDim2.new(0, 34, 0, 0), Size = UDim2.new(0, 44, 1, 0), Font = Enum.Font.Code })
        image("Type", content, { Position = UDim2.new(0, 82, 0.5, -8), Size = UDim2.new(0, 16, 0, 16) })
        label("Label", content, "", { Position = UDim2.new(0, 106, 0, 0), Size = UDim2.new(1, -112, 1, 0), Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Left })
        local identifiers = frame("Identifiers", condition, { Position = UDim2.new(1, -68, 0, 0), Size = UDim2.new(0, 68, 1, 0), BackgroundTransparency = 1 })
        image("ByType", identifiers, { Position = UDim2.new(0, 4, 0.5, -8), Size = UDim2.new(0, 16, 0, 16) })
        local status = image("Status", identifiers, { Position = UDim2.new(0, 32, 0.5, -8), Size = UDim2.new(0, 16, 0, 16) })
        image("Border", status, { Size = UDim2.new(1, 0, 1, 0) })
        return condition
    end
    conditionTemplate(remote)
    conditionTemplate(closure)

    local script = create("Folder", "ScriptScanner", templates)
    local function scannerLog(parent, name)
        local row = rowTemplate(parent, name, 34)
        label("Name", row, "", { Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -136, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
        label("Protos", row, "0", { Position = UDim2.new(1, -128, 0, 0), Size = UDim2.new(0, 56, 1, 0), Font = Enum.Font.Code, TextColor3 = Theme.Colors.SecondaryText })
        label("Constants", row, "0", { Position = UDim2.new(1, -68, 0, 0), Size = UDim2.new(0, 60, 1, 0), Font = Enum.Font.Code, TextColor3 = Theme.Colors.SecondaryText })
        return row
    end
    scannerLog(script, "ScriptLog")
    for _, podName in ipairs({ "ProtoPod", "ConstantPod" }) do
        local pod = rowTemplate(script, podName, 28)
        local information = frame("Information", pod, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 })
        label("Index", information, "", { Size = UDim2.new(0, 44, 1, 0), Font = Enum.Font.Code })
        image("Icon", information, { Position = UDim2.new(0, 48, 0.5, -8), Size = UDim2.new(0, 16, 0, 16) })
        label("Label", information, "", { Position = UDim2.new(0, 72, 0, 0), Size = UDim2.new(1, -80, 1, 0), Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Left })
    end

    local module = create("Folder", "ModuleScanner", templates)
    scannerLog(module, "ModuleLog")

    local constant = create("Folder", "ConstantScanner", templates)
    basicValueRow(constant, "Constant")
    local constantClosure = rowTemplate(constant, "ClosureLog", 34)
    label("Name", constantClosure, "", { Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 0, 28), TextXAlignment = Enum.TextXAlignment.Left })
    local constants = frame("Constants", constantClosure, { Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 })
    listLayout(constants, 5)

    local upvalue = create("Folder", "UpvalueScanner", templates)
    basicValueRow(upvalue, "Upvalue")
    local tableRow = basicValueRow(upvalue, "Table")
    local elements = frame("Elements", tableRow, { Position = UDim2.new(0, 0, 0, 28), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 })
    listLayout(elements, 5)
    local element = rowTemplate(upvalue, "Element", 28)
    borderImage(element)
    for index, field in ipairs({ "Index", "Value" }) do
        local group = frame(field, element, { Position = UDim2.new((index - 1) * 0.5, 0, 0, 0), Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1 })
        image("Icon", group, { Position = UDim2.new(0, 8, 0.5, -8), Size = UDim2.new(0, 16, 0, 16) })
        label("Label", group, "", { Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(1, -40, 1, 0), Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Left })
    end
    local upvalueClosure = rowTemplate(upvalue, "ClosureLog", 34)
    label("Name", upvalueClosure, "", { Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 0, 28), TextXAlignment = Enum.TextXAlignment.Left })
    local upvalues = frame("Upvalues", upvalueClosure, { Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 })
    listLayout(upvalues, 5)

    return templates
end

local function buildInterface()
    local interface = create("ScreenGui", "Hydroxide", nil, {
        DisplayOrder = 1000,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    local open = imageButton("Open", interface, {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, -Theme.Layout.LauncherSize - Theme.Layout.WorkspaceInset),
        Size = UDim2.new(0, Theme.Layout.LauncherSize, 0, Theme.Layout.LauncherSize),
        BackgroundColor3 = Theme.Colors.Elevated,
        Visible = false,
        ZIndex = 100
    })
    addCorner(open, 8)
    addStroke(open, Theme.Colors.Accent)
    image("Icon", open, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, Theme.Layout.LauncherIconSize, 0, Theme.Layout.LauncherIconSize),
        ZIndex = 101
    })

    local base = frame("Base", interface, {
        Position = UDim2.new(0, Theme.Layout.OuterMargin, 0, Theme.Layout.OuterMargin),
        Size = UDim2.new(0, Theme.Layout.DefaultWindowSize.X, 0, Theme.Layout.DefaultWindowSize.Y),
        BackgroundColor3 = Theme.Colors.Canvas,
        ClipsDescendants = false
    })
    addCorner(base, 8)
    addStroke(base)

    local drag = label("Drag", base, "", {
        Size = UDim2.new(1, 0, 0, Theme.Layout.TitleBarHeight),
        BackgroundColor3 = Theme.Colors.Rail,
        BackgroundTransparency = 0,
        TextColor3 = Theme.Colors.SecondaryText,
        ZIndex = 10
    })
    local brand = frame("Brand", drag, { Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0, 196, 1, 0), BackgroundTransparency = 1, ZIndex = 11 })
    image("Logo", brand, { Position = UDim2.new(0, 0, 0.5, -12), Size = UDim2.new(0, 24, 0, 24), ZIndex = 12 })
    label("Name", brand, "Hydroxide", { Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(0, 84, 1, 0), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 })
    label("Version", brand, "c.1", { Position = UDim2.new(0, 116, 0, 0), Size = UDim2.new(0, 40, 1, 0), TextColor3 = Theme.Colors.MutedText, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 })
    textButton("Collapse", drag, "×", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.new(0, Theme.Layout.ControlTargetSize, 0, Theme.Layout.ControlTargetSize), BackgroundTransparency = 1, TextSize = 16, ZIndex = 20 })

    local tabs = frame("Tabs", base, { Position = UDim2.new(0, 0, 0, Theme.Layout.TitleBarHeight), Size = UDim2.new(0, Theme.Layout.RailWidth, 1, -(Theme.Layout.TitleBarHeight + Theme.Layout.StatusBarHeight)), BackgroundColor3 = Theme.Colors.Rail })
    local tabContainer = frame("Container", tabs, { Position = UDim2.new(0, 6, 0, 8), Size = UDim2.new(1, -12, 1, -16), BackgroundTransparency = 1 })
    listLayout(tabContainer, Theme.Layout.TabGap)
    for index, tabName in ipairs({ "Home", "RemoteSpy", "ClosureSpy", "ScriptScanner", "ModuleScanner", "UpvalueScanner", "ConstantScanner" }) do
        local tab = imageButton(tabName, tabContainer, { Size = UDim2.new(0, Theme.Layout.TabTargetSize, 0, Theme.Layout.TabTargetSize), BackgroundColor3 = Theme.Colors.Rail, LayoutOrder = index })
        image("Icon", tab, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, Theme.Layout.TabIconSize, 0, Theme.Layout.TabIconSize) })
    end

    local body = frame("Body", base, {
        Position = UDim2.new(0, Theme.Layout.RailWidth + Theme.Layout.WorkspaceInset, 0, Theme.Layout.TitleBarHeight + Theme.Layout.WorkspaceInset),
        Size = UDim2.new(1, -(Theme.Layout.RailWidth + Theme.Layout.WorkspaceInset * 2), 1, -(Theme.Layout.TitleBarHeight + Theme.Layout.StatusBarHeight + Theme.Layout.WorkspaceInset * 2)),
        BackgroundTransparency = 1
    })
    local pages = frame("Pages", body, { Size = UDim2.new(1, -(Theme.Layout.ExplorerMaxWidth + Theme.Layout.PaneGap), 1, 0), BackgroundTransparency = 1 })
    local home = frame("Home", pages, { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.Colors.Panel, Visible = true })
    addPadding(home, Theme.Layout.PagePadding)
    label("Welcome", home, "Welcome to Hydroxide", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.24, 0), Size = UDim2.new(1, -48, 0, 32), TextSize = 22 })
    image("Logo", home, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.48, 0), Size = UDim2.new(0, 164, 0, 164) })
    label("Tagline", home, "forever better than racist dolphin's console", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.70, 0), Size = UDim2.new(1, -48, 0, 32), TextColor3 = Theme.Colors.SecondaryText, TextSize = 16 })
    spyPage(pages, "RemoteSpy", "RemoteObject", true)
    spyPage(pages, "ClosureSpy", "ClosureObject", false)
    scriptPage(pages)
    scannerPage(pages, "ModuleScanner", "Filter modules...", false)
    local upvaluePage = scannerPage(pages, "UpvalueScanner", "Closure name or constant...", true)
    local queryContentOffset = Theme.Layout.QueryHeight + 8
    local filters = frame("Filters", upvaluePage, { Position = UDim2.new(0, 0, 0, queryContentOffset), Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1 })
    checkbox(filters, "SearchInTables", "Search in tables", false)
    upvaluePage.Results.Position = UDim2.new(0, 0, 0, queryContentOffset + 40)
    upvaluePage.Results.Size = UDim2.new(1, 0, 1, -(queryContentOffset + 40))
    label("ResultStatus", upvaluePage.Results.Clip, "Results", { Size = UDim2.new(1, 0, 0, 32), TextColor3 = Theme.Colors.MutedText, Visible = false })
    scannerPage(pages, "ConstantScanner", "Closure name or constant...", true)

    local explorer = frame("Explorer", body, { Position = UDim2.new(1, -Theme.Layout.ExplorerMaxWidth, 0, 0), Size = UDim2.new(0, Theme.Layout.ExplorerMaxWidth, 1, 0), BackgroundColor3 = Theme.Colors.Panel })
    addCorner(explorer, 6)
    addStroke(explorer)
    local explorerSearch = create("TextBox", "Search", explorer, {
        Position = UDim2.new(0, 12, 0, 12),
        Size = UDim2.new(1, -24, 0, Theme.Layout.QueryHeight),
        BackgroundColor3 = Theme.Colors.Elevated,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderColor3 = Theme.Colors.MutedText,
        PlaceholderText = "Filter explorer ...",
        Text = "",
        TextColor3 = Theme.Colors.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    addCorner(explorerSearch, 5)
    addStroke(explorerSearch)
    addPadding(explorerSearch, 12, 12, 0, 0)

    local status = label("Status", base, "Status  ·  Home Page", { Position = UDim2.new(0, 0, 1, -Theme.Layout.StatusBarHeight), Size = UDim2.new(1, 0, 0, Theme.Layout.StatusBarHeight), BackgroundColor3 = Theme.Colors.Rail, BackgroundTransparency = 0, TextColor3 = Theme.Colors.MutedText, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })
    addPadding(status, 12, 12, 0, 0)

    local prompts = frame("Prompts", base, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 60 })
    frame("PromptShadow", prompts, { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, Visible = false, ZIndex = 60 })
    conditionPrompt(prompts, "NewRemoteCondition", "New remote condition")
    conditionPrompt(prompts, "NewClosureCondition", "New closure condition")
    modifyPrompt(prompts, "ModifyUpvalue", "Modify upvalue", "Number")
    modifyPrompt(prompts, "ModifyElement", "Modify element", "Data")

    local messageShadow = frame("MessageBoxShadow", base, { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, Visible = false, ZIndex = 90 })
    local message = frame("MessageBox", base, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 360, 0, 220), BackgroundColor3 = Theme.Colors.Panel, Visible = false, ZIndex = 91 })
    addCorner(message, 7)
    addStroke(message)
    label("Title", message, "", { Position = UDim2.new(0, 20, 0, 12), Size = UDim2.new(1, -40, 0, 32), TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 92 })
    local messageInner = frame("Inner", message, { Position = UDim2.new(0, 20, 0, 52), Size = UDim2.new(1, -40, 1, -72), BackgroundTransparency = 1, ZIndex = 92 })
    label("Message", messageInner, "", { Size = UDim2.new(1, 0, 1, -48), TextColor3 = Theme.Colors.SecondaryText, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 93 })
    local messageButtons = frame("Buttons", messageInner, { Position = UDim2.new(0, 0, 1, -40), Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, ZIndex = 93 })
    for _, groupName in ipairs({ "OK", "OKCancel", "YesNo" }) do
        local group = frame(groupName, messageButtons, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 94 })
        if groupName == "OK" then
            textButton("OK", group, "OK", { Position = UDim2.new(1, -72, 0, 0), Size = UDim2.new(0, 72, 0, 36), ZIndex = 95 })
        elseif groupName == "OKCancel" then
            textButton("OK", group, "OK", { Position = UDim2.new(1, -152, 0, 0), Size = UDim2.new(0, 72, 0, 36), ZIndex = 95 })
            textButton("Cancel", group, "Cancel", { Position = UDim2.new(1, -72, 0, 0), Size = UDim2.new(0, 72, 0, 36), ZIndex = 95 })
        else
            textButton("Yes", group, "Yes", { Position = UDim2.new(1, -152, 0, 0), Size = UDim2.new(0, 72, 0, 36), ZIndex = 95 })
            textButton("No", group, "No", { Position = UDim2.new(1, -72, 0, 0), Size = UDim2.new(0, 72, 0, 36), ZIndex = 95 })
        end
    end

    local contextMenus = frame("ContextMenus", interface, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 90 })
    local templates = buildTemplates(interface)
    return interface, templates, contextMenus
end

local function ensureRuntime()
    if not cached then
        local interface, templates, contextMenus = buildInterface()
        cached = {
            Interface = interface,
            Templates = templates,
            ContextMenus = contextMenus
        }
    end
    return cached
end

function Runtime.GetInterface()
    return ensureRuntime().Interface
end

function Runtime.GetTemplates()
    return ensureRuntime().Templates
end

function Runtime.GetContextMenus()
    return ensureRuntime().ContextMenus
end

return Runtime
