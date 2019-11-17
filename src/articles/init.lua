local worker = require("worker")
local log = require("log")
local inspect = require("inspect")
local mysql = require("articles.mysql")

-- local M = {}

local function article_save(ctx, state, input)
    log.info("=== article_save" .. inspect(input))
    state.storage.save()
end

-- local function article_request_in(ctx, state, input)

--     log.info("=== article_request_in" .. inspect(state))
--     state.test = state.test + 1

--     M.get_article_in(ctx, {body = input})
--     return "aaaaaa"
-- end

-- M.article_request_in = worker.new({
--     size = 10,
--     work = article_request_in,
--     state = {test = 1},
-- })

-- local function get_article(ctx, state, input)
--     --
--     log.info("=== get_article" .. inspect(input.body) .. "====" .. inspect(ctx))
-- end

-- M.get_article_in = worker.new({size = 10, work = get_article, state = {}})

local function new(opts)
    local mysql_storage = mysql.new({db = opts.db})

    return {
        save = worker.new({
            size = 10,
            work = article_save,
            state = {storage = mysql_storage},
        }),
    }
end

return {new = new}
