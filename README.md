# vim-tpipeline

Embed your vim statusline in the tmux statusline!

![Screenshot](https://user-images.githubusercontent.com/21310755/106371530-bdacd780-6365-11eb-8d98-1df0eb3830f1.png)
# Installation

Using **vim-plug**:

```vim
Plug 'vimpostor/vim-tpipeline'
```

Put this in your `~/.tmux.conf`:

```bash
set -g focus-events on
set -g status-style bg=default
set -g status-left '#(cat #{socket_path}-\#{session_id}-vimbridge)'
set -g status-left-length 80
set -g status-right '#(cat #{socket_path}-\#{session_id}-vimbridge-R)'
set -g status-right-length 80
set -g status-justify centre # optionally put the window list in the middle
```

Restart tmux and now you should see your vim statusline inside tmux.

`vim-tpipeline` is compatible with most statuslines and can be used together with other statusline plugins like *lightline*. If it doesn't work with yours, file a bug report.

## Requirements

- Vim 8 (with patch `8.2.2345` for best experience) OR Neovim
- True color support (`set termguicolors` in vim)
- For best experience use a terminal that supports [focus events](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-FocusIn_FocusOut) (Known good terminals are `Konsole`, `Gnome Terminal` and `iTerm2`)

# Configuration

By default `vim-tpipeline` will copy your standard vim `statusline`. If your `statusline` is empty, the default *tpipeline statusline* from the screenshot above is used.
If you want to use a different statusline just for tmux, you can set it manually:

```vim
" tpipeline comes bundled with its own custom minimal statusline seen above
let g:tpipeline_statusline = '%!tpipeline#stl#line()'
" You can also use standard statusline syntax, see :help stl
let g:tpipeline_statusline = '%f'
```

You can use `let g:tpipeline_split = 0` to merge the left and right part of your statusline into one single chunk which you can then use with the following tmux block instead:

```bash
set -g focus-events on
set -g status-style bg=default
set -g status-right '#(cat #{socket_path}-\#{session_id}-vimbridge)'
set -g status-right-length 80
```

# FAQ

## But why?

Usually there is plenty of empty space available in your tmux statusline, hence you make much better use of your space if you put your vim statusline there.
After all you don't want to have your carefully handcrafted vim config end up as a bad Internet Explorer meme, do you?
![meme_shitpost](https://user-images.githubusercontent.com/21310755/108243701-a71cc380-714e-11eb-9274-bc1cdb3590af.png)


## Can I use the default *tpipeline statusline* outside of tmux as well?

Yes, use `set stl=%!tpipeline#stl#line()` in your `~/.vimrc`. In fact this plugin uses *Vim*'s autoload mechanism to lazily load features, i.e. if you don't use tmux, you can still use the statusline inside vim without loading unnecessary features.

## How do I get the config from the screenshot at the top?

```vim
" .vimrc
set stl=%!tpipeline#stl#line()
```

```bash
# .tmux.conf
set -g focus-events on
set -g status-style bg=default
set -g status-left '#(cat #{socket_path}-\#{session_id}-vimbridge)'
set -g status-left-length 80
set -g status-right '#(cat #{socket_path}-\#{session_id}-vimbridge-R)'
set -g status-right-length 80
set -g status-justify centre
set -g window-status-current-format "#[fg=colour4]\uE0B6#[fg=colour7,bg=colour4]#{?window_zoomed_flag,#[fg=yellow]🔍,}#W#[fg=colour4,bg=default]\uE0B4"
set -g window-status-format "#[fg=colour244]\uE0B6#[fg=default,bg=colour244]#W#[fg=colour244,bg=default]\uE0B4"
```

## How do I update the statusline on every cursor movement?

```vim
let g:tpipeline_cursormoved = 1
```
**Warning**: When using `neovim`, this can cause performance problems with some configurations. If you experience this problem, you can fix it by using `set guicursor=` which disables `neovim`'s `DECSCUSR` feature that can sometimes cause laggy scrolling when used inside `tmux`.
In all other cases this `autocmd` can be used without problems. `tpipeline` is heavily optimized to allow for this usage and finishes within a few milliseconds to allow for smooth scrolling.

## Focus events are not working for me in tmux

Besides putting `set -g focus-events on` in your `tmux` config, you also need to have the `XT`-capability available, which you can test by issuing the `tput XT` command. If the capability is not present inside tmux, then there are three ways to fix the [issue](https://github.com/tmux/tmux/issues/2606):

- Put `set -g default-terminal "xterm-256color"` in your `tmux` config. Note that this option is discouraged by tmux and can cause other issues.
- Force vim to enable it by using this in your `.vimrc`
```vim
let &t_fe = "\<Esc>[?1004h"
let &t_fd = "\<Esc>[?1004l"
```
- Write your own custom terminfo entry based on *tmux-256color*

## How do I stop the centered window list from flickering when changing panes?

Since `tmux` version **3.2** you can use `absolute-centre` instead of `centre`:
```diff
-set -g status-justify centre
+set -g status-justify absolute-centre
```

## Why should I use this plugin over [onestatus](https://github.com/narajaon/onestatus)?

- `tpipeline` works out of the box with your current vim statusline, whereas `onestatus` does not actually use your statusline at all and requires you to configure its own statusline.
- As a result of the above, `oneline` isn't able to use many vim features such as your vim colorscheme and requires you to redefine your colors. In `tpipeline`, vim colors are translated to tmux syntax automatically.
- Simple things such as showing your current mode or linenumber require writing your own function in `oneline`. In `tpipeline` this works out of the box.
- In `oneline` the tmux statusline is updated using a blocking call, whereas `tpipeline` uses non-blocking jobs to asynchronously update the statusline.
