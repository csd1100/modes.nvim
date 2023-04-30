local utils = require("utils")
local spy = require("luassert.spy")

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

    it("modes.toggleMode updates active list - global", function()
        local testData = {
            id = "one",
            icon = "1",
            activationFn = spy.new(function() end),
            deactivationFn = spy.new(function() end),
        }

        local mode = modes.createIfNotPresent(
            testData.id,
            testData.activationFn,
            testData.deactivationFn,
            testData.icon
        )

        -- toggle mode --
        modes.toggleMode(mode)
        -- assert mode was added
        assert.same(
            modes.activeModes["*"][testData.id],
            { id = testData.id, icon = testData.icon }
        )
        modes.toggleMode(mode)
        -- assert mode was removed
        assert.is_nil(modes.activeModes["*"][testData.id])
    end)

    it("modes.getActiveModesIcons return valid list - global", function()
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

        local mode1 = modes.createIfNotPresent(
            testData1.id,
            activationFn,
            deactivationFn,
            testData1.icon
        )
        local mode2 = modes.createIfNotPresent(
            testData2.id,
            activationFn,
            deactivationFn,
            testData2.icon
        )
        local mode3 = modes.createIfNotPresent(
            testData3.id,
            activationFn,
            deactivationFn,
            testData3.icon
        )

        -- toggle mode --
        modes.toggleMode(mode1)
        modes.toggleMode(mode2)
        modes.toggleMode(mode3)

        local iconList = modes.getActiveModesIcons("*")

        assert.equals(utils.has_value(iconList, "1"), true)
        assert.equals(utils.has_value(iconList, "2"), true)
        assert.equals(utils.has_value(iconList, "t"), true)
    end)

    it("modes.toggleMode updates active list - buffer", function()
        local testData = {
            id = "one",
            icon = "1",
            activationFn = spy.new(function() end),
            deactivationFn = spy.new(function() end),
        }

        local options1 = {
            buffer = "1",
        }

        local mode = modes.createIfNotPresent(
            testData.id,
            testData.activationFn,
            testData.deactivationFn,
            testData.icon
        )

        -- toggle mode --
        modes.toggleMode(mode, options1)
        -- assert mode was added
        assert.same(
            modes.activeModes["1"][testData.id],
            { id = testData.id, icon = testData.icon, options = options1 }
        )
        modes.toggleMode(mode, options1)
        -- assert mode was removed
        assert.is_nil(modes.activeModes["1"][testData.id])
    end)

    it("modes.getActiveModesIcons return valid list - buffer", function()
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
            icon = "3",
        }

        local testData4 = {
            id = "four",
            icon = "4",
        }

        local options1 = {
            buffer = "1",
        }

        local options2 = {
            buffer = "2",
        }
        local mode1 = modes.createIfNotPresent(
            testData1.id,
            activationFn,
            deactivationFn,
            testData1.icon
        )
        local mode2 = modes.createIfNotPresent(
            testData2.id,
            activationFn,
            deactivationFn,
            testData2.icon
        )
        local mode3 = modes.createIfNotPresent(
            testData3.id,
            activationFn,
            deactivationFn,
            testData3.icon
        )
        local mode4 = modes.createIfNotPresent(
            testData4.id,
            activationFn,
            deactivationFn,
            testData4.icon
        )

        -- toggle mode --
        -- buffer 1 --
        modes.toggleMode(mode1, options1)
        modes.toggleMode(mode2, options1)
        -- buffer 2 --
        modes.toggleMode(mode3, options2)
        modes.toggleMode(mode4, options2)

        -- buffer 1 --
        local iconList1 = modes.getActiveModesIcons("1")
        -- buffer 2 --
        local iconList2 = modes.getActiveModesIcons("2")

        -- buffer 1 --
        assert.equals(utils.has_value(iconList1, "1"), true)
        assert.equals(utils.has_value(iconList1, "2"), true)
        -- buffer 2 --
        assert.equals(utils.has_value(iconList2, "3"), true)
        assert.equals(utils.has_value(iconList2, "4"), true)
    end)

    describe("modes mix validation", function()
        local activationFn
        local deactivationFn

        local testData1
        local testData2
        local testData3
        local testData4

        local options1

        local mode1
        local mode2
        local mode3
        local mode4

        before_each(function()
            activationFn = spy.new(function() end)
            deactivationFn = spy.new(function() end)

            testData1 = {
                id = "one",
                icon = "1",
            }

            testData2 = {
                id = "two",
                icon = "2",
            }

            options1 = {
                buffer = "99",
            }

            mode1 = modes.createIfNotPresent(
                testData1.id,
                activationFn,
                deactivationFn,
                testData1.icon
            )
            mode2 = modes.createIfNotPresent(
                testData2.id,
                activationFn,
                deactivationFn,
                testData2.icon
            )
        end)

        after_each(function()
            modes.deleteAllModes()
        end)

        it("mode enabled globally try to activate locally", function()
            local iconListGlobal
            local iconListLocal
            -- toggle mode --
            -- globally --
            modes.toggleMode(mode1)
            modes.toggleMode(mode2)

            iconListGlobal = modes.getActiveModesIcons("*")

            assert.equals(utils.has_value(iconListGlobal, "1"), true)
            assert.equals(utils.has_value(iconListGlobal, "2"), true)
            -- buffer 99 --
            modes.toggleMode(mode1, options1)

            iconListGlobal = modes.getActiveModesIcons("*")
            iconListLocal = modes.getActiveModesIcons("99")

            assert.equals(utils.has_value(iconListGlobal, "1"), true)
            assert.equals(utils.has_value(iconListGlobal, "2"), true)

            -- assert mode not added to buffer list --
            assert(#iconListLocal == 0, true)
        end)

        it("mode enabled globally try to deactivate locally", function()
            local iconListGlobal
            local iconListLocal
            -- toggle mode --
            -- globally --
            modes.toggleMode(mode1)
            modes.toggleMode(mode2)

            iconListGlobal = modes.getActiveModesIcons("*")

            assert.equals(utils.has_value(iconListGlobal, "1"), true)
            assert.equals(utils.has_value(iconListGlobal, "2"), true)
            -- enable buffer 99 --
            modes.toggleMode(mode1, options1)

            iconListGlobal = modes.getActiveModesIcons("*")
            iconListLocal = modes.getActiveModesIcons("99")

            assert.equals(utils.has_value(iconListGlobal, "1"), true)
            assert.equals(utils.has_value(iconListGlobal, "2"), true)

            assert(#iconListLocal == 0, true)

            -- try to disable it shouldn't work as it should not enabled at all --
            -- disable buffer 99 --
            modes.toggleMode(mode1, options1)

            iconListGlobal = modes.getActiveModesIcons("*")
            iconListLocal = modes.getActiveModesIcons("99")

            assert.equals(utils.has_value(iconListGlobal, "1"), true)
            assert.equals(utils.has_value(iconListGlobal, "2"), true)

            assert(#iconListLocal == 0, true)
        end)

        it("mode enabled locally try to activate globally", function()
            local iconListGlobal
            local iconListLocal
            -- toggle mode --
            -- buffer 99 --
            modes.toggleMode(mode1, options1)
            modes.toggleMode(mode2, options1)

            iconListLocal = modes.getActiveModesIcons("99")

            assert.equals(utils.has_value(iconListLocal, "1"), true)
            assert.equals(utils.has_value(iconListLocal, "2"), true)

            iconListGlobal = modes.getActiveModesIcons("*")
            assert(#iconListGlobal == 0, true)

            -- activate a mode globally --
            modes.toggleMode(mode1)

            iconListLocal = modes.getActiveModesIcons("99")
            iconListGlobal = modes.getActiveModesIcons("*")

            -- assert mode 1 is added to global list --
            assert.equals(utils.has_value(iconListGlobal, "1"), true)
            -- assert mode 1 is not in local list --
            assert.equals(utils.has_value(iconListLocal, "1"), false)
            -- assert mode 2 is still in buffer list --
            assert.equals(utils.has_value(iconListLocal, "2"), true)
        end)
    end)
end)
