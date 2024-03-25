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
	if !empty($TMUX)
		let g:tpipeline_size = str2nr(systemlist("sh -c 'echo \"\"; tmux display-message -p \"#{window_width}\"'")[-1])
	elseif !empty($ZELLIJ)
		" TODO: verify if this is reasonable.
		let g:tpipeline_size = str2nr(systemlist("sh -c 'tput cols'")[-1])
	endif
endfunc

func tpipeline#util#set_custom_size()
	if exists('#User#TpipelineSize')
		doautocmd User TpipelineSize
	endif
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
