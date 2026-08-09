#!/bin/csh -f
# mal step4: if / fn* / do plus a small core library.
#
# Pure classic csh for all control flow.  READ and EVAL are goto-based
# subprograms: RCALLER / CALLER hold the return label, and every piece of
# per-call state is indexed by the recursion depth D.  awk is used only for
# character-level work csh cannot do.
#
# Value representation (all mal values are plain, "safe" strings):
#   numbers/symbols/keywords  literal text
#   strings                   ZZQ<escaped body>ZZQ   (see tok.awk / strlib.awk)
#   collections               (a b c)  [a b c]  {k v}
#   builtin functions         __CORE_<name>__
#   closures                  __FNC_<n>__  with FNPAR/FNBODY/FNENV[n]

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
set strlib = "$dir/strlib.awk"
set joinprog = "$dir/join.awk"
set wrapprog = "$dir/wrap.awk"
set equalprog = "$dir/equal.awk"
set fnidxprog = "$dir/fnidx.awk"

set T = "/tmp/mal_csh_$$"

# ---- pre-allocated reader stack ----
set op = (`awk 'BEGIN{for(i=1;i<=128;i++)printf("\"\" ")}'`)
set buf = (`awk 'BEGIN{for(i=1;i<=128;i++)printf("\"\" ")}'`)
set hd = (`awk 'BEGIN{for(i=1;i<=128;i++)printf("\"\" ")}'`)
set wrap = (`awk 'BEGIN{for(i=1;i<=128;i++)printf("\"\" ")}'`)
set wmeta = (`awk 'BEGIN{for(i=1;i<=128;i++)printf("\"\" ")}'`)
# ---- eval state, indexed by depth D ----
set EL_N = (`awk 'BEGIN{for(i=1;i<=256;i++)printf("\"\" ")}'`)
set EL_I = (`awk 'BEGIN{for(i=1;i<=256;i++)printf("\"\" ")}'`)
set COLL_CALLER = (`awk 'BEGIN{for(i=1;i<=256;i++)printf("\"\" ")}'`)
set COLL_ENV = (`awk 'BEGIN{for(i=1;i<=256;i++)printf("\"\" ")}'`)
set EOPEN = (`awk 'BEGIN{for(i=1;i<=256;i++)printf("\"\" ")}'`)
set ECLOSE = (`awk 'BEGIN{for(i=1;i<=256;i++)printf("\"\" ")}'`)
set DEFKEY = (`awk 'BEGIN{for(i=1;i<=256;i++)printf("\"\" ")}'`)
set LETENV = (`awk 'BEGIN{for(i=1;i<=256;i++)printf("\"\" ")}'`)
set LETK = (`awk 'BEGIN{for(i=1;i<=256;i++)printf("\"\" ")}'`)
set LB_N = (`awk 'BEGIN{for(i=1;i<=256;i++)printf("\"\" ")}'`)
set LB_I = (`awk 'BEGIN{for(i=1;i<=256;i++)printf("\"\" ")}'`)
# ---- environments ----
set ENV_OUTER = (`awk 'BEGIN{for(i=1;i<=4096;i++)printf("\"\" ")}'`)
set DBGV = (`awk 'BEGIN{for(i=1;i<=4096;i++)printf("\"\" ")}'`)
set DBG_ANY = 0
set BKEY = (`awk 'BEGIN{for(i=1;i<=4096;i++)printf("\"\" ")}'`)
set BVAL = (`awk 'BEGIN{for(i=1;i<=4096;i++)printf("\"\" ")}'`)
set BENV = (`awk 'BEGIN{for(i=1;i<=4096;i++)printf("\"\" ")}'`)
set BN = 0
set ENVN = 1
set ENV_OUTER[1] = 0
# ---- closures ----
set FNPAR = (`awk 'BEGIN{for(i=1;i<=512;i++)printf("\"\" ")}'`)
set FNBODY = (`awk 'BEGIN{for(i=1;i<=512;i++)printf("\"\" ")}'`)
set FNENV = (`awk 'BEGIN{for(i=1;i<=512;i++)printf("\"\" ")}'`)
set FNN = 0

set ERR = 0
set ERRTARGET = REPL_PRINT

