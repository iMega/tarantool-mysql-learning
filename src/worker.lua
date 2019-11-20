local fiber = require("fiber")
local log = require('log')

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

    local ok, result = pcall(worker.work, msg.ctx, worker.state, msg.input)
    if not ok then
        log.error('failed to start function of worker %s', worker.name)
    end

    if worker.channel_out:has_readers() then
        log.debug('attempt to put a message to channel of worker %s',
                  worker.name)
        ok = worker.channel_out:put(result, 60)
        if not ok then
            log.error('failed to put message in channel of worker %s %s',
                      worker.name, 'because no free slots or channel is closed.')
        end
    end

    return consumer(worker)
end

local function shutdownEmpty()
end

local function new(w)
    local channel_in = fiber.channel(w.size)
    local channel_out = fiber.channel()
    fiber.create(consumer, {
        name = w.name or '',
        channel_in = channel_in,
        channel_out = channel_out,
        work = w.work,
        state = w.state,
        shutdown = w.shutdown or shutdownEmpty,
        timeout = w.timeout,
    })

    return function(ctx, input)
        channel_in:put({ctx = ctx, input = input})
        return channel_out:get(w.response and w.response.timeout)
    end
end

return {new = new}
