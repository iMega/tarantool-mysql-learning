local box = require('box')
box.cfg{log_format = 'json'}

local log = require('log')
local inspect = require('inspect')
local articles = require('articles')
local http_server = require('http.server')
-- local http_server = require('http.nginx_server')
local http_router = require('http.router')
local mysqlpool = require('mysqlpool').new()

box.once('articles', function()
    log.info('======================box.once==========================')

    local articles = box.schema.space.create('articles', {
        engine = 'memtx',
        is_local = true,
        temporary = true,
    })

    articles:format({
        {name = 'site_id', type = 'unsigned'},
        {name = 'entity_id', type = 'unsigned'},
        -- {name = 'create_at', type = 'unsigned'}
        -- {name = 'title', type = 'string'}
    })

    articles:create_index('primary', {type = 'hash', parts = {'site_id'}})
end)

-- 2.2.1 not work
-- _ = box.ctl.on_shutdown(function()
--     log.warn("================= shutdown ===============")
-- end)

-- box.schema.user.grant('guest', 'read,write,execute', 'universe')

-- local pool = mysql.pool_create({
--     host = 'dbstorage',
--     user = 'root',
--     password = 'qwerty',
--     db = 'tester',
--     size = 5
-- })

-- local mysql_conn = pool:get()

-- local function recovery_records()
--     local res, err = conn:execute('select * from articles')
--     box.space.articles:insert({res.siteId, res.id})
-- end

-- local ok, data, err = pcall(mysql_conn.execute, mysql_conn,
--                             'select * from articles')
-- if not ok then log.error("failed getting data from mysql " .. data) end

-- pool:put(mysql_conn)

-- local res = data[1][1] -- WTF

-- box.space.articles:insert({res.siteId, 2})

-- print(inspect(res.siteId))
-- print(inspect(err))

-- local d = box.space.articles:select{100500}
-- log.info("===FROM TUPLE" .. inspect(d))

-- local writerDB
-- writerDB = fiber.create(function()
--     local msg
--     local buffer = ""
--     while true do
--         log.info("===== while true do START len=" .. buffer:len())

--         log.info("===== 65")

--         if buffer:len() == 0 then
--             log.info("===== INFINITY")
--             msg = channels.http_in:get()
--         else
--             log.info("===== TIMEOUT 15")
--             msg = channels.http_in:get(15)
--         end

--         log.info("===== 73")

--         if msg == nil then
--             log.info("===== ENDING send to DB ")
--             buffer = ""
--             -- writerDB.
--             fiber.yield()
--         else
--             buffer = buffer .. "+" .. msg
--             log.info("===== BUFFER: " .. buffer:len())
--         end

--         if buffer:len() >= 15 then
--             log.info("===== send to DB ")
--             buffer = ""
--         end

--         log.info("===== while true do END")
--     end
-- end)

-- local function http_handler(ctx)
--     log.info("count fibers " .. writerDB.status())
--     local ok = channels.http_in:put("test")
--     return {status = 200, body = 'test' .. inspect(ok)}
-- end

-- local function ocuppy_conn()
--     local c = pool:get()
--     log.info("=====ocuppy connection" .. inspect(c))

--     local ok, data, err = pcall(c.execute, c, 'select sleep(2)')
--     if not ok then log.error("failed query mysql " .. data) end
--     pool:put(c)
-- end

-- local function http_handler2(ctx)
--     ocuppy_conn()
--     return {status = 200, body = 'test'}
-- end

-- local func_worker3
-- func_worker3 = function()
--     local msg = channels.http_in3:get()
--     log.info("@@@@@@@@@@ WORK fiber three +++ " .. msg)
--     return func_worker3()
-- end

-- local function func_worker4()
--     local msg = channels.http_in3:get()
--     log.info("@@@@@@@@@@ WORK fiber three +++ " .. msg)
--     return func_worker4()
-- end

-- local function http_handler3(ctx)
--     local id = ctx:stash("id")
--     local ok = channels.http_in3:put(tonumber(id))
--     return {status = 200, body = ' done \n'}
-- end

local is_shutdown = false

local function http_handler(ctx)
    -- log.info('====== http_handler =======')

    if is_shutdown then
        return {status = 503, body = 'is_shutdown  ' .. ' \n'}
    end

    -- local pool = mysqlpool.get_pool()
    -- local conn = pool:get()

    -- log.info('======http_handler1===========')
    -- local tuples, status = conn:execute("SELECT SLEEP(30)")
    -- log.info('======http_handler2===========' .. inspect(tuples))
    -- log.info('======http_handler3===========' .. inspect(status))
    -- pool:put(conn)

    -- log.info('======http_handler1===========' .. inspect(conn))
    -- log.info('======http_handler2===========' .. inspect(conn:ping()))
    -- log.info('======http_handler3===========' .. inspect(status))
    return {
        status = 200,
        headers = {
            ['server'] = 'trololo',
            ['content-type'] = 'application/json; charset=utf8',
        },
        body = 'root  ' .. ' \n',
    }
end

-- local function pinger()
--     log.info('====== PINGER ======= %s', box.info.status)
-- end
-- worker.create({size = 1, work = pinger, timeout = 1})

local signal = require("posix.signal")
signal.signal(signal.SIGTERM, function(signum)
    log.info('====== SIGNAL ======= %d', signum)
    is_shutdown = true
    -- httpd:stop()
end)

local function article_save_handler_out(ctx, state, input)

end

local function article_save_handler(ctx)
    local res = "1"
    articles.article_request_in({}, ctx:json())
    return {status = 200, body = ' test3 ' .. inspect(res) .. ' \n'}
end

-- хрень
-- local function before_dispatch(httpd, req)
--     log.info('====== before_dispatch =======')
-- end
-- httpd:hook('before_dispatch', before_dispatch)
local httpd = http_server.new('0.0.0.0', 9000,
                              {log_requests = true, log_errors = true})
-- local httpd = http_server.new({
--     host = '0.0.0.0',
--     port = 9000,
--     tnt_method = 'nginx_entrypoint',
--     log_requests = true,
--     log_errors = true,
-- })
local router = http_router.new()
httpd:set_router(router)
router:route({path = '/', method = 'GET'}, http_handler)
router:route({path = '/article/save', method = 'POST'}, article_save_handler)
httpd:start()
