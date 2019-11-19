local box = require('box')
box.cfg{feedback_enabled = false, log_format = 'json', log_level = 5}

-- local log = require('log')
local inspect = require('inspect')
local signal = require("posix.signal")
local http_server = require('http.server')
local http_router = require('http.router')
local mysqlpool = require('mysqlpool').new()
local articles = require('articles').new({db = mysqlpool.get_pool()})

box.once('articles', function()
    local articles_space = box.schema.space.create('articles', {
        engine = 'memtx',
        is_local = true,
        temporary = true,
    })

    articles_space:format({
        {name = 'site_id', type = 'unsigned'},
        {name = 'entity_id', type = 'unsigned'},
        {name = 'entity', type = 'string'},
        {name = 'create_at', type = 'string'},
        {name = 'update_at', type = 'string'},
        {name = 'is_deleted', type = 'boolean'},
    })

    articles_space:create_index('primary', {
        type = 'hash',
        parts = {1, 'unsigned', 2, 'unsigned'},
    })
end)

-- 2.2.1 not work
-- _ = box.ctl.on_shutdown(function()
--     log.warn("================= shutdown ===============")
-- end)

-- box.schema.user.grant('guest', 'read,write,execute', 'universe')

-- local function recovery_records()
--     local res, err = conn:execute('select * from articles')
--     box.space.articles:insert({res.siteId, res.id})
-- end

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

local is_shutdown = false

local function http_handler()
    return {
        status = 200,
        headers = {['content-type'] = 'application/json; charset=utf8'},
        body = 'root1  ' .. ' \n',
    }
end

signal.signal(signal.SIGTERM, function()
    is_shutdown = true
end)

local function article_save_handler(req)
    local res = articles.save({site_id = req.site_id, req_id = req.req_id},
                              req:json())
    return {status = 200, body = ' test3 ' .. inspect(res) .. ' \n'}
end

local function http_shutdown(req)
    if is_shutdown then
        return {status = 503}
    end
    return req:next()
end

local function http_set_context(req)
    local site_id = req:header('x-site-id')
    local req_id = req:header('x-req-id')
    if site_id == nil or req_id == nil then
        return {status = 400}
    end

    req.site_id = site_id
    req.req_id = req_id

    return req:next()
end

local function http_response_headers(req)
    local resp = req:next()
    if resp.headers == nil then
        resp.headers = {}
    end
    resp.headers['x-req-id'] = req.req_id
    resp.headers['content-type'] = 'application/json; charset=utf8'
    resp.headers['server'] = 'server'
    return resp
end

local router = http_router.new()
router:use(http_shutdown, {preroute = true, path = '.*', method = 'ANY'})
router:use(http_shutdown, {preroute = true, path = '/', method = 'ANY'})
router:use(http_set_context, {path = '.*', method = 'ANY'})
router:use(http_set_context, {path = '/', method = 'ANY'})
router:use(http_response_headers, {path = '.*', method = 'ANY'})
router:use(http_response_headers, {path = '/', method = 'ANY'})

router:route({path = '/', method = 'GET'}, http_handler)
router:route({path = '/save', method = 'POST'}, article_save_handler)

local httpd = http_server.new('0.0.0.0', 9000,
                              {log_requests = false, log_errors = true})
httpd:set_router(router)
httpd:start()
