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

	if vim.regex('%run'):match_str(info.job_state) == nil then
		vim.health.report_ok("Background job is running")
	else
		vim.health.report_error(string.format("Background job is not running: %s", info.job_state))
	end
end

return M
