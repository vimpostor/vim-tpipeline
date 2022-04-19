func tpipeline#stl#colors#init()
	hi TpipelineRed guifg=#000000 guibg=#f44336
	hi TpipelinePink guifg=#000000 guibg=#e91e63
	hi TpipelinePurple guifg=#ffffff guibg=#9c27b0
	hi TpipelineDeepPurple guifg=#ffffff guibg=#673ab7
	hi TpipelineIndigo guifg=#ffffff guibg=#3f51b5
	hi TpipelineBlue guifg=#000000 guibg=#2196f3
	hi TpipelineLightBlue guifg=#000000 guibg=#03a9f4
	hi TpipelineCyan guifg=#000000 guibg=#00bcd4
	hi TpipelineTeal guifg=#000000 guibg=#009688
	hi TpipelineGreen guifg=#000000 guibg=#4caf50
	hi TpipelineLightGreen guifg=#000000 guibg=#8bc34a
	hi TpipelineLime guifg=#000000 guibg=#cddc39
	hi TpipelineYellow guifg=#000000 guibg=#ffeb3b
	hi TpipelineAmber guifg=#000000 guibg=#ffc107
	hi TpipelineOrange guifg=#000000 guibg=#ff9800
	hi TpipelineDeepOrange guifg=#000000 guibg=#ff5722
	hi TpipelineBrown guifg=#ffffff guibg=#795548
	hi TpipelineGrey guifg=#ffffff guibg=#9e9e9e
	hi TpipelineBlueGrey guifg=#ffffff guibg=#607d8b

	hi TpipelineRedInv guifg=#f44336 guibg=bg
	hi TpipelinePinkInv guifg=#e91e63 guibg=bg
	hi TpipelinePurpleInv guifg=#9c27b0 guibg=bg
	hi TpipelineDeepPurpleInv guifg=#673ab7 guibg=bg
	hi TpipelineIndigoInv guifg=#3f51b5 guibg=bg
	hi TpipelineBlueInv guifg=#2196f3 guibg=bg
	hi TpipelineLightBlueInv guifg=#03a9f4 guibg=bg
	hi TpipelineCyanInv guifg=#00bcd4 guibg=bg
	hi TpipelineTealInv guifg=#009688 guibg=bg
	hi TpipelineGreenInv guifg=#4caf50 guibg=bg
	hi TpipelineLightGreenInv guifg=#8bc34a guibg=bg
	hi TpipelineLimeInv guifg=#cddc39 guibg=bg
	hi TpipelineYellowInv guifg=#ffeb3b guibg=bg
	hi TpipelineAmberInv guifg=#ffc107 guibg=bg
	hi TpipelineOrangeInv guifg=#ff9800 guibg=bg
	hi TpipelineDeepOrangeInv guifg=#ff5722 guibg=bg
	hi TpipelineBrownInv guifg=#795548 guibg=bg
	hi TpipelineGreyInv guifg=#9e9e9e guibg=bg
	hi TpipelineBlueGreyInv guifg=#607d8b guibg=bg
endfunc

func tpipeline#stl#colors#mode()
	return '%#Tpipeline' . get(s:mode_colormap, mode(), 'Red')
endfunc

func tpipeline#stl#colors#modec()
	return tpipeline#stl#colors#mode() . 'Inv'
endfunc


let s:mode_colormap = {'n': 'LightGreen', 'i': 'Cyan', 'R': 'Red', 'v': 'Orange', 'V': 'Yellow', "\<C-v>": 'DeepOrange', 'c': 'Brown', 's': 'Lime', 'S': 'DeepPurple', "\<C-s>": 'Cyan', 't': 'Teal'}

call tpipeline#stl#colors#init()
" reapply colors if colorscheme is changed
au ColorScheme * call tpipeline#stl#colors#init()
