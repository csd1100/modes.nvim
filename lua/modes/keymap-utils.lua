--- returns a new copy of table without specified keys
--- @param tbl table - table to filter
--- @param keys table - list of keys to remove
--- @return table opts table without keys
local function tbl_remove_keys(tbl, keys)
    local opts = vim.deepcopy(tbl)
    for _, key in ipairs(keys) do
        opts[key] = nil
    end
    return opts
end

--- returns a new copy of table with only specified keys
--- @param tbl table - table to filter
--- @param keys table - list of keys to keep
--- @return table opts table without keys
local function tbl_filter_keys(tbl, keys)
    local new_tbl = {}
    for _, key in ipairs(keys) do
        new_tbl[key] = tbl[key]
    end
    return new_tbl
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
local function init_nested_table(tbl, keys)
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
            init_nested_table(tbl[key], keys)
        else
            table.remove(keys, 1)
            init_nested_table(tbl[key], keys)
        end
    end
end

--- returns true if passed in list of keys is present in table
--- with passed in keys
--- @param tbl table a table to be checked
--- @param keys table a list of keys to be checked
local function is_nested_present(tbl, keys)
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
        return is_nested_present(tbl[key], keys)
    end
end

local M = {}

-- cache struct
-- M._maps_cache = {
--     ["plugin_mode"] = {
--         ["buffers"] = {},
--         ["mappings"] = {
--             ["vim_mode"] = {
--                 ["<lhs>"] = { "<rhs>", opts },
--             },
--         },
--     },
-- }

M._maps_cache = {}

-- cache struct
-- M._existing_maps_cache = {
--     ["plugin_mode"] = {
--         ["buffers"] = {},
--         ["mappings"] = {
--             ["vim_mode"] = {
--                 ["<lhs>"] = { "<rhs>", opts },
--             },
--         },
--     },
-- }

M._existing_maps_cache = {}

--- normalize lhs of keymap i.e. replace <leader> with value of g:mapleader
local function normalize_lhs(lhs)
    return string.gsub(lhs, "<leader>", vim.g.mapleader)
end

--- set vim keymap
--- @param id string this plugins mode id
--- @param mode string vim mode
--- @param map table map to be set
local function add_map(id, mode, map)
    init_nested_table(M._maps_cache, { id, mode, map[1] })
    M._maps_cache[id][mode][map[1]] = { map[2], map[3] }
    vim.keymap.set(mode, map[1], map[2], map[3])
end

--- backup keymap
--- @param id string this plugins mode id
--- @param mode string vim mode
--- @param lhs string lhs of keymap
--- @param map table keymap table
local function backup_keymap(id, mode, lhs, map)
    vim.notify(
        "Found existing keymap for '" .. lhs .. "' backing it up.",
        vim.log.levels.INFO
    )
    init_nested_table(M._existing_maps_cache, { id, mode, lhs })
    M._existing_maps_cache[id][mode][lhs] = map
end

--- return vim keymaps table if found in table
--- @param lhs string lhs of keymap to be found
--- @param maps table table containing keymaps tables
local function find_map(maps, lhs)
    for _, map in ipairs(maps) do
        if map["lhs"] == lhs then
            return map
        end
    end
end

--- get existing keymaps for mode and buffer
--- @param mode string vim mode
--- @param bufnr number buffer number; `"*"` if global
local function get_existing_keymaps(mode, bufnr)
    if bufnr == "*" then
        return vim.api.nvim_get_keymap(mode)
    else
        return vim.api.nvim_buf_get_keymap(bufnr, mode)
    end
end

--- backup existing keymap if found
--- @param id string this plugins mode id
--- @param mode string vim mode
--- @param lhs string lhs of keymap
--- @param bufnr number buffer number where map to be set; `'*'` if global
local function backup_existing_mapping_if_present(id, mode, lhs, bufnr)
    local keymaps = get_existing_keymaps(mode, bufnr)
    local found = find_map(keymaps, lhs)
    if found then
        backup_keymap(id, mode, lhs, found)
    end
end

--- set buffer keymap
--- @param id string this plugins mode id
--- @param mode string vim mode
--- @param map table map to be set
--- @param bufnr number buffer number where map to be set
local function map_buffer(id, mode, map, bufnr)
    map = vim.deepcopy(map)
    backup_existing_mapping_if_present(id, mode, map[1], bufnr)
    map[3]["buffer"] = bufnr
    add_map(id, mode, map)
end

--- set global keymap
--- @param id string this plugins mode id
--- @param mode string vim mode
--- @param map table map to be set
local function map_global(id, mode, map)
    map = vim.deepcopy(map)
    backup_existing_mapping_if_present(id, mode, map[1], "*")
    add_map(id, mode, map)
