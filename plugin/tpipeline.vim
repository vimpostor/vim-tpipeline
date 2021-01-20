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
		if v:vim_did_enter
			call s:tpipelineInitStatusline()
		else
			autocmd VimEnter * call s:tpipelineInitStatusline()
		endif

		autocmd FocusGained * call s:tpipelineForceUpdate()
		autocmd FocusLost * call s:cautious_cleanup()
		autocmd VimLeave * call s:cleanup()
		autocmd BufEnter,InsertEnter,InsertLeave,CursorHold,CursorHoldI,CursorMoved * call TPipelineUpdate()
	augroup END
endfunc

func s:initialize()
	if !exists('g:tpipeline_statusline')
		let g:tpipeline_statusline = ''
	endif
	set laststatus=0
	call s:set_filepath()
	call s:build_hooks()

	let s:socket_rotate_threshold = 128
	let s:socket_write_count = 0
	let s:last_statusline = ''
endfunc

func s:percentage()
	return line('.') * 100 / line('$')
endfunc

func s:pad(str, num)
	return repeat(' ', a:num - strchars(a:str)) . a:str
endfunc

func s:left_justify(str)
	let l:num = strchars(matchstr(a:str, '^\ *'))
	return strcharpart(a:str, l:num) . repeat(' ', l:num)
endfunc

func s:parse(opt)
	let l:first = strcharpart(a:opt, 0, 1)
	let l:len = strchars(a:opt)

	if l:len == 1
		" handle singlechar arguments
		if l:first ==# 'f'
			return expand('%')
		elseif l:first ==# 'F'
			return expand('%:p')
		elseif l:first ==# 't'
			return expand('%:t')
		elseif l:first ==# 'm'
			return &modified ? '[+]' : (&modifiable ? '' : '-')
		elseif l:first ==# 'M'
			return &modified ? '+' : (&modifiable ? '' : '-')
		elseif l:first ==# 'r'
			return &readonly ? '[RO]' : ''
		elseif l:first ==# 'R'
			return &readonly ? 'RO' : ''
		elseif l:first ==# 'y'
			return '[' . &filetype . ']'
		elseif l:first ==# 'Y'
			return &filetype
		elseif l:first ==# 'l'
			return line('.')
		elseif l:first ==# 'L'
			return line('$')
		elseif l:first ==# 'c'
			return col('.')
		elseif l:first ==# 'v'
			return virtcol('.')
		elseif l:first ==# 'p'
			return s:percentage()
		elseif l:first ==# '%'
			return '%'
		endif
	else
		" handle multichar arguments
		let l:inner = strcharpart(a:opt, 1, l:len - 2)
		if l:first ==# '{'
			return s:parse_stl(eval(l:inner))
		elseif l:first ==# '#'
			let l:id = synIDtrans(hlID(l:inner))
			return printf('#[fg=%s,bg=%s]', synIDattr(l:id, 'fg'), synIDattr(l:id, 'bg'))
		endif

		" handle formatting parameters
		let l:next = strcharpart(a:opt, 1)
		if l:first ==# '-'
			" Left justify the item
			return s:left_justify(s:parse(l:next))
		elseif l:first ==# '0'
			" Leading zeroes in numeric items
			" TODO: Implement this
			return s:parse(l:next)
		elseif match(l:first, '[0-9]') != -1
			" minwidth
			let l:num = matchstr(a:opt, '^[0-9]*')
			let l:next = strcharpart(a:opt, strchars(l:num))
			return s:pad(s:parse(l:next), str2nr(l:num))
		elseif l:first ==# '.'
			" maxwidth
			let l:num = matchstr(l:next, '^[0-9]*')
			let l:next = strcharpart(l:next, strchars(l:num))
			return strcharpart(s:parse(l:next), 0, str2nr(l:num))
		endif
	endif

	return ''
endfunc

func s:charmatch(s)
	let l:c = strcharpart(a:s, 0, 1)
	if l:c ==# '{'
		let l:c = '}'
	endif
	let l:i = 1
	let l:len = strchars(a:s)
	while l:i < l:len
		if strcharpart(a:s, l:i, 1) ==# l:c
			return l:i + 1
		endif
		let l:i += 1
	endwhile
	" whoops, looks like we didn't find a matching character
	return 1
endfunc

func s:parse_stl(stl)
	let l:res = a:stl

	if strcharpart(l:res, 0, 2) ==# '%!'
		" if we have a command, parse the evaluated command instead
		let l:cmd = strcharpart(l:res, 2)
		return s:parse_stl(eval(l:cmd))
	endif

	" parse every % according to standard statusline rules
	let l:i = 0
	while l:i < (strchars(l:res) - 1)
		if strcharpart(l:res, l:i, 1) ==# '%'
			let l:next = strcharpart(l:res, l:i + 1, 1)
			if (l:next ==# '#' || l:next ==# '{')
				let l:next = strcharpart(l:res, l:i + 1, s:charmatch(strcharpart(l:res, l:i + 1)))
			elseif (l:next ==# '-' || match(l:next, '[0-9]') == 0 || l:next ==# '.')
				let l:match = matchstr(strcharpart(l:res, l:i + 1), '^\(-\|\)[0-9]*\(\.[0-9]*\|\).')
				if strchars(l:match) > 1
					let l:next = l:match
				endif
			endif
			let l:ins = s:parse(l:next)
			let l:res = strcharpart(l:res, 0, l:i) . l:ins . strcharpart(l:res, l:i + 1 + strchars(l:next))
			let l:i += strchars(l:ins) - 1
		endif
		let l:i += 1
	endwhile

	return l:res
endfunc

func s:tpipelineInitStatusline()
	if empty(g:tpipeline_statusline)
		if empty(&statusline)
			" default statusline
			let g:tpipeline_statusline = '%f'
		else
			let g:tpipeline_statusline = &statusline
		endif
	endif
endfunc

func TPipelineUpdate()
	let l:line = s:parse_stl(g:tpipeline_statusline)
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
	call writefile([l:line], s:tpipeline_filepath, l:write_mode)
endfunc

func s:tpipelineForceUpdate()
	let s:last_statusline = ''
	call TPipelineUpdate()
endfunc

func s:cleanup()
	call writefile([''], s:tpipeline_filepath, 'a')
endfunc

func s:cautious_cleanup()
	" check if some other instance wrote to the socket right before us
	let l:written_line = reduce(readfile(s:tpipeline_filepath, '', -1), { acc, val -> acc . val }, '')
	if s:last_statusline ==# l:written_line
		call s:cleanup()
	endif
endfunc

call s:initialize()
