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
	}
}


-- TODO : window resize logic using get_window_config
Nux.refresh = function()
	if not H.is_active() then return end
end

-- TODO Open workspace_adder from the selection menu
-- TODO Relative windows : hard coded atm
-- TODO Once the root is selected, navigate through files to add them.
-- TODO How to add a term ? Maybe it (S) to (S)pecial windows select term or processes and add some commands to run ? `:term jupyter notebook` will run only the notebook and will be discarded at the shutdown
Nux.workspace_adder = function(on_confirm)
	local pick_config = H.get_window_config({ title = "picker" })
	local picker = H.create_floating_window(pick_config, false)
	vim.wo[picker.win].cul = true
	---@type vim.api.keyset.win_config
	local default_win_options = {
		relative = "win",
		win = picker.win,
		row = -4,
		col = -1,
		height = 1,
		focusable = true,
		style = "minimal",
		border = "single",
		title = " Select a workspace root "
	}

	local workspace_comp_config = H.get_window_config({
		relative = "win",
		win = picker.win,
		height = math.floor(.68 * .68 * vim.o.lines) + 2,
		row = -4,
		col = vim.api.nvim_win_get_config(picker.win).width + 1,
	})

	local workspace_comp = H.create_floating_window(workspace_comp_config, false)

	local prompt = H.create_floating_window(H.get_window_config(default_win_options), true)
	vim.bo[prompt.buf].buftype = 'prompt'
	-- TODO : completion function for folders
	vim.bo[prompt.buf].bufhidden = 'wipe'

	local defered_callback = function(input)
		vim.defer_fn(function()
			on_confirm(input)
		end, 10)
	end

	vim.fn.prompt_setprompt(prompt.buf, '')
	vim.fn.prompt_setcallback(prompt.buf, defered_callback)

	vim.keymap.set('i', Nux.config.key_mappings.forward, function()
		local cursor = vim.api.nvim_win_get_cursor(picker.win)
		vim.api.nvim_win_set_cursor(picker.win, { math.max(cursor[1] + 1), 0 })
	end, { buffer = prompt.buf }
	)

	vim.keymap.set('i', Nux.config.key_mappings.backward, function()
		local cursor = vim.api.nvim_win_get_cursor(picker.win)
		vim.api.nvim_win_set_cursor(picker.win, { math.max(cursor[1] - 1, 1), 0 })
	end, { buffer = prompt.buf }
	)

	vim.api.nvim_create_autocmd('TextChangedI', {
		buffer = prompt.buf,
		callback = function()
			-- vim.print(vim.fn.prompt_getinput(buf))
			local ns = vim.api.nvim_create_namespace("MyHighlightNs")
			local user_path = H.parse_path(vim.fn.prompt_getinput(prompt.buf))
			local files = vim.fn.readdir(user_path)
			vim.api.nvim_buf_set_lines(picker.buf, 0, -1, false, files)
			for i, v in pairs(files) do
				local stat = vim.uv.fs_stat(user_path .. '/' .. v)
				-- vim.api.nvim_buf_set_lines(shower.buf, i - 1, i - 1, false, { v })
				local hl = (stat and stat.type == "directory") and "Directory" or "Normal"
				vim.api.nvim_buf_set_extmark(picker.buf, ns, i - 1, 0, {
					end_line = i,
					hl_group = hl,
				})
			end
			-- vim.api.nvim_buf_set_lines(shower.buf, 0, -1, false, files)
			H.update_win(picker.win, { title_pos = "right", title = tostring(#files) })
		end
	})

	vim.api.nvim_create_autocmd('WinLeave', {
		buffer = prompt.buf,
		callback = function()
			vim.api.nvim_win_close(picker.win, true)
			vim.api.nvim_win_close(workspace_comp.win, true)
		end
	})

	vim.keymap.set({ 'i', 'n' }, "<CR>", "<CR><Esc>:close!<CR>:stopinsert<CR>", { silent = true, buffer = prompt.buf })
	vim.keymap.set('n', '<Esc>', "<cmd>close!<CR>", { silent = true, buffer = prompt.buf })


	-- win_opts = vim.tbl_deep_extend)
	-- local win = vim.api.nvim_open_win(prompt.buf, true, default_win_options)
	vim.cmd("startinsert")

	-- vim.defer_fn(function ()
	-- 	vim.api.nvim_buf_set_text(buf, 0, #prompt, 0, #prompt, { default_text })
	-- 	vim.cmd("startinsert!")
	-- end, 5)
end



--- root { files } { {specials, opt} }
Nux.add_workspace = function(root, ...)
	H.check_filereadable()
	local parsed_path = H.parse_path(H.get_config().workspace.file_path)
	vim.fn.writefile({ root }, parsed_path, 'a')
end

-- TODO rename function `inplace` boolean in not then just a :t var
Nux.rename = function(workspace, inplace)
end

-- Helper --------------------------------------------------------------
H.setup_hl = function()
	local hl = function(name, val)
		val.default = true
		vim.api.nvim_set_hl(0, name, val)
	end

	hl('NuxCursor', { blend = 100, nocombine = true })
end

-- TODO to update maybe
H.update_win = function(win, opts)
	local current = vim.api.nvim_win_get_config(win)
	local updated_config = vim.tbl_deep_extend('force', current, opts)
	vim.api.nvim_win_set_config(win, updated_config)
end
-- TODO
-- --- Will just return the height / width, col, line of each windows
-- H.layouts.centric = function(cols, rows)
-- end

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

H.get_path = function()
	local path = H.get_config().workspace.file_path
	local parsed_path = H.parse_path(path)
	return parsed_path
end

H.load_projects = function()
	local path = H.get_path()
	if vim.fn.filereadable(path) == 0 then return {} end
	local projects = vim.fn.readfile(path)
	if vim.tbl_isempty(projects) then return {} end
	return vim.fn.json_decode(projects)
	-- return vim.fn.json_decode(table.concat(projects, "\n"))
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
--
-- NOTE : autocompletion path
-- vim.ui.input({ prompt = 'select workspace dir', completion = 'dir_in_path' },
-- 	function()
-- 		vim.print("lol")
-- 	end)

Nux.setup()
--
-- H.cache.guicursor = vim.o.guicursor
-- local side_bar_float = H.create_floating_window(H.get_window_config({ title = " Pick a project " }))
-- local main_content_float = H.create_floating_window(H.get_window_config(function()
-- 	local width = vim.o.columns
-- 	return {
-- 		relative = "win",
-- 		win = side_bar_float.win,
-- 		width = math.floor(.68 * .309 * width),
-- 		row = -1,
-- 		col = vim.api.nvim_win_get_width(side_bar_float.win) + 1,
-- 		anchor = "NW"
-- 	}
-- end), false)
-- vim.o.guicursor = "a:NuxCursor"
-- local titles = {}
-- local project_keys = {}
-- local projects = H.load_projects(H.get_config().workspace.file_path)
-- vim.print(projects)
-- for k, v in pairs(projects) do
-- 	local centered_title = k .. string.rep(" ", vim.api.nvim_win_get_width(side_bar_float.win) - #k - 3) .. "[L]"
-- 	table.insert(titles, centered_title)
-- 	table.insert(project_keys, k)
-- end
--
-- vim.api.nvim_create_autocmd("WinLeave", {
-- 	buffer = side_bar_float.buf,
-- 	callback = function()
-- 		vim.api.nvim_win_close(main_content_float.win, true)
-- 		vim.o.guicursor = H.cache.guicursor
-- 	end
-- })
--
-- vim.api.nvim_buf_set_lines(side_bar_float.buf, 0, -1, false, titles)
-- vim.wo[side_bar_float.win].cul = true
-- vim.bo[side_bar_float.buf].modifiable = false
--
-- local current_project_key = 0
--
-- vim.api.nvim_create_autocmd("CursorMoved", {
-- 	buffer = side_bar_float.buf,
-- 	callback = function()
-- 		local row = vim.fn.line(".")
-- 		local key = project_keys[row]
-- 		if not key then return end
--
-- 		current_project_key = key
-- 		local project = projects[key]
-- 		local local_files = vim.iter(project.default_files)
-- 				:map(function(item) return item.path end)
-- 				:totable()
-- 		vim.api.nvim_buf_set_lines(main_content_float.buf, 0, -1, false, local_files)
-- 		local og_conf = vim.api.nvim_win_get_config(main_content_float.win)
-- 		vim.api.nvim_win_set_config(main_content_float.win,
-- 			vim.tbl_deep_extend('force', og_conf,
-- 				{ footer = vim.fn.pathshorten(" " .. project.root .. " ", 7), title = "[L]ast", title_pos = "right" }))
-- 	end
-- })
--
-- vim.keymap.set("n", Nux.config.key_mappings.quit, function()
-- 	vim.api.nvim_win_close(side_bar_float.win, true)
-- end, { buffer = side_bar_float.buf }
-- )
--
-- vim.keymap.set("n", Nux.config.key_mappings.select, function()
-- 	vim.api.nvim_win_close(side_bar_float.win, true)
-- 	H.open_project(projects[current_project_key])
-- end, { buffer = side_bar_float.buf })
--
-- Nux.workspace_adder(function() vim.print("confirmed") end)
local tests = {
	{
		root = "~/.config/nvim",
		files = { "init.lua" }
	},
	{
		root = "~/Documents/AREAS/riskpat/patrisk-amplify",
		files = { "backend.ts" }
	}
}

local write_json = function(path, tbl)
	local json_str = vim.fn.json_encode(tbl)
	local file = assert(io.open(path, "w"))
	file:write(json_str)
	file:close()
end

local read_json = function(path)
	local file = assert(io.open(path, "r"))
	local content = file:read("*a")
	file:close()
	return vim.fn.json_decode(content)
end


local parsed = H.parse_path("~/.nux_workspaces")
-- write_json(parsed, tests)
-- vim.print(read_json(parsed))
vim.print(vim.fn.filereadable(parsed))
