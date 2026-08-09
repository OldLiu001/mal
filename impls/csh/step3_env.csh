#!/bin/csh -f
# mal step3: environments.  Adds a chained environment (def! / let*) on top of
# the step2 evaluator.
#
# Pure classic csh for all control flow.  EVAL is a goto-based subprogram; the
# CALLER variable holds the return label and every piece of per-call state is
# indexed by the recursion depth D so nested forms cannot clobber each other.
# awk is used ONLY for character-level work csh cannot do (tokenize, decode,
# nth line, count lines, split a collection into top-level elements, classify).
#
# Environments are stored in flat arrays:
#   ENV_OUTER[e]           - index of the enclosing environment (0 = none)
#   BKEY[i]/BVAL[i]/BENV[i] - one binding: symbol, value, owning environment

set histchars=
set dir = `dirname $0`
set tokprog = "$dir/tok.awk"
set decprog = "$dir/dec.awk"
set nthprog = "$dir/nth.awk"
set countprog = "$dir/count.awk"
set splitprog = "$dir/split.awk"
set classifyprog = "$dir/classify.awk"

# ---- pre-allocated reader stack ----
set op = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set buf = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set hd = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set wrap = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set wmeta = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
# ---- eval state, indexed by depth D ----
set EL_N = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set EL_I = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set COLL_CALLER = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set COLL_ENV = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set EOPEN = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set ECLOSE = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set DEFKEY = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set LETENV = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set LETK = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set LB_N = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set LB_I = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
# ---- environments ----
set ENV_OUTER = (`awk 'BEGIN{for(i=1;i<=512;i++)printf("\"\" ")}'`)
set DBGV = (`awk 'BEGIN{for(i=1;i<=512;i++)printf("\"\" ")}'`)
set DBG_ANY = 0
set BKEY = (`awk 'BEGIN{for(i=1;i<=1024;i++)printf("\"\" ")}'`)
set BVAL = (`awk 'BEGIN{for(i=1;i<=1024;i++)printf("\"\" ")}'`)
set BENV = (`awk 'BEGIN{for(i=1;i<=1024;i++)printf("\"\" ")}'`)
set BN = 0
set ENVN = 1
set ENV_OUTER[1] = 0

@ BN++
set BENV[$BN] = 1
set BKEY[$BN] = "+"
set BVAL[$BN] = "__FN_PLUS__"
@ BN++
set BENV[$BN] = 1
set BKEY[$BN] = "-"
set BVAL[$BN] = "__FN_MINUS__"
@ BN++
set BENV[$BN] = 1
set BKEY[$BN] = "*"
set BVAL[$BN] = "__FN_MUL__"
@ BN++
set BENV[$BN] = 1
set BKEY[$BN] = "/"
set BVAL[$BN] = "__FN_DIV__"

set ERR = 0
set ERRTARGET = REPL_PRINT

# ===================== REPL =====================
REPL_START:
    echo -n "user> "
    set line = "$<"
    if ($status != 0) goto REPL_EXIT
    if ("$line" == "") goto REPL_START

    # ---------- READER ----------
    set rtmp = "/tmp/mal_csh_$$"
    echo "$line" | awk -f "$tokprog" > "$rtmp"
    set ntok = `awk -f $countprog "$rtmp"`
    if ($ntok == 0) goto REPL_START

    set d = 0
    set read_result = ""
    set rerr = ""

    @ i = 1
    while ($i <= $ntok)
        set tok = "`awk -v n=$i -f $nthprog "$rtmp"`"
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
    set E_ENV = 1
    set D = 0
    set ERR = 0
    set CALLER = REPL_PRINT
    goto EVAL

REPL_PRINT:
    echo "$E_RESULT" | awk -f "$decprog"
    goto REPL_START

REPL_EXIT:

