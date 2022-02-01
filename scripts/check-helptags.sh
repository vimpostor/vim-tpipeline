#!/usr/bin/env bash

set -e

TAGS='doc/tags'
BACKUP='/tmp/.tags.before'

cp "$TAGS" "$BACKUP"
scripts/gen-helptags.sh
if ! diff --color=auto "$BACKUP" "$TAGS"; then
	echo 'Found changes in the tags file. Did you forget to update the helptags with scripts/gen-helptags.sh?'
	exit 1
fi
