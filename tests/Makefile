all: tests_vim tests_neovim
tests_vim:
	touch /tmp/.vim-tpipeline.test && TMUX='' tmux new-session 'vim -f --not-a-term -u vimrc -S run_test.vim test_general.vim > /tmp/.vim-tpipeline.log || rm /tmp/.vim-tpipeline.test' && rm /tmp/.vim-tpipeline.test || ( cat /tmp/.vim-tpipeline.log && false )
tests_neovim:
	touch /tmp/.vim-tpipeline.test && TMUX='' tmux new-session 'nvim -f -u vimrc -S run_test.vim test_general.vim > /tmp/.vim-tpipeline.log || rm /tmp/.vim-tpipeline.test' && rm /tmp/.vim-tpipeline.test || ( cat /tmp/.vim-tpipeline.log && false )
