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
		split = { "vsplit ", "split " }
	}
}


-- TODO : window resize logic using get_window_config
Nux.refresh = function()
 if not H.is_active() then return end

end


-- Helper --------------------------------------------------------------
H.setup_hl = function()
	local hl = function(name, val)
		val.default = true
		vim.api.nvim_set_hl(0, name, val)
	end

	hl('NuxCursor', { blend = 100, nocombine = true })
end

-- TODO
-- --- Will just return the height / width, col, line of each windows
-- H.layouts.centric = function(cols, rows)
-- end

-- TODO : `:Nux` centric commands
-- TODO : open project based on their name allowing `:Nux open <project>`
-- TODO : disable all possible actions in the buffer
-- TODO : adaptative path using `vim.fn.pathshorten()`
-- TODO : implement a config checker
H.check_config = function(config)
	return config ~= nil and config or {}
end

-- TODO
H.setup_config = function(config)
	Nux.config = vim.tbl_deep_extend('force', H.default_config, config)
end

---@param win_config? vim.api.keyset.win_config|function The function must return a `vim.api.keyset.win_config` table
H.get_window_config = function(win_config)
	local has_statusline = vim.o.laststatus > 1
	local local_width = vim.o.columns
	local local_height = vim.o.lines - vim.o.cmdheight - (has_statusline and 1 or 0)
	local default_config = {
		relative = "editor",
		width = math.floor(.68 * 0.382 * local_width),
		height = math.floor(.68 * .68 * local_height),
		row = (local_height - math.floor(.382 * .68 * local_height)) / 2,
		col = (local_width - math.floor(.3 * local_width)) / 2,
		border = "single",
		style = "minimal",
	}
	local config = vim.tbl_deep_extend("force", default_config, H.extends_callable(win_config) or {})
	return config
end

-- TODO : open the selecting windows
H.open_select_windows = function()
end


H.parse_path = function(path)
	return vim.fs.normalize(path)
end


H.load_projects = function(path)
	local parsed_path = H.parse_path(path)
	if vim.fn.filereadable(path) == 0 then return {} end
	local projects = vim.fn.readfile(parsed_path)
	if vim.tbl_isempty(projects) then return {} end
	return vim.fn.json_decode(table.concat(projects, "\n"))
end

-- TO REWORK
H.open_project = function(project, mode)
	local current_split = H.get_config().workspace.split
	local chosen_mode = "default"
	vim.cmd("tabnew | tcd " .. project.root)
	local files = {}
	if chosen_mode == "default" then
		files = vim.deepcopy(project.default_files)
	else
		files = vim.deepcopy(project.last_session.files)
	end
	if #files ~= 0 then
		vim.cmd("edit " .. files[1].path)
		for i = 2, #files do
			vim.cmd(current_split[(i % 2 + 1)] .. files[i].path)
		end
	end
end



H.extends_callable = function(callable, ...)
	return vim.is_callable(callable) and callable(...) or callable
end

H.create_floating_window = function(config, enter)
	local enter_win = (enter == nil) and true or enter
	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, enter_win, config)
	return { buf = buf, win = win }
end

H.get_config = function()
	return Nux.config
end

-- TODO : implement an active checker and a picker object
H.is_active = function()
	return true
end

H.setup_autocmds = function()
	local nux_augroup = vim.api.nvim_create_augroup("nux_augroup", { clear = true })

	vim.api.nvim_create_autocmd("WinResized", { group = nux_augroup, callback = Nux.refresh })
end


--
H.cache = {}

H.default_config = vim.deepcopy(Nux.config)
-- TESTING --------------------------------
Nux.setup()

H.cache.guicursor = vim.o.guicursor
local side_bar_float = H.create_floating_window(H.get_window_config({ title = " Pick a project " }))
local main_content_float = H.create_floating_window(H.get_window_config(function()
	local width = vim.o.columns
	return {
		relative = "win",
		win = side_bar_float.win,
		width = math.floor(.68 * .309 * width),
		row = -1,
		col = vim.api.nvim_win_get_width(side_bar_float.win) + 1,
		anchor = "NW"
	}
end), false)
vim.o.guicursor = "a:NuxCursor"
local titles = {}
local project_keys = {}
local projects = H.load_projects("./projects.json")
for k, v in pairs(projects) do
	local centered_title = k .. string.rep(" ", vim.api.nvim_win_get_width(side_bar_float.win) - #k - 3) .. "[L]"
	table.insert(titles, centered_title)
	table.insert(project_keys, k)
end

vim.api.nvim_create_autocmd("WinLeave", {
	buffer = side_bar_float.buf,
	callback = function()
		vim.api.nvim_win_close(main_content_float.win, true)
		vim.o.guicursor = H.cache.guicursor
	end
})

vim.api.nvim_buf_set_lines(side_bar_float.buf, 0, -1, false, titles)
vim.wo[side_bar_float.win].cul = true
vim.bo[side_bar_float.buf].modifiable = false

local current_project_key = 0

vim.api.nvim_create_autocmd("CursorMoved", {
	buffer = side_bar_float.buf,
	callback = function()
		local row = vim.fn.line(".")
		local key = project_keys[row]
		if not key then return end

		current_project_key = key
		local project = projects[key]
		local local_files = vim.iter(project.default_files)
				:map(function(item) return item.path end)
				:totable()
		vim.api.nvim_buf_set_lines(main_content_float.buf, 0, -1, false, local_files)
		local og_conf = vim.api.nvim_win_get_config(main_content_float.win)
		vim.api.nvim_win_set_config(main_content_float.win,
			vim.tbl_deep_extend('force', og_conf,
				{ footer = vim.fn.pathshorten(" " .. project.root .. " ", 7), title = "[L]ast", title_pos = "right" }))
	end
})

vim.keymap.set("n", Nux.config.key_mappings.quit, function()
	vim.api.nvim_win_close(side_bar_float.win, true)
end, { buffer = side_bar_float.buf }
)

vim.keymap.set("n", Nux.config.key_mappings.select, function()
	vim.api.nvim_win_close(side_bar_float.win, true)
	open_project(projects[current_project_key])
end, { buffer = side_bar_float.buf })
