local inspect = require('inspect')
local log = require('log')
local worker = require("worker")
local mysql = require("mysql")

local pool

local function connect(ctx, state, input)
    log.debug('try connect to mysql')

    local ok, res = pcall(mysql.pool_create, {
        host = 'dbstorage',
        user = 'root',
        password = 'qwerty',
        db = 'tester',
        size = 5,
    })

    if not ok then
        log.error('failed to connect to mysql, %s', res)
        return
    end

    pool = res
end

local need_connect_in = worker.create({size = 1, work = connect, state = {}})

local function connect_checker(ctx, state, input)
    if pool == nil then
        need_connect_in(ctx, true)
        return
    end

    local conn = pool:get()
    if not conn:ping() then
        pool = nil
        return
    end
    pool:put(conn)
end

connect_checker_in = worker.create({
    size = 1,
    work = connect_checker,
    timeout = 10,
})

local function get_pool()
    return pool
end

local function new()
    connect_checker_in(nil, true)
    return {get_pool = get_pool}
end

return {new = new}
