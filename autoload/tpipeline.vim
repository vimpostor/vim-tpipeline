func tpipeline#set_filepath()
	" for example /tmp/tmux-1000/default-$0-vimbridge
	let l:tmux = $TMUX
	let l:path = strcharpart(l:tmux, 0, stridx(l:tmux, ","))
	let l:session_id = strcharpart(l:tmux, strridx(l:tmux, ",") + 1)
	let l:head = l:path . '-$' . l:session_id
	let s:tpipeline_filepath = l:head . '-vimbridge'
	let s:tpipeline_right_filepath = s:tpipeline_filepath . '-R'
endfunc

func tpipeline#build_hooks()
	let g:tpipeline_hooks_enabled = 1
	augroup tpipeline
		autocmd FocusGained * call tpipeline#forceupdate()
		if g:tpipeline_focuslost
			autocmd FocusLost * call tpipeline#cautious_cleanup()
		endif
		autocmd VimLeavePre * call tpipeline#cleanup()
		autocmd BufEnter,InsertLeave,CursorHold,CursorHoldI * call tpipeline#update()
		autocmd InsertEnter,CmdlineEnter * call tpipeline#deferred_update()
		if g:tpipeline_cursormoved
			autocmd CursorMoved * call tpipeline#update()
		endif
	augroup END
endfunc

func tpipeline#initialize()
	if !exists('g:tpipeline_statusline')
		let g:tpipeline_statusline = ''
	endif
	if !exists('g:tpipeline_split')
		let g:tpipeline_split = 1
	endif
	if !exists('g:tpipeline_focuslost')
		let g:tpipeline_focuslost = 1
	endif
	if !exists('g:tpipeline_cursormoved')
		let g:tpipeline_cursormoved = 0
	endif
	if !exists('g:tpipeline_tabline')
		let g:tpipeline_tabline = 0
	endif
	if !exists('g:tpipeline_preservebg')
		let g:tpipeline_preservebg = 0
	endif
	if g:tpipeline_tabline
		set showtabline=0
	else
		set laststatus=0
	endif
	call tpipeline#set_filepath()
	augroup tpipelinei
		if v:vim_did_enter
			call tpipeline#init_statusline()
		else
			autocmd VimEnter * call tpipeline#init_statusline()
		endif
	augroup END

	let s:update_delay = 128
	let s:update_pending = 0
	let s:update_required = 0
	let s:last_statusline = ''
	let s:last_writtenline = ''
	let l:hlid = synIDtrans(hlID('StatusLine'))
	let l:bg_color = synIDattr(l:hlid, 'bg')
	if empty(l:bg_color)
		let l:bg_color = synIDattr(synIDtrans(hlID('Normal')), 'bg')
	endif
	let s:default_color = printf('#[fg=%s,bg=%s]', synIDattr(l:hlid, 'fg'), l:bg_color)
	let s:line_pfx = ''
	if !g:tpipeline_preservebg
		" prepend default color
		let s:line_pfx = s:default_color
	endif

	let s:job_check = 1

	let s:is_nvim = 0
	if has('nvim')
		let s:is_nvim = 1
	endif
endfunc

func tpipeline#fork_job()
	let l:script = printf("while IFS='$\\n' read -r l; do echo \"$l\" > '%s'", s:tpipeline_filepath)
	if g:tpipeline_split
		let l:script = l:script . printf("; IFS='$\\n' read -r l; echo \"$l\" > '%s'", s:tpipeline_right_filepath)
	endif
	let l:script = l:script . "; tmux refresh-client -S; done"

	let l:command = ['bash', '-c', l:script]
	if s:is_nvim
		let s:job = jobstart(l:command)
		let s:channel = s:job
	else
		let l:options = {}
		if has("patch-8.1.350")
			let options['noblock'] = 1
		endif
		let s:job = job_start(l:command, l:options)
		let s:channel = job_getchannel(s:job)
	endif
endfunc

func tpipeline#init_statusline()
	autocmd! tpipelinei
	call tpipeline#build_hooks()
	call tpipeline#fork_job()

	if empty(g:tpipeline_statusline)
		if g:tpipeline_tabline
			" TODO: Add a default tabline
			let g:tpipeline = &tabline
		else
			if empty(&statusline)
				set statusline=%!tpipeline#stl#line()
			endif
			let g:tpipeline_statusline = &statusline
		endif
	endif

	call tpipeline#update()
endfunc

func tpipeline#deferred_update()
	let s:update_required = 1
	if s:update_pending
		return
	endif
	let s:update_pending = 1
	let s:delay_timer = timer_start(s:update_delay, {-> tpipeline#delayed_update()})
endfunc

func tpipeline#delayed_update()
	if s:job_check
		if (s:is_nvim && s:job < 0) || (!s:is_nvim && job_status(s:job) == 'dead')
			call tpipeline#state#freeze()
		endif
		let s:job_check = 0
	endif
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

	let l:line = s:line_pfx . l:line
	let l:cstream = ''

	if g:tpipeline_split
		let l:split_point = stridx(l:line, '%=')
		let l:left_line = l:line
		let l:right_line = ''
		if l:split_point != -1
			let l:left_line = strpart(l:line, 0, l:split_point)
			let l:right_line = s:line_pfx . strpart(l:line, l:split_point + 2)
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

func tpipeline#cleanup()
	call writefile([''], s:tpipeline_filepath, '')
	if g:tpipeline_split
		call writefile([''], s:tpipeline_right_filepath, '')
	endif
	call system('tmux refresh-client -S')
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
		let l:cstream = "\n"
		if g:tpipeline_split
			let l:cstream = l:cstream . "\n"
		endif
		if s:is_nvim
			call chansend(s:channel, l:cstream)
		else
			call ch_sendraw(s:channel, l:cstream)
		endif
	endif
endfunc
