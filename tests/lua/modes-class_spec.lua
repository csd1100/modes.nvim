local spy = require("luassert.spy")
local stub = require("luassert.stub")

describe("modes-class_spec", function()
    local mode_class

    before_each(function()
        mode_class = require("modes.mode-class").get_mode_class()
    end)

    it("mode-class.new creates a new mode", function()
        local test_data = {
            id = "one",
            icon = "1",
            activation_fn = spy.new(function() end),
            deactivation_fn = spy.new(function() end),
        }

        local mode = mode_class.new(
            test_data.id,
            test_data.activation_fn,
            test_data.deactivation_fn,
            test_data.icon
        )

        assert.equals(mode:get_id(), "one")
        assert.equals(mode:get_icon(), "1")
    end)

    it("mode:get_icon returns initial of id if icon not provided", function()
        local test_data = {
            id = "one",
            icon = nil,
            activation_fn = spy.new(function() end),
            deactivation_fn = spy.new(function() end),
        }

        local mode = mode_class.new(
            test_data.id,
            test_data.activation_fn,
            test_data.deactivation_fn,
            test_data.icon
        )

        assert.equals(mode:get_icon(), "o")
    end)

    it("when mode:activate is called mode._buffer is updated", function()
        local test_data = {
            id = "one",
            icon = "1",
            activation_fn = spy.new(function() end),
            deactivation_fn = spy.new(function() end),
        }

        local mode = mode_class.new(
            test_data.id,
            test_data.activation_fn,
            test_data.deactivation_fn,
            test_data.icon
        )

        assert.same(mode._buffers, {})
        mode:activate({ buffer = 1, test_1 = "1" })
        assert.same(mode._buffers, { ["1"] = { buffer = 1, test_1 = "1" } })

        mode:activate({ buffer = 2, test_2 = "2" })
        assert.same(mode._buffers, {
            ["1"] = { buffer = 1, test_1 = "1" },
            ["2"] = { buffer = 2, test_2 = "2" },
        })

        mode:activate({ test_opt = "test" })
        assert.same(mode._buffers, { ["*"] = { test_opt = "test" } })
    end)

    it("when mode:toggle toggles the mode", function()
        local test_data = {
            id = "one",
            icon = "1",
            activation_fn = spy.new(function() end),
            deactivation_fn = spy.new(function() end),
        }

        local mode = mode_class.new(
            test_data.id,
            test_data.activation_fn,
            test_data.deactivation_fn,
            test_data.icon
        )

        assert.same(mode._buffers, {})
        assert.is_not.True(mode:is_enabled_globally())
        assert.is_not.True(mode:is_enabled_for_buffer(1))

        mode:toggle({ buffer = 1, test_1 = "1" })

        assert.same(mode._buffers, { ["1"] = { buffer = 1, test_1 = "1" } })
        assert.is_not.True(mode:is_enabled_globally())
        assert.is.True(mode:is_enabled_for_buffer(1))

        mode:toggle({ buffer = 2, test_2 = "2" })

        assert.same(mode._buffers, {
            ["1"] = { buffer = 1, test_1 = "1" },
            ["2"] = { buffer = 2, test_2 = "2" },
        })
        assert.is_not.True(mode:is_enabled_globally())
        assert.is.True(mode:is_enabled_for_buffer(1))
        assert.is.True(mode:is_enabled_for_buffer(2))

        mode:toggle({ buffer = 2, test_2 = "2" })

        assert.is_not.True(mode:is_enabled_globally())
        assert.is_not.True(mode:is_enabled_for_buffer(2))
        assert.is.True(mode:is_enabled_for_buffer(1))
        assert.same(mode._buffers, {
            ["1"] = { buffer = 1, test_1 = "1" },
        })

        mode:toggle({ test_opt = "test" })

        assert.same(mode._buffers, { ["*"] = { test_opt = "test" } })
        assert.is.True(mode:is_enabled_globally())
        assert.is_not.True(mode:is_enabled_for_buffer(1))

        local warn_stub = stub(vim, "notify")
        mode:toggle({ buffer = 1, test_1 = "1" })
        assert.stub(warn_stub).was.called_with(
            "Mode " .. test_data.id .. " is already activated Globally",
            vim.log.levels.WARN
        )

        assert.same(mode._buffers, { ["*"] = { test_opt = "test" } })
        assert.is.True(mode:is_enabled_globally())
        assert.is_not.True(mode:is_enabled_for_buffer(1))

        mode:toggle({ test_opt = "test" })

        assert.is_not.True(mode:is_enabled_globally())
        assert.same(mode._buffers, {})

        mode:toggle({ test_opt = "test" })
        assert.same(mode._buffers, { ["*"] = { test_opt = "test" } })
        assert.is.True(mode:is_enabled_globally())

        mode:toggle({ test_opt = "test" })

        assert.is_not.True(mode:is_enabled_globally())
        assert.same(mode._buffers, {})

        mode:toggle({ buffer = 1, test_1 = "1" })

        assert.same(mode._buffers, { ["1"] = { buffer = 1, test_1 = "1" } })
        assert.is_not.True(mode:is_enabled_globally())
        assert.is.True(mode:is_enabled_for_buffer(1))
    end)
end)

