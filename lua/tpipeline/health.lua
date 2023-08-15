local M = {}

M.check = function()
	vim.health.report_start("tpipeline report")
	local info = vim.fn['tpipeline#debug#info']()

	ver = vim.version()
	if vim.version.lt(ver, {0, 6, 0}) then
		vim.health.report_error(string.format("Neovim version %d.%d is not supported, use 0.6 or higher", ver.major, ver.minor))
	else
		vim.health.report_ok("Neovim version is supported")
	end
end

return M
