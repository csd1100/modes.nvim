local modeClass = require("modes.mode-class").getModeClass()
local utils = require("lua.utils")

local modeStorage = {}

local module = {}

module.activeModes = {}

--- get global active modes list
---@return table
local globalList = function()
	if not module.activeModes["*"] then
		module.activeModes["*"] = {}
	end
	return module.activeModes["*"]
end

--- get list of active modes for buffer
---@param buffer number
---@return table
local bufferList = function(buffer)
	if not module.activeModes[buffer] then
		module.activeModes[buffer] = {}
	end
	return module.activeModes[buffer]
end

--- add mode to buffer active modes list
---@param id string
---@param options table
local function addToBufferList(id, options)
	if globalList()[id] then
		print("Mode " .. id .. " is already enabled Globally")
		return
	end
	local mode = modeStorage[id]
	mode:activate(options)
	bufferList(options.buffer)[id] = {
		id = id,
		icon = mode:getIcon(),
	}
end

--- remove mode from buffer's active modes list
---@param id string
---@param options table
local function removeFromBufferList(id, options)
	if globalList()[id] then
		error("Mode " .. id .. " is enabled Globally")
	end
	local mode = modeStorage[id]
	mode:deactivate(options)
	bufferList(options.buffer)[id] = nil
end

--- handle toggling of mode for buffer
---@param id string identifier of buffer
---@param options table additional options
local function handleBufferToggle(id, options)
	if bufferList(options.buffer)[id] then
		removeFromBufferList(id, options)
	else
		addToBufferList(id, options)
	end
end

--- check if mode is enabled for any buffer
---@param id string identifier for mode
---@return table list of buffer for which mode is active
-- TODO: might be unstable causing mode not removed from buffer list when enabling globally
local function isInBufferList(id)
	local inBuffersList = {}
	for key, value in pairs(module.activeModes) do
		if key == "*" then
			break
		else
			if value[id] then
				table.insert(inBuffersList, key)
			end
		end
	end
	return inBuffersList
end

--- add mode to global active modes list
---@param id string identifier of mode
---@param options table additional options
local function addToGlobalList(id, options)
	local inBuffersList = isInBufferList(id)
	if #inBuffersList > 0 then
		print("Mode " .. id .. " is enabled in buffers; disabling")
		for _, buffer in pairs(inBuffersList) do
			bufferList(buffer)[id] = nil
		end
	end
	local mode = modeStorage[id]
	mode:activate(options)
	globalList()[id] = {
		id = id,
		icon = mode:getIcon(),
	}
end

--- remove mode from global active modes list
---@param id string identifier of mode
---@param options table additional options
local function removeFromGlobalList(id, options)
	local mode = modeStorage[id]
	mode:deactivate(options)
	globalList()[id] = nil
end

--- toggle mode globally
---@param id string identifier of mode
---@param options table additional options
local function handleGlobalToggle(id, options)
	if globalList()[id] then
		removeFromGlobalList(id, options)
	else
		addToGlobalList(id, options)
	end
end

--- Get a mode or Create a new Mode
---@param id string identifier for Mode
---@param activationFn function to be called when enabled
---@param deactivationFn function to be called when disabled
---@param icon string icon to be displayed
---@return Mode.id
function module.createIfNotPresent(id, activationFn, deactivationFn, icon)
	if not id or not activationFn or not deactivationFn then
		error("id, activationFn and deactivationFn are required")
	end
	local mode = modeStorage[id]
	if not mode then
		mode = modeClass.new(id, activationFn, deactivationFn, icon)
		modeStorage[id] = mode
	end
	return mode:getId()
end

--- toggle the mode
---@param id string
---@param options table
function module.toggleMode(id, options)
	local mode = modeStorage[id]
	if not mode then
		error("Mode " .. id .. " doesn't exist'")
	end
	if options and options.buffer then
		handleBufferToggle(id, options)
	else
		handleGlobalToggle(id, options)
	end
end

--- get list of icons of active modes to display
---@return table list of icons
function module.getActiveModesIcons(buffer)
	local iconList = {}
	for key, idAndIcon in pairs(module.activeModes[buffer]) do
		table.insert(iconList, idAndIcon.icon)
	end
	return iconList
end

--- Remove all defined modes from storage
function module.deleteAllModes()
	modeStorage = {}
	module.activeModes = {}
end

return module
