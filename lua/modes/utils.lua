local M = {}

function M.throw_error(message)
    vim.notify(message, vim.log.levels.ERROR)
    error(message)
end

return M
