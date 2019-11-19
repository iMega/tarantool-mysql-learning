local log = require('log')
-- local inspect = require('inspect')
local worker = require('worker')

local db

local function save(ctx, _, input)
    if db == nil then
        log.error({
            message = "failed to insert data to mysql, db instance not yet initialized.",
            ['req-id'] = ctx.req_id,
            ['site-id'] = ctx.site_id,
        })
        return false
    end

    local conn = db:get()
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
        log.error("failed to insert data to mysql, " .. data)
        db:put(conn)
        return false
    end

    db:put(conn)

    return true
end

local function new(opts)
    db = opts.db
    return {
        save = worker.new({size = 10, work = save, response = {timeout = 0}}),
    }
end

return {new = new}
