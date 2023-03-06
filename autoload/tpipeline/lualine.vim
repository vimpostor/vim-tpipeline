func tpipeline#lualine#is_lualine()
	" lualine doesn't play nice, so it needs extra workarounds
	return has('nvim') && !empty(nvim_get_autocmds(#{group: "lualine"}))
endfunc

func tpipeline#lualine#clear_all_stl()
	for i in range(1, tabpagewinnr(tabpagenr(), '$'))
		noa call win_execute(win_getid(i), 'setlocal stl<')
	endfor
endfunc
