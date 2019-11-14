local fiber = require('fiber')

local function consumer(worker)
    local msg = worker.channel:get()
    if msg == nil then
        worker.shutdown(worker.ctx)
        return
    end
    local newCtx = worker(ctx, msg) or ctx
    worker.ctx = worker.work(worker.ctx)
    return consumer(worker)
end

local function create(w)
    local channel = fiber.channel(w.size or 0)
    fiber.create(consumer, {
        channel = channel,
        work = w.work,
        ctx = w.ctx,
        shutdown = w.shutdown
    })
    return channel
end

return {create = create}

