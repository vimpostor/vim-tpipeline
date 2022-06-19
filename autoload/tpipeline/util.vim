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
