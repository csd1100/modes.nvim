local function helper(txt)
	return txt .. " helper"
end

local module = {}

function module.fn(txt)
	return helper(txt)
end

return module
