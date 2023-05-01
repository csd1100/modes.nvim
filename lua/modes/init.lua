local mode_class = require("modes.mode-class").get_mode_class()

local mode_storage = {}

local module = {}

module.setup_called = false

module._active_modes = {}

local throw_error = function(msg)
    vim.notify(msg, vim.log.levels.ERROR)
    error(msg)
end

--- get global active modes list
---@return table
local global_list = function()
    if not module._active_modes["*"] then
        module._active_modes["*"] = {}
    end
    return module._active_modes["*"]
end

--- get list of active modes for buffer
---@param buffer number
---@return table
local buffer_list = function(buffer)
    if not module._active_modes[buffer] then
        module._active_modes[buffer] = {}
    end
    return module._active_modes[buffer]
end

--- add mode to buffer active modes list
---@param id string
---@param options table
local function add_to_buffer_list(id, options)
    if global_list()[id] then
        print("Mode " .. id .. " is already enabled Globally")
        return
    end
    local mode = mode_storage[id]
    mode:activate(options)
    buffer_list(options.buffer)[id] = {
        id = id,
        icon = mode:get_icon(),
        options = options,
    }
end

--- remove mode from buffer's active modes list
---@param id string
---@param options table
local function remove_from_buffer_list(id, options)
    if global_list()[id] then
        throw_error("Mode " .. id .. " is enabled Globally")
    end
    local mode = mode_storage[id]
    mode:deactivate(options)
    buffer_list(options.buffer)[id] = nil
end

--- handle toggling of mode for buffer
---@param id string identifier of buffer
---@param options table additional options
local function handle_buffer_toggle(id, options)
    if buffer_list(options.buffer)[id] then
        remove_from_buffer_list(id, options)
    else
        add_to_buffer_list(id, options)
    end
end

--- check if mode is enabled for any buffer
---@param id string identifier for mode
---@return table list of buffer for which mode is active
local function get_active_buffers(id)
    local active_buffers_list = {}
    for buffer, modes_list in pairs(module._active_modes) do
        if buffer ~= "*" then
            if vim.tbl_contains(vim.tbl_keys(modes_list), id) then
                table.insert(active_buffers_list, buffer)
            end
        end
    end
    return active_buffers_list
end

--- add mode to global active modes list
---@param id string identifier of mode
---@param options table additional options
local function add_to_global_list(id, options)
    local in_buffers_list = get_active_buffers(id)
    if #in_buffers_list > 0 then
        print("Mode " .. id .. " is enabled in buffers; disabling")
        for _, buffer in pairs(in_buffers_list) do
            buffer_list(buffer)[id] = nil
        end
    end
    local mode = mode_storage[id]
    mode:activate(options)
    global_list()[id] = {
        id = id,
        icon = mode:get_icon(),
        options = options,
    }
end

--- remove mode from global active modes list
---@param id string identifier of mode
---@param options table additional options
local function remove_from_global_list(id, options)
    local mode = mode_storage[id]
    mode:deactivate(options)
    global_list()[id] = nil
end

--- toggle mode globally
---@param id string identifier of mode
---@param options table additional options
local function handle_global_toggle(id, options)
    if global_list()[id] then
        remove_from_global_list(id, options)
    else
        add_to_global_list(id, options)
    end
end

local function on_BufDel_clear_active_modes()
    local bufnr = tonumber(vim.fn.expand("<abuf>"))
    if not buffer_list(bufnr) then
        return
    end

    for id, data in pairs(buffer_list(bufnr)) do
        module.toggle_mode(id, data.options)
        buffer_list(bufnr)[id] = nil
    end
    module._active_modes[bufnr] = nil
end

--- get a mode or create a new Mode
---@param id string identifier for Mode
---@param activation_fn function to be called when enabled
---@param deactivation_fn function to be called when disabled
---@param icon string icon to be displayed
---@return any
function module.create_if_not_present(id, activation_fn, deactivation_fn, icon)
    if not module.setup_called then
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
    if not module.setup_called then
        return
    end

    local mode = mode_storage[id]
    if not mode then
        throw_error("Mode " .. id .. " doesn't exist'")
    end

    if options and options.buffer then
        handle_buffer_toggle(id, options)
    else
        handle_global_toggle(id, options)
    end
end

--- get list of icons of active modes to display
---@return table list of icons
function module.get_active_modes_icons(buffer)
    local icon_list = {}
    for _, id_and_icon in pairs(module._active_modes[buffer]) do
        table.insert(icon_list, id_and_icon.icon)
    end
    return icon_list
end

--- remove all defined modes from storage
function module._delete_all_modes()
    mode_storage = {}
    module._active_modes = {}
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
