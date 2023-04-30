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
end)
