local tinytoml = require "tinytoml"

local Nux = {}
local H = {}


Nux.setup = function(config)
	_G.Nux = Nux
	-- Setup custom highlight groups
	H.setup_hl()
	-- TODO : config setup
	-- 	-	check if every prop is in good format
	config = H.check_config(config)
	-- Setup config
	H.setup_config(config)
	-- 	TODO : user commands setup
	H.setup_autocmds()
	-- 	TODO : global autocommands setup
end

Nux.config = {
	-- Base keymaps
	key_mappings = {
		select = "<CR>",
		quit = "<Esc>",

		forward = "<C-n>",
		backward = "<C-p>",
	},
	-- Window config
	window = {
		-- Floating window config, Default to nil. Must be `vim.api.keyset.win_config` or be a function that return it
		---@type vim.api.keyset.win_config|function|nil
		config = nil
	},
	workspace = {
		split = { "vsplit ", "split " },
		file_path = "~/.nux_workspaces"
		-- file_path = vim.fn.stdpath("config") .. "/projects"
	}
}


-- TODO : window resize logic using get_window_config
Nux.refresh = function()
	if not H.is_window_active() then return end
	local config = H.get_window_config(H.window.active.config)
	vim.api.nvim_win_set_config(H.window.active.win, config)
end


-- TODO: check if a window is already open to prevent multiple ones
Nux.pickWorkspace = function()
	local picker = H.create_nux_window({ title = " Pick a project " })
	H.cache.cursor = vim.o.guicursor
	vim.o.guicursor = "a:NuxCursor"
	vim.wo[picker.win].cursorline = true
	local projects = H.load_projects()
	local project_keys = H.get_dict_keys(projects)
	local current_project_key = 0

	vim.api.nvim_create_autocmd("WinLeave", {
		buffer = picker.buf,
		callback = function()
			vim.o.guicursor = H.cache.cursor
			if H.window.active == picker then H.window.active = nil end
		end
	})

	vim.keymap.set("n", Nux.config.key_mappings.quit, function()
			vim.api.nvim_win_close(picker.win, true)
		end,
		{ buffer = picker.buf }
	)

	vim.api.nvim_create_autocmd("CursorMoved", {
		callback = function()
			local idx = vim.fn.line('.')
			local key = project_keys[idx]
			if not key then return end
			current_project_key = key
		end
	})

	vim.keymap.set("n", H.get_config().key_mappings.select, function()
			vim.api.nvim_win_close(picker.win, true)
			H.open_project(projects[current_project_key])
		end,
		{ buffer = picker.buf }
	)

	vim.keymap.set("n", "E", function()
			vim.api.nvim_win_close(picker.win, true)
			Nux.editWorkspace()
		end,
		{ buffer = picker.buf }
	)

	vim.api.nvim_buf_set_lines(picker.buf,
		0, -1, false, H.get_dict_keys(projects))
	vim.bo[picker.buf].modifiable = false
end

Nux.editWorkspace = function()
	local buf = vim.fn.bufnr(H.get_path(), true)
	local win = vim.api.nvim_open_win(buf, true, H.get_window_config())
end
-- Helper --------------------------------------------------------------
-- Setup and Checks ----------------------------------------------------
H.setup_hl = function()
	local hl = function(name, val)
		val.default = true
		vim.api.nvim_set_hl(0, name, val)
	end

	hl('NuxCursor', { blend = 100, nocombine = true })
end


-- TODO : `:Nux` centric commands
-- TODO : open project based on their name allowing `:Nux open <project>`
-- TODO : disable all possible actions in the buffer
-- TODO : add_project()
-- TODO : adaptative path using `vim.fn.pathshorten()`
-- TODO : implement a config checker
H.check_config = function(config)
	return config ~= nil and config or {}
end

H.check_filereadable = function()
	local path = H.get_path()
	return vim.fn.filereadable(path) == 1
end

-- TODO
H.setup_config = function(config)
	Nux.config = vim.tbl_deep_extend('force', H.default_config, config)
end

-- Win and Buffers ----------------------------------------------------
-- TODO to update maybe
H.setup_autocmds = function()
	local nux_augroup = vim.api.nvim_create_augroup("nux_augroup", { clear = true })
	local nux_autocmd = function(event, callback)
		vim.api.nvim_create_autocmd(event, { group = nux_augroup, callback = callback })
	end

	nux_autocmd("WinResized", Nux.refresh)
	-- Since plugin is sourced before colorschemes and thoses can wipe any defined highlights.
	nux_autocmd("ColorScheme", H.setup_hl)
end

---@param win_config? vim.api.keyset.win_config|function The function must return a `vim.api.keyset.win_config` table
H.get_window_config = function(win_config)
	local has_statusline = vim.o.laststatus > 1
	local local_width = vim.o.columns
	local local_height = vim.o.lines - vim.o.cmdheight - (has_statusline and 1 or 0)
	local default_config = {
		relative = "editor",
		width = math.floor(.52 * local_width),
		height = math.floor(.52 * local_height),
		col = (local_width - math.floor(.52 * local_width)) / 2,
		row = (local_height - math.floor(.52 * local_height)) / 2,
		border = "single",
		style = "minimal",
	}
	local config = vim.tbl_deep_extend("force", default_config, H.extends_callable(win_config) or {})
	return config
end

---@param config? vim.api.keyset.win_config
---@param enter boolean Enter or not the created window.
H.create_floating_window = function(config, enter)
	local final_config = H.get_window_config(config)
	local enter_win = (enter == nil) and true or enter
	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, enter_win, final_config)
	return { buf = buf, win = win, config = config }
end

---@param win_config? vim.api.keyset.win_config
H.create_nux_window = function(win_config)
	if H.is_window_active() then
		vim.api.nvim_win_close(H.window.active.win, true)
	end
	local nux_window = H.create_floating_window(win_config, true)
	H.window.active = nux_window
	return nux_window
end



H.parse_path = function(path)
	return vim.fs.normalize(path)
end

H.get_path = function()
	local path = H.get_config().workspace.file_path
	local parsed_path = H.parse_path(path)
	return parsed_path
end

H.load_projects = function()
	local path = H.get_path()
	if vim.fn.filereadable(path) == 0 then return {} end
	local code, res = pcall(function() return tinytoml.parse(path) end)
	return code and res or {}
end


-- TO REWORK
H.open_project = function(project)
	local current_split = H.get_config().workspace.split
	vim.cmd("tabnew | tcd " .. project.root)
	local files = project.files or {}
	if #files ~= 0 then
		vim.cmd("edit " .. files[1])
		for i = 2, #files do
			vim.cmd(current_split[(i % 2 + 1)] .. files[i])
		end
	end
end



H.extends_callable = function(callable, ...)
	return vim.is_callable(callable) and callable(...) or callable
end



H.get_config = function()
	return Nux.config
end

-- TODO : implement an active checker and a picker object
H.is_window_active = function()
	return H.window.active ~= nil
end



H.get_dict_keys = function(dict)
	local keys = {}
	for k, _ in pairs(dict) do
		table.insert(keys, k)
	end
	return keys
end

--
H.cache = {}
H.window = { active = nil }
H.default_config = vim.deepcopy(Nux.config)


return Nux

-- Nux.setup()
-- Nux.pickWorkspace()
