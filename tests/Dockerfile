FROM archlinux:base

RUN pacman -Syu --noconfirm gvim neovim tmux make
COPY . /tmp/vim-tpipeline
WORKDIR /tmp/vim-tpipeline/tests
CMD make
