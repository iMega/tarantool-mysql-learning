-- local box = require('box')
local worker = require('worker')
-- local log = require('log')
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
    -- box.space.articles:insert({res.siteId, 2})
    state.storage.save(ctx, data)
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
