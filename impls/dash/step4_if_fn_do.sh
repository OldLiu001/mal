#!/bin/dash
# step4: if / fn* / do + comparison & list ops.
STEPNUM=4
d=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$d/core.sh"
init_repl_env
mal_repl "$@"
