let s:mode_map = {'n': 'NORMAL', 'i': 'INSERT', 'R': 'REPLACE', 'v': 'VISUAL'}

func tpipeline#stl#mode()
	return get(s:mode_map, mode())
endfunc
