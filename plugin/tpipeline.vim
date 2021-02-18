if exists('g:loaded_tpipeline') || empty($TMUX) || !(has('nvim') || has('job'))
	finish
endif
let g:loaded_tpipeline = 1

call tpipeline#initialize()