# ===================== EVAL subprogram =====================
# Entry: E_AST = form, E_ENV = environment index.
# Exit:  E_RESULT = value; jumps to $CALLER.  On error ERR=1 and the whole
#        evaluation is aborted to $ERRTARGET.
EVAL:
    echo "$E_AST" > "/tmp/mal_evalast_$$"
    set TCLASS = "`awk -f $classifyprog "/tmp/mal_evalast_$$"`"

# Same as EVAL but the caller already knows the class (avoids a second
# classify pass when a collection element is dispatched).
EVAL_DISPATCH:
    if ($DBG_ANY == 1) then
        set ge = $E_ENV
        set dv = ""
        while ($ge != 0)
            if ("$DBGV[$ge]" != "") then
                set dv = "$DBGV[$ge]"
                break
            endif
            set ge = $ENV_OUTER[$ge]
        end
        if ("$dv" != "" && "$dv" != "nil" && "$dv" != "false") then
            echo -n "EVAL: "
            echo "$E_AST" | awk -f "$decprog"
        endif
    endif
    if ("$TCLASS" == "list" || "$TCLASS" == "vector" || "$TCLASS" == "hash") goto EVAL_COLL
    if ("$TCLASS" == "string" || "$TCLASS" == "keyword" || "$TCLASS" == "number") goto EVAL_SELF
    goto EVAL_SYM

EVAL_ABORT:
    set D = 0
    goto $ERRTARGET

EVAL_SELF:
    set E_RESULT = "$E_AST"
    goto $CALLER

EVAL_SYM:
    set key = "$E_AST"
    if ("$key" == "nil" || "$key" == "true" || "$key" == "false") goto EVAL_SELF
    set ge = $E_ENV
    set found = 0
    while ($ge != 0)
        @ bi = $BN
        while ($bi > 0)
            if ("$BENV[$bi]" == "$ge" && "$BKEY[$bi]" == "$key") then
                set E_RESULT = "$BVAL[$bi]"
                set found = 1
                break
            endif
            @ bi--
        end
        if ($found == 1) break
        set ge = $ENV_OUTER[$ge]
    end
    if ($found == 0) then
        set E_RESULT = "Error: '$key' not found"
        set ERR = 1
    endif
    goto $CALLER

# ---- collections ----
EVAL_COLL:
    @ D++
    set COLL_CALLER[$D] = "$CALLER"
    set COLL_ENV[$D] = "$E_ENV"
    if ("$TCLASS" == "list") then
        set EOPEN[$D] = "("
        set ECLOSE[$D] = ")"
    else if ("$TCLASS" == "vector") then
        set EOPEN[$D] = "["
        set ECLOSE[$D] = "]"
    else
        set EOPEN[$D] = "{"
        set ECLOSE[$D] = "}"
    endif
    echo -n "" > "/tmp/mal_elv_$$_$D"
    echo "$E_AST" | awk -f "$splitprog" > "/tmp/mal_split_$$_$D"
    set EL_N[$D] = `awk -f $countprog "/tmp/mal_split_$$_$D"`
    if ($EL_N[$D] == 0) then
        set E_RESULT = "$EOPEN[$D]$ECLOSE[$D]"
        set cc = "$COLL_CALLER[$D]"
        @ D--
        goto $cc
    endif
    if ("$EOPEN[$D]" != "(") goto EVAL_COLL_ELEMS
    set FIRST = "`awk -v n=1 -f $nthprog "/tmp/mal_split_$$_$D"`"
    if ("$FIRST" == "def!") goto EVAL_DEF
    if ("$FIRST" == "let*") goto EVAL_LET

EVAL_COLL_ELEMS:
    set EL_I[$D] = 0

EVAL_COLL_LOOP:
    @ EL_I[$D]++
    if ($EL_I[$D] > $EL_N[$D]) goto EVAL_COLL_BUILD
    set ELEM = "`awk -v n=$EL_I[$D] -f $nthprog "/tmp/mal_split_$$_$D"`"
    echo "$ELEM" > "/tmp/mal_evalast_$$"
    set ec = "`awk -f $classifyprog "/tmp/mal_evalast_$$"`"
    if ("$ec" == "number" || "$ec" == "string" || "$ec" == "keyword") then
        set E_RESULT = "$ELEM"
        goto EVAL_COLL_STORE
    endif
    set E_AST = "$ELEM"
    set E_ENV = "$COLL_ENV[$D]"
    set CALLER = EVAL_COLL_STORE
    if ("$ec" == "symbol") goto EVAL_SYM
    set TCLASS = "$ec"
    goto EVAL_DISPATCH

