#!/usr/bin/env sh
# This needs to be run from the root of the repository

vim -f --clean -u NONE --not-a-term -c 'set rtp=. | helptags ./doc | quit'
