#!/bin/csh -f
# mal step0: REPL that reads a line and prints it back (read-print only).
# Pure classic csh (no tcsh extensions, no external binaries in the loop).
set histchars=

while (1)
    echo -n "user> "
    set line = "$<"
    if ($status != 0) break
    echo "$line"
end