# ---- core namespace ----
# Registered one by one: several of these names ("<", ">", "*", "=") are csh
# metacharacters and are only safe inside double quotes.
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "+";       set BVAL[$BN] = "__CORE_add__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "-";       set BVAL[$BN] = "__CORE_sub__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "*";       set BVAL[$BN] = "__CORE_mul__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "/";       set BVAL[$BN] = "__CORE_div__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "list";    set BVAL[$BN] = "__CORE_list__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "list?";   set BVAL[$BN] = "__CORE_listp__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "empty?";  set BVAL[$BN] = "__CORE_emptyp__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "count";   set BVAL[$BN] = "__CORE_count__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "=";       set BVAL[$BN] = "__CORE_eq__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "<";       set BVAL[$BN] = "__CORE_lt__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "<=";      set BVAL[$BN] = "__CORE_le__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = ">";       set BVAL[$BN] = "__CORE_gt__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = ">=";      set BVAL[$BN] = "__CORE_ge__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "pr-str";  set BVAL[$BN] = "__CORE_prstr__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "str";     set BVAL[$BN] = "__CORE_str__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "prn";     set BVAL[$BN] = "__CORE_prn__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "println"; set BVAL[$BN] = "__CORE_println__"

# ---- mal-defined core ----
set INIT_SRC = ("(def! not (fn* (a) (if a false true)))")
set INIT_N = $#INIT_SRC
set INIT_I = 0

INIT_LOOP:
    @ INIT_I++
    if ($INIT_I > $INIT_N) goto REPL_START
    set R_LINE = "$INIT_SRC[$INIT_I]"
    set RCALLER = INIT_READ_DONE
    goto READ

INIT_READ_DONE:
    set E_AST = "$read_result"
    set E_ENV = 1
    set D = 0
    set ERR = 0
    set ERRTARGET = INIT_EVAL_DONE
    set CALLER = INIT_EVAL_DONE
    goto EVAL

INIT_EVAL_DONE:
    goto INIT_LOOP

# ===================== REPL =====================
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
    set R_LINE = "$line"
    set RCALLER = REPL_AFTER_READ
    goto READ

REPL_AFTER_READ:
    if ("$rerr" != "") then
        echo "$rerr"
        goto REPL_START
    endif
    if ("$read_result" == "") then
        echo "Error: unexpected end of input"
        goto REPL_START
    endif
    set E_AST = "$read_result"
    set E_ENV = 1
    set D = 0
    set ERR = 0
    set ERRTARGET = REPL_PRINT
    set CALLER = REPL_PRINT
    goto EVAL

REPL_PRINT:
    echo "$E_RESULT" | awk -f "$decprog"
    goto REPL_START

REPL_EXIT:
    exit 0

# ===================== READ subprogram =====================
# Entry: R_LINE.  Exit: read_result (or rerr); jumps to $RCALLER.
READ:
    set read_result = ""
    set rerr = ""
    echo "$R_LINE" | awk -f "$tokprog" > "$T.tok"
    set ntok = `awk -f $countprog $T.tok`
    if ($ntok == 0) goto $RCALLER

    set d = 0
    @ i = 1
    while ($i <= $ntok)
        set tok = "`awk -v n=$i -f $nthprog $T.tok`"
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
    goto $RCALLER

# ===================== EVAL subprogram =====================
EVAL:
    echo "$E_AST" > "$T.ast"
    set TCLASS = "`awk -f $classifyprog $T.ast`"

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
    echo -n "" > "$T.elv.$D"
    echo "$E_AST" | awk -f "$splitprog" > "$T.spl.$D"
    set EL_N[$D] = `awk -f $countprog $T.spl.$D`
    if ($EL_N[$D] == 0) then
        set E_RESULT = "$EOPEN[$D]$ECLOSE[$D]"
        goto EVAL_RETURN
    endif
    if ("$EOPEN[$D]" != "(") goto EVAL_COLL_ELEMS
    set FIRST = "`awk -v n=1 -f $nthprog $T.spl.$D`"
    if ("$FIRST" == "def!") goto EVAL_DEF
    if ("$FIRST" == "let*") goto EVAL_LET
    if ("$FIRST" == "if") goto EVAL_IF
    if ("$FIRST" == "do") goto EVAL_DO
    if ("$FIRST" == "fn*") goto EVAL_FN

EVAL_COLL_ELEMS:
    set EL_I[$D] = 0

EVAL_COLL_LOOP:
    @ EL_I[$D]++
    if ($EL_I[$D] > $EL_N[$D]) goto EVAL_COLL_BUILD
    set ELEM = "`awk -v n=$EL_I[$D] -f $nthprog $T.spl.$D`"
    echo "$ELEM" > "$T.ast"
    set ec = "`awk -f $classifyprog $T.ast`"
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
    echo "$E_RESULT" >> "$T.elv.$D"
    goto EVAL_COLL_LOOP

