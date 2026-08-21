local Prism = import("ui/prism")

local QueryBar = {}
local mounted = {}

local function copyFilter(values)
    return {
        ShowExecutor = values and values.ShowExecutor == true,
        ShowGame = not values or values.ShowGame ~= false,
        ShowRoblox = values and values.ShowRoblox == true,
    }
end

local function sync(bar)
    bar.Handle.update({
        kind = "queryBar",
        placeholder = bar.Placeholder,
        value = bar.Value,
        action = bar.Action,
        actionLabel = bar.ActionLabel,
        filter = bar.FilterValues,
        onChange = function(value)
            if bar.Value == value then
                return
            end
            bar.Value = value
            if bar.Changed then
                bar.Changed(value)
            end
            sync(bar)
        end,
        onSubmit = function(value)
            bar.Value = value
            if bar.Submitted then
                bar.Submitted(value)
            end
        end,
        onAction = function(value)
            bar.Value = value
            if bar.Actioned then
                bar.Actioned(value)
            end
        end,
        onFilterChange = function(values)
            bar.FilterValues = copyFilter(values)
            if bar.Filter.Callback then
                bar.Filter.Callback(bar.FilterValues)
            end
            sync(bar)
        end,
    })
end

function QueryBar.new(host, spec)
    spec = spec or {}
    if mounted[host] then
        return mounted[host]
    end

    local action = spec.action
    if action == false then
        action = nil
    elseif action == nil then
        action = host:GetAttribute("Action")
    end
    local bar = {
        Host = host,
        Placeholder = spec.placeholder or host:GetAttribute("Placeholder") or "",
        Value = spec.value or "",
        Action = action,
        ActionLabel = spec.actionLabel or host:GetAttribute("ActionLabel"),
        FilterValues = spec.filter and copyFilter(type(spec.filter) == "table" and spec.filter or nil) or nil,
        SetCallback = QueryBar.setFilterCallback,
        SetValues = QueryBar.setFilterValues,
        GetText = QueryBar.getText,
        SetText = QueryBar.setText,
        OnChange = QueryBar.onChange,
        OnSubmit = QueryBar.onSubmit,
        OnAction = QueryBar.onAction,
        SetFilterCallback = QueryBar.setFilterCallback,
        SetFilterValues = QueryBar.setFilterValues,
    }

    if bar.FilterValues then
        bar.Filter = bar
    end

    bar.Handle = Prism.mount(host, {
        kind = "queryBar",
        placeholder = bar.Placeholder,
        value = bar.Value,
        action = bar.Action,
        actionLabel = bar.ActionLabel,
        filter = bar.FilterValues,
    })
    sync(bar)

    mounted[host] = bar
    return bar
end

function QueryBar.getText(bar)
    return bar.Value
end

function QueryBar.setText(bar, value)
    bar.Value = value or ""
    sync(bar)
end

function QueryBar.onChange(bar, callback)
    bar.Changed = callback
    sync(bar)
end

function QueryBar.onSubmit(bar, callback)
    bar.Submitted = callback
    sync(bar)
end

function QueryBar.onAction(bar, callback)
    bar.Actioned = callback
    sync(bar)
end

function QueryBar.setFilterCallback(bar, callback)
    bar.Filter.Callback = callback
end

function QueryBar.setFilterValues(bar, values, notify)
    bar.FilterValues = copyFilter(values)
    sync(bar)
    if notify ~= false and bar.Filter.Callback then
        bar.Filter.Callback(bar.FilterValues)
    end
end

return QueryBar