EVAL_COLL_STORE:
    if ($ERR == 1) goto EVAL_ABORT
    echo "$E_RESULT" >> "/tmp/mal_elv_$$_$D"
    goto EVAL_COLL_LOOP

EVAL_COLL_BUILD:
    if ("$EOPEN[$D]" == "(") goto EVAL_APPLY
    set s = ""
    @ k = 1
    while ($k <= $EL_N[$D])
        set ev = "`awk -v n=$k -f $nthprog "/tmp/mal_elv_$$_$D"`"
        if ("$s" == "") then
            set s = "$ev"
        else
            set s = "$s $ev"
        endif
        @ k++
    end
    set E_RESULT = "$EOPEN[$D]$s$ECLOSE[$D]"
    set cc = "$COLL_CALLER[$D]"
    set E_ENV = "$COLL_ENV[$D]"
    @ D--
    goto $cc

# ---- special form: def! ----
EVAL_DEF:
    set DEFKEY[$D] = "`awk -v n=2 -f $nthprog "/tmp/mal_split_$$_$D"`"
    set E_AST = "`awk -v n=3 -f $nthprog "/tmp/mal_split_$$_$D"`"
    set E_ENV = "$COLL_ENV[$D]"
    set CALLER = EVAL_DEF_DONE
    goto EVAL

EVAL_DEF_DONE:
    if ($ERR == 1) goto EVAL_ABORT
    set eenv = "$COLL_ENV[$D]"
    set ekey = "$DEFKEY[$D]"
    set eval_v = "$E_RESULT"
    @ bi = 0
    set bfound = 0
    while ($bi < $BN)
        @ bi++
        if ("$BENV[$bi]" == "$eenv" && "$BKEY[$bi]" == "$ekey") then
            set BVAL[$bi] = "$eval_v"
            set bfound = 1
            break
        endif
    end
    if ($bfound == 0) then
        @ BN++
        set BENV[$BN] = "$eenv"
        set BKEY[$BN] = "$ekey"
        set BVAL[$BN] = "$eval_v"
    endif
    if ("$ekey" == "DEBUG-EVAL") then
        set DBGV[$eenv] = "$eval_v"
        set DBG_ANY = 1
    endif
    set E_RESULT = "$eval_v"
    set cc = "$COLL_CALLER[$D]"
    set E_ENV = "$COLL_ENV[$D]"
    @ D--
    goto $cc

# ---- special form: let* ----
EVAL_LET:
    @ ENVN++
    set LETENV[$D] = $ENVN
    set ENV_OUTER[$ENVN] = "$COLL_ENV[$D]"
    set bl = "`awk -v n=2 -f $nthprog "/tmp/mal_split_$$_$D"`"
    echo "$bl" | awk -f "$splitprog" > "/tmp/mal_lb_$$_$D"
    set LB_N[$D] = `awk -f $countprog "/tmp/mal_lb_$$_$D"`
    set LB_I[$D] = 0

EVAL_LET_LOOP:
    @ LB_I[$D]++
    if ($LB_I[$D] > $LB_N[$D]) goto EVAL_LET_BODY
    set LETK[$D] = "`awk -v n=$LB_I[$D] -f $nthprog "/tmp/mal_lb_$$_$D"`"
    @ LB_I[$D]++
    set E_AST = "`awk -v n=$LB_I[$D] -f $nthprog "/tmp/mal_lb_$$_$D"`"
    set E_ENV = "$LETENV[$D]"
    set CALLER = EVAL_LET_STORE
    goto EVAL

