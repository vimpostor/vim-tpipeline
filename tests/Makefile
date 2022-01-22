all: tests
tests: tests_vim tests_neovim
tests_vim:
	touch /tmp/.vim-tpipeline.test && TMUX='' tmux -L vim-tpipeline -f tmux.conf new-session 'vim -f --not-a-term -u vimrc -S run_test.vim test_general.vim || rm /tmp/.vim-tpipeline.test' && rm /tmp/.vim-tpipeline.test &>/dev/null || ( cat *.failed.log && false )
tests_neovim:
	touch /tmp/.vim-tpipeline.test && TMUX='' tmux -L vim-tpipeline -f tmux.conf new-session 'nvim -f -u vimrc -S run_test.vim test_general.vim || rm /tmp/.vim-tpipeline.test' && rm /tmp/.vim-tpipeline.test &>/dev/null || ( cat *.failed.log && false )
