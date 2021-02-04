func tpipeline#set_filepath()
	" for example /tmp/tmux-1000/default-$0-vimbridge
	let l:tmux = $TMUX
	let l:path = strcharpart(l:tmux, 0, stridx(l:tmux, ","))
	let l:session_id = strcharpart(l:tmux, strridx(l:tmux, ",") + 1)
	let s:tpipeline_filepath = l:path . '-$' . l:session_id . '-vimbridge'
	let s:tpipeline_right_filepath = s:tpipeline_filepath . '-R'
endfunc

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
			autocmd FocusLost * call tpipeline#cautious_cleanup()
		endif
		autocmd VimLeave * call tpipeline#cleanup('')
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
	call tpipeline#set_filepath()
	call tpipeline#build_hooks()

	let s:socket_rotate_threshold = 128
	let s:socket_write_count = 0
	let s:last_statusline = ''
	let s:last_writtenline = ''
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
endfunc

func tpipeline#update()
	let l:line = tpipeline#parse#parse_stl(g:tpipeline_statusline)
	if l:line ==# s:last_statusline
		" don't spam the same message twice
		return
	endif
	let s:last_statusline = l:line

	let l:write_mode = 'a' " append mode
	let s:socket_write_count += 1
	" rotate the file when it gets too large
	if s:socket_write_count > s:socket_rotate_threshold
		let l:write_mode = ''
		let s:socket_write_count = 0
	endif

	" append default color
	let l:line = s:default_color . l:line

	if g:tpipeline_split
		let l:split_point = stridx(l:line, '%=')
		let l:left_line = l:line
		let l:right_line = ''
		if l:split_point != -1
			let l:left_line = strpart(l:line, 0, l:split_point)
			let l:right_line = s:default_color . tpipeline#parse#remove_align(strpart(l:line, l:split_point + 2))
		endif
		call writefile([l:right_line], s:tpipeline_right_filepath, l:write_mode)
		let s:last_writtenline = l:left_line
	else
		let s:last_writtenline = tpipeline#parse#remove_align(l:line)
	endif
	call writefile([s:last_writtenline], s:tpipeline_filepath, l:write_mode)
	" force tmux to update its statusline
	let s:timer = timer_start(1, {-> system('tmux refresh-client -S')})
endfunc

func tpipeline#cleanup(mode)
	call writefile([''], s:tpipeline_filepath, a:mode)
	if g:tpipeline_split
		call writefile([''], s:tpipeline_right_filepath, a:mode)
	endif
endfunc

func tpipeline#forceupdate()
	let s:last_statusline = ''
	call tpipeline#update()
endfunc

func tpipeline#cautious_cleanup()
	" check if some other instance wrote to the socket right before us
	let l:written_file = readfile(s:tpipeline_filepath, '', -1)
	if empty(l:written_file)
		let l:written_line = ''
	else
		let l:written_line = l:written_file[0]
	endif

	if s:last_writtenline ==# l:written_line
		call tpipeline#cleanup('a')
	endif
endfunc
