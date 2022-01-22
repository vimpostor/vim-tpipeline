" This file is adapted from https://github.com/puremourning/a-test-to-attest-to
" It is licensed under the Vim license

let g:test_name = expand("%:p:t")
let g:test_path = expand("%:p:h")
let g:logfile = g:test_path . "/" . g:test_name . ".failed.log"

" Source the file that's open and close it
source %
%bwipe!

" Extract the list of functions matching ^Test_
let s:tests = split(substitute(execute('function /^Test_'), 'function \(\k*()\)', '\1', 'g'))

" Save all errors
let s:errors = []

function! s:EarlyExit()
	call add(v:errors, "Test " . g:test_name . ":" . g:test_function . " caused Vim to quit!")
	call s:EndTest()
	call s:Done()
endfunction

function! s:Start()
	" Truncate
	call writefile([], g:logfile, 's')
endfunction

function! s:EndTest()
	if len(v:errors) > 0
		" Append errors to test failure log
		call writefile(v:errors, g:logfile, 'as')
	endif
	call extend(s:errors, v:errors)
	let v:errors = []
endfunction

function! s:Done()
	if len(s:errors) > 0
		" Quit with an error code
		echom s:errors
		cquit!
	else
		echom "All tests passed!"
		quit!
	endif
endfunction

call s:Start()

if exists("*SetUp")
	call SetUp()
endif

" ... run all of the Test_* functions
for test_function in s:tests
	let g:test_function = test_function
	au VimLeavePre * call s:EarlyExit()
	try
		execute 'call ' test_function
	catch
		call add(v:errors, "Uncaught exception in test " . g:test_name . ":" . test_function . ": " . v:exception . " at " . v:throwpoint)
	finally
		au! VimLeavePre
	endtry

	call s:EndTest()
endfor

if exists("*TearDown")
	call TearDown()
endif

call s:Done()
