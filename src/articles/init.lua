local box = require('box')
local worker = require('worker')
local json = require('json')
local log = require('log')
-- local inspect = require('inspect')
local mysql = require('articles.mysql')

local function table_filter(original, input)
    local res = {}
    for k, v in pairs(original) do
        res[k] = v
    end
    for k, v in pairs(input) do
        if res[k] ~= nil then
            res[k] = v
        end
    end
    return res
end

local article_default = {
    category_id = 0,
    create_at = "",
    update_at = "",
    title = "",
    body = "",
    tags = {},
    seo = {title = "", description = "", keywords = {}},
    is_visible = true,
    is_deleted = false,
}

local function save_article(ctx, state, input)
    local data = table_filter(article_default, input)
    local entity = json.encode(data)

    local res = state.storage.save(ctx, data)
    if res == nil then
        return false
    end

    local ok, err = pcall(box.space.articles.insert, box.space.articles, {
        tonumber(ctx.site_id), tonumber(res.id), entity, data.create_at,
        data.update_at, data.is_deleted,
    })
    if not ok then
        log.error({
            message = string.format('failed to insert data to box, %s', err),
            ['req-id'] = ctx.req_id,
            ['site-id'] = ctx.site_id,
        })
        return false
    end

    return true
end

local function new(opts)
    local mysql_storage = mysql.new({db = opts.db})

    return {
        save = worker.new({
            size = 10,
            work = save_article,
            state = {storage = mysql_storage},
        }),
    }
end

return {new = new}
