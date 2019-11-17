local fiber = require("fiber")

local function consumer(worker)
    local msg

    if worker.timeout == nil then
        msg = worker.channel_in:get()
    else
        msg = worker.channel_in:get(worker.timeout)
    end

    if msg == nil then
        msg = {ctx = nil, input = nil}
    end

    -- TODO need append system message for shutdown
    -- worker.shutdown(worker.state)

    local result = worker.work(msg.ctx, worker.state, msg.input)
    worker.channel_out:put(result)

    return consumer(worker)
end

local function shutdownEmpty()
end

local function new(w)
    local channel_in = fiber.channel(w.size or 0)
    local channel_out = fiber.channel()
    fiber.create(consumer, {
        channel_in = channel_in,
        channel_out = channel_out,
        work = w.work,
        state = w.state,
        shutdown = w.shutdown or shutdownEmpty,
        timeout = w.timeout,
    })

    return function(ctx, input)
        channel_in:put({ctx = ctx, input = input})
        return channel_out:get()
    end
end

return {new = new}
