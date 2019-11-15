local worker = require("worker")
local log = require("log")
local inspect = require("inspect")

local M = {}

local function article_request_in(ctx, state, input)
    --
    log.info("=== article_request_in" .. inspect(input.body))
    M.get_article_in(ctx, input.body)
end

M.article_request_in = worker.create({
    size = 10,
    work = article_request_in,
    state = {},
})

local function get_article(ctx, state, input)
    --
    log.info("=== get_article" .. inspect(input.body) .. "====" .. inspect(ctx))
end

M.get_article_in = worker.create({size = 10, work = get_article, state = {}})

return M
