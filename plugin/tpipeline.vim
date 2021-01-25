if exists('g:loaded_tpipeline') || empty($TMUX)
	finish
endif
let g:loaded_tpipeline = 1

call tpipeline#initialize()
