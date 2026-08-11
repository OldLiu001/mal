#!/bin/csh -f
# mal step2: read a form, EVAL it (numbers, symbols, lists applied to the
# core arithmetic functions, vectors and hash-maps evaluated element-wise),
# and PRINT the result.
#
# Pure classic csh for all control flow (the EVAL "function" is a goto-based
# subprogram with a CALLER return-label variable; recursion is simulated with
# an explicit depth D so nested forms do not clobber each other's state).
# awk is used ONLY for the character-level work csh cannot do:
#   tok.awk   - tokenizer (encoded)
#   dec.awk   - decode before printing
#   nth.awk   - fetch the n-th line of a token/result file
#   count.awk - count lines
#   split.awk - split a collection string into top-level elements
#
# All mal values are carried as normalized strings (e.g. "(+ 1 2)"), exactly
# as produced by the step1 reader, so EVAL only ever manipulates strings and
# the printer just decodes them.

set histchars=
# csh cannot detect EOF: "$<" returns "" for both a blank line and end of
# input, with $status always 0.  Re-read without re-prompting on an empty
# line and give up after a short run, so a closed pipe exits promptly.
@ blank = 0
set dir = `dirname $0`
set tokprog = "$dir/tok.awk"
set decprog = "$dir/dec.awk"
set nthprog = "$dir/nth.awk"
set countprog = "$dir/count.awk"
set splitprog = "$dir/split.awk"
set classifyprog = "$dir/classify.awk"

# ---- pre-allocated reader stack (step1 reader) ----
set op = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set buf = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set hd = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set wrap = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set wmeta = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
# ---- eval collection-loop state, indexed by depth D ----
set EL_N = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set EL_I = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set COLL_CALLER = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set EOPEN = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set ECLOSE = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
# ---- global environment (step2: flat) ----
set GKEY = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set GVAL = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set GN = 0
@ GN++
set GKEY[$GN] = "+"; set GVAL[$GN] = "__FN_PLUS__"
@ GN++
set GKEY[$GN] = "-"; set GVAL[$GN] = "__FN_MINUS__"
@ GN++
set GKEY[$GN] = "*"; set GVAL[$GN] = "__FN_MUL__"
@ GN++
set GKEY[$GN] = "/"; set GVAL[$GN] = "__FN_DIV__"

# ===================== REPL (goto-based loop) =====================
REPL_START:
    echo -n "user> "
