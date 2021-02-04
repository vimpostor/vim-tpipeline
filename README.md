# vim-tpipeline

![Screenshot](https://user-images.githubusercontent.com/21310755/106371530-bdacd780-6365-11eb-8d98-1df0eb3830f1.png)
# Installation

Using **vim-plug**:

```vim
Plug 'vimpostor/vim-tpipeline'
```

Put this in your `~/.tmux.conf`:

```bash
set -g status-bg default
set -g status-right '#(tail -f #{socket_path}-\#{session_id}-vimbridge)'
set -g status-right-length 120
set -g status-interval 0
```

Restart tmux and now you should see your vim statusline inside tmux.

`vim-tpipeline` is compatible with most statuslines and can be used together with other statusline plugins like *lightline*. If it doesn't work with yours, file a bug report.

# Configuration

By default `vim-tpipeline` will copy your standard vim `statusline`. If your `statusline` is empty, the default *tpipeline statusline* from the screenshot above is used.
If you want to use a different statusline just for tmux, you can set it manually:

```vim
" tpipeline comes bundled with its own custom minimal statusline seen above
let g:tpipeline_statusline = '%!tpipeline#stl#line()'
" You can also use standard statusline syntax, see :help stl
let g:tpipeline_statusline = '%f'
```

By default `vim-tpipeline` flattens the statusline into one continuous chunk. If you would like to keep the left part and right part separate, then set `let g:tpipeline_split = 1` in your `.vimrc` and use the following tmux block instead:

```bash
set -g status-bg default
set -g status-left '#(tail -f #{socket_path}-\#{session_id}-vimbridge)'
set -g status-left-length 120
set -g status-right '#(tail -f #{socket_path}-\#{session_id}-vimbridge-R)'
set -g status-right-length 120
set -g status-interval 0
set -g status-justify centre # optionally put the window list in the middle
```

If you use the default *tpipeline statusline*, then you can set the length of the progress widget using:

```vim
let g:tpipeline_progresslen = 10
```

Some terminals do not fire `FocusLost` signals correctly. If you don't want *tpipeline* to respond to `FocusLost`, then use:

```vim
let g:tpipeline_focuslost = 0
```

# FAQ

## But why?

Usually there is plenty of empty space available in your tmux statusline, hence you make much better use of your space if you put your vim statusline there.
After all you don't want to have your carefully handcrafted vim config end up as a bad Internet Explorer meme, do you?
![meme_shitpost](https://user-images.githubusercontent.com/21310755/106005356-70eea580-60b4-11eb-8aa3-105e213e472c.png)


## Can I use the default *tpipeline statusline* outside of tmux as well?

Yes, use `set stl=%!tpipeline#stl#line()` in your `~/.vimrc`. In fact this plugin uses *Vim*'s autoload mechanism to lazily load features, i.e. if you don't use tmux, you can still use the statusline inside vim without a performance penalty.

## How do i get the config from the screenshot at the top?

```vim
" .vimrc
set stl=%!tpipeline#stl#line()
let g:tpipeline_split = 1
```

```bash
# .tmux.conf
set -g status-bg default
set -g status-left '#(tail -f #{socket_path}-\#{session_id}-vimbridge)'
set -g status-left-length 120
set -g status-right '#(tail -f #{socket_path}-\#{session_id}-vimbridge-R)'
set -g status-right-length 120
set -g status-interval 0
set -g status-justify centre
set -g window-status-current-format "#[fg=colour4]\uE0B6#[fg=colour7,bg=colour4]#{?window_zoomed_flag,#[fg=yellow]🔍,}#W#[fg=colour4,bg=default]\uE0B4"
set -g window-status-format "#[fg=colour244]\uE0B6#[fg=default,bg=colour244]#W#[fg=colour244,bg=default]\uE0B4"
```

## How do I make focus events work inside tmux?

You need `set -g focus-events on` in your `~/.tmux.conf`. Also make sure that your terminal supports [focus events](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-FocusIn_FocusOut). Keep in mind that terminal vim only supports focus events since patch level `8.2.2345`.

## vim-multiple-cursors is slow with this plugin

Unfortunately due to the way that *vim-multiple-cursors* works, it can sometimes cause this plugin to send `n` different updates to tmux on every movement, where `n` is the number of cursors.
Put the following block in your `.vimrc` to freeze this plugin while using multiple cursors:

```vim
function! Multiple_cursors_before()
	call tpipeline#state#freeze()
endfunction
function! Multiple_cursors_after()
	call tpipeline#state#thaw()
endfunction
```
