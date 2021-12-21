if !exists('g:tpipeline_progresslen')
	let g:tpipeline_progresslen = 10
endif
let s:mode_map = {'n': 'NORMAL', 'i': 'INSERT', 'R': 'REPLACE', 'v': 'VISUAL', 'V': 'V-LINE', "\<C-v>": 'V-BLOCK', 'c': 'COMMAND', 's': 'SELECT', 'S': 'S-LINE', "\<C-s>": 'S-BLOCK', 't': 'TERMINAL'}

func tpipeline#stl#mode()
	return tpipeline#stl#colors#mode() . '# ' . tpipeline#stl#colors#mode() . '#' . get(s:mode_map, mode()) . tpipeline#stl#colors#modec() . '#'
endfunc

func tpipeline#stl#fn()
	return '%#TpipelineBlueGreyInv#%#TpipelineBlueGrey#%f%#TpipelineBlueGreyInv#'
endfunc

func tpipeline#stl#attr()
	let r = ''
	if &readonly
		let r = ' %#TpipelinePinkInv#%#TpipelinePink#%R%#TpipelinePinkInv#'
	endif
	if &modified
		let r = r . ' %#TpipelineAmberInv#%#TpipelineAmber#%M%#TpipelineAmberInv#'
	endif
	return r
endfunc

func tpipeline#stl#ft()
	return '%#TpipelineLightBlueInv# %#TpipelineLightBlue#%Y%#TpipelineLightBlueInv#'
endfunc

func tpipeline#stl#progress()
	let p = tpipeline#util#percentage() * g:tpipeline_progresslen / 100
	let text = line('.')
	let text = repeat(' ', g:tpipeline_progresslen - strchars(text) - 1) . text . ' '

	let pre = '%#TpipelineGreyInv#%#TpipelineGrey#'
	return pre . strcharpart(text, 0, p) . '%#TpipelineGreyInv#' . strcharpart(text, p)
endfunc

func tpipeline#stl#line()
	return tpipeline#stl#mode() . ' ' . tpipeline#stl#fn() . tpipeline#stl#attr() . '%=' . tpipeline#stl#ft() . ' ' . tpipeline#stl#progress()
endfunc

func tpipeline#stl#tabline()
	let s = ''
	for i in range(tabpagenr('$'))
		if i + 1 == tabpagenr()
			let s .= '%#TpipelineOrangeInv#%#TpipelineOrange#'
		else
			let s .= '%#TpipelineBlueGreyInv#%#TpipelineBlueGrey#'
		endif
		let s .= bufname(tabpagebuflist(i + 1)[tabpagewinnr(i + 1) - 1])
		if i + 1 == tabpagenr()
			let s .= '%#TpipelineOrangeInv# '
		else
			let s .= '%#TpipelineBlueGreyInv# '
		endif
	endfor
	return s
endfunc
