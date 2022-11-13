--- Check if a row matches the specified key constraints.
-- @param row The row to check
-- @param key_constraints The key constraints to apply
-- @return A boolean result
local function filter_row(row, key_constraints)
	-- Loop through all constraints
	for k, v in pairs(key_constraints) do
		if v and not row[k] then
			-- The row is missing the key entirely,
			-- definitely not a match
			return false
		end

		-- Wrap the key and constraint values in arrays,
		-- if they're not arrays already (so we can loop through them)
		local actual_values = type(row[k]) == "table" and row[k] or { row[k] }
		local required_values = type(v) == "table" and v or { v }

		-- Loop through the values we *need* to find
		for i = 1, #required_values do
			local found
			-- Loop through the values actually present
			for j = 1, #actual_values do
				if actual_values[j] == required_values[i] then
					-- This object has the required value somewhere in the key,
					-- no need to look any farther
					found = true
					break
				end
			end

			if not found then
				return false
			end
		end
	end

	return true
end

local M = {}

function M.DeepPrint(e)
	-- if e is a table, we should iterate over its elements
	if type(e) == "table" then
		for k, v in pairs(e) do -- for every element in the table
			print(k)
			M.DeepPrint(v) -- recursively repeat the same procedure
		end
	else -- if not, we can just print it
		print(e)
	end
end

function M.if_successful(plug)
	local status, plugin = pcall(require, plug)
	if not status then
		vim.notify("failed to load " .. plug, "error")
		return
	end
	return plugin
end

function M.if_successful_then_setup(plug)
	local plugin = M.if_successful(plug)
	if not plugin then
		vim.notify("failed to load and setup " .. plug, "error")
		return
	end
	plugin.setup()
end

--- Filter an array, returning entries matching `key_values`.
-- Found at https://stackoverflow.com/questions/52330757/table-filter-in-lua-for-multidimensional-tables
-- @param input The array to process
-- @param key_values A table of keys mapped to their viable values
-- @return An array of matches
function M.filter(input, key_values)
	local result = {}

	for i = 1, #input do
		local row = input[i]
		if filter_row(row, key_values) then
			result[#result + 1] = row
		end
	end

	return result
end

function M.tableLength(tbl)
	local count = 0
	for _, _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

return M