EVAL_COLL_BUILD:
    if ("$EOPEN[$D]" == "(") goto EVAL_APPLY
    set s = ""
    @ k = 1
    while ($k <= $EL_N[$D])
        set ev = "`awk -v n=$k -f $nthprog $T.elv.$D`"
        if ($k == 1) then
            set s = "$ev"
        else
            set s = "$s $ev"
        endif
        @ k++
    end
    set E_RESULT = "$EOPEN[$D]$s$ECLOSE[$D]"
    goto EVAL_RETURN

# Common exit: E_RESULT already holds the value of the collection at depth D.
EVAL_RETURN:
    set cc = "$COLL_CALLER[$D]"
    set E_ENV = "$COLL_ENV[$D]"
    @ D--
    goto $cc

# Exit after a recursive EVAL whose result is the value of this form.
EVAL_RET:
    if ($ERR == 1) goto EVAL_ABORT
    goto EVAL_RETURN

# ---- special form: def! ----
EVAL_DEF:
    set DEFKEY[$D] = "`awk -v n=2 -f $nthprog $T.spl.$D`"
    set E_AST = "`awk -v n=3 -f $nthprog $T.spl.$D`"
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
    goto EVAL_RETURN

# ---- special form: let* ----
EVAL_LET:
    @ ENVN++
    set LETENV[$D] = $ENVN
    set ENV_OUTER[$ENVN] = "$COLL_ENV[$D]"
    set bl = "`awk -v n=2 -f $nthprog $T.spl.$D`"
    echo "$bl" > "$T.ast"
    awk -f "$splitprog" "$T.ast" > "$T.lb.$D"
    set LB_N[$D] = `awk -f $countprog $T.lb.$D`
    set LB_I[$D] = 0

EVAL_LET_LOOP:
    @ LB_I[$D]++
    if ($LB_I[$D] > $LB_N[$D]) goto EVAL_LET_BODY
    set LETK[$D] = "`awk -v n=$LB_I[$D] -f $nthprog $T.lb.$D`"
    @ LB_I[$D]++
    set E_AST = "`awk -v n=$LB_I[$D] -f $nthprog $T.lb.$D`"
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
    set E_AST = "`awk -v n=3 -f $nthprog $T.spl.$D`"
    set E_ENV = "$LETENV[$D]"
    set CALLER = EVAL_RET
    goto EVAL

# ---- special form: if ----
EVAL_IF:
    set E_AST = "`awk -v n=2 -f $nthprog $T.spl.$D`"
    set E_ENV = "$COLL_ENV[$D]"
    set CALLER = EVAL_IF_TEST
    goto EVAL

EVAL_IF_TEST:
    if ($ERR == 1) goto EVAL_ABORT
    if ("$E_RESULT" == "nil" || "$E_RESULT" == "false") then
        if ($EL_N[$D] < 4) then
            set E_RESULT = "nil"
            goto EVAL_RETURN
        endif
        set E_AST = "`awk -v n=4 -f $nthprog $T.spl.$D`"
    else
        set E_AST = "`awk -v n=3 -f $nthprog $T.spl.$D`"
    endif
    set E_ENV = "$COLL_ENV[$D]"
    set CALLER = EVAL_RET
    goto EVAL

# ---- special form: do ----
EVAL_DO:
    set EL_I[$D] = 1

EVAL_DO_LOOP:
    @ EL_I[$D]++
    if ($EL_I[$D] > $EL_N[$D]) then
        set E_RESULT = "nil"
        goto EVAL_RETURN
    endif
    set E_AST = "`awk -v n=$EL_I[$D] -f $nthprog $T.spl.$D`"
    set E_ENV = "$COLL_ENV[$D]"
    if ($EL_I[$D] == $EL_N[$D]) then
        set CALLER = EVAL_RET
    else
        set CALLER = EVAL_DO_STEP
    endif
    goto EVAL

EVAL_DO_STEP:
    if ($ERR == 1) goto EVAL_ABORT
    goto EVAL_DO_LOOP

# ---- special form: fn* ----
EVAL_FN:
    @ FNN++
    set FNPAR[$FNN] = "`awk -v n=2 -f $nthprog $T.spl.$D`"
    set FNBODY[$FNN] = "`awk -v n=3 -f $nthprog $T.spl.$D`"
    set FNENV[$FNN] = "$COLL_ENV[$D]"
    set E_RESULT = "__FNC_${FNN}__"
    goto EVAL_RETURN

