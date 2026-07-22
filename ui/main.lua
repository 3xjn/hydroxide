local CoreGui = game:GetService("CoreGui")

local Runtime = import("ui/runtime")
local Interface = Runtime.GetInterface()

if oh.Cache["ui/main"] then
	return Interface
end

local VisualAssets = import("ui/assets")
local Theme = import("ui/theme")
local Window = import("ui/window")

local function isHydroxideInterface(instance)
	if not instance:IsA("ScreenGui") then
		return false
	end

	local base = instance:FindFirstChild("Base")
	return base ~= nil
		and instance:FindFirstChild("Open") ~= nil
		and base:FindFirstChild("Drag") ~= nil
		and base:FindFirstChild("Tabs") ~= nil
		and base:FindFirstChild("Status") ~= nil
end

local function destroyPreviousInterfaces(parent)
	for _index, instance in ipairs(parent:GetChildren()) do
		if isHydroxideInterface(instance) then
			instance:Destroy()
		end
	end
end

VisualAssets.Load()
local Base = Interface.Base
local Status = Base.Status

function oh.setStatus(text)
	Status.Text = 'Status  ·  ' .. text
end

function oh.getStatus()
	return Status.Text:gsub('Status  ·  ', '')
end

local TabSelector = import("ui/controls/TabSelector")
local MessageBox, MessageType = import("ui/controls/MessageBox")

local moduleLoaders = {
	{ Name = "RemoteSpy", Label = "Remote Spy", Path = "ui/modules/RemoteSpy" },
	{ Name = "ClosureSpy", Label = "Closure Spy", Path = "ui/modules/ClosureSpy" },
	{ Name = "ScriptScanner", Label = "Script Scanner", Path = "ui/modules/ScriptScanner" },
	{ Name = "ModuleScanner", Label = "Module Scanner", Path = "ui/modules/ModuleScanner" },
	{ Name = "UpvalueScanner", Label = "Upvalue Scanner", Path = "ui/modules/UpvalueScanner" },
	{ Name = "ConstantScanner", Label = "Constant Scanner", Path = "ui/modules/ConstantScanner" }
}
local failures = {}

for _index, moduleLoader in ipairs(moduleLoaders) do
	local success, result = xpcall(function()
		return import(moduleLoader.Path)
	end, function(err)
		return tostring(err)
	end)

	if not success then
		table.insert(failures, {
			Name = moduleLoader.Name,
			Label = moduleLoader.Label,
			Error = result
		})
	end
end

oh.LoadErrors = failures

local interfaceParent
if getHui then
	interfaceParent = getHui()
else
	if syn then
		syn.protect_gui(Interface)
	end

	interfaceParent = CoreGui
end

destroyPreviousInterfaces(interfaceParent)
Interface.Name = "Hydroxide"
oh.Interface = Interface
Interface.Parent = interfaceParent

Theme.Apply(Interface, VisualAssets)
TabSelector.SelectTab("Home")
Window.Attach(Interface)

if #failures > 0 then
	local summaries = {}
	for _index, failure in ipairs(failures) do
		local firstLine = failure.Error:match("^[^\r\n]+") or failure.Error
		table.insert(summaries, "• " .. failure.Label .. ": " .. firstLine)

		local tab = Interface.Base.Tabs.Container:FindFirstChild(failure.Name)
		if tab then
			tab.Visible = false
		end
	end

	MessageBox.Show(
		"Some tools could not start",
		"Hydroxide is still running, but the affected tools were disabled for this session:\n\n"
			.. table.concat(summaries, "\n")
			.. "\n\nScreenshot this message when reporting the bug.",
		MessageType.OK
	)
end

return Interface
