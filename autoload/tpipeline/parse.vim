vim9script

var was_bold = 0
var was_italic = 0

def Parse(opt: string): string
	var first = strcharpart(opt, 0, 1)
	var len = strchars(opt)

	if len == 1
		# handle singlechar arguments
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
			return '[' .. &filetype .. ']'
		elseif first ==# 'Y'
			return &filetype
		elseif first ==# 'l'
			return string(line('.'))
		elseif first ==# 'L'
			return string(line('$'))
		elseif first ==# 'c'
			return string(col('.'))
		elseif first ==# 'v'
			return string(virtcol('.'))
		elseif first ==# 'p'
			return tpipeline#util#percentage()
		elseif first ==# 'P'
			return tpipeline#util#percentage() .. '%'
		elseif first ==# '='
			return '%='
		elseif first ==# '%'
			return '%'
		endif
	else
		# handle multichar arguments
		var inner = strcharpart(opt, 1, len - 2)
		if first ==# '{'
			exe printf('legacy let g:tpipeline_leg = eval("%s")', inner)
			return Parse_stl("" .. g:tpipeline_leg)
		elseif first ==# '#'
			var id = synIDtrans(hlID(inner))

			var fg = tolower(synIDattr(id, 'fg'))
			if fg ==# 'fg'
				fg = 'default'
			endif
			var bg = tolower(synIDattr(id, 'bg'))
			if bg ==# 'bg'
				bg = 'default'
			elseif bg ==# '' || bg ==# '#NONE'
				bg = 'terminal'
			endif
			var st = ''
			if !empty(synIDattr(id, 'bold'))
				st = ',bold'
				was_bold = 1
			elseif was_bold
				st = ',nobold'
				was_bold = 0
			endif
			if !empty(synIDattr(id, 'italic'))
				st ..= ',italics'
				was_italic = 1
			elseif was_italic
				st ..= ',noitalics'
				was_italic = 0
			endif
			return printf('#[fg=%s,bg=%s%s]', fg, bg, st)
		endif

		# handle formatting parameters
		var next = strcharpart(opt, 1)
		if first ==# '-'
			# Left justify the item
			return tpipeline#util#left_justify(Parse(next))
		elseif first ==# '0'
			# Leading zeroes in numeric items
			# TODO: Implement this
			return Parse(next)
		elseif match(first, '[0-9]') != -1
			# minwidth
			var num = matchstr(opt, '^[0-9]*')
			next = strcharpart(opt, strchars(num))
			return tpipeline#util#pad(Parse(next), str2nr(num))
		elseif first ==# '.'
			# maxwidth
			var num = matchstr(next, '^[0-9]*')
			next = strcharpart(next, strchars(num))
			return strcharpart(Parse(next), 0, str2nr(num))
		endif
	endif

	return ''
enddef

def Charmatch(s: string): number
	var c = strcharpart(s, 0, 1)
	if c ==# '{'
		c = '}'
	endif
	var i = 1
	var len = strchars(s)
	while i < len
		if strcharpart(s, i, 1) ==# c
			return i + 1
		endif
		i += 1
	endwhile
	# whoops, looks like we didn't find a matching character
	return 1
enddef

export def Parse_stl(stl: string): string
	var res = stl

	if strcharpart(res, 0, 2) ==# '%!'
		# if we have a command, parse the evaluated command instead
		return Parse_stl(eval(strcharpart(res, 2)))
	endif

	# parse every % according to standard statusline rules
	var i = 0
	while i < (strchars(res) - 1)
		if strcharpart(res, i, 1) ==# '%'
			var next = strcharpart(res, i + 1, 1)
			if (next ==# '#' || next ==# '{')
				next = strcharpart(res, i + 1, Charmatch(strcharpart(res, i + 1)))
			elseif (next ==# '-' || match(next, '[0-9]') == 0 || next ==# '.')
				var match = matchstr(strcharpart(res, i + 1), '^\(-\|\)[0-9]*\(\.[0-9]*\|\).')
				if strchars(match) > 1
					next = match
				endif
			endif
			var ins = Parse(next)
			res = strcharpart(res, 0, i) .. ins .. strcharpart(res, i + 1 + strchars(next))
			i += strchars(ins) - 1
		endif
		i += 1
	endwhile
	return res
enddef