# ---- apply ----
EVAL_APPLY:
    set FN = "`awk -v n=1 -f $nthprog $T.elv.$D`"
    set fidx = `awk -f $fnidxprog $T.elv.$D`
    if ($fidx > 0) goto APPLY_CLOSURE
    if ("$FN" == "__CORE_add__") goto APPLY_ADD
    if ("$FN" == "__CORE_sub__") goto APPLY_SUB
    if ("$FN" == "__CORE_mul__") goto APPLY_MUL
    if ("$FN" == "__CORE_div__") goto APPLY_DIV
    if ("$FN" == "__CORE_list__") goto APPLY_LIST
    if ("$FN" == "__CORE_listp__") goto APPLY_LISTP
    if ("$FN" == "__CORE_emptyp__") goto APPLY_EMPTYP
    if ("$FN" == "__CORE_count__") goto APPLY_COUNT
    if ("$FN" == "__CORE_eq__") goto APPLY_EQ
    if ("$FN" == "__CORE_lt__") goto APPLY_LT
    if ("$FN" == "__CORE_le__") goto APPLY_LE
    if ("$FN" == "__CORE_gt__") goto APPLY_GT
    if ("$FN" == "__CORE_ge__") goto APPLY_GE
    if ("$FN" == "__CORE_prstr__") goto APPLY_PRSTR
    if ("$FN" == "__CORE_str__") goto APPLY_STR
    if ("$FN" == "__CORE_prn__") goto APPLY_PRN
    if ("$FN" == "__CORE_println__") goto APPLY_PRINTLN
    set E_RESULT = "Error: '$FN' is not a function"
    set ERR = 1
    goto EVAL_ABORT

APPLY_CLOSURE:
    @ ENVN++
    set nenv = $ENVN
    set ENV_OUTER[$nenv] = "$FNENV[$fidx]"
    echo "$FNPAR[$fidx]" > "$T.ast"
    awk -f "$splitprog" "$T.ast" > "$T.par.$D"
    set pn = `awk -f $countprog $T.par.$D`
    @ pi = 1
    @ ai = 2
    while ($pi <= $pn)
        set pk = "`awk -v n=$pi -f $nthprog $T.par.$D`"
        if ("$pk" == "&") then
            @ pi++
            set pk = "`awk -v n=$pi -f $nthprog $T.par.$D`"
            set rest = ""
            while ($ai <= $EL_N[$D])
                set av = "`awk -v n=$ai -f $nthprog $T.elv.$D`"
                if ("$rest" == "") then
                    set rest = "$av"
                else
                    set rest = "$rest $av"
                endif
                @ ai++
            end
            @ BN++
            set BENV[$BN] = "$nenv"
            set BKEY[$BN] = "$pk"
            set BVAL[$BN] = "($rest)"
            break
        endif
        set av = "`awk -v n=$ai -f $nthprog $T.elv.$D`"
        @ BN++
        set BENV[$BN] = "$nenv"
        set BKEY[$BN] = "$pk"
        set BVAL[$BN] = "$av"
        @ ai++
        @ pi++
    end
    set E_AST = "$FNBODY[$fidx]"
    set E_ENV = $nenv
    set CALLER = EVAL_RET
    goto EVAL

APPLY_ADD:
    set a1 = "`awk -v n=2 -f $nthprog $T.elv.$D`"
    @ r = $a1
    @ k = 3
    while ($k <= $EL_N[$D])
        set ak = "`awk -v n=$k -f $nthprog $T.elv.$D`"
        @ r = $r + $ak
        @ k++
    end
    set E_RESULT = "$r"
    goto EVAL_RETURN

APPLY_SUB:
    set a1 = "`awk -v n=2 -f $nthprog $T.elv.$D`"
    @ r = $a1
    @ k = 3
    while ($k <= $EL_N[$D])
        set ak = "`awk -v n=$k -f $nthprog $T.elv.$D`"
        @ r = $r - $ak
        @ k++
    end
    set E_RESULT = "$r"
    goto EVAL_RETURN

APPLY_MUL:
    set a1 = "`awk -v n=2 -f $nthprog $T.elv.$D`"
    @ r = $a1
    @ k = 3
    while ($k <= $EL_N[$D])
        set ak = "`awk -v n=$k -f $nthprog $T.elv.$D`"
        @ r = $r * $ak
        @ k++
    end
    set E_RESULT = "$r"
    goto EVAL_RETURN

APPLY_DIV:
    set a1 = "`awk -v n=2 -f $nthprog $T.elv.$D`"
    @ r = $a1
    @ k = 3
    while ($k <= $EL_N[$D])
        set ak = "`awk -v n=$k -f $nthprog $T.elv.$D`"
        @ r = $r / $ak
        @ k++
    end
    set E_RESULT = "$r"
    goto EVAL_RETURN

