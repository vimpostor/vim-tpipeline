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

func tpipeline#state#restore()
	call tpipeline#cleanup()
	call tpipeline#state#freeze()
	if g:tpipeline_tabline
		set showtabline=1
	else
		set laststatus=2
	endif
endfunc

func tpipeline#state#reload()
	call tpipeline#initialize()
endfunc
