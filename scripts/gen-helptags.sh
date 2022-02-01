#!/usr/bin/env sh

vim -f --clean -u NONE --not-a-term -c 'set rtp=. | helptags ./doc | quit'
