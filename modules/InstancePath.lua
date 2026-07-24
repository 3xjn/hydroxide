local InstancePath = {}

local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

local function parseQuoted(text, position)
    local quote = text:sub(position, position)
    if quote ~= '"' and quote ~= "'" then
        return nil, position, "Expected a quoted name"
    end

    local value = {}
    local index = position + 1
    while index <= #text do
        local character = text:sub(index, index)
        if character == quote then
            return table.concat(value), index + 1
        elseif character == "\\" then
            local escaped = text:sub(index + 1, index + 1)
            local replacements = {
                n = "\n",
                r = "\r",
                t = "\t",
                ["\\"] = "\\",
                ['"'] = '"',
                ["'"] = "'",
            }
            if escaped == "" then
                return nil, index, "Unterminated escape sequence"
            end

            table.insert(value, replacements[escaped] or escaped)
            index = index + 2
        else
            table.insert(value, character)
            index = index + 1
        end
    end

    return nil, position, "Unterminated quoted name"
end

local function skipWhitespace(text, position)
    local _, last = text:find("^%s*", position)
    return (last or position - 1) + 1
end

function InstancePath.Parse(source)
    local text = trim(source or "")
    if text == "" then
        return nil, "Enter an instance path"
    end

    local root
    local position
    if text:sub(1, 4) == "game" then
        root = "game"
        position = 5
    elseif text:sub(1, 9) == "workspace" then
        root = "workspace"
        position = 10
    else
        return nil, 'Paths must begin with "game" or "workspace"'
    end

    local segments = {}
    while position <= #text do
        position = skipWhitespace(text, position)
        if position > #text then
            break
        end

        local character = text:sub(position, position)
        if character == "." then
            local name = text:match("^([%a_][%w_]*)", position + 1)
            if not name then
                return nil, "Expected an instance member after position " .. position
            end

            table.insert(segments, {
                Kind = "Member",
                Name = name,
            })
            position = position + #name + 1
        elseif character == "[" then
            local name, nextPosition, parseError = parseQuoted(text, skipWhitespace(text, position + 1))
            if not name then
                return nil, parseError .. " at position " .. position
            end

            nextPosition = skipWhitespace(text, nextPosition)
            if text:sub(nextPosition, nextPosition) ~= "]" then
                return nil, "Expected ] after position " .. position
            end

            table.insert(segments, {
                Kind = "Member",
                Name = name,
            })
            position = nextPosition + 1
        elseif text:sub(position, position + 10) == ":GetService" then
            position = skipWhitespace(text, position + 11)
            if text:sub(position, position) ~= "(" then
                return nil, "Expected ( after GetService"
            end

            local name, nextPosition, parseError = parseQuoted(text, skipWhitespace(text, position + 1))
            if not name then
                return nil, parseError .. " in GetService"
            end

            nextPosition = skipWhitespace(text, nextPosition)
            if text:sub(nextPosition, nextPosition) ~= ")" then
                return nil, "Expected ) after GetService"
            end

            table.insert(segments, {
                Kind = "Service",
                Name = name,
            })
            position = nextPosition + 1
        else
            return nil, "Unsupported instance path syntax at position " .. position
        end
    end

    return {
        Root = root,
        Segments = segments,
    }
end

function InstancePath.Resolve(source, options)
    local parsed, parseError = InstancePath.Parse(source)
    if not parsed then
        return nil, parseError
    end

    local current = parsed.Root == "game" and options.Game or options.Workspace
    for _, segment in ipairs(parsed.Segments) do
        local succeeded
        local result
        if segment.Kind == "Service" then
            succeeded, result = pcall(options.GetService, segment.Name)
        else
            succeeded, result = pcall(options.GetMember, current, segment.Name)
        end

        if not succeeded or not options.IsInstance(result) then
            return nil, ('Could not resolve "%s" from %s'):format(segment.Name, source)
        end

        current = result
    end

    if not options.IsInstance(current) then
        return nil, "The path did not resolve to an Instance"
    end

    return current
end

return InstancePath
