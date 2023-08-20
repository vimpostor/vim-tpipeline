func tpipeline#debug#init()
	let s:stderr = []
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
	if filereadable(s:tpipeline_filepath)
		let left = readfile(s:tpipeline_filepath)
	else
		let left = ''
	endif
	if filereadable(s:tpipeline_right_filepath)
		let right = readfile(s:tpipeline_right_filepath)
	else
		let right = ''
	endif
	let tmux = systemlist("tmux -V")[-1]
	let jobstate = tpipeline#job_state()
	let os = tpipeline#debug#os()
	let bad_colors = len(tpipeline#debug#get_bad_hl_groups())
	let result = #{left: left, right: right, tmux: tmux, plugin_version: tpipeline#version#string(), job_state: jobstate, job_errors: s:stderr, os: os, bad_colors: bad_colors}

	if has('nvim')
		let stl = get(g:, 'tpipeline_statusline', '')
		if empty(stl)
			let stl = &stl
		endif
		let native = nvim_eval_statusline(stl, #{highlights: 1, use_tabline: get(g:, 'tpipeline_tabline', 0)})
		let brand = 'neovim'
		let version_info = join(luaeval("vim.inspect(vim.version())")->split('\n'))

		let result.native_str = native.str
		let result.native_highlights = native.highlights
		let result.tpipeline_size = get(g:, 'tpipeline_size', 0)
	else
		let brand = 'vim'
		let version_info = v:versionlong
	endif

	let result.brand = brand
	let result.version_info = version_info

	return result
endfunc

func tpipeline#debug#log_err(line)
	call add(s:stderr, a:line)
endfunc

func tpipeline#debug#is_truecolor(s)
	return empty(a:s) || a:s == 'fg' || a:s== 'bg' || a:s == '#NONE' || a:s =~ '#\x\{6}'
endfunc

func tpipeline#debug#is_truecolor_group(id)
	let syn = synIDtrans(a:id)
	let fg = tolower(synIDattr(syn, 'fg'))
	let bg = tolower(synIDattr(syn, 'bg'))
	return tpipeline#debug#is_truecolor(fg) && tpipeline#debug#is_truecolor(bg)
endfunc

func tpipeline#debug#get_bad_hl_groups()
	if has('nvim')
		let hls = luaeval('vim.tbl_keys(vim.api.nvim_get_hl(0, {}))')->map({_, v -> #{id: hlID(v), name: v}})
	else
		let hls = hlget()
	endif
	return hls->filter({_, v -> !tpipeline#debug#is_truecolor_group(v.id)})->map({_, v -> v.name})
endfunc

call tpipeline#debug#init()
