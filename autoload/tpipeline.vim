func tpipeline#get_filepath()
	" e.g. /tmp/tmux-1000/default-$0-vimbridge
	let tmux = $TMUX
	return strcharpart(tmux, 0, stridx(tmux, ",")) . '-$' . strcharpart(tmux, strridx(tmux, ",") + 1) . '-vimbridge'
endfunc

func tpipeline#build_hooks()
	let g:tpipeline_hooks_enabled = 1
	augroup tpipeline
		au FocusGained * call tpipeline#forceupdate()
		if g:tpipeline_focuslost
			au FocusLost * call tpipeline#deferred_cleanup()
		endif
		au VimLeavePre * call tpipeline#cleanup()
		au BufEnter,InsertLeave,CursorHold,CursorHoldI * call tpipeline#update()
		if s:has_modechgd
			au ModeChanged *:[^c]* call tpipeline#update()
			au CmdlineEnter * call tpipeline#deferred_update()
		else
			au InsertEnter,CmdlineEnter,CmdlineLeave * call tpipeline#deferred_update()
		endif
		if g:tpipeline_cursormoved
			au CursorMoved * call tpipeline#update()
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
	if !exists('g:tpipeline_fillcentre')
		let g:tpipeline_fillcentre = 0
	endif
	if !exists('g:tpipeline_usepane')
		let g:tpipeline_usepane = 0
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
	if !exists('g:tpipeline_clearstl')
		let g:tpipeline_clearstl = 0
	endif
	if !exists('g:tpipeline_restore')
		let g:tpipeline_restore = 0
	endif
	if !exists('g:tpipeline_delay')
		let g:tpipeline_delay = 128
	endif
	if g:tpipeline_tabline
		set showtabline=0
	else
		set laststatus=0
		set noruler
	endif
	let s:tpipeline_filepath = tpipeline#get_filepath()
	let s:tpipeline_right_filepath = s:tpipeline_filepath . '-R'
	augroup tpipelinei
		if v:vim_did_enter
			call tpipeline#init_statusline()
		else
			au VimEnter * call tpipeline#init_statusline()
		endif
	augroup END

	let s:update_pending = 0
	let s:update_required = 0
	let s:last_statusline = ''
	let s:last_writtenline = ''
	let s:cleanup_delay = 45
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
	let s:clear_stream = "\n"
	if g:tpipeline_split
		let s:clear_stream .= "\n"
	endif

	let s:job_check = 1

	let s:is_nvim = has('nvim')
	let s:has_modechgd = exists('##ModeChanged')
	let s:has_eval_stl = 0
	if has('nvim-0.6')
		let s:has_eval_stl = 1
		let g:tpipeline_fillchar = ""
		if g:tpipeline_delay == 128
			let g:tpipeline_delay = 0
		endif

		call tpipeline#util#set_size()
		au VimResized * call tpipeline#util#set_size()
		au UIEnter * call tpipeline#util#check_gui()
	endif
endfunc

func tpipeline#fork_job()
	if g:tpipeline_restore
		let s:restore_left = system("tmux display-message -p '#{status-left}'")
		let s:restore_right = system("tmux display-message -p '#{status-right}'")
	endif
	let script = printf("while IFS='$\\n' read -r l; do echo \"$l\" > '%s'", s:tpipeline_filepath)
	if g:tpipeline_usepane
		" end early if file was truncated so as not to overwrite any titles of panes we may switch to
		let script .= "; if [ -z \"$l\" ]; then continue; fi"
	endif
	if g:tpipeline_autoembed
		for o in g:tpipeline_embedopts
			let script = 'tmux set -g ' . o . '; ' . script
		endfor
	endif
	if g:tpipeline_fillcentre
		let script .= "; C=$(echo \"$l\" | grep -o 'bg=#[0-9a-f]\\{6\\}'| tail -1)"
		if !g:tpipeline_usepane
			let script .= "; tmux set -g status-style \"$C\""
		endif
	endif
	if g:tpipeline_split
		let script .= printf("; IFS='$\\n' read -r r; echo \"$r\" > '%s'", s:tpipeline_right_filepath)
	endif
	if g:tpipeline_usepane
		let script .= "; tmux select-pane -T \"#[fill=${C:3}]#[align=left]$l#[align=right]$r\""
	endif
	let script .= "; tmux refresh-client -S; done"

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
	au! tpipelinei
	call tpipeline#build_hooks()
	call tpipeline#fork_job()

	if empty(g:tpipeline_statusline)
		if g:tpipeline_tabline
			if empty(&tabline)
				set tabline=%!tpipeline#stl#tabline()
			endif
			let g:tpipeline_statusline = &tabline
		else
			if empty(&stl)
				set stl=%!tpipeline#stl#line()
			endif
			if !s:is_nvim
				let g:tpipeline_statusline = &stl
			endif
			if g:tpipeline_clearstl
				set stl=%#StatusLine#
			endif
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
	let s:delay_timer = timer_start(g:tpipeline_delay, {-> tpipeline#delayed_update()})
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
	if g:tpipeline_delay
		if s:update_pending
			let s:update_required = 1
			return
		endif
		let s:update_pending = 1
		let s:delay_timer = timer_start(g:tpipeline_delay, {-> tpipeline#delayed_update()})
	endif

	if s:has_eval_stl
		let line = luaeval("require'tpipeline.main'.update()")
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

func tpipeline#restore_tmux()
	call system('tmux set -g status-left ' . shellescape(s:restore_left))
	if g:tpipeline_split
		call system('tmux set -g status-right ' . shellescape(s:restore_right))
	endif
endfunc

func tpipeline#cleanup()
	if g:tpipeline_restore
		call tpipeline#restore_tmux()
	else
		if s:is_nvim
			call jobstop(s:job)
		else
			call job_stop(s:job)
		endif
		call writefile([''], s:tpipeline_filepath, '')
		if g:tpipeline_split
			call writefile([''], s:tpipeline_right_filepath, '')
		endif
		call system('tmux refresh-client -S')
	endif
endfunc

func tpipeline#forceupdate()
	if g:tpipeline_restore
		call system("tmux set -g status-left '#(cat #{socket_path}-\\#{session_id}-vimbridge)'")
		if g:tpipeline_split
			call system("tmux set -g status-right '#(cat #{socket_path}-\\#{session_id}-vimbridge-R)'")
		endif
	endif
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
		if g:tpipeline_restore
			call tpipeline#restore_tmux()
		else
			if s:is_nvim
				call chansend(s:channel, s:clear_stream)
			else
				call ch_sendraw(s:channel, s:clear_stream)
			endif
		endif
	endif
endfunc

func tpipeline#deferred_cleanup()
	let s:cleanup_timer = timer_start(s:cleanup_delay, {-> tpipeline#cautious_cleanup()})
endfunc
