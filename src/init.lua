local log = require 'log'
local inspect = require 'inspect'
local fiber = require 'fiber'
local mysql = require('mysql')

local channels = {http_in = fiber.channel(10)}

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

function http_handler(ctx)
    log.info("count fibers " .. writerDB.status())
    local ok = channels.http_in:put("test")
    return {status = 200, body = 'test' .. inspect(ok)}
end

function http_handler2(ctx)
    log.info("http_handler2 = " .. writerDB.status())
    return {status = 200, body = 'test'}
end

local httpd = require('http.server').new('0.0.0.0', 9000, {})
httpd:route({path = '/', method = 'GET'}, http_handler)
httpd:route({path = '/2', method = 'GET'}, http_handler2)
httpd:start()
