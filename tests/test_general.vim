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

func Scroll()
	if line(".") - 1
		norm k
	else
		norm G
	endif
	call tpipeline#update()
endfunc

func Test_loaded()
	call assert_equal(1, g:loaded_tpipeline)
endfunc

func Test_can_debug()
	let info = tpipeline#debug#info()
	call assert_true(len(info))
endfunc

func Test_job_runs()
	let job = tpipeline#debug#info()
	" background job is still running
	call assert_match("^run", job.job_state)
	" no errors
	call assert_true(job.job_errors->empty(), job.job_errors)
endfunc

func Strip_hl(s)
	return substitute(a:s, '#\[[^\]]*\]', '', 'g')
endfunc

func Test_autoembed()
	call assert_equal('status-left "#(cat #{socket_path}-\\#{session_id}-vimbridge)"', trim(system('tmux show-options status-left')))
endfunc

func Test_socket()
	let g:tpipeline_statusline = 'test'
	call Read_socket()
	call assert_equal('test', Strip_hl(s:left))
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
	call assert_equal('focused', Strip_hl(s:left))
	" lose focus
	call tpipeline#deferred_cleanup()
	call Read_socket()
	call assert_notequal('focused', Strip_hl(s:left))
	" gain focus
	call tpipeline#forceupdate()
	call Read_socket()
	call assert_equal('focused', Strip_hl(s:left))
endfunc

func Test_rapidfocus()
	let g:tpipeline_statusline = 'focused'
	" rapidly lose focus and gain focus in quick succession
	call tpipeline#deferred_cleanup()
	call tpipeline#forceupdate()
	call Read_socket()
	call assert_equal('focused', Strip_hl(s:left))
endfunc

func Test_split()
	let g:tpipeline_statusline = 'LEFT%=RIGHT'
	call Read_socket()
	call assert_equal('LEFT', Strip_hl(s:left))
	call assert_notequal('RIGHT', Strip_hl(s:left))
	call assert_equal('RIGHT', Strip_hl(s:right))
	call assert_notequal('LEFT', Strip_hl(s:right))
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
	call assert_equal(left, Strip_hl(s:left))
	call assert_equal(right, Strip_hl(s:right))

	bd!
endfunc

func Test_unicode()
	let left = "🪛🔧🔨⚒"
	let right = "🛠⛏🪚🔩"
	let g:tpipeline_statusline = "%#String#" . left . "%=%#Error#" . right
	call Read_socket()
	call assert_equal(left, Strip_hl(s:left))
	call assert_equal(right, Strip_hl(s:right))
endfunc

func Test_performance()
	" make sure we use a somewhat heavy statusline
	let g:tpipeline_statusline = "%!tpipeline#stl#line()"
	let test_duration = "3"
	" one iteration should absolutely stay below 1 frame at 120FPS
	let fps = 120
	let individual_threshold = 1.0 / fps
	let log_file = "/tmp/.vim-tpipeline-perf.log"
	" setup a file with enough lines to scroll
	norm 99o

	exec printf("profile start %s", log_file)
	profile func tpipeline#update
	" simulate someone scrolling at 120FPS
	let timer = timer_start(float2nr(individual_threshold * 1000), {-> Scroll()}, {'repeat': -1})
	exec "sleep " . test_duration

	profile stop
	call timer_stop(timer)
	" wait for tmux to catch up
	sleep 200m

	let log = readfile(log_file, '', 5)
	call assert_equal('FUNCTION  tpipeline#update()', log[0])

	let call_num = str2nr(log[2]->matchstr('\d\+'))
	call assert_equal(printf("Called %d times", call_num), log[2])

	let total_time = str2float(log[3]->matchstr('\d\.\d\+'))
	call assert_match("Total time:", log[3])

	let self_time = str2float(log[4]->matchstr('\d\.\d\+'))
	call assert_match("Self time:", log[4])

	let individual_time = total_time / call_num
	echo printf("Called %d times\nTotal time: %f\n Self time: %f\nIndividual time: %f", call_num, total_time, self_time, individual_time)
	" make sure that we don't exceed the threshold time
	call assert_true(individual_time < individual_threshold)

	bd!
endfunc

func Test_case_insensitive()
	" color codes may be uppercase, but tmux only understands lowercase so we have to translate them
	hi Uppercase guifg=#FFFFFF guibg=#AAAAAA
	let g:tpipeline_statusline = '%#Uppercase#test'
	call Read_socket()
	call assert_equal('#[fg=#ffffff,bg=#aaaaaa]test', s:left)
endfunc

func Test_late_evaluation()
	" stl may change dynamically, even without function indirections
	let g:tpipeline_statusline = ""
	for i in range(10)
		exec 'set stl=%=' . string(i)
		call Read_socket()
		call assert_equal(string(i), s:right)
	endfor
endfunc

func g:ReturnNumber()
	return 2
endfunc

func Test_number_evaluation()
	let g:tpipeline_statusline = "%{g:ReturnNumber()}"
	call Read_socket()
	call assert_equal(string(g:ReturnNumber()), Strip_hl(s:left))
endfunc

func Test_quoted_strings()
	let g:tpipeline_statusline = '%{eval("g:ReturnNumber()")}'
	call Read_socket()
	call assert_equal(string(g:ReturnNumber()), Strip_hl(s:left))
endfunc

func Test_minwid_padded()
	" padding stl groups with minwid should not confuse the statusline splitter to cause right alignment where there is none
	let g:tpipeline_statusline = '%2(a%)%='
	call Read_socket()
	call assert_match("a$", s:left)
	call assert_true(empty(s:right))
endfunc

func Test_lag_behind()
	" statusline should not lag behind even after rapid fire updates
	let g:tpipeline_statusline = "%!tpipeline#stl#line()"
	let test_duration = "3"
	norm 99o
	" update literally every single ms
	let timer = timer_start(1, {-> Scroll()}, {'repeat': -1})
	exec "sleep " . test_duration
	call timer_stop(timer)

	" now set a new statusline, the new value should appear immediately without any lag
	let g:tpipeline_statusline = "RAPIDFIRE"
	call Read_socket()
	call assert_equal('RAPIDFIRE', Strip_hl(s:left))

	bd!
endfunc
