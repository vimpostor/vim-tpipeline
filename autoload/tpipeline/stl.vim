if !exists('g:progress_length')
	let g:progress_length = 10
endif
let s:mode_map = {'n': 'NORMAL', 'i': 'INSERT', 'R': 'REPLACE', 'v': 'VISUAL', 'V': 'V-LINE', "\<C-v>": 'V-BLOCK', 'c': 'COMMAND', 's': 'SELECT', 'S': 'S-LINE', "\<C-s>": 'S-BLOCK', 't': 'TERMINAL'}

func tpipeline#stl#mode()
	return get(s:mode_map, mode())
endfunc

func tpipeline#stl#progress()
	let l:p = tpipeline#util#percentage() * g:progress_length / 100
	let l:text = line('.') . ':' . col('.')
	let l:text = l:text . repeat(' ', g:progress_length - strchars(l:text))
	return '%#TpipelineGreyInv#%#TpipelineGrey#' . strcharpart(l:text, 0, l:p) . '%#TpipelineGreyInv#' . strcharpart(l:text, l:p) . ''
endfunc

func tpipeline#stl#line()
	let l:mode = tpipeline#stl#colors#modec() . '#' . tpipeline#stl#colors#mode() . '#' . tpipeline#stl#mode() . tpipeline#stl#colors#modec() . '#'
	return l:mode . ' %#TpipelineBrownInv#%#TpipelineBrown#%f%#TpipelineBrownInv#%=%#TpipelineCyanInv#%#TpipelineCyan#%Y%#TpipelineCyanInv# ' . tpipeline#stl#progress()
endfunc