EVAL_LET_STORE:
    if ($ERR == 1) goto EVAL_ABORT
    set eenv = "$LETENV[$D]"
    set ekey = "$LETK[$D]"
    set eval_v = "$E_RESULT"
    @ bi = 0
    set bfound = 0
    while ($bi < $BN)
        @ bi++
        if ("$BENV[$bi]" == "$eenv" && "$BKEY[$bi]" == "$ekey") then
            set BVAL[$bi] = "$eval_v"
            set bfound = 1
            break
        endif
    end
    if ($bfound == 0) then
        @ BN++
        set BENV[$BN] = "$eenv"
        set BKEY[$BN] = "$ekey"
        set BVAL[$BN] = "$eval_v"
    endif
    if ("$ekey" == "DEBUG-EVAL") then
        set DBGV[$eenv] = "$eval_v"
        set DBG_ANY = 1
    endif
    goto EVAL_LET_LOOP

EVAL_LET_BODY:
    set E_AST = "`awk -v n=3 -f $nthprog "/tmp/mal_split_$$_$D"`"
    set E_ENV = "$LETENV[$D]"
    set CALLER = EVAL_LET_DONE
    goto EVAL

EVAL_LET_DONE:
    if ($ERR == 1) goto EVAL_ABORT
    set cc = "$COLL_CALLER[$D]"
    set E_ENV = "$COLL_ENV[$D]"
    @ D--
    goto $cc

# ---- apply ----
EVAL_APPLY:
    set FN = "`awk -v n=1 -f $nthprog "/tmp/mal_elv_$$_$D"`"
    if ("$FN" == "__FN_PLUS__") goto APPLY_PLUS
    if ("$FN" == "__FN_MINUS__") goto APPLY_MINUS
    if ("$FN" == "__FN_MUL__") goto APPLY_MUL
    if ("$FN" == "__FN_DIV__") goto APPLY_DIV
    set E_RESULT = "Error: '$FN' is not a function"
    set ERR = 1
    goto EVAL_ABORT

APPLY_PLUS:
    @ cnt = $EL_N[$D]
    set a1 = "`awk -v n=2 -f $nthprog "/tmp/mal_elv_$$_$D"`"
    @ r = $a1
    @ k = 3
    while ($k <= $cnt)
        set ak = "`awk -v n=$k -f $nthprog "/tmp/mal_elv_$$_$D"`"
        @ r = $r + $ak
        @ k++
    end
    goto APPLY_RETURN

APPLY_MINUS:
    @ cnt = $EL_N[$D]
    set a1 = "`awk -v n=2 -f $nthprog "/tmp/mal_elv_$$_$D"`"
    @ r = $a1
    @ k = 3
    while ($k <= $cnt)
        set ak = "`awk -v n=$k -f $nthprog "/tmp/mal_elv_$$_$D"`"
        @ r = $r - $ak
        @ k++
    end
    goto APPLY_RETURN

APPLY_MUL:
    @ cnt = $EL_N[$D]
    set a1 = "`awk -v n=2 -f $nthprog "/tmp/mal_elv_$$_$D"`"
    @ r = $a1
    @ k = 3
    while ($k <= $cnt)
        set ak = "`awk -v n=$k -f $nthprog "/tmp/mal_elv_$$_$D"`"
        @ r = $r * $ak
        @ k++
    end
    goto APPLY_RETURN

APPLY_DIV:
    @ cnt = $EL_N[$D]
    set a1 = "`awk -v n=2 -f $nthprog "/tmp/mal_elv_$$_$D"`"
    @ r = $a1
    @ k = 3
    while ($k <= $cnt)
        set ak = "`awk -v n=$k -f $nthprog "/tmp/mal_elv_$$_$D"`"
        @ r = $r / $ak
        @ k++
    end
    goto APPLY_RETURN

APPLY_RETURN:
    set E_RESULT = "$r"
    set cc = "$COLL_CALLER[$D]"
    set E_ENV = "$COLL_ENV[$D]"
    @ D--
    goto $cc
