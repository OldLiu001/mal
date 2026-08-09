#!/bin/dash
# step1: read and print (tokenizer + reader + printer). EVAL is identity.
STEPNUM=1
d=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$d/core.sh"
init_repl_env
mal_repl
