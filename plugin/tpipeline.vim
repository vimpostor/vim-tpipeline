if exists('g:loaded_tpipeline') || empty($TMUX) || !(has('nvim') || has('job')) || has('gui_running')
	finish
endif
let g:loaded_tpipeline = 1

call tpipeline#initialize()
