local split_pattern = vim.g.tpipeline_fillchar .. '+'

local M = {
	was_bold = false,
	was_italic = false,
}

function M.color(grp)
	local id = vim.fn.synIDtrans(vim.fn.hlID(grp))
	local fg = string.lower(vim.fn.synIDattr(id, 'fg'))
	if fg == 'fg' then
		fg = 'default'
	end
	local bg = string.lower(vim.fn.synIDattr(id, 'bg'))
	if bg == 'bg' then
		bg = 'default'
	elseif bg == '' or bg == '#NONE' then
		bg = 'terminal'
	end
	local st = ''
	if vim.fn.synIDattr(id, 'bold') == '1' then
		st = ',bold'
		was_bold = true
	elseif was_bold then
		st = ',nobold'
		was_bold = false
	end
	if vim.fn.synIDattr(id, 'italic') == '1' then
		st = st .. ',italics'
		was_italic = true
	elseif was_italic then
		st = st .. ',noitalics'
		was_italic = false
	end
	return string.format('#[fg=%s,bg=%s%s]', fg, bg, st)
end

function M.eval_stl(stl, width)
	local evl = vim.api.nvim_eval_statusline(stl, {fillchar = vim.g.tpipeline_fillchar, highlights = 1, use_tabline = vim.g.tpipeline_tabline, maxwidth = width})
	local res = evl.str
	local i = 0
	for k, hl in pairs(evl.highlights) do
		local grp = M.color(hl.group)
		-- unfortunately we need to use vimscript strpart() as Lua's UTF 8 support is absolutely horrendous
		res = vim.fn.strpart(res, 0, hl.start + i) .. grp .. vim.fn.strpart(res, hl.start + i)
		i = i + string.len(grp)
	end
	return res
end

function M.update()
	was_bold = false
	was_italic = false

	local stl = vim.g.tpipeline_statusline
	if stl == '' then
		stl = vim.o.stl
	end

	local res = M.eval_stl(stl, vim.g.tpipeline_size)

	if #vim.split(res, split_pattern) <= 2 then
		res = res:gsub(split_pattern, '%%=')
	else
		-- sometimes the split point is not unique, in which case we have to find it out manually
		local retry = M.eval_stl(stl, vim.g.tpipeline_size + 2)
		local i = 1
		local start = 1
		while i <= res:len() and res:sub(i, i) == retry:sub(i, i) do
			if res:sub(i, i) ~= vim.g.tpipeline_fillchar then
				start = i
			end
			i = i + 1
		end
		res = string.gsub(res:sub(1, start), vim.g.tpipeline_fillchar, ' ') .. string.gsub(res:sub(start + 1, i - 1), split_pattern, '%%=') .. string.gsub(res:sub(i), vim.g.tpipeline_fillchar, ' ')
	end

	return res
end

return M
