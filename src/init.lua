local log = require 'log'
local inspect = require 'inspect'
local fiber = require 'fiber'
local mysql = require('mysql')
local articles = require('articles')

local channels = {http_in = fiber.channel(10), http_in3 = fiber.channel(10)}

box.cfg{log_format = 'json'}

box.once('articles', function()
    log.info('======================box.once==========================')

    local articles = box.schema.space.create('articles', {
        engine = 'memtx',
        is_local = true,
        temporary = true
    })

    articles:format({
        {name = 'site_id', type = 'unsigned'},
        {name = 'entity_id', type = 'unsigned'}
        -- {name = 'create_at', type = 'unsigned'}
        -- {name = 'title', type = 'string'}
    })

    articles:create_index('primary', {type = 'hash', parts = {'site_id'}})
end)

-- box.schema.user.grant('guest', 'read,write,execute', 'universe')

local pool = mysql.pool_create({
    host = 'dbstorage',
    user = 'root',
    password = 'qwerty',
    db = 'tester',
    size = 5
})

local mysql_conn = pool:get()

-- local function recovery_records()
--     local res, err = conn:execute('select * from articles')
--     box.space.articles:insert({res.siteId, res.id})
-- end

local ok, data, err = pcall(mysql_conn.execute, mysql_conn,
                            'select * from articles')
if not ok then log.error("failed getting data from mysql " .. data) end

pool:put(mysql_conn)

local res = data[1][1] -- WTF

box.space.articles:insert({res.siteId, 2})

print(inspect(res.siteId))
print(inspect(err))

local d = box.space.articles:select{100500}
log.info("===FROM TUPLE" .. inspect(d))

local writerDB
writerDB = fiber.create(function()
    local msg
    local buffer = ""
    while true do
        log.info("===== while true do START len=" .. buffer:len())

        log.info("===== 65")

        if buffer:len() == 0 then
            log.info("===== INFINITY")
            msg = channels.http_in:get()
        else
            log.info("===== TIMEOUT 15")
            msg = channels.http_in:get(15)
        end

        log.info("===== 73")

        if msg == nil then
            log.info("===== ENDING send to DB ")
            buffer = ""
            -- writerDB.
            fiber.yield()
        else
            buffer = buffer .. "+" .. msg
            log.info("===== BUFFER: " .. buffer:len())
        end

        if buffer:len() >= 15 then
            log.info("===== send to DB ")
            buffer = ""
        end

        log.info("===== while true do END")
    end
end)

local function http_handler(ctx)
    log.info("count fibers " .. writerDB.status())
    local ok = channels.http_in:put("test")
    return {status = 200, body = 'test' .. inspect(ok)}
end

local function ocuppy_conn()
    local c = pool:get()
    log.info("=====ocuppy connection" .. inspect(c))

    local ok, data, err = pcall(c.execute, c, 'select sleep(2)')
    if not ok then log.error("failed query mysql " .. data) end
    pool:put(c)
end

local function http_handler2(ctx)
    ocuppy_conn()
    return {status = 200, body = 'test'}
end

local func_worker3
func_worker3 = function()
    local msg = channels.http_in3:get()
    log.info("@@@@@@@@@@ WORK fiber three +++ " .. msg)
    return func_worker3()
end

local function func_worker4()
    local msg = channels.http_in3:get()
    log.info("@@@@@@@@@@ WORK fiber three +++ " .. msg)
    return func_worker4()
end

local w = {channel = "", work = "", shutdown = "", ctx = {}}

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

local function test_worker(ctx, msg)
    local s = ctx + msg
    log.info("@@@@@@@@@@ Worker WORK @@@@@@@ " .. s)
    return s
end

local worker3 = fiber.create(consumer, channels.http_in3, test_worker, 1)

local function http_handler3(ctx)
    local id = ctx:stash("id")
    local ok = channels.http_in3:put(tonumber(id))
    return {status = 200, body = ' done \n'}
end

local function http_handler4(ctx)
    return {
        status = 200,
        body = ' test3 ' .. inspect(worker3:status()) .. ' \n'
    }
end

local function http_handler5(ctx)

    -- log.info('=== http_handler5' .. inspect(ctx))
    log.info('=== http_handler5' .. inspect(ctx:header("x-req-id")))
    -- print(inspect(ctx:header("x-req-id")))
    local id = ctx:stash('id')
    -- local res = articles.article_request_in(nil, {type = 'msg', body = id})
    return {status = 200, body = ' test3 ' .. inspect(id) .. ' \n'}
end

local httpd = require('http.server').new('0.0.0.0', 9000, {})
httpd:route({path = '/', method = 'GET'}, http_handler)
httpd:route({path = '/2', method = 'GET'}, http_handler2)
httpd:route({path = '/put/:id', method = 'GET'}, http_handler3)
httpd:route({path = '/get', method = 'GET'}, http_handler4)
httpd:route({path = '/close/:id', method = 'GET'}, http_handler5)
httpd:start()