APPLY_LIST:
    set s = ""
    @ k = 2
    while ($k <= $EL_N[$D])
        set ev = "`awk -v n=$k -f $nthprog $T.elv.$D`"
        if ($k == 2) then
            set s = "$ev"
        else
            set s = "$s $ev"
        endif
        @ k++
    end
    set E_RESULT = "($s)"
    goto EVAL_RETURN

APPLY_LISTP:
    set a1 = "`awk -v n=2 -f $nthprog $T.elv.$D`"
    echo "$a1" > "$T.ast"
    set c = "`awk -f $classifyprog $T.ast`"
    if ("$c" == "list") then
        set E_RESULT = "true"
    else
        set E_RESULT = "false"
    endif
    goto EVAL_RETURN

APPLY_EMPTYP:
    set a1 = "`awk -v n=2 -f $nthprog $T.elv.$D`"
    if ("$a1" == "nil") then
        set E_RESULT = "true"
        goto EVAL_RETURN
    endif
    echo "$a1" > "$T.ast"
    awk -f "$splitprog" "$T.ast" > "$T.cnt"
    set n = `awk -f $countprog $T.cnt`
    if ($n == 0) then
        set E_RESULT = "true"
    else
        set E_RESULT = "false"
    endif
    goto EVAL_RETURN

APPLY_COUNT:
    set a1 = "`awk -v n=2 -f $nthprog $T.elv.$D`"
    if ("$a1" == "nil") then
        set E_RESULT = "0"
        goto EVAL_RETURN
    endif
    echo "$a1" > "$T.ast"
    awk -f "$splitprog" "$T.ast" > "$T.cnt"
    set E_RESULT = `awk -f $countprog $T.cnt`
    goto EVAL_RETURN

APPLY_EQ:
    awk -v n=2 -f "$nthprog" "$T.elv.$D" > "$T.eq"
    awk -v n=3 -f "$nthprog" "$T.elv.$D" >> "$T.eq"
    set E_RESULT = "`awk -f $strlib -f $equalprog $T.eq`"
    goto EVAL_RETURN

APPLY_LT:
    set a1 = "`awk -v n=2 -f $nthprog $T.elv.$D`"
    set a2 = "`awk -v n=3 -f $nthprog $T.elv.$D`"
    @ x = $a1
    @ y = $a2
    if ($x < $y) then
        set E_RESULT = "true"
    else
        set E_RESULT = "false"
    endif
    goto EVAL_RETURN

APPLY_LE:
    set a1 = "`awk -v n=2 -f $nthprog $T.elv.$D`"
    set a2 = "`awk -v n=3 -f $nthprog $T.elv.$D`"
    @ x = $a1
    @ y = $a2
    if ($x <= $y) then
        set E_RESULT = "true"
    else
        set E_RESULT = "false"
    endif
    goto EVAL_RETURN

APPLY_GT:
    set a1 = "`awk -v n=2 -f $nthprog $T.elv.$D`"
    set a2 = "`awk -v n=3 -f $nthprog $T.elv.$D`"
    @ x = $a1
    @ y = $a2
    if ($x > $y) then
        set E_RESULT = "true"
    else
        set E_RESULT = "false"
    endif
    goto EVAL_RETURN

APPLY_GE:
    set a1 = "`awk -v n=2 -f $nthprog $T.elv.$D`"
    set a2 = "`awk -v n=3 -f $nthprog $T.elv.$D`"
    @ x = $a1
    @ y = $a2
    if ($x >= $y) then
        set E_RESULT = "true"
    else
        set E_RESULT = "false"
    endif
    goto EVAL_RETURN

APPLY_PRSTR:
    awk -f "$strlib" -f "$joinprog" -v mode=1 "$T.elv.$D" > "$T.j"
    set E_RESULT = "`awk -f $strlib -f $wrapprog -v esc=1 $T.j`"
    goto EVAL_RETURN

APPLY_STR:
    awk -f "$strlib" -f "$joinprog" -v mode=2 "$T.elv.$D" > "$T.j"
    set E_RESULT = "`awk -f $strlib -f $wrapprog -v esc=0 $T.j`"
    goto EVAL_RETURN

APPLY_PRN:
    awk -f "$strlib" -f "$joinprog" -v mode=1 "$T.elv.$D" | awk -f "$decprog"
    set E_RESULT = "nil"
    goto EVAL_RETURN

APPLY_PRINTLN:
    awk -f "$strlib" -f "$joinprog" -v mode=3 "$T.elv.$D" | awk -f "$decprog"
    set E_RESULT = "nil"
    goto EVAL_RETURN