REPL_READ:
    set line = "$<"
    if ("$line" == "") then
        @ blank++
        if ($blank >= 3) goto REPL_EXIT
        goto REPL_READ
    endif
    @ blank = 0

    # ---------- READER ----------
    set rtmp = "/tmp/mal_csh_$$"
    echo "$line" | awk -f "$tokprog" > "$rtmp"
    set ntok = `awk -f $countprog $rtmp`
    if ($ntok == 0) goto REPL_START

    set d = 0
    set read_result = ""
    set rerr = ""

    @ i = 1
    while ($i <= $ntok)
        set tok = "`awk -v n=$i -f $nthprog $rtmp`"
        if ("$tok" == "__MAL_STRERR__") then
            set rerr = "Error: end of input in string"
            break
        endif
        if ("$tok" == "(" || "$tok" == "[" || "$tok" == "{") then
            @ d++
            set op[$d] = "$tok"
            set hd[$d] = ""
            set buf[$d] = ""
            set wrap[$d] = 0
            set wmeta[$d] = ""
        else if ("$tok" == ")" || "$tok" == "]" || "$tok" == "}") then
            if ($d < 1) then
                set rerr = "Error: unbalanced '$tok'"
                break
            endif
            set closed = "$op[$d]$buf[$d]$tok"
            @ d--
            set F = "$closed"
            while (1)
                if ($d == 0) then
                    set read_result = "$F"
                    break
                endif
                if ("$wrap[$d]" == "0") then
                    if ("$buf[$d]" == "") then
                        set buf[$d] = "$F"
                    else
                        set buf[$d] = "$buf[$d] $F"
                    endif
                    break
                else if ("$wrap[$d]" == "1") then
                    if ("$buf[$d]" == "") then
                        set buf[$d] = "$hd[$d]$F"
                    else
                        set buf[$d] = "$buf[$d] $F"
                    endif
                    set F = "($buf[$d])"
                    @ d--
                    continue
                else if ("$wrap[$d]" == "2") then
                    set wmeta[$d] = "$F"
                    set wrap[$d] = 3
                    break
                else if ("$wrap[$d]" == "3") then
                    set F = "(with-meta $F $wmeta[$d])"
                    @ d--
                    continue
                endif
            end
            if ("$read_result" != "") break
        else if ("$tok" == "ZQ") then
            @ d++; set op[$d]="("; set hd[$d]="quote "; set buf[$d]=""; set wrap[$d]=1; set wmeta[$d]=""
        else if ("$tok" == "ZB") then
            @ d++; set op[$d]="("; set hd[$d]="quasiquote "; set buf[$d]=""; set wrap[$d]=1; set wmeta[$d]=""
        else if ("$tok" == "ZS") then
            @ d++; set op[$d]="("; set hd[$d]="splice-unquote "; set buf[$d]=""; set wrap[$d]=1; set wmeta[$d]=""
        else if ("$tok" == "ZU") then
            @ d++; set op[$d]="("; set hd[$d]="unquote "; set buf[$d]=""; set wrap[$d]=1; set wmeta[$d]=""
        else if ("$tok" == "ZA") then
            @ d++; set op[$d]="("; set hd[$d]="deref "; set buf[$d]=""; set wrap[$d]=1; set wmeta[$d]=""
        else if ("$tok" == "ZM") then
            @ d++; set op[$d]="("; set hd[$d]="with-meta "; set buf[$d]=""; set wrap[$d]=2; set wmeta[$d]=""
        else
            set F = "$tok"
            while (1)
                if ($d == 0) then
                    set read_result = "$F"
                    break
                endif
                if ("$wrap[$d]" == "0") then
                    if ("$buf[$d]" == "") then
                        set buf[$d] = "$F"
                    else
                        set buf[$d] = "$buf[$d] $F"
                    endif
                    break
                else if ("$wrap[$d]" == "1") then
                    if ("$buf[$d]" == "") then
                        set buf[$d] = "$hd[$d]$F"
                    else
                        set buf[$d] = "$buf[$d] $F"
                    endif
                    set F = "($buf[$d])"
                    @ d--
                    continue
                else if ("$wrap[$d]" == "2") then
                    set wmeta[$d] = "$F"
                    set wrap[$d] = 3
                    break
                else if ("$wrap[$d]" == "3") then
                    set F = "(with-meta $F $wmeta[$d])"
                    @ d--
                    continue
                endif
            end
            if ("$read_result" != "") break
        endif
        @ i++
    end

    if ("$rerr" != "") then
        echo "$rerr"
        goto REPL_START
    endif
    if ("$read_result" == "") then
        echo "Error: unexpected end of input"
        goto REPL_START
    endif

    # ---------- EVAL ----------
    set E_AST = "$read_result"
    set D = 0
    set CALLER = REPL_PRINT
    goto EVAL

REPL_PRINT:
    echo "$E_RESULT" | awk -f "$decprog"
    goto REPL_START

REPL_EXIT:
    exit 0

# ===================== EVAL subprogram =====================
# Entry: E_AST holds the form to evaluate.
# Exit:  E_RESULT holds the value; jumps to $CALLER.
EVAL:
    echo "$E_AST" > "/tmp/mal_evalast_$$"
    set tclass = "`awk -f $classifyprog /tmp/mal_evalast_$$`"
    set TCLASS = "$tclass"
    if ("$tclass" == "list" || "$tclass" == "vector" || "$tclass" == "hash") goto EVAL_COLL
    if ("$tclass" == "string" || "$tclass" == "keyword" || "$tclass" == "number") goto EVAL_SELF
    goto EVAL_SYM

EVAL_SELF:
    set E_RESULT = "$E_AST"
    goto $CALLER

EVAL_SYM:
    set key = "$E_AST"
    if ("$key" == "nil" || "$key" == "true" || "$key" == "false") goto EVAL_SELF
    @ li = 0
    set found = 0
    while ($li < $GN)
        @ li++
        if ("$GKEY[$li]" == "$key") then
            set E_RESULT = "$GVAL[$li]"
            set found = 1
            break
        endif
    end
    if ($found == 0) then
        set E_RESULT = "Error: '$key' not found"
    endif
    goto $CALLER

