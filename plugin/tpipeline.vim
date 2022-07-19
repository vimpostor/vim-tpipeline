if exists('g:loaded_tpipeline') || empty($TMUX) || !(has('nvim') ? len(v:lua.vim.api.nvim_list_uis()) : has('job')) || has('gui_running')
	finish
endif
let g:loaded_tpipeline = 1

call tpipeline#initialize()
