local ReactiveState = {}

function ReactiveState.new(initialValue)
    local value = initialValue
    local subscribers = {}
    local nextSubscriberId = 0
    local destroyed = false
    local state = {}

    function state:Get()
        return value
    end

    function state:Set(nextValue)
        if destroyed then
            return
        end

        value = nextValue

        local currentSubscribers = {}
        for subscriberId, callback in pairs(subscribers) do
            currentSubscribers[subscriberId] = callback
        end

        for subscriberId, callback in pairs(currentSubscribers) do
            if subscribers[subscriberId] == callback then
                callback(value)
            end
        end
    end

    function state:Subscribe(callback, emitCurrent)
        assert(type(callback) == "function", "ReactiveState subscriptions require a callback")

        if destroyed then
            return {
                Disconnect = function() end,
            }
        end

        nextSubscriberId = nextSubscriberId + 1
        local subscriberId = nextSubscriberId
        subscribers[subscriberId] = callback

        local connected = true
        local subscription = {}

        function subscription:Disconnect()
            if not connected then
                return
            end

            connected = false
            subscribers[subscriberId] = nil
        end

        if emitCurrent ~= false and not destroyed then
            callback(value)
        end

        return subscription
    end

    function state:Destroy()
        if destroyed then
            return
        end

        destroyed = true
        subscribers = {}
    end

    return state
end

return ReactiveState
