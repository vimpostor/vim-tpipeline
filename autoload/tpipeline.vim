func tpipeline#set_filepath()
	" for example /tmp/tmux-1000/default-$0-vimbridge
	let l:tmux = $TMUX
	let l:path = strcharpart(l:tmux, 0, stridx(l:tmux, ","))
	let l:session_id = strcharpart(l:tmux, strridx(l:tmux, ",") + 1)
	let l:head = l:path . '-$' . l:session_id
	let s:tpipeline_filepath = l:head . '-vimbridge'
	let s:tpipeline_right_filepath = s:tpipeline_filepath . '-R'
	let s:script_path = l:head . '-so.sh'
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
		autocmd BufEnter,InsertEnter,InsertLeave,CursorHold,CursorHoldI,CmdlineEnter * call tpipeline#update()
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

	let s:update_delay = 128
	let s:update_pending = 0
	let s:update_required = 0
	let s:last_statusline = ''
	let s:last_writtenline = ''
	let l:hlid = synIDtrans(hlID('StatusLine'))
	let s:default_color = printf('#[fg=%s,bg=%s]', synIDattr(l:hlid, 'fg'), synIDattr(l:hlid, 'bg'))

	let s:is_nvim = 0
	if has('nvim')
		let s:is_nvim = 1
	endif
endfunc

func tpipeline#fork_job()
	" TODO: Append to the file
	let l:script = printf("#!/usr/bin/env bash\nwhile IFS='$\\n' read -r l; do\necho \"$l\" > '%s'", s:tpipeline_filepath)
	if g:tpipeline_split
		let l:script = l:script . printf("\nIFS='$\\n' read -r l\necho \"$l\" > '%s'", s:tpipeline_right_filepath)
	endif
	let l:script = split(l:script . "\ntmux refresh-client -S\ndone", "\n")
	call writefile(l:script, s:script_path)

	let l:command = '/usr/bin/env bash ' . s:script_path
	if s:is_nvim
		let s:job = jobstart(split(l:command))
		let s:channel = s:job
	else
		let s:job = job_start(l:command, {'noblock': 1})
		let s:channel = job_getchannel(s:job)
	endif
endfunc

func tpipeline#init_statusline()
	call tpipeline#fork_job()

	if empty(g:tpipeline_statusline)
		if empty(&statusline)
			" default statusline
			set statusline=%!tpipeline#stl#line()
		endif
		let g:tpipeline_statusline = &statusline
	endif
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

	" append default color
	let l:line = s:default_color . l:line
	let l:cstream = ''

	if g:tpipeline_split
		let l:split_point = stridx(l:line, '%=')
		let l:left_line = l:line
		let l:right_line = ''
		if l:split_point != -1
			let l:left_line = strpart(l:line, 0, l:split_point)
			let l:right_line = s:default_color . strpart(l:line, l:split_point + 2)
		endif
		let l:cstream = l:right_line . "\n"
		let s:last_writtenline = l:left_line
	else
		let s:last_writtenline = tpipeline#parse#remove_align(l:line)
	endif
	let l:cstream = s:last_writtenline . "\n" . l:cstream
	if s:is_nvim
		call chansend(s:channel, l:cstream)
	else
		call ch_sendraw(s:channel, l:cstream)
	endif
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
