local utils = require("utils")
local spy = require("luassert.spy")
local match = require("luassert.match")

describe("modes_spec", function()
	local modes

	before_each(function()
		modes = require("modes")
	end)

	after_each(function()
		modes.deleteAllModes()
	end)

	it("toggleMode throws error if mode doesn't exist", function()
		assert.has.errors(function()
			modes.toggleMode("id")
		end)
	end)

	it("modes.toggleMode calls activation and deactivation function", function()
		local testData = {
			id = "one",
			icon = "1",
			activationFn = spy.new(function() end),
			deactivationFn = spy.new(function() end),
		}

		local mode =
			modes.createIfNotPresent(testData.id, testData.activationFn, testData.deactivationFn, testData.icon)

		-- toggle mode --
		modes.toggleMode(mode)
		-- assert activation from 1st mode is called --
		assert.spy(testData.activationFn).was_called_with(match._)
		assert.same(modes.activeModes[testData.id], { id = testData.id, icon = testData.icon })
		modes.toggleMode(mode)
		-- assert deactivation from 1st mode is called as second mode is not created it will toggle existing mode --
		assert.spy(testData.deactivationFn).was_called_with(match._)
		assert.is_nil(modes.activeModes[testData.id])
	end)

	it("modes.getActiveModesIcons return valid list", function()
		local activationFn = spy.new(function() end)
		local deactivationFn = spy.new(function() end)

		local testData1 = {
			id = "one",
			icon = "1",
		}

		local testData2 = {
			id = "two",
			icon = "2",
		}

		local testData3 = {
			id = "three",
		}

		local mode1 = modes.createIfNotPresent(testData1.id, activationFn, deactivationFn, testData1.icon)
		local mode2 = modes.createIfNotPresent(testData2.id, activationFn, deactivationFn, testData2.icon)
		local mode3 = modes.createIfNotPresent(testData3.id, activationFn, deactivationFn, testData3.icon)

		-- toggle mode --
		modes.toggleMode(mode1)
		modes.toggleMode(mode2)
		modes.toggleMode(mode3)

		local iconList = modes.getActiveModesIcons()

		assert.equals(utils.has_value(iconList, "1"), true)
		assert.equals(utils.has_value(iconList, "2"), true)
		assert.equals(utils.has_value(iconList, "t"), true)
	end)

	it("modes.createIfNotPresent returns a existing mode", function()
		local testData = {
			id = "one",
			icon = "1",
			activationFn = spy.new(function() end),
			deactivationFn = spy.new(function() end),
		}

		local mode1 =
			modes.createIfNotPresent(testData.id, testData.activationFn, testData.deactivationFn, testData.icon)

		local testData2 = {
			id = "one",
			icon = "o",
			activationFn = spy.new(function() end),
			deactivationFn = spy.new(function() end),
		}

		local mode2 =
			modes.createIfNotPresent(testData2.id, testData2.activationFn, testData2.deactivationFn, testData2.icon)

		assert.equals(mode2, mode1)

		-- toggle mode --
		modes.toggleMode(mode1)
		-- assert activation from 1st mode is called --
		assert.spy(testData.activationFn).was_called_with(match._)
		modes.toggleMode(mode2)
		-- assert deactivation from 1st mode is called as second mode is not created it will toggle existing mode --
		assert.spy(testData.deactivationFn).was_called_with(match._)
	end)
end)
