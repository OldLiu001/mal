#!/bin/dash
# step0: REPL that echoes the raw (whitespace-trimmed) input line.
STEPNUM=0
d=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$d/core.sh"
mal_repl
