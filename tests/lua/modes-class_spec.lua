local spy = require("luassert.spy")
local match = require("luassert.match")
local utils = require("utils")

describe("modes-class_spec", function()
	local modeClass

	before_each(function()
		modeClass = require("modes.mode-class").getModeClass()
	end)

	it("mode-class.new creates a new mode if mode doesn't exist", function()
		local testData = {
			id = "one",
			icon = "1",
			activationFn = spy.new(function() end),
			deactivationFn = spy.new(function() end),
		}

		local mode = modeClass.new(testData.id, testData.activationFn, testData.deactivationFn, testData.icon)

		assert.equals(mode:getId(), "one")
		assert.equals(mode:getIcon(), "1")
		assert.equals(mode:isActive(), false)
	end)

	it("mode:getIcon returns initial of id if icon not provided", function()
		local testData = {
			id = "one",
			icon = nil,
			activationFn = spy.new(function() end),
			deactivationFn = spy.new(function() end),
		}

		local mode = modeClass.new(testData.id, testData.activationFn, testData.deactivationFn, testData.icon)

		assert.equals(mode:getIcon(), "o")
	end)

	it("if mode:toggle called mode:isActive returns toggled value", function()
		local testData = {
			id = "one",
			icon = "1",
			activationFn = spy.new(function() end),
			deactivationFn = spy.new(function() end),
		}

		local mode = modeClass.new(testData.id, testData.activationFn, testData.deactivationFn, testData.icon)

		assert.equals(mode:isActive(), false)
		mode:toggle()
		assert.spy(testData.activationFn).was_called_with(match._)
		assert.equals(mode:isActive(), true)
		mode:toggle()
		assert.equals(mode:isActive(), false)
		assert.spy(testData.deactivationFn).was_called_with(match._)
	end)
end)