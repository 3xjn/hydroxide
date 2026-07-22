local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local contextMenuSource = fs.readFile("ui/controls/ContextMenu.lua")
local mainSource = fs.readFile("ui/main.lua")
local runtimeSource = fs.readFile("ui/runtime.lua")
local themeSource = fs.readFile("ui/theme.lua")
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
assert(themeSource:find("PaneGap = 12", 1, true), "The list-detail panes must use a declared gap")
assert(themeSource:find("MinimumPageWidth = 400", 1, true), "Responsive reflow must preserve the primary tool pane")
assert(themeSource:find("TitleBarHeight = 44", 1, true), "The title bar must use compact chrome")
assert(themeSource:find("RailWidth = 52", 1, true), "The tool rail must use compact chrome")
assert(themeSource:find("TabTargetSize = 40", 1, true), "Tab targets must stay usable without oversized artwork")

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
local statusHeight = layoutNumber("StatusBarHeight")
local workspaceInset = layoutNumber("WorkspaceInset")
local paneGap = layoutNumber("PaneGap")
local explorerMin = layoutNumber("ExplorerMinWidth")
local explorerMax = layoutNumber("ExplorerMaxWidth")

assert(defaultWidth and defaultHeight and minimumWidth and minimumHeight, "Window size tokens must remain numeric")
local defaultBodyWidth = defaultWidth - railWidth - workspaceInset * 2
local defaultExplorerWidth = math.max(explorerMin, math.min(explorerMax, math.floor(defaultBodyWidth * 0.25 + 0.5)))
local defaultPageWidth = defaultBodyWidth - defaultExplorerWidth - paneGap
local minimumPageWidth = minimumWidth - railWidth - workspaceInset * 2 - explorerMin - paneGap
local minimumBodyHeight = minimumHeight - titleHeight - statusHeight - workspaceInset * 2

assert(defaultPageWidth >= 720, "The default primary workspace must not be crowded by Explorer")
assert(minimumPageWidth >= 400, "The minimum primary workspace must remain usable")
assert(minimumBodyHeight >= 320, "The minimum window must retain a usable content height")

print("ui-runtime-contracts-ok")
