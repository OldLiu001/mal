#!/bin/csh -f
set histchars=
set noglob
set dir = "$0:h"
if ("$dir" == "$0") set dir = "."
set awkprog = "$dir/mal.awk"
set T = "/tmp/mal_csh_$$"
echo "T1" | awk -v mode=tok -f "$awkprog"
set line = "(str ZZQabcZZSPZZSPdefZZQ)"
set TKA = (`echo "$line" | awk -v mode=tok -f "$awkprog"`)
set ntok = $#TKA
@ ti2 = 1
while ($ti2 <= $ntok)
    set TKA[$ti2] = "$TKA[$ti2]:as/ZZSP/ /"
    @ ti2++
end
echo "t2=[$TKA[3]]"
set t3 = "`echo "$TKA[3]" | awk -v mode=wrap -v esc=0 -f "$awkprog"`"
echo "t3=[$t3]"
set t4 = "`echo "$t3" | awk -v mode=dec -f "$awkprog"`"
echo "t4=[$t4]"
