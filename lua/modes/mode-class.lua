local throw_error = require("modes.utils").throw_error
local module = {}
--- get icon for mode.
-- if icon is not provided then return 1st character of id
---@param id string id of mode
---@param icon string icon for mode
---@return string icon to be used by mode
local function get_valid_icon(id, icon)
    if icon == nil or icon == "" then
        return string.sub(id, 1, 1)
    else
        return icon
    end
end

--- get a mode class (table) to create and manage modes
---@return table Mode class (table)
function module.get_mode_class()
    local Mode = {
        _id = "Mode",
        _icon = "M",
        _activation_fn = nil,
        _deactivation_fn = nil,
        _buffers = nil,
    }
    Mode.__index = Mode

    --- create a new mode
    ---@param id string identifier for the mode
    ---@param activation_fn function will be called when mode is enabled
    ---@param deactivation_fn function will be called when mode is disabled
    ---@param icon string icon to be displayed that can be displayed
    ---@return table Mode
    function Mode.new(id, activation_fn, deactivation_fn, icon)
        local this = setmetatable({}, Mode)
        this._id = id
        this._icon = get_valid_icon(id, icon)
        this._buffers = {}
        this._activation_fn = activation_fn
        this._deactivation_fn = deactivation_fn
        return this
    end

    --- get id of the Mode object
    ---@return string id
    function Mode:get_id()
        return self._id
    end

    --- get icon of the Mode object
    ---@return string
    function Mode:get_icon()
        return self._icon
    end

    --- returns true if mode is enabled globally
    --- @returns boolean
    function Mode:is_enabled_globally()
        return self._buffers and self._buffers["*"] ~= nil
    end

    --- returns true if mode is enabled for buffer
    --- @param bufnr number buffer number
    --- @returns boolean
    function Mode:is_enabled_for_buffer(bufnr)
        return self._buffers and self._buffers[tostring(bufnr)] ~= nil
    end

    --- enables the mode for passed in buffer
    --- @param buffer_str string buffer number converted to string
    --- @param options table options passed to enable the mode
    function Mode:enable_for_buffer(buffer_str, options)
        vim.notify(
            "Enabling Mode " .. self:get_id() .. " for buffer",
            vim.log.levels.DEBUG
        )
        if not self._buffers[buffer_str] then
            self._buffers[buffer_str] = options
        end
    end

    --- Enables the mode globally. Disables modes for buffers is enabled.
    --- @param options table options passed to enable the mode
    function Mode:enable_globally(options)
        for buffer, buf_options in pairs(self._buffers) do
            vim.notify(
                "Disabling Mode "
                    .. self:get_id()
                    .. " for buffer "
                    .. buffer
                    .. " and enabling Globally",
                vim.log.levels.DEBUG
            )
            self:deactivate(buf_options)
        end
        vim.notify(
            "Enabling Mode " .. self:get_id() .. " Globally",
            vim.log.levels.DEBUG
        )
        self._buffers = { ["*"] = options }
    end

    --- Activate the mode
    --- @param options table passed in options
    function Mode:activate(options)
        options = options or {}
        if options.buffer then
            self:enable_for_buffer(tostring(options.buffer), options)
        else
            self:enable_globally(options)
        end
        self._activation_fn(options)
    end

    --- Disables the mode globally.
    function Mode:disable_globally()
        if not self._buffers["*"] then
            throw_error(
                "The Mode " .. self:get_id() .. " was not enabled Globally!"
            )
        else
            self._buffers = {}
        end
    end

    --- Disables mode for passed in buffer
    --- @param buffer_str string buffer number converted to string
    function Mode:disable_for_buffer(buffer_str)
        self._buffers[buffer_str] = nil
    end

    --- Deactivate the mode
    --- @param options table passed in options
    function Mode:deactivate(options)
        options = options or {}
        if options.buffer then
            self:disable_for_buffer(tostring(options.buffer))
        else
            self:disable_globally()
        end
        self._deactivation_fn(options)
    end

    --- Toggles the mode based on passed in enabled value
    --- @param enabled boolean if mode is enabled or disabled
    --- @param options table options passed in
    function Mode:handle_toggle(enabled, options)
        if enabled then
            self:deactivate(options)
        else
            self:activate(options)
        end
    end

    --- Toggles the mode for buffer
    --- @param bufnr number buffer number
    --- @param options table options passed in
    function Mode:handle_buffer_toggle(bufnr, options)
        if self._buffers["*"] then
            throw_error(
                "Mode " .. self:get_id() .. " is already activated Globally"
            )
        else
            self:handle_toggle(self:is_enabled_for_buffer(bufnr), options)
        end
    end

    --- Toggles the mode globally
    --- @param options table options passed in
    function Mode:handle_global_toggle(options)
        self:handle_toggle(self:is_enabled_globally(), options)
    end

    --- Toggles the mode
    --- @param options table options passed in
    function Mode:toggle(options)
        if options.buffer then
            self:handle_buffer_toggle(options.buffer, options)
        else
            self:handle_global_toggle(options)
        end
    end

    return Mode
end

return module
