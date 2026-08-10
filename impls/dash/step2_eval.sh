#!/bin/dash
# step2: eval arithmetic (+ - * /) with symbol lookup & apply.
STEPNUM=2
d=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$d/core.sh"
init_repl_env
mal_repl "$@"
