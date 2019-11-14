-- local worker = require('worker')
-- local function article_request_in(ctx, input)
--     --
-- end
-- local function get_article(ctx, input)
--     --
-- end
-- return {
--     article_request_in = worker.create({
--         size = 10,
--         work = article_request_in,
--         ctx = {}
--     }),
--     get_article_in = worker.create({size = 10, work = get_article, ctx = {}})
-- }
local log = require('log')

local function aaa() log.info("==========aaa=============") end

return {aaa = aaa}
