local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local contextMenuSource = fs.readFile("ui/controls/ContextMenu.lua")
local assetsSource = fs.readFile("ui/assets.lua")
local mainSource = fs.readFile("ui/main.lua")
local runtimeSource = fs.readFile("ui/runtime.lua")
local themeSource = fs.readFile("ui/theme.lua")
local tabSelectorSource = fs.readFile("ui/controls/TabSelector.lua")
local windowSource = fs.readFile("ui/window.lua")

local imageButton = roblox.Instance.new("ImageButton")
local label = roblox.Instance.new("TextLabel")

local imageButtonAcceptsTextWrapped = pcall(function()
    imageButton.TextWrapped = false
end)
local labelAcceptsTextWrapped = pcall(function()
    label.TextWrapped = false
end)

assert(not imageButtonAcceptsTextWrapped, "ImageButton unexpectedly accepted TextWrapped")
assert(labelAcceptsTextWrapped, "TextLabel must accept TextWrapped")
assert(
    contextMenuSource:find("label.TextWrapped = false", 1, true),
    "Context menu wrapping must be configured on the row label"
)
assert(
    not contextMenuSource:find("buttonInstance.TextWrapped = false", 1, true),
    "Context menu rows are ImageButtons and cannot receive TextWrapped"
)
assert(
    not contextMenuSource:find("buttonInstance.Icon.AbsoluteSize", 1, true),
    "Context menu width must not depend on pre-parent AbsoluteSize"
)
assert(
    not contextMenuSource:find("buttonInstance.AbsoluteSize", 1, true),
    "Context menu height must not depend on pre-parent AbsoluteSize"
)

assert(mainSource:find("local moduleLoaders = {", 1, true), "Feature modules must have independent loader boundaries")
assert(mainSource:find("oh.LoadErrors = failures", 1, true), "Feature load errors must remain inspectable")
assert(
    not mainSource:find("Interface:Destroy()", 1, true),
    "A feature-module load error must not destroy the Hydroxide interface"
)

assert(themeSource:find("LauncherSize = 36", 1, true), "The collapsed launcher must use a compact 36px target")
assert(themeSource:find("LauncherIconSize = 18", 1, true), "The collapsed launcher artwork must retain internal padding")
assert(runtimeSource:find('image("Icon", open', 1, true), "The launcher logo must render inside a padded child")
assert(
    runtimeSource:find('local templates = frame("Templates", interface', 1, true),
    "Runtime templates must live under a hidden GuiObject so visible template rows cannot render across the viewport"
)
assert(
    runtimeSource:find('local templates = frame("Templates", interface, { Visible = false', 1, true),
    "The runtime template container must hide all stored GuiObjects without changing clone visibility"
)
assert(
    themeSource:find("assets.ApplyLogo(interface.Open.Icon)", 1, true),
    "The launcher logo must be applied to its child icon"
)
assert(
    not themeSource:find("assets.ApplyLogo(interface.Open)\n", 1, true),
    "The full launcher button must not be painted as the logo"
)
assert(
    not windowSource:find("local hideWindow = TweenService:Create(base", 1, true),
    "Collapse must not slide the full window through the viewport"
)
assert(windowSource:find("base.Visible = false", 1, true), "Collapse must atomically hide the full window")
assert(themeSource:find("WorkspaceInset = 12", 1, true), "The shell must use a consistent workspace inset")
assert(themeSource:find("MinimumPageWidth = 400", 1, true), "Responsive reflow must preserve the primary tool pane")
assert(themeSource:find("TitleBarHeight = 44", 1, true), "The title bar must use compact chrome")
assert(themeSource:find("RailWidth = 52", 1, true), "The tool rail must use compact chrome")
assert(themeSource:find("TabTargetSize = 40", 1, true), "Tab targets must stay usable without oversized artwork")
assert(
    runtimeSource:find('frame("Selection", tab', 1, true),
    "Every tool tab must expose a quiet leading-edge selection marker"
)
assert(
    tabSelectorSource:find("tab.Selection.Visible = true", 1, true),
    "The selected tab must display its semantic marker"
)
assert(
    tabSelectorSource:find("selectedTab.Selection.Visible = false", 1, true),
    "Changing tools must clear the previous selection marker"
)
assert(
    runtimeSource:find("0, Theme.Layout.WorkspaceInset", 1, true),
    "Rail content must share the workspace top inset"
)
assert(
    not themeSource:find("addStroke(page, Theme.Colors.Border)", 1, true),
    "Tool pages must not add a second card elevation"
)
assert(
    themeSource:find("tab.HydroxideStroke.Transparency = 1", 1, true),
    "Tool tabs must not render an outlined card in their default state"
)

