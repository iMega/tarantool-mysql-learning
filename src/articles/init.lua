local worker = require("worker")
local log = require("log")
local inspect = require("inspect")

local M = {}

local function article_request_in(ctx, state, input)

    log.info("=== article_request_in" .. inspect(state))
    state.test = state.test + 1

    M.get_article_in(ctx, {body = input})
    return "aaaaaa"
end

M.article_request_in = worker.new({
    size = 10,
    work = article_request_in,
    state = {test = 1},
})

local function get_article(ctx, state, input)
    --
    log.info("=== get_article" .. inspect(input.body) .. "====" .. inspect(ctx))
end

M.get_article_in = worker.new({size = 10, work = get_article, state = {}})

return M
