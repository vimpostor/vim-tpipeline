func tpipeline#debug#init()
	let s:tpipeline_filepath = tpipeline#get_filepath()
	let s:tpipeline_right_filepath = s:tpipeline_filepath . '-R'
endfunc

func tpipeline#debug#os()
	if has('linux')
		return "Linux"
	elseif has('osx') || has('osxdarwin')
		return "MacOS"
	elseif has('win32') || has('win64')
		return "Windows"
	fi
	return "Unknown OS"
endfunc

func tpipeline#debug#info()
	let left = readfile(s:tpipeline_filepath)
	let right = readfile(s:tpipeline_right_filepath)
	let tmux = systemlist("tmux -V")[-1]
	let jobstate = tpipeline#job_state()
	let os = tpipeline#debug#os()
	let result = #{left: left, right: right, tmux: tmux, plugin_version: tpipeline#version#string(), job_state: jobstate, os: os}

	if has('nvim')
		let stl = g:tpipeline_statusline
		if empty(stl)
			let stl = &stl
		endif
		let native = nvim_eval_statusline(stl, #{highlights: 1, use_tabline: g:tpipeline_tabline})
		let brand = 'neovim'
		let version_info = join(luaeval("vim.inspect(vim.version())")->split('\n'))

		let result.native_str = native.str
		let result.native_highlights = native.highlights
		let result.tpipeline_size = g:tpipeline_size
	else
		let brand = 'vim'
		let version_info = v:versionlong
	endif

	let result.brand = brand
	let result.version_info = version_info

	return result
endfunc

call tpipeline#debug#init()
