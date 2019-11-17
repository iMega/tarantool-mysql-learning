local log = require('log')

local db

local function save()
    log.info("++++++++++ MYSQL SAVE ++++++++++++++++")
    return "1231312312313"
end

local function new(opts)
    db = opts.db
    return {save = save}
end

return {new = new}
