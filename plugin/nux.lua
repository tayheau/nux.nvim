CustomTabLine = function()
	local tabline = ""
	for index = 1, vim.fn.tabpagenr('$') do
		-- select the highlighting
		if index == vim.fn.tabpagenr() then
			tabline = tabline .. '%#TabLineSel#'
		else
			tabline = tabline .. '%#TabLine#'
		end

		-- set the tab page number (for mouse clicks)
		tabline = tabline .. '%' .. index .. 'T'

		local win_num = vim.fn.tabpagewinnr(index)
		local working_directory = vim.fn.getcwd(win_num, index)
		local project_name = vim.fn.fnamemodify(working_directory, ":t")
		tabline = tabline .. " " .. project_name .. " "
	end

	-- after the last tab fill with TabLineFill and reset tab page nr
	tabline = tabline .. '%#TabLineFill#%T'
	--
	-- -- right-align the label to close the current tab page
	-- if vim.fn.tabpagenr('$') > 1 then
	-- 	tabline = tabline .. '%=%#TabLine#%999Xclose'
	-- end

	return tabline
end

vim.go.tabline = "%!v:lua.CustomTabLine()"
--- Thanks to `nvim-best-practices` ;)
---
---@class NuxSubCmd
---@field impl fun(args:string[], opts: table) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] (optional) Command completions callback, taking the lead of the subcommand's arguments

---@type table<string, NuxSubCmd>
local subcommand_tbl = {
	pickprojects = {
		impl = function(args, opts)
			require("nux").select_project()
		end,
	}
}

---@param opts table :h lua-guide-commands-create
local nux_cmd = function(opts)
	local fargs = opts.fargs
	local subcommand_key = fargs[1]
	local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
	local subcommand = subcommand_tbl[subcommand_key]
	if not subcommand then
		vim.notify("Nux: Unknown command: " .. subcommand_key, vim.log.levels.ERROR)
		return
	end
	subcommand.impl(args, opts)
end

vim.api.nvim_create_user_command("Nux", nux_cmd, {
	nargs = "+",
	complete = function(arg_lead, cmdline, _)
		local subcommand_key, subcmd_arg_lead = cmdline:match("^['<, '>]*Nux[!]*%s(%S+)%s(.*)$")
		if subcommand_key
				and subcmd_arg_lead
				and subcommand_tbl[subcommand_key]
				and subcommand_tbl[subcommand_key].complete
		then
			return subcommand_tbl[subcommand_key].complete(subcmd_arg_lead)
		end
		if cmdline:match("^['<, >']*Nux[!]*%s+%w*$") then
			local subcommand_key = vim.tbl_keys(subcommand_tbl)
			return vim.iter(subcommand_key)
					:filter(function(key)
						return key:find(arg_lead) ~= nil
					end)
					:totable()
		end
	end,
	bang = true
})

-- vim.api.nvim_create_user_command('PickProjects', function()
-- 	require("nux").select_project()
-- end, {}
-- )