# Evaluate a collection (list/vector/hash-map). Elements are evaluated one by
# one (stored in a per-depth temp file), then either rebuilt (vector/hash) or
# applied (list).
EVAL_COLL:
    @ D++
    set COLL_CALLER[$D] = "$CALLER"
    if ("$TCLASS" == "list") then
        set EOPEN[$D] = "("; set ECLOSE[$D] = ")"
    else if ("$TCLASS" == "vector") then
        set EOPEN[$D] = "["; set ECLOSE[$D] = "]"
    else
        set EOPEN[$D] = "{"; set ECLOSE[$D] = "}"
    endif
    echo -n "" > "/tmp/mal_elv_$$_$D"
    echo "$E_AST" | awk -f "$splitprog" > "/tmp/mal_split_$$_$D"
    set EL_N[$D] = `awk -f $countprog /tmp/mal_split_$$_$D`
    if ($EL_N[$D] == 0) then
        set E_RESULT = "$EOPEN[$D]$ECLOSE[$D]"
        set cc = "$COLL_CALLER[$D]"
        @ D--
        goto $cc
    endif
    set EL_I[$D] = 0

EVAL_COLL_LOOP:
    @ EL_I[$D]++
    if ($EL_I[$D] > $EL_N[$D]) goto EVAL_COLL_BUILD
    set ELEM = "`awk -v n=$EL_I[$D] -f $nthprog /tmp/mal_split_$$_$D`"
    set E_AST = "$ELEM"
    set CALLER = EVAL_COLL_STORE
    goto EVAL

EVAL_COLL_STORE:
    echo "$E_RESULT" >> "/tmp/mal_elv_$$_$D"
    goto EVAL_COLL_LOOP

EVAL_COLL_BUILD:
    if ("$EOPEN[$D]" == "(") goto EVAL_APPLY
    set s = ""
    @ k = 1
    while ($k <= $EL_N[$D])
        set ev = "`awk -v n=$k -f $nthprog /tmp/mal_elv_$$_$D`"
        if ("$s" == "") then
            set s = "$ev"
        else
            set s = "$s $ev"
        endif
        @ k++
    end
    set E_RESULT = "$EOPEN[$D]$s$ECLOSE[$D]"
    set cc = "$COLL_CALLER[$D]"
    @ D--
    goto $cc

EVAL_APPLY:
    set FN = "`awk -v n=1 -f $nthprog /tmp/mal_elv_$$_$D`"
    if ("$FN" == "__FN_PLUS__") goto APPLY_PLUS
    if ("$FN" == "__FN_MINUS__") goto APPLY_MINUS
    if ("$FN" == "__FN_MUL__") goto APPLY_MUL
    if ("$FN" == "__FN_DIV__") goto APPLY_DIV
    set E_RESULT = "Error: '$FN' is not a function"
    set cc = "$COLL_CALLER[$D]"
    @ D--
    goto $cc

APPLY_PLUS:
    @ cnt = $EL_N[$D]
    set a1 = "`awk -v n=2 -f $nthprog /tmp/mal_elv_$$_$D`"
    @ r = $a1
    @ k = 3
    while ($k <= $cnt)
        set ak = "`awk -v n=$k -f $nthprog /tmp/mal_elv_$$_$D`"
        @ r = $r + $ak
        @ k++
    end
    set E_RESULT = "$r"
    set cc = "$COLL_CALLER[$D]"
    @ D--
    goto $cc

APPLY_MINUS:
    @ cnt = $EL_N[$D]
    set a1 = "`awk -v n=2 -f $nthprog /tmp/mal_elv_$$_$D`"
    @ r = $a1
    @ k = 3
    while ($k <= $cnt)
        set ak = "`awk -v n=$k -f $nthprog /tmp/mal_elv_$$_$D`"
        @ r = $r - $ak
        @ k++
    end
    set E_RESULT = "$r"
    set cc = "$COLL_CALLER[$D]"
    @ D--
    goto $cc

APPLY_MUL:
    @ cnt = $EL_N[$D]
    set a1 = "`awk -v n=2 -f $nthprog /tmp/mal_elv_$$_$D`"
    @ r = $a1
    @ k = 3
    while ($k <= $cnt)
        set ak = "`awk -v n=$k -f $nthprog /tmp/mal_elv_$$_$D`"
        @ r = $r * $ak
        @ k++
    end
    set E_RESULT = "$r"
    set cc = "$COLL_CALLER[$D]"
    @ D--
    goto $cc

APPLY_DIV:
    @ cnt = $EL_N[$D]
    set a1 = "`awk -v n=2 -f $nthprog /tmp/mal_elv_$$_$D`"
    @ r = $a1
    @ k = 3
    while ($k <= $cnt)
        set ak = "`awk -v n=$k -f $nthprog /tmp/mal_elv_$$_$D`"
        @ r = $r / $ak
        @ k++
    end
    set E_RESULT = "$r"
    set cc = "$COLL_CALLER[$D]"
    @ D--
    goto $cc
