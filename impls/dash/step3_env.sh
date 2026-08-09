#!/bin/dash
# step3: environment (def! / let*) on top of step2.
STEPNUM=3
d=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$d/core.sh"
init_repl_env
mal_repl
