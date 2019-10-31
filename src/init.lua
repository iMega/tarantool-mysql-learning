local inspect = require 'inspect'
local mysql = require('mysql')

box.cfg{}

box.once('articles', function()
    print('======================1==========================')

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

    print('======================2==========================')
    articles:create_index('primary', {type = 'hash', parts = {'site_id'}})
end)

-- box.schema.user.grant('guest', 'read,write,execute', 'universe')
print('======================3==========================')

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

-- local status, data, err = pcall(self.execute, self, 'SELECT 1 AS code')
local ok, data, err = pcall(mysql_conn.execute, mysql_conn,
                            'select * from articles')
if not ok then
    print("=======" .. inspect(ok))
    print("=======" .. inspect(data))
    print("=======" .. inspect(err))
end
-- local res, err = ('select * from articles1')

local res = data[1][1]

box.space.articles:insert({res.siteId, res.id})

print(inspect(res.siteId))
print(inspect(err))

print('exit')

local d = box.space.articles:select{100500}
print(inspect(d))

-- local httpd = require('http.server').new('0.0.0.0', 9000, {})
-- httpd:route({path = '/dictionary/:record_name', method = 'GET'}, get_dictionary_record_handler)
-- httpd:start()
