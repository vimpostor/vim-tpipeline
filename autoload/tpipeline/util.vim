func tpipeline#util#percentage()
	return line('.') * 100 / line('$')
endfunc

func tpipeline#util#pad(str, num)
	return repeat(' ', a:num - strchars(a:str)) . a:str
endfunc

func tpipeline#util#left_justify(str)
	let num = strchars(matchstr(a:str, '^\ *'))
	return strcharpart(a:str, num) . repeat(' ', num)
endfunc

func tpipeline#util#set_size()
	let g:tpipeline_size = str2nr(systemlist("tmux display-message -p '#{window_width}'")[-1])
endfunc

func tpipeline#util#check_gui()
	if (v:event['chan'] && !has('nvim-0.9')) || has('gui_running')
		call tpipeline#state#restore()
	endif
endfunc

func tpipeline#util#remove_align(str)
	return substitute(a:str, '%=', '', 'g')
endfunc

func tpipeline#util#clear_stl()
	let g:tpipeline_statusline = &stl
	set stl=%#StatusLine#
endfunc

func tpipeline#util#set_stl_hooks()
	if empty(g:tpipeline_statusline) && !g:tpipeline_tabline
		if g:tpipeline_clearstl
			au OptionSet statusline if v:option_type == 'global' | call tpipeline#util#clear_stl() | endif
		endif
		au OptionSet statusline call tpipeline#update()
	endif
endfunc
