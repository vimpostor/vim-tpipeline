func tpipeline#debug#init()
	let s:tpipeline_filepath = tpipeline#get_filepath()
	let s:tpipeline_right_filepath = s:tpipeline_filepath . '-R'
endfunc

func tpipeline#debug#info()
	let left = readfile(s:tpipeline_filepath)
	let right = readfile(s:tpipeline_right_filepath)
	let result = #{left: left, right: right}

	if has('nvim')
		let stl = g:tpipeline_statusline
		if empty(stl)
			let stl = &stl
		endif
		let native = nvim_eval_statusline(stl, #{highlights: 1, use_tabline: g:tpipeline_tabline})
		let result.native_str = native.str
		let result.native_highlights = native.highlights
	endif

	return result
endfunc

call tpipeline#debug#init()
