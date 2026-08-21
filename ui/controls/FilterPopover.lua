local QueryBar = import("ui/controls/QueryBar")

local FilterPopover = {}

function FilterPopover.new(query, _eventName)
    if query.Filter then
        return query.Filter
    end

    local bar = QueryBar.new(query, {
        placeholder = query:GetAttribute("Placeholder"),
        action = query:GetAttribute("Action") or "refresh",
        actionLabel = query:GetAttribute("ActionLabel"),
        filter = true,
    })
    return bar.Filter
end

FilterPopover.setCallback = QueryBar.setFilterCallback
FilterPopover.setValues = QueryBar.setFilterValues

return FilterPopover
