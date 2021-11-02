func tpipeline#set_filepath()
	" e.g. /tmp/tmux-1000/default-$0-vimbridge
	let tmux = $TMUX
	let s:tpipeline_filepath = strcharpart(tmux, 0, stridx(tmux, ",")) . '-$' . strcharpart(tmux, strridx(tmux, ",") + 1) . '-vimbridge'
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
		if s:has_modechgd
			autocmd ModeChanged *:[^c]* call tpipeline#update()
			autocmd CmdlineEnter * call tpipeline#deferred_update()
		else
			autocmd InsertEnter,CmdlineEnter,CmdlineLeave * call tpipeline#deferred_update()
		endif
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
	if !exists('g:tpipeline_autoembed')
		let g:tpipeline_autoembed = 1
	endif
	if !exists('g:tpipeline_embedopts')
		let g:tpipeline_embedopts = ["status-left '#(cat #{socket_path}-\\#{session_id}-vimbridge)'"]
		if g:tpipeline_split
			let g:tpipeline_embedopts = add(g:tpipeline_embedopts, "status-right '#(cat #{socket_path}-\\#{session_id}-vimbridge-R)'")
		endif
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
	let hlid = synIDtrans(hlID('StatusLine'))
	let bg_color = synIDattr(hlid, 'bg')
	if empty(bg_color)
		let bg_color = synIDattr(synIDtrans(hlID('Normal')), 'bg')
	endif
	let s:default_color = printf('#[fg=%s,bg=%s]', synIDattr(hlid, 'fg'), bg_color)
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
	let s:has_modechgd = 0
	if has('patch-8.2.3430')
		let s:has_modechgd = 1
	endif
	let s:has_eval_stl = 0
	if has('nvim-0.6')
		let s:has_eval_stl = 1
		let g:tpipeline_fillchar = ""
	endif
endfunc

func tpipeline#fork_job()
	let script = printf("while IFS='$\\n' read -r l; do echo \"$l\" > '%s'", s:tpipeline_filepath)
	if g:tpipeline_autoembed
		for o in g:tpipeline_embedopts
			let script = 'tmux set -g ' . o . '; ' . script
		endfor
	endif
	if g:tpipeline_split
		let script = script . printf("; IFS='$\\n' read -r l; echo \"$l\" > '%s'", s:tpipeline_right_filepath)
	endif
	let script = script . "; tmux refresh-client -S; done"

	let command = ['bash', '-c', script]
	if s:is_nvim
		let s:job = jobstart(command)
		let s:channel = s:job
	else
		let options = {}
		if has("patch-8.1.350")
			let options['noblock'] = 1
		endif
		let s:job = job_start(command, options)
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
			let g:tpipeline_statusline = &tabline
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

	if s:has_eval_stl
		let line = tpipeline#parse#eval_stl(g:tpipeline_statusline)
	else
		let line = tpipeline#parse#parse_stl(g:tpipeline_statusline)
	endif
	if line ==# s:last_statusline
		" don't spam the same message twice
		return
	endif
	let s:last_statusline = line

	let line = s:line_pfx . line
	let cstream = ''

	if g:tpipeline_split
		let split_point = stridx(line, '%=')
		let left_line = line
		let right_line = ''
		if split_point != -1
			let left_line = strpart(line, 0, split_point)
			let right_line = s:line_pfx . strpart(line, split_point + 2)
		endif
		let cstream = right_line . "\n"
		let s:last_writtenline = left_line
	else
		let s:last_writtenline = tpipeline#parse#remove_align(line)
	endif
	let cstream = s:last_writtenline . "\n" . cstream
	if s:is_nvim
		call chansend(s:channel, cstream)
	else
		call ch_sendraw(s:channel, cstream)
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
	let written_file = readfile(s:tpipeline_filepath, '', -1)
	if empty(written_file)
		let written_line = ''
	else
		let written_line = written_file[0]
	endif

	if s:last_writtenline ==# written_line
		let cstream = "\n"
		if g:tpipeline_split
			let cstream = cstream . "\n"
		endif
		if s:is_nvim
			call chansend(s:channel, cstream)
		else
			call ch_sendraw(s:channel, cstream)
		endif
	endif
endfunc
