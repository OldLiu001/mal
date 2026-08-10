#!/bin/dash
STEPNUM=5
. "$(dirname "$0")/core.sh"
init_repl_env
mal_repl "$@"
