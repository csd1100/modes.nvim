local mode_class = require("modes.mode-class").get_mode_class()
local throw_error = require("modes.utils").throw_error

local mode_storage = {}

local module = {}

module.setup_called = false

local function on_BufDel_clear_active_modes()
    local bufnr = tonumber(vim.fn.expand("<abuf>"))
    for _, mode in pairs(mode_storage) do
        if mode:is_enabled_for_buffer(bufnr) then
            local options = mode:get_options_for_buffer(bufnr)
            mode:toggle(options)
        end
    end
end

--- get a mode or create a new Mode
---@param id string identifier for Mode
---@param activation_fn function to be called when enabled
---@param deactivation_fn function to be called when disabled
---@param icon string icon to be displayed
---@return any
function module.create_if_not_present(id, activation_fn, deactivation_fn, icon)
    if not module.setup_called then
        throw_error(
            "Plugin not initialized, please add require('modes').setup() to config"
        )
        return
    end
    if not id or not activation_fn or not deactivation_fn then
        throw_error("id, activation_fn and deactivation_fn are required")
    end
    local mode = mode_storage[id]
    if not mode then
        mode = mode_class.new(id, activation_fn, deactivation_fn, icon)
        mode_storage[id] = mode
    end
    return mode:get_id()
end

--- toggle the mode
---@param id string
---@param options table
function module.toggle_mode(id, options)
    options = options or {}
    if not module.setup_called then
        throw_error(
            "Plugin not initialized, please add require('modes').setup() to config"
        )
        return
    end

    local mode = mode_storage[id]
    if not mode then
        throw_error("Mode " .. id .. " doesn't exist")
    end

    mode:toggle(options)
end

--- get list of icons of active modes to display
---@return table list of icons
function module.get_active_modes_icons(buffer)
    local icon_list = {}
    for _, mode in pairs(mode_storage) do
        if buffer == "*" then
            if mode:is_enabled_globally() then
                table.insert(icon_list, mode:get_icon())
            end
        else
            if mode:is_enabled_for_buffer(buffer) then
                table.insert(icon_list, mode:get_icon())
            end
        end
    end
    return icon_list
end

--- remove all defined modes from storage
function module._delete_all_modes()
    mode_storage = {}
end

function module._get_globally_active_mode_with_id(id)
    local mode = mode_storage[id]
    if mode and mode:is_enabled_globally() then
        return {
            id = mode:get_id(),
            icon = mode:get_icon(),
            options = mode:get_options_for_global(),
        }
    end
end

function module._get_buffer_active_mode_with_id(buffer, id)
    local mode = mode_storage[id]
    if mode and mode:is_enabled_for_buffer(buffer) then
        return {
            id = mode:get_id(),
            icon = mode:get_icon(),
            options = mode:get_options_for_buffer(buffer),
        }
    end
end

function module.map(mode_id, maps, options) end

function module.unmap(mode_id, unmaps, options) end

function module.setup()
    vim.api.nvim_create_augroup("ModesNvim", {
        clear = true,
    })
    vim.api.nvim_create_autocmd("BufDelete", {
        group = "ModesNvim",
        callback = on_BufDel_clear_active_modes,
    })
    module.setup_called = true
end

return module
