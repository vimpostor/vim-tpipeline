let s:mode_map = {'n': 'NORMAL', 'i': 'INSERT', 'R': 'REPLACE', 'v': 'VISUAL'}

func tpipeline#statusline#mode()
	return get(s:mode_map, mode())
endfunc
