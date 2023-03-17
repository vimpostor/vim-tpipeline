func tpipeline#lualine#is_lualine()
	" lualine doesn't play nice, so it needs extra workarounds
	if !has('nvim')
		return 0
	endif

	try
		let res = !empty(nvim_get_autocmds(#{group: "lualine"}))
	catch
		let res = 0
	endtry

	return res
endfunc

func tpipeline#lualine#clear_all_stl()
	for i in range(1, tabpagewinnr(tabpagenr(), '$'))
		noa call win_execute(win_getid(i), 'setlocal stl<')
	endfor
endfunc

func tpipeline#lualine#fix_stl()
	noa let s = getwinvar(win_getid(), '&stl')
	if !empty(s) && s !=# '%#StatusLine#'
		let g:tpipeline_statusline = s
	endif

	if g:tpipeline_clearstl
		call tpipeline#lualine#clear_all_stl()
	endif
	call tpipeline#update()
endfunc

func tpipeline#lualine#delay_eval()
	let s:timer = timer_start(0, {-> tpipeline#lualine#fix_stl()})
endfunc
