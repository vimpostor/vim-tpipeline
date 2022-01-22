func SetUp()
	let l:tmux = $TMUX
	let s:tpipeline_filepath = strcharpart(tmux, 0, stridx(tmux, ",")) . '-$' . strcharpart(tmux, strridx(tmux, ",") + 1) . '-vimbridge'
	let s:tpipeline_right_filepath = s:tpipeline_filepath . '-R'

	" init statusline manually, because VimEnter is not triggered
	call tpipeline#init_statusline()
endfunc

func Read_socket()
	call tpipeline#update()
	" wait a few ms to catch up
	sleep 200m

	let l:written_file = readfile(s:tpipeline_filepath, '', -1)
	let l:written_line = ''
	if !empty(l:written_file)
		let l:written_line = l:written_file[0]
	endif
	let s:socket = l:written_line
endfunc

func Test_socket()
	let g:tpipeline_statusline = 'test'
	call Read_socket()
	call assert_match('test', s:socket)
endfunc

func Test_colors()
	hi Bold guifg=#000000 guibg=#ffffff gui=bold cterm=bold
	hi Red guifg=#ffffff guibg=#ff0000
	let g:tpipeline_statusline = '%#Bold#BOLD%#Red#RED'
	call Read_socket()
	call assert_equal('#[fg=#000000,bg=#ffffff,bold]BOLD#[fg=#ffffff,bg=#ff0000,nobold]RED', s:socket)
endfunc

func Test_focusevents()
	let g:tpipeline_statusline = 'focused'
	call Read_socket()
	call assert_match('focused', s:socket)
	" lose focus
	call tpipeline#deferred_cleanup()
	call Read_socket()
	call assert_notmatch('focused', s:socket)
	" gain focus
	call tpipeline#forceupdate()
	call Read_socket()
	call assert_match('focused', s:socket)
endfunc
