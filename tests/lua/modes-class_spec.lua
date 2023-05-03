local spy = require("luassert.spy")

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

        assert.has.errors(function()
            mode:toggle({ buffer = 1, test_1 = "1" })
        end)
        assert.same(mode._buffers, { ["*"] = { test_opt = "test" } })
        assert.is.True(mode:is_enabled_globally())
        assert.is_not.True(mode:is_enabled_for_buffer(1))

        mode:toggle({ test_opt = "test" })
        assert.is_not.True(mode:is_enabled_globally())
        assert.is_nil(mode._buffers)
    end)
end)
