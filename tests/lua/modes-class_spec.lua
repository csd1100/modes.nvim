local spy = require("luassert.spy")

describe("modes-class_spec", function()
    local modeClass

    before_each(function()
        modeClass = require("modes.mode-class").getModeClass()
    end)

    it("mode-class.new creates a new mode", function()
        local testData = {
            id = "one",
            icon = "1",
            activationFn = spy.new(function() end),
            deactivationFn = spy.new(function() end),
        }

        local mode = modeClass.new(
            testData.id,
            testData.activationFn,
            testData.deactivationFn,
            testData.icon
        )

        assert.equals(mode:getId(), "one")
        assert.equals(mode:getIcon(), "1")
    end)

    it("mode:getIcon returns initial of id if icon not provided", function()
        local testData = {
            id = "one",
            icon = nil,
            activationFn = spy.new(function() end),
            deactivationFn = spy.new(function() end),
        }

        local mode = modeClass.new(
            testData.id,
            testData.activationFn,
            testData.deactivationFn,
            testData.icon
        )

        assert.equals(mode:getIcon(), "o")
    end)
end)
