let s:mode_map = {'n': 'NORMAL', 'i': 'INSERT', 'R': 'REPLACE', 'v': 'VISUAL', 'V': 'V-LINE', "\<C-v>": 'V-BLOCK', 'c': 'COMMAND', 's': 'SELECT', 'S': 'S-LINE', "\<C-s>": 'S-BLOCK', 't': 'TERMINAL'}

func tpipeline#stl#mode()
	return get(s:mode_map, mode())
endfunc

func tpipeline#stl#line()
	let l:mode = tpipeline#stl#colors#modec() . '#' . tpipeline#stl#colors#mode() . '#' . tpipeline#stl#mode() . tpipeline#stl#colors#modec() . '#'
	return l:mode . ' %#TpipelineBrownInv#%#TpipelineBrown#%f%#TpipelineBrownInv#'
endfunc
