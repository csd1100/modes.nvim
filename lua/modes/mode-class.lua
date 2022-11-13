local module = {}
--- Get Icon for Mode.
-- If icon is not provided then return 1st character of id
---@param id string id of mode
---@param icon string icon for mode
---@return string icon to be used by mode
local function getValidIcon(id, icon)
	if icon == nil or icon == "" then
		return string.sub(id, 1, 1)
	else
		return icon
	end
end

--- Get a Mode class (table) to create and manage modes
---@return table Mode class (table)
function module.getModeClass()
	local Mode = {
		_id = "Mode",
		_icon = "M",
		_enabled = false,
		_activationFn = nil,
		_deactivationFn = nil,
	}
	Mode.__index = Mode

	--- Create a new Mode
	---@param id string identifier for the mode
	---@param activationFn function will be called when mode is enabled
	---@param deactivationFn function will be called when mode is disabled
	---@param icon character icon to be displayed that can be displayed
	---@return table Mode
	function Mode.new(id, activationFn, deactivationFn, icon)
		local this = setmetatable({}, Mode)
		this._id = id
		this._icon = getValidIcon(id, icon)
		this._activationFn = activationFn
		this._deactivationFn = deactivationFn
		return this
	end

	--- get id of the Mode object
	---@return string id
	function Mode:getId()
		return self._id
	end

	--- get icon of the Mode object
	---@return string
	function Mode:getIcon()
		return self._icon
	end

	--- is mode enabled at some scope
	---@return boolean
	function Mode:isEnabled()
		return self._enabled
	end

	--- activate the mode
	function Mode:activate(options)
		self._enabled = true
		self:_activationFn(options)
	end

	--- deactivate the mode
	function Mode:deactivate(options)
		self._enabled = false
		self:_deactivationFn(options)
	end

	return Mode
end

return module
