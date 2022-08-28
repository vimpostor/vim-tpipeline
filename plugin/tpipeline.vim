if exists('g:loaded_tpipeline') || (empty($TMUX) && !exists("g:tpipeline_refreshcmd")) || !(has('nvim') ? len(nvim_list_uis()) : has('job')) || has('gui_running')
	finish
endif
let g:loaded_tpipeline = 1

call tpipeline#initialize()
