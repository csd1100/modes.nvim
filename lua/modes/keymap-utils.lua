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

local normalize_lhs = function(lhs)
    return string.gsub(lhs, "<leader>", vim.g.mapleader)
end

local find_map = function(maps, lhs)
    for _, map in ipairs(maps) do
        if map["lhs"] == lhs then
            return map
        end
    end
end

local get_existing_keymaps = function(mode, bufnr)
    if bufnr == "*" then
        return vim.api.nvim_get_keymap(mode)
    else
        return vim.api.nvim_buf_get_keymap(bufnr, mode)
    end
end

local function backup_keymap(mode, lhs, map)
    vim.notify(
        "Found existing keymap for '" .. lhs .. "' backing it up.",
        vim.log.levels.INFO
    )
    M._existing_maps_cache[mode] = {}
    M._existing_maps_cache[mode][lhs] = map
end

local backup_existing_mapping_if_present = function(mode, lhs, bufnr)
    local keymaps = get_existing_keymaps(mode, bufnr)
    local found = find_map(keymaps, lhs)
    if found then
        backup_keymap(mode, lhs, found)
    end
end

local function add_map(mode, map)
    if not M._maps_cache[mode] then
        M._maps_cache[mode] = {}
    end
    M._maps_cache[mode][map[1]] = { map[2], map[3] }
    vim.keymap.set(mode, map[1], map[2], map[3])
end

local map_buffer = function(mode, bufnr, map)
    map = vim.deepcopy(map)
    backup_existing_mapping_if_present(mode, map[1], bufnr)
    map[3]["buffer"] = bufnr
    add_map(mode, map)
end

local map_global = function(mode, map)
    map = vim.deepcopy(map)
    backup_existing_mapping_if_present(mode, map[1], "*")
    add_map(mode, map)
end

local map_mode = function(mode, mappings, options)
    for _, mapping in ipairs(mappings) do
        mapping[1] = normalize_lhs(mapping[1])
        if options.buffer then
            map_buffer(mode, options.buffer, mapping)
        else
            map_global(mode, mapping)
        end
    end
end
--- map keymaps while mode is active
--- NOTE these will be automatically unmapped after mode is deactivated
--- @param maps table - user keymaps
--- @param options table - passed from toggle
-- maps = {
--     ["mode"] = {
--         { "<lhs>", "<rhs>", opts },
--     },
-- }
M.map = function(maps, options)
    maps = vim.deepcopy(maps)
    for mode, mappings in pairs(maps) do
        map_mode(mode, mappings, options)
    end
end

local function get_from_existing_maps_cache(mode, lhs)
    if M._existing_maps_cache[mode][lhs] then
        return M._existing_maps_cache[mode][lhs]
    end
end

local handle_remove_for_maps_cache = function(mode, lhs, options)
    M._maps_cache[mode][lhs] = nil
    M._existing_maps_cache[mode][lhs] = nil
end

local remove_map = function(mode, lhs, options)
    handle_remove_for_maps_cache(mode, lhs, options)
    vim.keymap.del(mode, lhs, options)
end

local function get_opts_from_map(keymap)
    local opts = vim.deepcopy(keymap)
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
    for _, non_opts in ipairs(non_opts_keys) do
        opts[non_opts] = nil
    end
    return opts
end

local function restore_keymap(mode, keymap, options)
    vim.notify(
        "Restoring existing keymap '" .. keymap["lhs"] .. "'.",
        vim.log.levels.INFO
    )
    keymap = vim.deepcopy(keymap)
    remove_map(mode, keymap["lhs"], options)
    local rhs = keymap["rhs"] or keymap["callback"]
    vim.keymap.set(mode, keymap["lhs"], rhs, get_opts_from_map(keymap))
end

local unmap_mode = function(mode, unmappings, options)
    for _, lhs in ipairs(unmappings) do
        lhs = normalize_lhs(lhs)
        local existing = get_from_existing_maps_cache(mode, lhs)
        if existing then
            restore_keymap(mode, existing, options)
        else
            remove_map(mode, lhs, options)
        end
    end
end

--- unmap keymaps
--- NOTE this will be called automatically on keymaps activated during mode activation
--- @param unmaps table - user keymaps
--- @param options table - passed from toggle
-- unmaps = {
--     ["mode"] = {
--         "<lhs>"
--     }
-- }
M.unmap = function(unmaps, options)
    unmaps = vim.deepcopy(unmaps)
    for mode, unmappings in pairs(unmaps) do
        unmap_mode(mode, unmappings, options)
    end
end

-- test data
-- local maps = {
--     ["n"] = {
--         {
--             "<leader>ldis",
--             ":lua print('<leader>ldis')<CR>",
--             { desc = "Do Something 2" },
--         },
--         {
--             "<leader>123",
--             ":lua print('<leader>123')<CR>",
--             { desc = "Do Something 2" },
--         },
--     },
-- }
-- local unmaps = {
--     ["n"] = {
--         "<leader>ldis",
--         "<leader>123",
--     },
-- }
return M
