local modeClass = require("modes.mode-class").getModeClass()

local module = {}

--- Create a new Mode
---@param id string identifier for Mode
---@param activationFn function to be called when enabled
---@param deactivationFn function to be called when disabled
---@param icon character icon to be displayed
---@return Mode
function module.createMode(id, activationFn, deactivationFn, icon)
	return modeClass.new(id, activationFn, deactivationFn, icon)
end

return module
