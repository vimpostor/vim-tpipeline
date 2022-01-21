# Testing

This directory contains a testing suite to make it easy to find regressions.

To run it locally, use the provided `Makefile`:
```bash
make tests_vim # Runs tests with vim
make tests_neovim # Runs tests with neovim
make all # Runs tests with both vim and neovim
```

You can also test with the provided `Dockerfile`:
```bash
cd .. # Go to the root of the repository
podman build -t vim-tpipeline -f tests/Dockerfile .
podman run -it vim-tpipeline
```
