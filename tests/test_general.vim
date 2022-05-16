func SetUp()
	let s:tpipeline_filepath = tpipeline#get_filepath()
	let s:tpipeline_right_filepath = s:tpipeline_filepath . '-R'

	" init statusline manually, because VimEnter is not triggered
	call tpipeline#init_statusline()
	" wait a bit for tmux to catch up
	sleep 500m
endfunc

func Read_socket()
	call tpipeline#update()
	" wait a few ms to catch up
	sleep 200m

	let s:left = ''
	let l:written_file = readfile(s:tpipeline_filepath, '', -1)
	if !empty(l:written_file)
		let s:left = l:written_file[0]
	endif

	let s:right = ''
	let l:written_file = readfile(s:tpipeline_right_filepath, '', -1)
	if !empty(l:written_file)
		let s:right = l:written_file[0]
	endif
endfunc

func Test_autoembed()
	call assert_equal('status-left "#(cat #{socket_path}-\\#{session_id}-vimbridge)"', trim(system('tmux show-options -g status-left')))
endfunc

func Test_socket()
	let g:tpipeline_statusline = 'test'
	call Read_socket()
	call assert_match('test', s:left)
endfunc

func Test_colors()
	hi Bold guifg=#000000 guibg=#ffffff gui=bold cterm=bold
	hi Red guifg=#ffffff guibg=#ff0000
	let g:tpipeline_statusline = '%#Bold#BOLD%#Red#RED'
	call Read_socket()
	call assert_equal('#[fg=#000000,bg=#ffffff,bold]BOLD#[fg=#ffffff,bg=#ff0000,nobold]RED', s:left)
endfunc

func Test_focusevents()
	let g:tpipeline_statusline = 'focused'
	call Read_socket()
	call assert_match('focused', s:left)
	" lose focus
	call tpipeline#deferred_cleanup()
	call Read_socket()
	call assert_notmatch('focused', s:left)
	" gain focus
	call tpipeline#forceupdate()
	call Read_socket()
	call assert_match('focused', s:left)
endfunc

func Test_split()
	let g:tpipeline_statusline = 'LEFT%=RIGHT'
	call Read_socket()
	call assert_match('LEFT', s:left)
	call assert_notmatch('RIGHT', s:left)
	call assert_match('RIGHT', s:right)
	call assert_notmatch('LEFT', s:right)
endfunc

" test that if a vim window is much smaller than the console window, that we still use the entire space available
func Test_small_pane()
	let c = &columns / 3
	if c < 5
		" this test does not make much sense for small overall console size
		return
	endif
	let left = repeat('L', c)
	let right = repeat('R', c)
	let g:tpipeline_statusline = left . '%=' . right
	" split window in half
	vsplit
	" Since 2/3 > 1/2, now the width of the pane is smaller than the width of the fully expanded statusline.
	" Make sure we still use the entire tmux statusline regardless, since we are not bound by the vim window size
	" This especially means that the right part is NOT empty.
	call Read_socket()
	call assert_false(empty(s:right))
	call assert_match(left, s:left)
	call assert_match(right, s:right)

	bd!
endfunc

func Test_unicode()
	let left = "🪛🔧🔨⚒"
	let right = "🛠⛏🪚🔩"
	let g:tpipeline_statusline = "%#String#" . left . "%=%#Error#" . right
	call Read_socket()
	call assert_match(left, s:left)
	call assert_match(right, s:right)
endfunc

func Test_performance()
	" make sure we use a somewhat heavy statusline
	let g:tpipeline_statusline = "%!tpipeline#stl#line()"
	let test_duration = "10"
	" one iteration should absolutely stay below 1 frame at 60FPS
	let individual_threshold = 0.016
	let log_file = "/tmp/.vim-tpipeline-perf.log"
	" setup a file with two lines
	norm o

	exec printf("profile start %s", log_file)
	profile func tpipeline#update
	" simulate someone scrolling at 60FPS
	func Scroll()
		if line(".") - 1
			norm k
		else
			norm j
		endif
		call tpipeline#update()
	endfunc
	let timer = timer_start(16, {-> Scroll()}, {'repeat': -1})
	exec "sleep " . test_duration

	profile stop
	call timer_stop(timer)
	let log = readfile(log_file, '', 5)
	call assert_equal('FUNCTION  tpipeline#update()', log[0])

	let call_num = str2nr(log[2]->matchstr('\d\+'))
	call assert_equal(printf("Called %d times", call_num), log[2])

	let total_time = str2float(log[3]->matchstr('\d\.\d\+'))
	call assert_equal(printf("Total time:   %f", total_time), log[3])

	let self_time = str2float(log[4]->matchstr('\d\.\d\+'))
	call assert_equal(printf(" Self time:   %f", self_time), log[4])

	let individual_time = total_time / call_num
	echo printf("Called %d times\nTotal time: %f\n Self time: %f\nIndividual time: %f", call_num, total_time, self_time, individual_time)
	" make sure that we don't exceed the threshold time
	call assert_true(individual_time < individual_threshold)

	bd!
endfunc
