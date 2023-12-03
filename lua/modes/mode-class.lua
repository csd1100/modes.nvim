local utils = require("modes.utils")

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
    -- all storage table docs
    -- _buffers for mode activated for buffer
    -- _buffers = {
    --     ["buffer_number_string"] = options, -- passed in options at the time of activate
    --     ["buffer_number_string1"] = options1, -- passed in options at the time of activate
    -- }
    -- _buffers for mode activated for globally
    -- _buffers = {
    --     ["*"] = options -- passed in options at the time of activate
    -- }
    -- _existing_maps_cache = {
    --     ["vim_mode"] = {
    --         ["lhs"] = {
    --             ["rhs"] = "",
    --             ["opts"] = keymap_options,
    --         },
    --     },
    --     -- only used for buffer related keymap backup
    --     ["buffer_number_string"] = {
    --         ["vim_mode"] = {
    --             ["lhs"] = {
    --                 ["rhs"] = "",
    --                 ["opts"] = keymap_options,
    --             },
    --         },
    --     },
    -- }
    -- _maps_cache = {
    --     ["vim_mode"] = {
    --         ["lhs"] = {
    --             ["rhs"] = "",
    --             ["opts"] = keymap_options,
    --         },
    --     },
    -- }

    local Mode = {
        _id = "Mode",
        _icon = "M",
        _activation_fn = nil,
        _deactivation_fn = nil,
        _buffers = nil,
        _existing_maps_cache = nil,
        _maps_cache = nil,
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
        this._existing_maps_cache = {}
        this._maps_cache = {}
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
        self:apply_maps(self._maps_cache, options)
    end

    --- Disables the mode globally.
    function Mode:disable_globally()
        if not self._buffers["*"] then
            vim.notify(
                "The Mode " .. self:get_id() .. " was not enabled Globally!",
                vim.log.levels.WARN
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
        self:unapply_maps(self._maps_cache, options)
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

    --- Enables the mode
    --- @param enabled boolean if mode is enabled or disabled
    --- @param options table options passed in
    function Mode:handle_enable(enabled, options)
        if not enabled then
            self:activate(options)
        end
    end

    --- Disables the mode
    --- @param enabled boolean if mode is enabled or disabled
    --- @param options table options passed in
    function Mode:handle_disable(enabled, options)
        if enabled then
            self:deactivate(options)
        else
            vim.notify(
                "Mode " .. self:get_id() .. " is not enabled",
                vim.log.levels.WARN
            )
        end
    end

    --- Toggles the mode for buffer
    --- @param bufnr number buffer number
    --- @param options table options passed in
    function Mode:handle_buffer_toggle(bufnr, options)
        if self._buffers["*"] then
            vim.notify(
                "Mode " .. self:get_id() .. " is already activated Globally",
                vim.log.levels.WARN
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

    --- Enables the mode for buffer
    --- @param bufnr number buffer number
    --- @param options table options passed in
    function Mode:handle_buffer_enable(bufnr, options)
        if self._buffers["*"] then
            vim.notify(
                "Mode " .. self:get_id() .. " is already activated Globally",
                vim.log.levels.WARN
            )
        else
            self:handle_enable(self:is_enabled_for_buffer(bufnr), options)
        end
    end

    --- Enables the mode globally
    --- @param options table options passed in
    function Mode:handle_global_enable(options)
        self:handle_enable(self:is_enabled_globally(), options)
    end

    --- Disables the mode for buffer
    --- @param bufnr number buffer number
    --- @param options table options passed in
    function Mode:handle_buffer_disable(bufnr, options)
        if self._buffers["*"] then
            vim.notify(
                "Mode " .. self:get_id() .. " is already activated Globally",
                vim.log.levels.WARN
            )
        else
            self:handle_disable(self:is_enabled_for_buffer(bufnr), options)
        end
    end

    --- Disables the mode globally
    --- @param options table options passed in
    function Mode:handle_global_disable(options)
        self:handle_disable(self:is_enabled_globally(), options)
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

    --- Enables the mode
    --- @param options table options passed in
    function Mode:enable(options)
        if options.buffer then
            self:handle_buffer_enable(options.buffer, options)
        else
            self:handle_global_enable(options)
        end
    end

    --- Disables the mode
    --- @param options table options passed in
    function Mode:disable(options)
        if options.buffer then
            self:handle_buffer_disable(options.buffer, options)
        else
            self:handle_global_disable(options)
        end
    end

    --- Get options for buffer
    --- @param bufnr number buffer number
    function Mode:get_options_for_buffer(bufnr)
        return self._buffers[tostring(bufnr)]
    end

    --- Get options for buffer
    function Mode:get_options_for_global()
        return self._buffers["*"]
    end

    --- Add maps to self._maps_cache
    ---@param maps table of maps to add
    function Mode:add_maps_to_cache(maps)
        local function store_maps(vim_mode, lhs, rhs_and_opts)
            lhs = utils.normalize_lhs(lhs)
            utils.init_nested_table(self._maps_cache, { vim_mode })
            if utils.is_nested_present(self._maps_cache, { vim_mode, lhs }) then
                vim.notify(
                    "The keymap "
                        .. lhs
                        .. " is already present for mode "
                        .. self:get_id()
                        .. ". Replacing the existing map.",
                    vim.log.levels.TRACE
                )
            end
            self._maps_cache[vim_mode][lhs] = rhs_and_opts
        end
        utils.traverse_maps_and_apply(maps, store_maps)
    end

    --- Backup keymaps that are not buffer specific
    ---@param maps table maps to backup in self._existing_maps_cache
    function Mode:backup_global_maps(maps)
        local global_maps = {}
        for _, vim_mode in ipairs(vim.tbl_keys(maps)) do
            global_maps[vim_mode] = vim.api.nvim_get_keymap(vim_mode)
        end

        local function backup_map(vim_mode, lhs, rhs_and_opts)
            lhs = utils.normalize_lhs(lhs)
            utils.init_nested_table(self._existing_maps_cache, { vim_mode })
            local found = utils.find_map(global_maps[vim_mode], lhs)
            if found then
                self._existing_maps_cache[vim_mode][lhs] = found
            end
        end

        utils.traverse_maps_and_apply(maps, backup_map)
    end

    --- Maps to add to the mode
    ---@param maps table to add maps to the mode
    function Mode:add_maps(maps)
        self:add_maps_to_cache(maps)
        self:backup_global_maps(maps)
    end

    --- Remove maps from the mode
    ---@param maps table maps to remove
    function Mode:remove_maps(maps)
        local function remove_map_from_cache(vim_mode, lhs, _)
            lhs = utils.normalize_lhs(lhs)
            if
                not utils.is_nested_present(self._maps_cache, { vim_mode, lhs })
            then
                utils.throw_error(
                    "The keymap "
                        .. lhs
                        .. " is not found for mode "
                        .. self:get_id()
                )
            else
                self._maps_cache[vim_mode][lhs] = nil
                self._existing_maps_cache[vim_mode][lhs] = nil
            end
        end
        utils.traverse_maps_and_apply(maps, remove_map_from_cache)
    end

    --- Apply maps
    ---@param maps table maps to apply from already defined in self._maps_cache
    ---@param options table options from activate contains buffer number
    function Mode:apply_maps(maps, options)
        options = options or {}
        options = vim.deepcopy(options)

        local buffer_maps
        if options.buffer then
            for _, vim_mode in ipairs(vim.tbl_keys(maps)) do
                buffer_maps = buffer_maps or {}
                buffer_maps[vim_mode] =
                    vim.api.nvim_buf_get_keymap(options.buffer, vim_mode)
            end
        end

        local function apply_a_map(vim_mode, lhs, rhs_and_opts)
            lhs = utils.normalize_lhs(lhs)
            if
                not utils.is_nested_present(self._maps_cache, { vim_mode, lhs })
            then
                utils.throw_error(
                    "The keymap "
                        .. lhs
                        .. " is not found for mode "
                        .. self:get_id()
                )
            end

            local rhs = rhs_and_opts["rhs"]
            local opts = vim.deepcopy(rhs_and_opts["opts"])
            if options.buffer then
                opts.buffer = options.buffer
                local found = utils.find_map(buffer_maps[vim_mode], lhs)
                if found then
                    if
                        not utils.is_nested_present(
                            self._existing_maps_cache,
                            { vim_mode, lhs }
                        )
                    then
                        utils.init_nested_table(
                            self._existing_maps_cache,
                            { tostring(options.buffer), vim_mode, lhs }
                        )
                        self._existing_maps_cache[tostring(options.buffer)][vim_mode][lhs] =
                            found
                    end
                end
            end
            opts.desc = opts.desc or ""
            opts.desc = opts.desc .. " <M:" .. self:get_id() .. ">"
            vim.keymap.set(vim_mode, lhs, rhs, opts)
        end
        utils.traverse_maps_and_apply(maps, apply_a_map)
    end

    --- Unmaps the maps from vim runtime
    ---@param maps table maps to unmap
    ---@param options table options from activate contains buffer number
    function Mode:unmap_maps(maps, options)
        local function unmap_a_map(vim_mode, lhs, rhs_and_opts)
            lhs = utils.normalize_lhs(lhs)
            if
                not utils.is_nested_present(self._maps_cache, { vim_mode, lhs })
            then
                utils.throw_error(
                    "The keymap "
                        .. lhs
                        .. " is not found for mode "
                        .. self:get_id()
                )
            end
            local opts = vim.deepcopy(rhs_and_opts["opts"])
            if options.buffer then
                opts.buffer = options.buffer
            end
            vim.keymap.del(vim_mode, lhs, opts)
        end
        utils.traverse_maps_and_apply(maps, unmap_a_map)
    end

    --- normalizes lhs for maps table and returns a new table such that map has new lhs keys without `<leader>`
    --- @param maps table maps to normalize_lhs
    --- @return table maps new maps with normalized lhs
    local function normalize_maps_lhs(maps)
        maps = vim.deepcopy(maps)
        -- normalize_lhs
        local function normalize_lhs_for_maps(vim_mode, lhs)
            if string.find(lhs, "<leader>") then
                local lhs_with_leader = lhs
                lhs = utils.normalize_lhs(lhs)
                maps[vim_mode][lhs] = maps[vim_mode][lhs_with_leader]
                maps[vim_mode][lhs_with_leader] = nil
            end
        end

        utils.traverse_maps_and_apply(maps, normalize_lhs_for_maps)
        return maps
    end

    local function filter_maps(maps, filter_from)
        local result = {}
        local function add_filterd_backup_maps_to_table(
            vim_mode,
            lhs,
            keymap_data
        )
            if utils.is_nested_present(maps, { vim_mode, lhs }) then
                utils.init_nested_table(result, { vim_mode, lhs })
                result[vim_mode][lhs] = keymap_data
            end
        end

        utils.traverse_maps_and_apply(
            filter_from,
            add_filterd_backup_maps_to_table
        )

        return result
    end

    --- Restores the map from backup_store
    ---@param maps table to restore
    ---@param options table options from activate contains buffer number
    ---@param backup_store table self._existing_maps_cache or self._existing_maps_cache["buffer"]
    function Mode:restore_maps(maps, options, backup_store)
        -- FIX: flaky
        maps = vim.deepcopy(maps)
        maps = normalize_maps_lhs(maps)
        local function restore_map(vim_mode, lhs, keymap_data)
            lhs = utils.normalize_lhs(lhs)
            local rhs = keymap_data["rhs"] or keymap_data["callback"]
            local opts =
                utils.tbl_filter_keys(keymap_data, utils.allowed_keymap_opts)
            if options.buffer then
                opts.buffer = options.buffer
            end
            -- required to reset keymap
            opts.replace_keycodes = false
            vim.keymap.set(vim_mode, lhs, rhs, opts)
        end

        local maps_to_restore = filter_maps(maps, backup_store)

        utils.traverse_maps_and_apply(maps_to_restore, restore_map)
    end

    function Mode:unapply_maps(maps, options)
        options = options or {}
        options = vim.deepcopy(options)
        self:unmap_maps(maps, options)
        self:restore_maps(maps, options, self._existing_maps_cache)
        if
            options.buffer
            and self._existing_maps_cache[tostring(options.buffer)]
        then
            self:restore_maps(
                maps,
                options,
                self._existing_maps_cache[tostring(options.buffer)]
            )
        end
    end

    return Mode
end

return module
