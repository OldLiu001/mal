#!/bin/csh -f
# mal step0: REPL that reads a line and prints it back (read-print only).
# Pure classic csh (no tcsh extensions, no external binaries in the loop).
# csh cannot detect end of input: "$<" yields an empty string both for a
# blank line and at EOF, and $status stays 0 in either case.  So on an empty
# read we loop back *without* re-printing the prompt, and give up after a
# short run of them -- that exits promptly once stdin is a closed pipe
# instead of spinning forever printing prompts.
set histchars=
@ blank = 0

REPL:
    echo -n "user> "
REPL_READ:
    set line = "$<"
    if ("$line" == "") then
        @ blank++
        if ($blank >= 3) exit 0
        goto REPL_READ
    endif
    @ blank = 0
    echo "$line"
    goto REPL
