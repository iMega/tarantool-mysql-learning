local log = require 'log'
local inspect = require 'inspect'
local mysql = require('mysql')

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

-- local httpd = require('http.server').new('0.0.0.0', 9000, {})
-- httpd:route({path = '/dictionary/:record_name', method = 'GET'}, get_dictionary_record_handler)
-- httpd:start()
