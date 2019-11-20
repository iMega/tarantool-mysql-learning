local log = require('log')
local worker = require('worker')

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

    return {entity_id = db.extract(data)}
end

local function new(opts)
    db = opts.db
    return {save = worker.new({size = 10, work = save})}
end

return {new = new}
