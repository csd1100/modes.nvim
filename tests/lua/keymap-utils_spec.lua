local utils = require("utils")
local spy = require("luassert.spy")

local function normalize_lhs(lhs)
    return string.gsub(lhs, "<leader>", vim.g.mapleader)
end

local function generate_expected_output(id, keymaps)
    local expected = {}
    expected[id] = {}
    for vim_modes, maps in pairs(keymaps) do
        if not expected[id][vim_modes] then
            expected[id][vim_modes] = {}
        end
        for _, map in ipairs(maps) do
            local lhs = normalize_lhs(map[1])
            expected[id][vim_modes][lhs] = { map[2], map[3] }
        end
    end
    return expected
end

describe("keymap utils", function()
    local keymap_utils

    before_each(function()
        keymap_utils = require("modes.keymap-utils")
        vim.g.mapleader = " "
    end)

    after_each(function()
        keymap_utils._reset_caches()
        keymap_utils = nil
    end)

    it("test map and unmap globally", function()
        local test_data = {
            ["n"] = {
                {
                    "<leader>lq",
                    ":lua print('<leader>lq')<CR>",
                    { desc = "Do Something 2" },
                },
                {
                    "<leader>123",
                    ":lua print('<leader>123')<CR>",
                    { desc = "Do Something 2" },
                },
            },
            ["v"] = {
                {
                    "<leader>lq",
                    ":lua print('<leader>lq')<CR>",
                    { desc = "Do Something 2" },
                },
                {
                    "<leader>123",
                    ":lua print('<leader>123')<CR>",
                    { desc = "Do Something 2" },
                },
            },
        }

        -- set map before calling map
        vim.keymap.set("n", "<leader>123", ":echo hello", { desc = "test" })

        local leader_123 = vim.tbl_filter(function(row)
            return row["lhs"] == " 123"
        end, vim.api.nvim_get_keymap("n"))

        local expected_existing_map = {
            ["test_mode"] = {
                ["n"] = {
                    [" 123"] = leader_123[1],
                },
            },
        }

        assert.same(keymap_utils._maps_cache, {})
        assert.same(keymap_utils._existing_maps_cache, {})

        keymap_utils.map("test_mode", test_data, {})

        -- assert module cache is updated
        assert.same(
            keymap_utils._maps_cache,
            generate_expected_output("test_mode", test_data)
        )
        assert.same(keymap_utils._existing_maps_cache, expected_existing_map)

        -- assert keymaps are added
        local all_n_maps = vim.api.nvim_get_keymap("n")
        local expected_n_maps = vim.tbl_filter(function(row)
            if row["lhs"] == " 123" or row["lhs"] == " lq" then
                return true
            end
        end, all_n_maps)
        assert.equal(#expected_n_maps, 2)

        local all_v_maps = vim.api.nvim_get_keymap("v")
        local expected_v_maps = vim.tbl_filter(function(row)
            if row["lhs"] == " 123" or row["lhs"] == " lq" then
                return true
            end
        end, all_v_maps)
        assert.equal(#expected_v_maps, 2)

        -- assert existing keymap is updated
        for _, map in ipairs(expected_n_maps) do
            if map["lhs"] == " 123" then
                -- <leader> is replace with " "
                assert.equal(map["rhs"], ":lua print(' 123')<CR>")
            end
        end

        local partial_unmaps = {
            ["n"] = {
                "<leader>lq",
                "<leader>123",
            },
        }

        keymap_utils.unmap("test_mode", partial_unmaps, {})

        assert.equal(#keymap_utils._maps_cache["test_mode"]["n"], 0)
        assert.equal(
            #vim.tbl_keys(keymap_utils._maps_cache["test_mode"]["v"]),
            2
        )

        -- assert 1 keymap removed and 1 restored
        local all_n_maps_after_unmap = vim.api.nvim_get_keymap("n")
        local expected_n_maps_after_unmap = vim.tbl_filter(function(row)
            if row["lhs"] == " 123" or row["lhs"] == " lq" then
                return true
            end
        end, all_n_maps_after_unmap)
        assert.equal(#vim.tbl_keys(expected_n_maps_after_unmap), 1)

        for _, map in ipairs(expected_n_maps_after_unmap) do
            if map["lhs"] == " 123" then
                -- <leader> is replace with " "
                assert.equal(map["rhs"], ":echo hello")
            end
        end
    end)
end)
