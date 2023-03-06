if !has('nvim')
	import autoload 'tpipeline/parse.vim'
endif

func tpipeline#get_filepath()
	" e.g. /tmp/tmux-1000/default-$0-vimbridge
	let tmux = $TMUX
	if empty(tmux)
		let p = "/tmp/tmux-" . systemlist("id -u")[-1]
		silent! call mkdir(p)
		let tmux = p . "/default,0,0"
	endif
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
			au CmdlineEnter * call tpipeline#update()
		else
			au InsertEnter,CmdlineEnter,CmdlineLeave * call tpipeline#update()
		endif
		if g:tpipeline_cursormoved
			au CursorMoved * call tpipeline#update()
		endif

		if empty(g:tpipeline_statusline) && !g:tpipeline_tabline
			if tpipeline#lualine#is_lualine()
				au OptionSet statusline call tpipeline#lualine#delay_eval()
			elseif g:tpipeline_clearstl
				au OptionSet statusline if v:option_type == 'global' | call tpipeline#util#clear_stl() | endif
			endif
			au OptionSet statusline call tpipeline#update()
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
		let g:tpipeline_cursormoved = 1
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
	if !exists('g:tpipeline_refreshcmd')
		let g:tpipeline_refreshcmd = 'tmux refresh-client -S'
	endif
	if !exists('g:tpipeline_clearstl')
		let g:tpipeline_clearstl = 0
	endif
	if !exists('g:tpipeline_restore')
		let g:tpipeline_restore = 0
	endif
	if g:tpipeline_tabline
		set showtabline=0
	else
		set laststatus=0
		set noruler
	endif
	let s:tpipeline_filepath = tpipeline#get_filepath()
	let s:tpipeline_right_filepath = s:tpipeline_filepath . '-R'

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

	let s:needs_cleanup = 0

	let s:is_nvim = has('nvim')
	let s:has_modechgd = exists('##ModeChanged')

	if s:is_nvim
		let g:tpipeline_fillchar = ""

		if !exists('g:tpipeline_size')
			call tpipeline#util#set_size()
			au VimResized * call tpipeline#util#set_size()
		endif
		au UIEnter * call tpipeline#util#check_gui()
	endif

	augroup tpipelinei
		if v:vim_did_enter
			call tpipeline#init_statusline()
		else
			au VimEnter * call tpipeline#init_statusline()
		endif
	augroup END
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
			let script = 'tmux set ' . o . '; ' . script
		endfor
	endif
	if g:tpipeline_fillcentre
		let script .= "; C=$(echo \"$l\" | grep -o 'bg=#[0-9a-f]\\{6\\}'| tail -1)"
		if !g:tpipeline_usepane
			let script .= "; tmux set status-style \"$C\""
		endif
	endif
	if g:tpipeline_split
		let script .= printf("; IFS='$\\n' read -r r; echo \"$r\" > '%s'", s:tpipeline_right_filepath)
	endif
	if g:tpipeline_usepane
		let script .= "; tmux select-pane -T \"#[fill=${C:3}]#[align=left]$l#[align=right]$r\""
	endif
	let script .= "; " . g:tpipeline_refreshcmd . "; done"

	let command = ['bash', '-c', script]
	if s:is_nvim
		let s:job = jobstart(command)
		let s:channel = s:job
	else
		let options = #{noblock: 1}
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
			if g:tpipeline_clearstl
				call tpipeline#util#clear_stl()
			endif
		endif
	endif

	call tpipeline#update()
endfunc

func tpipeline#update()
	if s:is_nvim
		let line = luaeval("require'tpipeline.main'.update()")
	else
		let stl = g:tpipeline_statusline
		if empty(stl)
			let stl = &stl
		endif
		let line = s:parse.Parse_stl(stl)
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
		let s:last_writtenline = tpipeline#util#remove_align(line)
	endif
	let cstream = s:last_writtenline . "\n" . cstream
	if s:is_nvim
		call chansend(s:channel, cstream)
	else
		call ch_sendraw(s:channel, cstream)
	endif
endfunc

func tpipeline#restore_tmux()
	call system('tmux set status-left ' . shellescape(s:restore_left))
	if g:tpipeline_split
		call system('tmux set status-right ' . shellescape(s:restore_right))
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
	let s:needs_cleanup = 0
	if g:tpipeline_restore
		call system("tmux set status-left '#(cat #{socket_path}-\\#{session_id}-vimbridge)'")
		if g:tpipeline_split
			call system("tmux set status-right '#(cat #{socket_path}-\\#{session_id}-vimbridge-R)'")
		endif
	endif
	let s:last_statusline = ''
	call tpipeline#update()
endfunc

func tpipeline#cautious_cleanup()
	if !s:needs_cleanup
		return
	endif
	let s:needs_cleanup = 0
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
	let s:needs_cleanup = 1
	let s:cleanup_timer = timer_start(s:cleanup_delay, {-> tpipeline#cautious_cleanup()})
endfunc
