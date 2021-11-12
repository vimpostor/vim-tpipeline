if !exists('g:tpipeline_hooks_enabled')
	let g:tpipeline_hooks_enabled = 0
endif

func tpipeline#state#freeze()
	if g:tpipeline_hooks_enabled
		au! tpipeline
	endif
endfunc

func tpipeline#state#thaw()
	if g:tpipeline_hooks_enabled
		call tpipeline#build_hooks()
	endif
endfunc
