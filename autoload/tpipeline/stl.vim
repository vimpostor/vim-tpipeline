if !exists('g:tpipeline_progresslen')
	let g:tpipeline_progresslen = 10
endif
let s:mode_map = {'n': 'NORMAL', 'i': 'INSERT', 'R': 'REPLACE', 'v': 'VISUAL', 'V': 'V-LINE', "\<C-v>": 'V-BLOCK', 'c': 'COMMAND', 's': 'SELECT', 'S': 'S-LINE', "\<C-s>": 'S-BLOCK', 't': 'TERMINAL'}

func tpipeline#stl#mode()
	return tpipeline#stl#colors#modec() . '#' . tpipeline#stl#colors#mode() . '#' . get(s:mode_map, mode()) . tpipeline#stl#colors#modec() . '#'
endfunc

func tpipeline#stl#fn()
	return '%#TpipelineBlueGreyInv#%#TpipelineBlueGrey#%f%#TpipelineBlueGreyInv#'
endfunc

func tpipeline#stl#attr()
	let l:r = ''
	if &readonly
		let l:r = ' %#TpipelinePinkInv#%#TpipelinePink#%R%#TpipelinePinkInv#'
	endif
	if &modified
		let l:r = l:r . ' %#TpipelineAmberInv#%#TpipelineAmber#%M%#TpipelineAmberInv#'
	endif
	return l:r
endfunc

func tpipeline#stl#ft()
	return '%#TpipelineLightBlueInv# %#TpipelineLightBlue#%Y%#TpipelineLightBlueInv#'
endfunc

func tpipeline#stl#progress()
	let l:p = tpipeline#util#percentage() * g:tpipeline_progresslen / 100
	let l:text = line('.')
	let l:text = repeat(' ', g:tpipeline_progresslen - strchars(l:text)) . l:text

	let l:pre = '%#TpipelineGreyInv#%#TpipelineGrey#'
	let l:post = ''
	if l:p < g:tpipeline_progresslen
		let l:post = ' '
	endif
	return l:pre . strcharpart(l:text, 0, l:p) . '%#TpipelineGreyInv#' . strcharpart(l:text, l:p) . l:post
endfunc

func tpipeline#stl#line()
	return tpipeline#stl#mode() . ' ' . tpipeline#stl#fn() . tpipeline#stl#attr() . '%=' . tpipeline#stl#ft() . ' ' . tpipeline#stl#progress()
endfunc
