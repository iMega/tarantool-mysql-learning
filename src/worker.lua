local fiber = require("fiber")
local log = require("log")
local inspect = require('inspect')

local function consumer(worker)
    local msg

    if worker.timeout == nil then
        msg = worker.channel:get()
    else
        msg = worker.channel:get(worker.timeout)
    end

    -- if msg == nil then
    --     worker.shutdown(worker.state)
    --     return
    -- end

    if msg == nil then
        msg = {ctx = nil, input = nil}
    end

    local newState = worker.work(msg.ctx, worker.state, msg.input) or
                         worker.state

    worker.state = newState

    return consumer(worker)
end

local function shutdownEmpty()
end

local function create(w)
    log.info("===============CREATE WORKER=====================" ..
                 inspect(w.timeout))
    local channel = fiber.channel(w.size or 0)
    fiber.create(consumer, {
        channel = channel,
        work = w.work,
        state = w.state,
        shutdown = w.shutdown or shutdownEmpty,
        ctx = w.ctx,
        timeout = w.timeout,
    })
    return function(ctx, input)
        return channel:put({ctx = ctx, input = input})
    end
end

return {create = create}
