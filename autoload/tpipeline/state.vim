let s:frozen = 0
let s:active = 1
if !exists('g:tpipeline_hooks_enabled')
	let g:tpipeline_hooks_enabled = 0
endif

func tpipeline#state#freeze()
	let s:frozen = 1

	if g:tpipeline_hooks_enabled
		au! tpipeline
	endif
endfunc

func tpipeline#state#thaw()
	let s:frozen = 0

	if g:tpipeline_hooks_enabled
		call tpipeline#build_hooks()
	endif
endfunc

func tpipeline#state#toggle_frozen()
	if s:frozen
		call tpipeline#state#thaw()
	else
		call tpipeline#state#freeze()
	endif
endfunc

func tpipeline#state#restore()
	let s:active = 0

	call tpipeline#cleanup()
	call tpipeline#state#freeze()
	if g:tpipeline_tabline
		set showtabline=1
	else
		set laststatus=2
	endif
endfunc

func tpipeline#state#reload()
	let s:active = 1

	call tpipeline#initialize()
endfunc

func tpipeline#state#toggle()
	if s:active
		call tpipeline#state#restore()
	else
		call tpipeline#state#reload()
	endif
endfunc
