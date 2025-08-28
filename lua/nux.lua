local Nux = {}
local H = {}

--@param opts table
Nux.setup = function(opts)
	opts = opts or {} -- if opts is nil, use an empty table
	-- opts.statusline = opts.statusline ~= false
	-- if opts.statusline then
	-- 	_G.Nux = Nux
	-- 	vim.go.tabline = "%!v:lua.Nux.customTabLine()"
	-- end
end

---@class nux.FloatingWindow
---@field buf integer: Buffer ID
---@field win integer: Window ID

---@param config vim.api.keyset.win_config
---@param enter boolean
---
---@return nux.FloatingWindow
H.create_floating_window = function(config, enter)
	--create a buffer
	local buf = vim.api.nvim_create_buf(false, true)
	--create a window
	local win = vim.api.nvim_open_win(buf, enter or false, config)

	return { buf = buf, win = win }
end

---@param title? string Defaults to None
H.create_window_configuration = function(title)
	local width = vim.o.columns
	local height = vim.o.lines

	---@type  vim.api.keyset.win_config
	return {
		relative = "editor",
		width = math.ceil(width / 3),
		height = math.ceil(height / 4),
		style = "minimal",
		border = "double",
		col = (width - math.ceil(width / 3)) / 2,
		row = (height - math.ceil(height / 4)) / 2,
		zindex = 1,
		title = { { title or "", "NormalFloat" } },
		title_pos = "center",
		footer = "<CR> to Enter | <Esc> to abort",
		footer_pos = "right",
	}
end

---@type vim.bo
local local_options_buf = {
	modifiable = false
}

---@type vim.wo
local local_options_win = {
	cul = true,
	winhighlight = "CursorLine:CurSearch"
}


local global_options = {
	guicursor = {
		default = vim.o.guicursor,
		nux = "a:NormalFloat-ver1"
	}
}

---@param scope 'global' | 'window' | 'buffer'
---@param opts table<string, any>
---@param global_value? 'default' | 'nux'
---@param id? integer
H.apply_options = function(scope, opts, global_value, id)
	local target = ({
		global = vim.o,
		window = vim.wo,
		buffer = vim.bo,
	})[scope]
	assert(target, "Invalid scope: " .. tostring(scope))

	for k, v in pairs(opts) do
		if type(v) == "table" and global_value ~= nil and v[global_value] then
			target[k] = v[global_value]
		else
			target[id][k] = v
		end
	end
end

---@param scope  'window' | 'buffer'
---@param opts table<string, any>
---@param id integer
H.apply_local_options = function(scope, opts, id)
	H.apply_options(scope, opts, nil, id)
end

---@param opts table<string, any>
---@param global_value? 'default' | 'nux'
H.apply_global_options = function(opts, global_value)
	H.apply_options('global', opts, global_value or 'default')
end

---@class nux.Project
---@field root string
---@field files string[]
---
---@return nux.Project[]
H.getProject = function()
	local projects = {}
	for line in io.lines(vim.fn.stdpath("config") .. "/projects") do
		local root, files = line:match("^(%S+)%s*(.*)$")
		local file_list = {}
		for f in files:gmatch("%S+") do
			table.insert(file_list, f)
		end
		table.insert(projects, { root = root, files = file_list })
	end
	return projects
end

---@param items any[]
---@param opts table
---				opts.prompt? string : Prompt to show to the user. Defaults to
H.openPicker = function(items, opts, on_choice)
	local picker = H.create_floating_window(
		H.create_window_configuration(opts.prompt),
		true)

	vim.keymap.set('n', '<Cr>', function()
		local line = vim.api.nvim_win_get_cursor(picker.win)[1]
		local selected_item = items[line]
		vim.api.nvim_win_close(picker.win, true)
		on_choice(selected_item)
	end
	, { buffer = picker.buf })

	vim.keymap.set("n", "<Esc>", function()
		vim.api.nvim_win_close(picker.win, true)
	end, { buffer = picker.buf })

	local printed_items
	if type(opts.format_items) == "function" then
		printed_items = vim.tbl_map(opts.format_items, items)
	else
		printed_items = items
	end

	vim.api.nvim_buf_set_lines(picker.buf, 0, -1, false, printed_items)
	H.apply_local_options('buffer', local_options_buf, picker.buf)
	-- H.apply_local_options('window', local_options_win, picker.win)
	vim.api.nvim_set_option_value("cursorline", true, { win = picker.win })
	H.apply_global_options(global_options, 'nux')

	vim.api.nvim_create_autocmd('WinResized', {
		group = vim.api.nvim_create_augroup("nux-resized", {}),
		callback = function()
			if not vim.api.nvim_win_is_valid(picker.win) or picker.win == nil then
				return
			end
			local updated = H.create_window_configuration(opts.prompt)
			vim.api.nvim_win_set_config(picker.win, updated)
			vim.api.nvim_set_option_value("cursorline", true, { win = picker.win })
		end
	})

	vim.api.nvim_create_autocmd('BufLeave', {
		buffer = picker.buf,
		callback = function()
			H.apply_global_options(global_options, 'default')
		end
	})
	return picker
end


--===============================================================

Nux.select_project = function()
	local function handleOpenProject(item)
		if not item then return end
		local function buildCmd(action, file)
			return file == "term" and action .. "| terminal" or action .. file
		end
		local split = { "vsplit ", "split " }
		vim.cmd("tabnew | tcd " .. item.root)
		-- vim.cmd("tcd " .. item.root)
		if #item.files == 0 then goto continue end
		vim.cmd(buildCmd("edit ", item.files[1]))
		for i = 2, #item.files do
			vim.cmd(buildCmd(split[(i % 2) + 1], item.files[i]))
		end
		::continue::
	end

	local projects = H.getProject()
	local picker = H.openPicker(projects, {
			prompt = "Select working dir...",
			format_items = function(item) return vim.fn.fnamemodify(item.root, ":t") end
		},
		handleOpenProject
	)
end

return Nux