local function normalize_lhs(lhs)
    return string.gsub(lhs, "<leader>", vim.g.mapleader)
end

describe("modes-class_spec keymap", function()
    local modes_class

    local test_data = {
        ["n"] = {
            ["<leader>lq"] = {
                ["rhs"] = ":lua print('<leader>lq')<CR>",
                ["opts"] = { desc = "Do Something 2" },
            },
            ["<leader>123"] = {
                ["rhs"] = ":lua print('<leader>123')<CR>",
                ["opts"] = { desc = "Do Something 2" },
            },
        },
        ["v"] = {
            ["<leader>lq"] = {
                ["rhs"] = ":lua print('<leader>lq')<CR>",
                ["opts"] = { desc = "Do Something 2" },
            },
            ["<leader>123"] = {
                ["rhs"] = ":lua print('<leader>123')<CR>",
                ["opts"] = { desc = "Do Something 2" },
            },
        },
    }

    before_each(function()
        modes_class = require("modes.mode-class").get_mode_class()
        vim.g.mapleader = " "
    end)

    it(
        "tests global add_maps adds maps to caches and apply_maps applies maps",
        function()
            -- set map before calling map
            vim.keymap.set("n", "<leader>123", ":echo hello", { desc = "test" })

            local leader_123 = vim.tbl_filter(function(row)
                return row["lhs"] == " 123"
            end, vim.api.nvim_get_keymap("n"))

            local vim_keymap_set_stub = stub(vim.keymap, "set", function() end)

            local test_mode = modes_class.new(
                "test_mode",
                function() end,
                function() end,
                "T"
            )

            local expected_existing_map = {
                ["n"] = {
                    [" 123"] = leader_123[1],
                },
                ["v"] = {},
            }

            assert.same(test_mode._maps_cache, {})
            assert.same(test_mode._existing_maps_cache, {})

            test_mode:add_maps(test_data)

            -- assert module cache is updated
            assert.same(test_mode._maps_cache, {
                ["n"] = {

                    [" lq"] = {

                        ["rhs"] = ":lua print('<leader>lq')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                    [" 123"] = {
                        ["rhs"] = ":lua print('<leader>123')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                },
                ["v"] = {
                    [" lq"] = {
                        ["rhs"] = ":lua print('<leader>lq')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                    [" 123"] = {
                        ["rhs"] = ":lua print('<leader>123')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                },
            })

            assert.same(test_mode._existing_maps_cache, expected_existing_map)

            test_mode:apply_maps(test_data)
            -- assert keymaps are added
            assert.stub(vim_keymap_set_stub).was.called(4)
            -- can only check last call with called_with
            -- TODO: add assertions for all calls
            assert.stub(vim_keymap_set_stub).was.called_with(
                "v",
                " 123",
                ":lua print('<leader>123')<CR>",
                { desc = "Do Something 2" }
            )
        end
    )

    it(
        "tests global add_maps adds maps to caches and remove_maps removes maps",
        function()
            -- set map before calling map
            vim.keymap.set("n", "<leader>123", ":echo hello", { desc = "test" })

            local leader_123 = vim.tbl_filter(function(row)
                return row["lhs"] == " 123"
            end, vim.api.nvim_get_keymap("n"))

            local test_mode = modes_class.new(
                "test_mode",
                function() end,
                function() end,
                "T"
            )

            assert.same(test_mode._maps_cache, {})
            assert.same(test_mode._existing_maps_cache, {})

            test_mode:add_maps(test_data)

            -- assert module cache is updated
            assert.same(test_mode._maps_cache, {
                ["n"] = {

                    [" lq"] = {

                        ["rhs"] = ":lua print('<leader>lq')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                    [" 123"] = {
                        ["rhs"] = ":lua print('<leader>123')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                },
                ["v"] = {
                    [" lq"] = {
                        ["rhs"] = ":lua print('<leader>lq')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                    [" 123"] = {
                        ["rhs"] = ":lua print('<leader>123')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                },
            })

            assert.same(test_mode._existing_maps_cache, {
                ["n"] = {
                    [" 123"] = leader_123[1],
                },
                ["v"] = {},
            })

            test_mode:remove_maps(test_data)
            -- assert module cache is updated
            assert.same(test_mode._maps_cache, {
                ["n"] = {},
                ["v"] = {},
            })

            assert.same(test_mode._existing_maps_cache, {
                ["n"] = {},
                ["v"] = {},
            })
        end
    )

    it(
        "tests global unapply_maps unmaps the maps and restores _existing_maps_cache",
        function()
            -- set map before calling map
            vim.keymap.set("n", "<leader>123", ":echo hello", { desc = "test" })

            local leader_123 = vim.tbl_filter(function(row)
                return row["lhs"] == " 123"
            end, vim.api.nvim_get_keymap("n"))

            local test_mode = modes_class.new(
                "test_mode",
                function() end,
                function() end,
                "T"
            )

            assert.same(test_mode._maps_cache, {})
            assert.same(test_mode._existing_maps_cache, {})

            test_mode:add_maps(test_data)

            -- assert module cache is updated
            assert.same(test_mode._maps_cache, {
                ["n"] = {

                    [" lq"] = {

                        ["rhs"] = ":lua print('<leader>lq')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                    [" 123"] = {
                        ["rhs"] = ":lua print('<leader>123')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                },
                ["v"] = {
                    [" lq"] = {
                        ["rhs"] = ":lua print('<leader>lq')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                    [" 123"] = {
                        ["rhs"] = ":lua print('<leader>123')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                },
            })

            assert.same(test_mode._existing_maps_cache, {
                ["n"] = {
                    [" 123"] = leader_123[1],
                },
                ["v"] = {},
            })

            local vim_keymap_del_stub = stub(vim.keymap, "del", function() end)
            local vim_keymap_set_stub = stub(vim.keymap, "set", function() end)
            test_mode:apply_maps(test_data)
            -- assert keymaps are added
            assert.stub(vim_keymap_set_stub).was.called(4)
            -- can only check last call with called_with
            -- TODO: add assertions for all calls
            assert.stub(vim_keymap_set_stub).was.called_with(
                "v",
                " 123",
                ":lua print('<leader>123')<CR>",
                { desc = "Do Something 2" }
            )

            test_mode:unapply_maps(test_data)
            -- assert keymaps are added
            assert.stub(vim_keymap_del_stub).was.called(4)
            -- can only check last call with called_with
            -- TODO: add assertions for all calls
            assert
                .stub(vim_keymap_del_stub).was
                .called_with("v", " 123", { desc = "Do Something 2" })
            -- assert map was restored
            assert
                .stub(vim_keymap_set_stub).was
                .called_with("n", " 123", ":echo hello", {
                    desc = "test",
                    buffer = 0,
                    expr = true,
                    nowait = 0,
                    script = 0,
                    silent = 0,
                })
        end
    )

    it(
        "tests buffer apply_maps and unapply_maps",
        function()
            local buf_handle = vim.api.nvim_create_buf(true, false)
            vim.api.nvim_buf_attach(buf_handle, false, {})
            -- set map before calling map
            vim.keymap.set("n", "<leader>123", ":echo hello", { desc = "test" })
            vim.api.nvim_buf_set_keymap(
                buf_handle,
                "v",
                "<leader>lq",
                ":print test",
                { desc = "test" }
            )

            local n_leader_123 = vim.tbl_filter(function(row)
                return row["lhs"] == " 123"
            end, vim.api.nvim_get_keymap("n"))

            local v_leader_lq_buf = vim.tbl_filter(function(row)
                return row["lhs"] == " lq"
            end, vim.api.nvim_buf_get_keymap(buf_handle, "v"))

            local vim_keymap_set_stub = stub(vim.keymap, "set", function() end)
            local vim_keymap_del_stub = stub(vim.keymap, "del", function() end)

            local test_mode = modes_class.new(
                "test_mode",
                function() end,
                function() end,
                "T"
            )

            local expected_existing_map = {
                ["n"] = {
                    [" 123"] = n_leader_123[1],
                },
                ["v"] = {},
            }

            assert.same(test_mode._maps_cache, {})
            assert.same(test_mode._existing_maps_cache, {})

            test_mode:add_maps(test_data)

            -- assert module cache is updated
            assert.same(test_mode._maps_cache, {
                ["n"] = {

                    [" lq"] = {

                        ["rhs"] = ":lua print('<leader>lq')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                    [" 123"] = {
                        ["rhs"] = ":lua print('<leader>123')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                },
                ["v"] = {
                    [" lq"] = {
                        ["rhs"] = ":lua print('<leader>lq')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                    [" 123"] = {
                        ["rhs"] = ":lua print('<leader>123')<CR>",
                        ["opts"] = { desc = "Do Something 2" },
                    },
                },
            })

            assert.same(test_mode._existing_maps_cache, expected_existing_map)

            local expected_existing_map_after_apply =
                vim.deepcopy(expected_existing_map)
            expected_existing_map_after_apply[tostring(buf_handle)] = {
                ["v"] = {
                    [" lq"] = v_leader_lq_buf[1],
                },
            }

            test_mode:apply_maps(test_data, { buffer = buf_handle })

            assert.same(
                test_mode._existing_maps_cache,
                expected_existing_map_after_apply
            )
            -- assert keymaps are added
            assert.stub(vim_keymap_set_stub).was.called(4)
            -- can only check last call with called_with
            -- TODO: add assertions for all calls
            assert.stub(vim_keymap_set_stub).was.called_with(
                "v",
                " 123",
                ":lua print('<leader>123')<CR>",
                { desc = "Do Something 2", buffer = buf_handle }
            )

            test_mode:unapply_maps(test_data, { buffer = buf_handle })
            -- assert keymaps are added
            assert.stub(vim_keymap_del_stub).was.called(4)
            -- can only check last call with called_with
            -- TODO: add assertions for all calls
            assert
                .stub(vim_keymap_del_stub).was
                .called_with("v", " 123", { desc = "Do Something 2", buffer = buf_handle })
            -- assert map was restored
            assert
                .stub(vim_keymap_set_stub).was
                .called_with("n", " 123", ":echo hello", {
                    desc = "test",
                    buffer = buf_handle,
                    expr = true,
                    nowait = 0,
                    script = 0,
                    silent = 0,
                })
        end
    )
end)
