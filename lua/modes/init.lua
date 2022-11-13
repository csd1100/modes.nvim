local modeClass = require("modes.mode-class").getModeClass()

local modeStorage = {}

local module = {}

--- add to active modes storage
---@param id string identifier of mode
---@param icon string icon to be displayed
local function addToActiveModes(id, icon)
	module.activeModes[id] = {
		id = id,
		icon = icon,
	}
end

--- remove from active modes storage
---@param id any
local function removeFromActiveModes(id)
	module.activeModes[id] = nil
end

module.activeModes = {}

--- Get a mode or Create a new Mode
---@param id string identifier for Mode
---@param activationFn function to be called when enabled
---@param deactivationFn function to be called when disabled
---@param icon string icon to be displayed
---@return Mode.id
function module.createIfNotPresent(id, activationFn, deactivationFn, icon)
	local mode = modeStorage[id]
	if not mode then
		mode = modeClass.new(id, activationFn, deactivationFn, icon)
		modeStorage[id] = mode
	end
	return mode:getId()
end

--- toggle mode and update active modes
---@param id string identifier of mode
function module.toggleMode(id)
	local mode = modeStorage[id]
	if not mode then
		error("Mode with id " .. id .. " doesn't exist")
	end

	mode:toggle()

	if mode:isActive() then
		addToActiveModes(mode:getId(), mode:getIcon())
	else
		removeFromActiveModes(mode:getId())
	end
end

--- get list of icons of active modes to display
---@return table list of icons
function module.getActiveModesIcons()
	local iconList = {}
	for _, idAndIcon in pairs(module.activeModes) do
		table.insert(iconList, idAndIcon.icon)
	end
	return iconList
end

--- Remove all defined modes from storage
function module.deleteAllModes()
	modeStorage = {}
end

return module
