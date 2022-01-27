let s:b = 0
let s:i = 0

func tpipeline#parse#remove_align(str)
	return substitute(a:str, '%=', '', 'g')
endfunc

func tpipeline#parse#parse(opt)
	let first = strcharpart(a:opt, 0, 1)
	let len = strchars(a:opt)

	if len == 1
		" handle singlechar arguments
		if first ==# 'f'
			return expand('%')
		elseif first ==# 'F'
			return expand('%:p')
		elseif first ==# 't'
			return expand('%:t')
		elseif first ==# 'm'
			return &modified ? '[+]' : (&modifiable ? '' : '-')
		elseif first ==# 'M'
			return &modified ? '+' : (&modifiable ? '' : '-')
		elseif first ==# 'r'
			return &readonly ? '[RO]' : ''
		elseif first ==# 'R'
			return &readonly ? 'RO' : ''
		elseif first ==# 'y'
			return '[' . &filetype . ']'
		elseif first ==# 'Y'
			return &filetype
		elseif first ==# 'l'
			return line('.')
		elseif first ==# 'L'
			return line('$')
		elseif first ==# 'c'
			return col('.')
		elseif first ==# 'v'
			return virtcol('.')
		elseif first ==# 'p'
			return tpipeline#util#percentage()
		elseif first ==# 'P'
			return tpipeline#util#percentage() . '%'
		elseif first ==# '='
			return '%='
		elseif first ==# '%'
			return '%'
		endif
	else
		" handle multichar arguments
		let inner = strcharpart(a:opt, 1, len - 2)
		if first ==# '{'
			return tpipeline#parse#parse_stl(eval(inner))
		elseif first ==# '#'
			let id = synIDtrans(hlID(inner))

			let fg = synIDattr(id, 'fg')
			if fg ==# 'fg'
				let fg = 'default'
			endif
			let bg = synIDattr(id, 'bg')
			if bg ==# 'bg'
				let bg = 'default'
			elseif bg ==# '' || bg ==# 'NONE'
				let bg = 'terminal'
			endif
			let st = ''
			if synIDattr(id, 'bold')
				let st = ',bold'
				let s:b = 1
			elseif s:b
				let st = ',nobold'
				let s:b = 0
			endif
			if synIDattr(id, 'italic')
				let st .= ',italics'
				let s:i = 1
			elseif s:i
				let st .= ',noitalics'
				let s:i = 0
			endif
			return printf('#[fg=%s,bg=%s%s]', fg, bg, st)
		endif

		" handle formatting parameters
		let next = strcharpart(a:opt, 1)
		if first ==# '-'
			" Left justify the item
			return tpipeline#util#left_justify(tpipeline#parse#parse(next))
		elseif first ==# '0'
			" Leading zeroes in numeric items
			" TODO: Implement this
			return tpipeline#parse#parse(next)
		elseif match(first, '[0-9]') != -1
			" minwidth
			let num = matchstr(a:opt, '^[0-9]*')
			let next = strcharpart(a:opt, strchars(num))
			return tpipeline#util#pad(tpipeline#parse#parse(next), str2nr(num))
		elseif first ==# '.'
			" maxwidth
			let num = matchstr(next, '^[0-9]*')
			let next = strcharpart(next, strchars(num))
			return strcharpart(tpipeline#parse#parse(next), 0, str2nr(num))
		endif
	endif

	return ''
endfunc

func tpipeline#parse#charmatch(s)
	let c = strcharpart(a:s, 0, 1)
	if c ==# '{'
		let c = '}'
	endif
	let i = 1
	let len = strchars(a:s)
	while i < len
		if strcharpart(a:s, i, 1) ==# c
			return i + 1
		endif
		let i += 1
	endwhile
	" whoops, looks like we didn't find a matching character
	return 1
endfunc

func tpipeline#parse#parse_stl(stl)
	let res = a:stl

	if strcharpart(res, 0, 2) ==# '%!'
		" if we have a command, parse the evaluated command instead
		return tpipeline#parse#parse_stl(eval(strcharpart(res, 2)))
	endif

	" parse every % according to standard statusline rules
	let i = 0
	while i < (strchars(res) - 1)
		if strcharpart(res, i, 1) ==# '%'
			let next = strcharpart(res, i + 1, 1)
			if (next ==# '#' || next ==# '{')
				let next = strcharpart(res, i + 1, tpipeline#parse#charmatch(strcharpart(res, i + 1)))
			elseif (next ==# '-' || match(next, '[0-9]') == 0 || next ==# '.')
				let match = matchstr(strcharpart(res, i + 1), '^\(-\|\)[0-9]*\(\.[0-9]*\|\).')
				if strchars(match) > 1
					let next = match
				endif
			endif
			let ins = tpipeline#parse#parse(next)
			let res = strcharpart(res, 0, i) . ins . strcharpart(res, i + 1 + strchars(next))
			let i += strchars(ins) - 1
		endif
		let i += 1
	endwhile
	return res
endfunc

func tpipeline#parse#eval_stl()
	let evl = nvim_eval_statusline(g:tpipeline_statusline, #{fillchar: g:tpipeline_fillchar, highlights: 1, use_tabline: g:tpipeline_tabline})
	let res = evl.str
	let i = 0
	for hl in evl.highlights
		let grp = tpipeline#parse#parse('#'.hl.group.'#')
		let res = strpart(res, 0, hl.start+i) . grp . strpart(res, hl.start+i)
		let i += len(grp)
	endfor
	return substitute(res, g:tpipeline_fillchar.'\+', '%=', '')
endfunc
