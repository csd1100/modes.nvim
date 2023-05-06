local M = {}

function M.throw_error(message)
    vim.notify(message, vim.log.levels.ERROR)
    error(message)
end

--- returns a new copy of table with only specified keys
--- @param tbl table - table to filter
--- @param keys table - list of keys to keep
--- @return table opts table without keys
function M.tbl_filter_keys(tbl, keys)
    local new_tbl = {}
    for _, key in ipairs(keys) do
        new_tbl[key] = tbl[key]
    end
    return new_tbl
end

--- returns a new copy of table without specified keys
--- @param tbl table - table to filter
--- @param keys table - list of keys to remove
--- @return table opts table without keys
function M.tbl_remove_keys(tbl, keys)
    local opts = vim.deepcopy(tbl)
    for _, key in ipairs(keys) do
        opts[key] = nil
    end
    return opts
end

--- `Mutates` a of passed in table adds nested table structure
--- with passed in keys
--- @param tbl table a table to be initialized (will be `mutated`)
--- @param keys table a list of keys to be initialized; will be initialized serially
-- tbl = {}
-- init_nested_table(tbl, {"a","b","c"})
-- now, tbl -> {
--     a = {
--         b = {
--             c = {}
--         }
--     }
-- }
function M.init_nested_table(tbl, keys)
    -- print("tbl")
    -- deep_print(tbl)
    -- print("keys")
    -- deep_print(keys)
    keys = vim.deepcopy(keys)
    if #keys > 0 then
        local key = keys[1]
        if not tbl[key] then
            tbl[key] = {}
            table.remove(keys, 1)
            M.init_nested_table(tbl[key], keys)
        else
            table.remove(keys, 1)
            M.init_nested_table(tbl[key], keys)
        end
    end
end

--- returns true if passed in list of keys is present in table
--- with passed in keys
--- @param tbl table a table to be checked
--- @param keys table a list of keys to be checked
function M.is_nested_present(tbl, keys)
    -- print("tbl")
    -- deep_print(tbl)
    -- print("keys")
    -- deep_print(keys)
    if #keys == 0 then
        return true
    end

    tbl = vim.deepcopy(tbl)
    keys = vim.deepcopy(keys)

    if not tbl[keys[1]] then
        return false
    else
        local key = keys[1]
        table.remove(keys, 1)
        return M.is_nested_present(tbl[key], keys)
    end
end

--- normalize lhs of keymap i.e. replace <leader> with value of g:mapleader
function M.normalize_lhs(lhs)
    return string.gsub(lhs, "<leader>", vim.g.mapleader)
end

M.allowed_keymap_opts = {
    "buffer",
    "nowait",
    "silent",
    "script",
    "expr",
    "unique",
    "desc",
}

--- return vim keymaps table if found in table
--- @param lhs string lhs of keymap to be found
--- @param maps table table containing keymaps tables
function M.find_map(maps, lhs)
    for _, map in ipairs(maps) do
        if map["lhs"] == lhs then
            return map
        end
    end
end

function M.traverse_maps_and_apply(map_store, cb)
    for vim_mode, mappings_for_vim_mode in pairs(map_store) do
        for lhs, rhs_and_options in pairs(mappings_for_vim_mode) do
            cb(vim_mode, lhs, rhs_and_options)
        end
    end
end

return M
