local log = require('log')
local worker = require('worker')
local inspect = require('inspect')

local db

local function save(ctx, _, input)
    local conn = db.get()
    if conn == nil then
        log.error({
            message = 'failed to insert data to mysql, db instance not yet initialized.',
            ['req-id'] = ctx.req_id,
            ['site-id'] = ctx.site_id,
        })
        return
    end

    local q = [[
        insert articles (
                        siteId,
                        categoryId,
                        timestamp,
                        title,
                        content,
                        tags,
                        seoMetaDesc,
                        seoMetaKeywords,
                        seoTitle,
                        priority,
                        isVisible
                    ) values (
                        ?, ?, ?, ?, ?,
                        ?, ?, ?, ?, ?,
                        ?
                    )]]

    local ok, data = pcall(conn.execute, conn, q, 100, input.category_id,
                           input.create_at, input.title, input.body,
                           "input.tags", input.seo.description,
                           "input.seo.keywords", input.seo.title, 0, 1)
    if not ok then
        log.error({
            message = string.format('failed to insert data to mysql, %s', data),
            ['req-id'] = ctx.req_id,
            ['site-id'] = ctx.site_id,
        })
        db.put(conn)
        return
    end

    ok, data = pcall(conn.execute, conn, 'select LAST_INSERT_ID() id')
    if not ok then
        log.error({
            message = string.format(
                'failed to select last insert id from mysql, %s', data),
            ['req-id'] = ctx.req_id,
            ['site-id'] = ctx.site_id,
        })
        db.put(conn)
        return
    end

    db.put(conn)

    return db.extract(data)
end

local function get1(ctx, _, input)
    log.info("++++++++++ 1")
    local conn = db.get()
    log.info("++++++++++ 2")
    if conn == nil then
        log.error({
            message = 'failed to insert data to mysql, db instance not yet initialized.',
            ['req-id'] = ctx.req_id,
            ['site-id'] = ctx.site_id,
        })
        return
    end
    log.info("++++++++++ 3")

    local q = [[select
                    siteId,
                    categoryId,
                    timestamp,
                    title,
                    content,
                    tags,
                    seoMetaDesc,
                    seoMetaKeywords,
                    seoTitle,
                    priority,
                    isVisible
                from articles
                where id = ?
                    and siteId = ?
                    and isDeleted = 0]]
    log.info("++++$$$$$$$$$$$$$$++++++ 3.5 , %s", inspect(conn))
    -- local ok, data = pcall(conn.execute, conn, q, input, ctx.site_id)
    local ok, data = pcall(conn.execute, conn,
                           'select siteId, categoryId, timestamp, title, content, tags, seoMetaDesc, seoMetaKeywords, seoTitle, priority, isVisible from articles where id = 2 and siteId = 100',
                           2)
    -- local data, err = conn:execute(q, tonumber(input), tonumber(ctx.site_id))
    -- local data, err = conn:execute('select siteId, categoryId, timestamp, title, content, tags, seoMetaDesc, seoMetaKeywords, seoTitle, priority, isVisible from articles where id = 2 and siteId = 100 and isDeleted = 0')
    log.info("++++++++++ 4 %s, %s", inspect(data), inspect(err))
    if not ok then
        log.error({
            message = string.format('failed getting article from mysql, %s',
                                    data),
            ['req-id'] = ctx.req_id,
            ['site-id'] = ctx.site_id,
        })
        db.put(conn)
        return
    end
    log.info("++++++++++ %s", inspect(data))

    db.put(conn)

    return db.extract(data)
end

local function new(opts)
    db = opts.db
    return {
        save = worker.new({size = 10, work = save}),
        get = worker.new({size = 10, work = get1, name = 'mygetter'}),
    }
end

return {new = new}