end

--- handle mappings for vim mode
--- @param id string this plugins mode id
--- @param mode string vim mode
--- @param mappings table mappings specified for that vim mode
--- @param opts table options passed in to mode toggle method
local function map_mode(id, mode, mappings, opts)
    for _, mapping in ipairs(mappings) do
        mapping[1] = normalize_lhs(mapping[1])
        if opts.buffer then
            map_buffer(id, mode, mapping, opts.buffer)
        else
            map_global(id, mode, mapping)
        end
    end
end

--- map keymaps while mode is active
--- NOTE these will be automatically unmapped after mode is deactivated
--- @param id string - this plugins mode id
--- @param maps table - user keymaps
--- @param options table - passed from toggle
-- maps = {
--     ["mode"] = {
--         { "<lhs>", "<rhs>", opts },
--     },
-- }
M.map = function(id, maps, options)
    maps = vim.deepcopy(maps)
    options = vim.deepcopy(options)
    options = tbl_filter_keys(options, { "buffer" })
    for mode, mappings in pairs(maps) do
        map_mode(id, mode, mappings, options)
    end
end

--- get keymap for existing cache
--- @param id string this plugins mode id
--- @param mode string vim mode
--- @param lhs string lhs of keymap
local function get_from_existing_maps_cache(id, mode, lhs)
    if is_nested_present(M._existing_maps_cache, { id, mode, lhs }) then
        return M._existing_maps_cache[id][mode][lhs]
    end
end

--- remove keymap from _maps_cache
--- @param id string this plugins mode id
--- @param mode string vim mode
--- @param lhs string lhs of keymap
--- @param opts table options passed in
local function handle_remove_for_maps_cache(id, mode, lhs, opts)
    M._maps_cache[id][mode][lhs] = nil
end

--- remove keymap
--- @param id string this plugins mode id
--- @param mode string vim mode
--- @param lhs string lhs of keymap
--- @param opts table options passed in
local function remove_map(id, mode, lhs, opts)
    handle_remove_for_maps_cache(id, mode, lhs, opts)
    vim.keymap.del(mode, lhs, opts)
end

--- remove not opts from keymap
--- @param keymap table vim keymap object
--- @returns copy of opts for keymap
local function get_opts_from_map(keymap)
    local non_opts_keys = {
        "lhs",
        "rhs",
        "lhsraw",
        "rhsraw",
        "callback",
        "sid",
        "mode",
        "lnum",
        "expr",
    }
    return tbl_remove_keys(keymap, non_opts_keys)
end

--- restore existing keymap
--- @param id string this plugins mode id
--- @param mode string vim mode
--- @param keymap table keymap object
--- @param opts table options passed in
local function restore_keymap(id, mode, keymap, opts)
    vim.notify(
        "Restoring existing keymap '" .. keymap["lhs"] .. "'.",
        vim.log.levels.INFO
    )
    keymap = vim.deepcopy(keymap)
    remove_map(id, mode, keymap["lhs"], opts)
    local rhs = keymap["rhs"] or keymap["callback"]
    local options = get_opts_from_map(keymap)
    if options["buffer"] == 0 then
        options["buffer"] = nil
    end
    vim.keymap.set(mode, keymap["lhs"], rhs, options)
end

--- unmap keymaps for vim mode
--- @param id string this plugins mode id
--- @param mode string vim mode
--- @param unmappings table keymap to be unmapped
--- @param opts table passed in options
local function unmap_mode(id, mode, unmappings, opts)
    for _, lhs in ipairs(unmappings) do
        lhs = normalize_lhs(lhs)
        local existing = get_from_existing_maps_cache(id, mode, lhs)
        if existing then
            restore_keymap(id, mode, existing, opts)
        else
            remove_map(id, mode, lhs, opts)
        end
    end
end

--- unmap keymaps
--- NOTE this will be called automatically on keymaps activated during mode activation
--- @param id string this plugins mode id
--- @param unmaps table - user keymaps
--- @param options table - passed from toggle
-- unmaps = {
--     ["mode"] = {
--         "<lhs>"
--     }
-- }
M.unmap = function(id, unmaps, options)
    unmaps = vim.deepcopy(unmaps)
    options = vim.deepcopy(options)
    options = tbl_filter_keys(options, { "buffer" })
    for mode, unmappings in pairs(unmaps) do
        unmap_mode(id, mode, unmappings, options)
    end
end

M._reset_caches = function()
    M._maps_cache = {}
    M._existing_maps_cache = {}
end

return M
