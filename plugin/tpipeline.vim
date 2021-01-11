if exists('g:loaded_tpipeline') || empty($TMUX)
	finish
endif
let g:loaded_tpipeline = 1

func s:set_filepath()
	" for example /tmp/tmux-1000/default-$0-vimbridge
	let l:tmux = $TMUX
	let l:path = strcharpart(l:tmux, 0, stridx(l:tmux, ","))
	let l:session_id = strcharpart(l:tmux, strridx(l:tmux, ",") + 1)
	let s:tpipeline_filepath = l:path . '-$' . l:session_id . '-vimbridge'
endfunc

func s:build_hooks()
	augroup tpipeline
		autocmd FocusGained * call s:tpipelineForceUpdate()
		autocmd VimLeave * call s:cleanup()
		autocmd BufEnter * call TPipelineUpdate()
	augroup END
endfunc

func s:initialize()
	if !exists('g:tpipeline_statusline')
		let g:tpipeline_statusline = '%t'
	endif
	set laststatus=0
	call s:set_filepath()
	call s:build_hooks()

	let s:socket_rotate_threshold = 128
	let s:socket_write_count = 0
	let s:last_statusline = ''
endfunc

func s:parse(opt)
	if a:opt == 'F'
		return expand('%:p')
	elseif a:opt == 't'
		return expand('%:t')
	endif
	return ''
endfunc

func s:parse_stl()
	let l:res = g:tpipeline_statusline

	" parse every % according to standard statusline rules
	let l:i = 0
	while l:i < (strlen(l:res) - 1)
		if strcharpart(l:res, l:i, 1) == '%'
			let l:ins = s:parse(strcharpart(l:res, l:i + 1, 1))
			let l:res = strcharpart(l:res, 0, l:i) . l:ins . strcharpart(l:res, l:i + 2)
			let l:i += l:ins
		endif
		let l:i += 1
	endwhile

	return l:res
endfunc

func TPipelineUpdate()
	let l:line = s:parse_stl()
	if l:line ==# s:last_statusline
		" don't spam the same message twice
		return
	endif
	let s:last_statusline = l:line

	let l:write_mode = "a"
	let s:socket_write_count += 1
	" rotate the file when it gets too large
	if s:socket_write_count > s:socket_rotate_threshold
		let l:write_mode = ""
		let s:socket_write_count = 0
	endif
	call writefile([l:line], s:tpipeline_filepath, l:write_mode)
endfunc

func s:tpipelineForceUpdate()
	let s:last_statusline = ''
	call TPipelineUpdate()
endfunc

func s:cleanup()
	call writefile([''], s:tpipeline_filepath)
endfunc

call s:initialize()
