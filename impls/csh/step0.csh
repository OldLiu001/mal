#!/bin/csh -f
# Wrapper so the Makefile build target (step0.csh) and the STEP=step0_repl
# run target both resolve. The real implementation lives in step0_repl.csh.
exec /bin/csh "$0:h/step0_repl.csh $argv
