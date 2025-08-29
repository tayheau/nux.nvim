local M = {}

M.defaults = {
	tabline = true,
	width_ratio = 3,
	height_ratio = 4,
	border = "double",
}

M.options = vim.deepcopy(M.defaults)

M.setup = function(opts)
	opts = opts or {}
	M.options = vim.tbl_deep_extend("force", {}, M.options, opts)

	-- if M.options.tabline then
	-- 	vim.go.tabline = "%!v:lua.CustomTabLine()"
	-- end

end

return M