local themeApply = assert(mainSource:find("Theme.Apply(Interface, VisualAssets)", 1, true))
local homeSelection = assert(mainSource:find('TabSelector.SelectTab("Home")', 1, true))
assert(themeApply < homeSelection, "Home selection must be applied after theming so it remains visible")
assert(not runtimeSource:find('frame("Explorer"', 1, true), "The inert Explorer pane must not consume workspace")
assert(not runtimeSource:find("Filter explorer ...", 1, true), "The inert Explorer filter must be removed")
assert(not windowSource:find("ShouldShowExplorer", 1, true), "Window layout must give the full workspace to the active tool")
assert(windowSource:find('createControl(drag, "Maximize"', 1, true), "Maximize must use the shared title control primitive")
assert(windowSource:find('createControl(drag, "Exit"', 1, true), "Exit must use the shared title control primitive")
assert(windowSource:find('corner.Name = "HydroxideCorner"', 1, true), "Title controls must share the shell corner treatment")
assert(windowSource:find('local resizeHandle = Instance.new("Frame")', 1, true), "The resize target must not be a button that overrides the custom cursor")
assert(windowSource:find("resizeHandle.MouseEnter:Connect", 1, true), "The resize target must show its cursor on hover")
assert(windowSource:find("resizeHandle.MouseLeave:Connect", 1, true), "The resize target must restore the previous cursor after hover")
assert(windowSource:find("UserInput.MouseIcon = VisualAssets.Load().ResizeCursor", 1, true), "The resize target must use generated cursor artwork")
assert(windowSource:find("WindowResizeCursorCleanup", 1, true), "Shutdown must restore a cursor owned by the resize target")
assert(windowSource:find("WindowFocusReleased:Connect", 1, true), "Losing Roblox focus must restore the resize cursor")
assert(assetsSource:find('ResizeCursor = installAsset("hydroxide-resize-cursor.png")', 1, true), "The resize cursor must load through getcustomasset")
assert(runtimeSource:find("ClipsDescendants = true", 1, true), "The shell must clip its chrome to the outer corner radius")
assert(runtimeSource:find("addCorner(drag, 8)", 1, true), "The opaque title bar must own the shell's top corner radius")
assert(runtimeSource:find('frame("SquareBottom", drag', 1, true), "The rounded title bar must square only its internal bottom edge")
assert(windowSource:find("drag.HydroxideCorner.CornerRadius", 1, true), "Maximized mode must flatten the title-bar corner mask")
assert(not runtimeSource:find('label("Status", base', 1, true), "The redundant visual status bar must not be built")
assert(not runtimeSource:find("StatusBarHeight", 1, true), "The removed status bar must not reserve page space")
assert(not themeSource:find("StatusBarHeight", 1, true), "The removed status bar must not retain a layout token")
assert(not themeSource:find("styleSurface(base.Status", 1, true), "The theme must not expect a removed status bar")
assert(not mainSource:find("Base.Status", 1, true), "The status API must not depend on removed UI")
assert(mainSource:find('local currentStatus = "Home Page"', 1, true), "Transient status state must remain available to feature modules")
assert(runtimeSource:find('local homeContent = frame("Content", home', 1, true), "Home content must use one responsive composition container")
assert(runtimeSource:find("listLayout(homeContent, Theme.Layout.HomeGap)", 1, true), "Home elements must reflow as a vertical stack")
assert(not runtimeSource:find("0.24, 0", 1, true), "Home elements must not use independent percentage positions that overlap when compact")
assert(runtimeSource:find("iconToggle(flags, flag, true)", 1, true), "Remote type filters must use compact icon toggles")
assert(not runtimeSource:find("checkbox(flags, flag, flag, true)", 1, true), "Remote type filters must not expose implementation class names")
assert(runtimeSource:find('image("Icon", refresh', 1, true), "Filter refresh must render a generated icon instead of a font glyph")
assert(assetsSource:find('RemoteAtlas = installAsset("hydroxide-remote-icons.png")', 1, true), "Generated Remote Spy icons must load through getcustomasset")
assert(assetsSource:find("function Assets.ApplyRemoteIcon", 1, true), "Remote Spy icons must use their own raster atlas mapping")
assert(not runtimeSource:find('frame("Selection", toggle', 1, true), "Remote type filters must not imitate tab selection with underlines")
assert(assetsSource:find('WindowAtlas = installAsset("hydroxide-window-icons.png")', 1, true), "Window controls must load their generated raster atlas")
assert(windowSource:find("VisualAssets.ApplyWindowIcon", 1, true), "Window controls must use the shared generated icon treatment")
assert(not windowSource:find('maximize.Text = "', 1, true), "Maximized state must not switch to a mismatched font glyph")
assert(windowSource:find("base.Position = UDim2.new(0, 0, 0, 0)", 1, true), "Maximized mode must sit flush to the viewport")
assert(windowSource:find("setShellMaximized", 1, true), "Maximized mode must remove normal rounded outer chrome")

local atomicHide = windowSource:find("base.Visible = false", 1, true)
local launcherShow = windowSource:find("open.Visible = true", 1, true)
assert(atomicHide and launcherShow and atomicHide < launcherShow, "The full window must hide before the launcher appears")

local defaultWidth, defaultHeight = themeSource:match("DefaultWindowSize = Vector2.new%((%d+), (%d+)%)")
local minimumWidth, minimumHeight = themeSource:match("MinimumWindowSize = Vector2.new%((%d+), (%d+)%)")
local function layoutNumber(name)
    return tonumber(themeSource:match(name .. " = (%d+)"))
end

defaultWidth = tonumber(defaultWidth)
defaultHeight = tonumber(defaultHeight)
minimumWidth = tonumber(minimumWidth)
minimumHeight = tonumber(minimumHeight)

local railWidth = layoutNumber("RailWidth")
local titleHeight = layoutNumber("TitleBarHeight")
local workspaceInset = layoutNumber("WorkspaceInset")
assert(defaultWidth and defaultHeight and minimumWidth and minimumHeight, "Window size tokens must remain numeric")
local defaultBodyWidth = defaultWidth - railWidth - workspaceInset * 2
local defaultPageWidth = defaultBodyWidth
local minimumPageWidth = minimumWidth - railWidth - workspaceInset * 2
local minimumBodyHeight = minimumHeight - titleHeight - workspaceInset * 2

assert(defaultPageWidth >= 720, "The default primary workspace must not be crowded by Explorer")
assert(minimumPageWidth >= 400, "The minimum primary workspace must remain usable")
assert(minimumBodyHeight >= 320, "The minimum window must retain a usable content height")

print("ui-runtime-contracts-ok")
