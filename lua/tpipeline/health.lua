local M = {}

M.check = function()
	vim.health.start("tpipeline report")
	local info = vim.fn['tpipeline#debug#info']()

	local ver = vim.version()
	if vim.version.lt(ver, {0, 6, 0}) then
		vim.health.error(string.format("Neovim version %d.%d is not supported, use 0.6 or higher", ver.major, ver.minor))
	else
		vim.health.ok("Neovim version is supported")
	end

	if vim.regex('^run'):match_str(info.job_state) == nil then
		vim.health.error(string.format("Background job is not running: %s", info.job_state))
	else
		vim.health.ok("Background job is running")
	end

	if next(info.job_errors) == nil then
		vim.health.ok("No job errors reported")
	else
		vim.health.warn("Job reported errors", info.job_errors)
	end

	if info.bad_colors > 0 then
		vim.health.warn(string.format("The current colorscheme contains %d highlight groups that don't properly support truecolor.\nThese colors might not render correctly in tmux.\nYou can list them with \":echom tpipeline#debug#get_bad_hl_groups()\".", info.bad_colors))
	else
		vim.health.ok("Colorscheme has true color support")
	end
end

return M
