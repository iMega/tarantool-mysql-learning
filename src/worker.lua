local fiber = require('fiber')

local function consumer(worker)
    local msg = worker.channel:get()
    if msg == nil then
        worker.shutdown(worker.state)
        return
    end
    local newState = worker.work(msg.ctx, worker.state, msg.input) or
                         worker.state
    worker.state = newState
    return consumer(worker)
end

local function shutdownEmpty() end

local function create(w)
    local channel = fiber.channel(w.size or 0)
    fiber.create(consumer, {
        channel = channel,
        work = w.work,
        state = w.state,
        shutdown = w.shutdown or shutdownEmpty,
        ctx = w.ctx
    })
    return function(ctx, input)
        return channel:put({ctx = ctx, input = input})
    end
end

return {create = create}

