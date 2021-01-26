func tpipeline#parse#percentage()
	return line('.') * 100 / line('$')
endfunc

func tpipeline#parse#pad(str, num)
	return repeat(' ', a:num - strchars(a:str)) . a:str
endfunc

func tpipeline#parse#left_justify(str)
	let l:num = strchars(matchstr(a:str, '^\ *'))
	return strcharpart(a:str, l:num) . repeat(' ', l:num)
endfunc

func tpipeline#parse#remove_align(str)
	return substitute(a:str, '%=', '', 'g')
endfunc

func tpipeline#parse#parse(opt)
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
			return tpipeline#parse#percentage()
		elseif l:first ==# 'P'
			return tpipeline#parse#percentage() . '%'
		elseif l:first ==# '='
			return '%='
		elseif l:first ==# '%'
			return '%'
		endif
	else
		" handle multichar arguments
		let l:inner = strcharpart(a:opt, 1, l:len - 2)
		if l:first ==# '{'
			return tpipeline#parse#parse_stl(eval(l:inner))
		elseif l:first ==# '#'
			let l:id = synIDtrans(hlID(l:inner))

			let l:fg = synIDattr(l:id, 'fg')
			if l:fg ==# 'fg'
				let l:fg = 'default'
			endif
			let l:bg = synIDattr(l:id, 'bg')
			if l:bg ==# 'bg'
				let l:bg = 'default'
			endif
			return printf('#[fg=%s,bg=%s]', l:fg, l:bg)
		endif

		" handle formatting parameters
		let l:next = strcharpart(a:opt, 1)
		if l:first ==# '-'
			" Left justify the item
			return tpipeline#parse#left_justify(tpipeline#parse#parse(l:next))
		elseif l:first ==# '0'
			" Leading zeroes in numeric items
			" TODO: Implement this
			return tpipeline#parse#parse(l:next)
		elseif match(l:first, '[0-9]') != -1
			" minwidth
			let l:num = matchstr(a:opt, '^[0-9]*')
			let l:next = strcharpart(a:opt, strchars(l:num))
			return tpipeline#parse#pad(tpipeline#parse#parse(l:next), str2nr(l:num))
		elseif l:first ==# '.'
			" maxwidth
			let l:num = matchstr(l:next, '^[0-9]*')
			let l:next = strcharpart(l:next, strchars(l:num))
			return strcharpart(tpipeline#parse#parse(l:next), 0, str2nr(l:num))
		endif
	endif

	return ''
endfunc

func tpipeline#parse#charmatch(s)
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

func tpipeline#parse#parse_stl(stl)
	let l:res = a:stl

	if strcharpart(l:res, 0, 2) ==# '%!'
		" if we have a command, parse the evaluated command instead
		let l:cmd = strcharpart(l:res, 2)
		return tpipeline#parse#parse_stl(eval(l:cmd))
	endif

	" parse every % according to standard statusline rules
	let l:i = 0
	while l:i < (strchars(l:res) - 1)
		if strcharpart(l:res, l:i, 1) ==# '%'
			let l:next = strcharpart(l:res, l:i + 1, 1)
			if (l:next ==# '#' || l:next ==# '{')
				let l:next = strcharpart(l:res, l:i + 1, tpipeline#parse#charmatch(strcharpart(l:res, l:i + 1)))
			elseif (l:next ==# '-' || match(l:next, '[0-9]') == 0 || l:next ==# '.')
				let l:match = matchstr(strcharpart(l:res, l:i + 1), '^\(-\|\)[0-9]*\(\.[0-9]*\|\).')
				if strchars(l:match) > 1
					let l:next = l:match
				endif
			endif
			let l:ins = tpipeline#parse#parse(l:next)
			let l:res = strcharpart(l:res, 0, l:i) . l:ins . strcharpart(l:res, l:i + 1 + strchars(l:next))
			let l:i += strchars(l:ins) - 1
		endif
		let l:i += 1
	endwhile

	return l:res
endfunc
