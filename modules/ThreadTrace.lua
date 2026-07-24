local ThreadTrace = {}

function ThreadTrace.resolveFunction(thread, options)
    if not thread or type(options.GetStackFunction) ~= "function" then
        return nil
    end

    for level = 1, options.MaximumDepth or 16 do
        local succeeded, candidate = pcall(options.GetStackFunction, thread, level)
        if not succeeded or candidate == nil then
            return nil
        end

        if type(candidate) == "function" then
            local isGameClosure = not options.IsExecutorClosure
                or not options.IsExecutorClosure(candidate)
            local isLuaClosure = not options.IsLClosure
                or options.IsLClosure(candidate)
            if isGameClosure and isLuaClosure then
                return candidate
            end
        end
    end

    return nil
end

return ThreadTrace
