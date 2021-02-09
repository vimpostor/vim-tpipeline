func tpipeline#build_hooks()
	let g:tpipeline_hooks_enabled = 1
	augroup tpipeline
		if v:vim_did_enter
			call tpipeline#init_statusline()
		else
			autocmd VimEnter * call tpipeline#init_statusline()
		endif

		autocmd FocusGained * call tpipeline#forceupdate()
		if g:tpipeline_focuslost
			autocmd FocusLost * lua require'socket'.cautious_cleanup()
		endif
		autocmd VimLeave * lua require'socket'.cleanup()
		autocmd BufEnter,InsertEnter,InsertLeave,CursorHold,CursorHoldI,CursorMoved,CmdlineEnter * call tpipeline#update()
	augroup END
endfunc

func tpipeline#initialize()
	if !exists('g:tpipeline_statusline')
		let g:tpipeline_statusline = ''
	endif
	if !exists('g:tpipeline_split')
		let g:tpipeline_split = 0
	endif
	if !exists('g:tpipeline_focuslost')
		let g:tpipeline_focuslost = 1
	endif
	set laststatus=0
	call tpipeline#build_hooks()

	let s:update_delay = 128
	let s:update_pending = 0
	let s:update_required = 0
	let s:last_statusline = ''
	let l:hlid = synIDtrans(hlID('StatusLine'))
	let s:default_color = printf('#[fg=%s,bg=%s]', synIDattr(l:hlid, 'fg'), synIDattr(l:hlid, 'bg'))
endfunc

func tpipeline#init_statusline()
	if empty(g:tpipeline_statusline)
		if empty(&statusline)
			" default statusline
			set statusline=%!tpipeline#stl#line()
		endif
		let g:tpipeline_statusline = &statusline
	endif

	exe 'py3file ' . expand('<sfile>:p:h') . '/python3/socket.py'
endfunc

func tpipeline#delayed_update()
	let s:update_pending = 0
	if s:update_required
		let s:update_required = 0
		call tpipeline#update()
	endif
endfunc

func tpipeline#update()
	if s:update_pending
		let s:update_required = 1
		return
	endif
	let s:update_pending = 1
	let s:delay_timer = timer_start(s:update_delay, {-> tpipeline#delayed_update()})

	let l:line = tpipeline#parse#parse_stl(g:tpipeline_statusline)
	if l:line ==# s:last_statusline
		" don't spam the same message twice
		return
	endif
	let s:last_statusline = l:line
	python3 write()
endfunc

func tpipeline#forceupdate()
	let s:last_statusline = ''
	call tpipeline#update()
endfunc
