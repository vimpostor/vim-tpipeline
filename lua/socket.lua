local M = {}

local is_nvim = false
if (vim.api ~= nil) then
	is_nvim = true
end

local split = 0
local default_color = ""
if is_nvim then
	split = vim.api.nvim_eval("g:tpipeline_split")
	default_color = vim.api.nvim_eval("s:default_color")
else
	local split = vim.eval("g:tpipeline_split")
	local default_color = vim.eval("s:default_color")
end

local tmux_s = os.getenv("TMUX")
-- for example /tmp/tmux-1000/default-$0-vimbridge
local left_filepath = string.sub(tmux_s, 1, string.find(tmux_s, ",", 1, true) - 1) .. "-$" .. string.match(tmux_s, "%d+$") .. "-vimbridge"
local right_filepath = left_filepath .. "-R"
local socket_write_count = 0
local socket_rotate_threshold = 128
local last_written_line = ""
local line = ""

function remove_align(s)
	return string.gsub(s, "%%=", "")
end

local tmux = coroutine.create(function (l)
	while true do
		local write_mode = "a" -- append mode
		socket_write_count = socket_write_count + 1
		-- rotate the file when it gets too large
		if socket_write_count > socket_rotate_threshold then
			write_mode = ""
			socket_write_count = 0
		end

		-- append default color
		line = default_color .. line

		if split then
			local split_point = string.find(line, "%=", 1, true)
			local left_line = line
			local right_line = ""
			if split_point ~= nil then
				left_line = string.sub(line, 1, split_point - 1)
				right_line = default_color .. remove_align(string.sub(line, split_point + 2))
			end
			-- TODO: Optimize IO perf
			local r_file = io.open(right_filepath, write_mode)
			r_file:write(right_line .. "\n")
			r_file:close()
			last_written_line = left_line
		else
			last_written_line = remove_align(line)
		end
		local l_file = io.open(left_filepath, write_mode)
		l_file:write(last_written_line .. "\n")
		l_file:close()
		os.execute("tmux refresh-client -S")
		coroutine.yield()
	end
end)

function M.update(l)
	line = l
	coroutine.resume(tmux)
end

function M.cleanup_priv(mode)
	local l_file = io.open(left_filepath, mode)
	l_file:write("\n")
	l_file:close()
	if split then
		local r_file = io.open(right_filepath, mode)
		r_file:write("\n")
		r_file:close()
	end
end

function M.cleanup()
	M.cleanup_priv("w")
end

function M.cautious_cleanup()
	-- check if some other instance wrote to the socket right before us
	local file = io.open(left_filepath, "r")
	local written_line = ""
	if file ~= nil then
		for l in file:lines() do
			written_line = l
		end
		if last_written_line == written_line then
			M.cleanup_priv("a")
		end
	end
end

return M
