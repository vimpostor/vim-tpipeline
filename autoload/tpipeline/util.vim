func tpipeline#util#percentage()
	return line('.') * 100 / line('$')
endfunc

func tpipeline#util#pad(str, num)
	return repeat(' ', a:num - strchars(a:str)) . a:str
endfunc

func tpipeline#util#left_justify(str)
	let l:num = strchars(matchstr(a:str, '^\ *'))
	return strcharpart(a:str, l:num) . repeat(' ', l:num)
endfunc
