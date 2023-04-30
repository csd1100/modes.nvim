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
        _enabled = false,
        _activation_fn = nil,
        _deactivation_fn = nil,
    }
    Mode.__index = Mode

    --- create a new mode
    ---@param id string identifier for the mode
    ---@param activation_fn function will be called when mode is enabled
    ---@param deactivation_fn function will be called when mode is disabled
    ---@param icon character icon to be displayed that can be displayed
    ---@return table Mode
    function Mode.new(id, activation_fn, deactivation_fn, icon)
        local this = setmetatable({}, Mode)
        this._id = id
        this._icon = get_valid_icon(id, icon)
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

    --- is mode enabled at some scope
    ---@return boolean
    function Mode:is_enabled()
        return self._enabled
    end

    --- activate the mode
    function Mode:activate(options)
        self._enabled = true
        self._activation_fn(options)
    end

    --- deactivate the mode
    function Mode:deactivate(options)
        self._enabled = false
        self._deactivation_fn(options)
    end

    return Mode
end

return module
