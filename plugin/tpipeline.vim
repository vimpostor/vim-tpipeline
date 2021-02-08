if exists('g:loaded_tpipeline') || empty($TMUX) || !(has('lua') || has('nvim'))
	finish
endif
let g:loaded_tpipeline = 1

call tpipeline#initialize()
