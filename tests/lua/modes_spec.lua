local utils = require("utils")
local spy = require("luassert.spy")

describe("modes_spec", function()
    local modes

    before_each(function()
        modes = require("modes")
        modes.setup()
    end)

    after_each(function()
        modes._delete_all_modes()
    end)

    it("toggle_mode throws error if mode doesn't exist", function()
        assert.has.errors(function()
            modes.toggle_mode("id")
        end)
    end)

    it("modes.toggle_mode updates active list - global", function()
        local test_data = {
            id = "one",
            icon = "1",
            activation_fn = spy.new(function() end),
            deactivation_fn = spy.new(function() end),
        }

        local mode = modes.create_if_not_present(
            test_data.id,
            test_data.activation_fn,
            test_data.deactivation_fn,
            test_data.icon
        )

        -- toggle mode --
        modes.toggle_mode(mode)
        -- assert mode was added
        assert.same(
            modes._active_modes["*"][test_data.id],
            { id = test_data.id, icon = test_data.icon }
        )
        modes.toggle_mode(mode)
        -- assert mode was removed
        assert.is_nil(modes._active_modes["*"][test_data.id])
    end)

    it("modes.get_active_modes_icons return valid list - global", function()
        local activation_fn = spy.new(function() end)
        local deactivation_fn = spy.new(function() end)

        local test_data1 = {
            id = "one",
            icon = "1",
        }

        local test_data2 = {
            id = "two",
            icon = "2",
        }

        local test_data3 = {
            id = "three",
        }

        local mode1 = modes.create_if_not_present(
            test_data1.id,
            activation_fn,
            deactivation_fn,
            test_data1.icon
        )
        local mode2 = modes.create_if_not_present(
            test_data2.id,
            activation_fn,
            deactivation_fn,
            test_data2.icon
        )
        local mode3 = modes.create_if_not_present(
            test_data3.id,
            activation_fn,
            deactivation_fn,
            test_data3.icon
        )

        -- toggle mode --
        modes.toggle_mode(mode1)
        modes.toggle_mode(mode2)
        modes.toggle_mode(mode3)

        local icon_list = modes.get_active_modes_icons("*")

        assert.equals(utils.has_value(icon_list, "1"), true)
        assert.equals(utils.has_value(icon_list, "2"), true)
        assert.equals(utils.has_value(icon_list, "t"), true)
    end)

    it("modes.toggle_mode updates active list - buffer", function()
        local test_data = {
            id = "one",
            icon = "1",
            activation_fn = spy.new(function() end),
            deactivation_fn = spy.new(function() end),
        }

        local options1 = {
            buffer = "1",
        }

        local mode = modes.create_if_not_present(
            test_data.id,
            test_data.activation_fn,
            test_data.deactivation_fn,
            test_data.icon
        )

        -- toggle mode --
        modes.toggle_mode(mode, options1)
        -- assert mode was added
        assert.same(
            modes._active_modes["1"][test_data.id],
            { id = test_data.id, icon = test_data.icon, options = options1 }
        )
        modes.toggle_mode(mode, options1)
        -- assert mode was removed
        assert.is_nil(modes._active_modes["1"][test_data.id])
    end)

    it("modes.get_active_modes_icons return valid list - buffer", function()
        local activation_fn = spy.new(function() end)
        local deactivation_fn = spy.new(function() end)

        local test_data1 = {
            id = "one",
            icon = "1",
        }

        local test_data2 = {
            id = "two",
            icon = "2",
        }

        local test_data3 = {
            id = "three",
            icon = "3",
        }

        local test_data4 = {
            id = "four",
            icon = "4",
        }

        local options1 = {
            buffer = "1",
        }

        local options2 = {
            buffer = "2",
        }
        local mode1 = modes.create_if_not_present(
            test_data1.id,
            activation_fn,
            deactivation_fn,
            test_data1.icon
        )
        local mode2 = modes.create_if_not_present(
            test_data2.id,
            activation_fn,
            deactivation_fn,
            test_data2.icon
        )
        local mode3 = modes.create_if_not_present(
            test_data3.id,
            activation_fn,
            deactivation_fn,
            test_data3.icon
        )
        local mode4 = modes.create_if_not_present(
            test_data4.id,
            activation_fn,
            deactivation_fn,
            test_data4.icon
        )

        -- toggle mode --
        -- buffer 1 --
        modes.toggle_mode(mode1, options1)
        modes.toggle_mode(mode2, options1)
        -- buffer 2 --
        modes.toggle_mode(mode3, options2)
        modes.toggle_mode(mode4, options2)

        -- buffer 1 --
        local icon_list1 = modes.get_active_modes_icons("1")
        -- buffer 2 --
        local icon_list2 = modes.get_active_modes_icons("2")

        -- buffer 1 --
        assert.equals(utils.has_value(icon_list1, "1"), true)
        assert.equals(utils.has_value(icon_list1, "2"), true)
        -- buffer 2 --
        assert.equals(utils.has_value(icon_list2, "3"), true)
        assert.equals(utils.has_value(icon_list2, "4"), true)
    end)

    describe("modes mix validation", function()
        local activation_fn
        local deactivation_fn

        local test_data1
        local test_data2
        local test_data3
        local test_data4

        local options1

        local mode1
        local mode2
        local mode3
        local mode4

        before_each(function()
            activation_fn = spy.new(function() end)
            deactivation_fn = spy.new(function() end)

            test_data1 = {
                id = "one",
                icon = "1",
            }

            test_data2 = {
                id = "two",
                icon = "2",
            }

            options1 = {
                buffer = "99",
            }

            mode1 = modes.create_if_not_present(
                test_data1.id,
                activation_fn,
                deactivation_fn,
                test_data1.icon
            )
            mode2 = modes.create_if_not_present(
                test_data2.id,
                activation_fn,
                deactivation_fn,
                test_data2.icon
            )
        end)

        after_each(function()
            modes._delete_all_modes()
        end)

        it("mode enabled globally try to activate locally", function()
            local icon_list_global
            local icon_list_local
            -- toggle mode --
            -- globally --
            modes.toggle_mode(mode1)
            modes.toggle_mode(mode2)

            icon_list_global = modes.get_active_modes_icons("*")

            assert.equals(utils.has_value(icon_list_global, "1"), true)
            assert.equals(utils.has_value(icon_list_global, "2"), true)
            -- buffer 99 --
            modes.toggle_mode(mode1, options1)

            icon_list_global = modes.get_active_modes_icons("*")
            icon_list_local = modes.get_active_modes_icons("99")

            assert.equals(utils.has_value(icon_list_global, "1"), true)
            assert.equals(utils.has_value(icon_list_global, "2"), true)

            -- assert mode not added to buffer list --
            assert(#icon_list_local == 0, true)
        end)

        it("mode enabled globally try to deactivate locally", function()
            local icon_list_global
            local icon_list_local
            -- toggle mode --
            -- globally --
            modes.toggle_mode(mode1)
            modes.toggle_mode(mode2)

            icon_list_global = modes.get_active_modes_icons("*")

            assert.equals(utils.has_value(icon_list_global, "1"), true)
            assert.equals(utils.has_value(icon_list_global, "2"), true)
            -- enable buffer 99 --
            modes.toggle_mode(mode1, options1)

            icon_list_global = modes.get_active_modes_icons("*")
            icon_list_local = modes.get_active_modes_icons("99")

            assert.equals(utils.has_value(icon_list_global, "1"), true)
            assert.equals(utils.has_value(icon_list_global, "2"), true)

            assert(#icon_list_local == 0, true)

            -- try to disable it shouldn't work as it should not enabled at all --
            -- disable buffer 99 --
            modes.toggle_mode(mode1, options1)

            icon_list_global = modes.get_active_modes_icons("*")
            icon_list_local = modes.get_active_modes_icons("99")

            assert.equals(utils.has_value(icon_list_global, "1"), true)
            assert.equals(utils.has_value(icon_list_global, "2"), true)

            assert(#icon_list_local == 0, true)
        end)

        it("mode enabled locally try to activate globally", function()
            local icon_list_global
            local icon_list_local
            -- toggle mode --
            -- buffer 99 --
            modes.toggle_mode(mode1, options1)
            modes.toggle_mode(mode2, options1)

            icon_list_local = modes.get_active_modes_icons("99")

            assert.equals(utils.has_value(icon_list_local, "1"), true)
            assert.equals(utils.has_value(icon_list_local, "2"), true)

            icon_list_global = modes.get_active_modes_icons("*")
            assert(#icon_list_global == 0, true)

            -- activate a mode globally --
            modes.toggle_mode(mode1)

            icon_list_local = modes.get_active_modes_icons("99")
            icon_list_global = modes.get_active_modes_icons("*")

            -- assert mode 1 is added to global list --
            assert.equals(utils.has_value(icon_list_global, "1"), true)
            -- assert mode 1 is not in local list --
            assert.equals(utils.has_value(icon_list_local, "1"), false)
            -- assert mode 2 is still in buffer list --
            assert.equals(utils.has_value(icon_list_local, "2"), true)
        end)
    end)
end)
