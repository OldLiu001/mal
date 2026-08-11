#!/bin/csh -f
# mal step3: environments (def! / let*) plus a small core library.
#
# Pure csh (tcsh) control flow; the EVAL "function" is a goto-based
# subprogram with a CALLER return-label variable, and every piece of
# per-call state lives in pre-allocated arrays indexed by the recursion
# depth D.  awk is used ONLY for character-level I/O work csh cannot do:
#   tok.awk    - tokenizer (once per input line)
#   split2.awk - split a collection into top-level elements (once per
#                collection that contains nesting or strings)
#   dec.awk    - decode before printing (once per output line)
#   strlib.awk / join.awk / wrap.awk - pr-str / str / prn / println
#   equal.awk  - deep equality when a hash-map (or vector) is involved
# Everything on the EVAL hot path - element access, classification,
# environment lookup, closure application, arithmetic - is pure array
# indexing, zero forks.
#
# Value representation (all mal values are plain, "safe" strings):
#   numbers/symbols/keywords  literal text
#   strings                   ZZQ<escaped body>ZZQ   (see tok.awk)
#   collections               (a b c)  [a b c]  {k v}
#   builtin functions         __CORE_<name>__
#   closures                  __FNC_<n>__  with FNPAR/FNBODY/FNENV[n]
#
# Arrays are pre-allocated by repeated doubling ($a:q $a:q ...), which is
# pure csh and costs no forks.  The flat element stores SPA/EVA use
# idx = (D-1)*256 + k; arithmetic is computed into a variable first because
# csh subscripts accept variables but not expressions.

set histchars=
# Disable filename expansion: mal atoms like * ? [ ] are data, and command
# substitution results must never be globbed.  Pattern matching (=~) is
# unaffected.
set noglob
# csh cannot detect EOF: "$<" returns "" for both a blank line and end of
# input, with $status always 0.  Re-read without re-prompting on an empty
# line and give up after a short run, so a closed pipe exits promptly.
@ blank = 0
set dir = "$0:h"
if ("$dir" == "$0") set dir = "."

set T = "/tmp/mal_csh_$$"
set awkprog = "$dir/mal.awk"

# ---- pre-allocated reader stack (indices 1..128) ----
set op = (0)
set op = ($op:q $op:q $op:q $op:q $op:q $op:q $op:q $op:q)
set op = ($op:q $op:q $op:q $op:q $op:q $op:q $op:q $op:q)
set op = ($op:q $op:q $op:q $op:q $op:q $op:q $op:q $op:q)
set buf = ($op:q)
set hd = ($op:q)
set wrap = ($op:q)
set wmeta = ($op:q)

# ---- flat element stores: stride 256, 128 depths -> 32768 slots ----
set SPA = (0)
set SPA = ($SPA:q $SPA:q $SPA:q $SPA:q $SPA:q $SPA:q $SPA:q $SPA:q)
set SPA = ($SPA:q $SPA:q $SPA:q $SPA:q $SPA:q $SPA:q $SPA:q $SPA:q)
set SPA = ($SPA:q $SPA:q $SPA:q $SPA:q $SPA:q $SPA:q $SPA:q $SPA:q)
set SPA = ($SPA:q $SPA:q $SPA:q $SPA:q $SPA:q $SPA:q $SPA:q $SPA:q)
set SPA = ($SPA:q $SPA:q $SPA:q $SPA:q $SPA:q $SPA:q $SPA:q $SPA:q)
set EVA = ($SPA:q)
# let* binding elements: stride 64 per depth (must not clobber SPA, which
# holds the let* form's own elements at the same depth)
set LBSPA = ($SPA:q)

# ---- eval state, indexed by depth D (indices 0..128) ----
set SPN = ($op:q)      # element count of the collection being evaled at D
set EVN = ($op:q)      # evaluated-element count at D
set EL_I = ($op:q)     # loop index at D
set COLL_CALLER = ($op:q)
set COLL_ENV = ($op:q)
set EOPEN = ($op:q)
set ECLOSE = ($op:q)
set DEFKEY = ($op:q)
set LETENV = ($op:q)
set LETK = ($op:q)
set LB_N = ($op:q)
set LB_I = ($op:q)

# ---- environments (up to 4096 bindings) ----
set ENV_OUTER = (0)
set ENV_OUTER = ($ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q)
set ENV_OUTER = ($ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q)
set ENV_OUTER = ($ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q)
set ENV_OUTER = ($ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q $ENV_OUTER:q)
set BKEY = ($ENV_OUTER:q)
set BVAL = ($ENV_OUTER:q)
set BENV = ($ENV_OUTER:q)
set DBGV = ($ENV_OUTER:q)
set DBG_ANY = 0
set BN = 0
set ENVN = 1
set ENV_OUTER[1] = 0

set ERR = 0
set ERRTARGET = REPL_PRINT
# TCO: TAILCALL=1 marks that the next goto EVAL is a tail position (the
# result of the form is the result of the enclosing frame), so EVAL_COLL
# may reuse the current frame instead of growing D.
set TAILCALL = 0
# BODYCACHE: a closure application is about to eval its body; the body has
# already been split at fn* definition time, so EVAL_COLL_SETUP copies the
# cached elements instead of re-splitting the string.
set BODYCACHE = 0

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

# ---- mal-defined core (none at this step) ----
set INIT_SRC = ()
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
    set TAILCALL = 0
    set ERR = 0
    set ERRTARGET = REPL_PRINT
    set CALLER = REPL_PRINT
    goto EVAL

REPL_PRINT:
    echo "$E_RESULT" | awk -v mode=dec -f "$awkprog"
    goto REPL_START

REPL_EXIT:
    exit 0

# ===================== READ subprogram =====================
# Entry: R_LINE.  Exit: read_result (or rerr); jumps to $RCALLER.
# All tokens are loaded into TKA with ONE awk invocation (tokens are
# ZZ-encoded and therefore contain no spaces, so word-splitting is exact).
READ:
    set read_result = ""
    set rerr = ""
    set TKA = (`echo "$R_LINE" | awk -v mode=tok -f $awkprog`)
    set ntok = $#TKA
    @ ti2 = 1
    while ($ti2 <= $ntok)
        set TKA[$ti2] = "$TKA[$ti2]:as/ZZSP/ /"
        @ ti2++
    end
    if ($ntok == 0) goto $RCALLER

    set d = 0
    @ i = 1
    while ($i <= $ntok)
        set tok = "$TKA[$i]"
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
# Classify E_AST with pure-csh globs; the { opener cannot appear in a glob
# pattern, so a hash is detected with a :s contains-check (the tokenizer
# never lets { appear inside an atom, so this is unambiguous).
EVAL:
    if ("$E_AST" =~ \(*) then
        set TCLASS = "list"
    else if ("$E_AST" =~ [[]*) then
        set TCLASS = "vector"
    else if ("$E_AST" =~ ZZQ*) then
        set TCLASS = "string"
    else if ("$E_AST" =~ :*) then
        set TCLASS = "keyword"
    else if ("$E_AST" =~ [0-9]* || "$E_AST" =~ -[0-9]*) then
        set TCLASS = "number"
    else
        set tmp = "$E_AST:s/{//"
        if ("$tmp" != "$E_AST") then
            set TCLASS = "hash"
        else
            set TCLASS = "symbol"
        endif
    endif

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
            echo "$E_AST" | awk -v mode=dec -f "$awkprog"
        endif
    endif
    if ("$TCLASS" == "list" || "$TCLASS" == "vector" || "$TCLASS" == "hash") goto EVAL_COLL
    if ("$TCLASS" == "string" || "$TCLASS" == "keyword" || "$TCLASS" == "number") goto EVAL_SELF
    goto EVAL_SYM

EVAL_ABORT:
    set D = 0
    set TAILCALL = 0
    goto $ERRTARGET

EVAL_SELF:
    set E_RESULT = "$E_AST"
    set TAILCALL = 0
    goto $CALLER

EVAL_SYM:
    set TAILCALL = 0
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
    # TCO: a tail-position goto EVAL (TAILCALL=1) reuses the current frame:
    # keep D and COLL_CALLER[D] (the tail return point), just re-initialise
    # the collection state below.  Non-tail evaluations always grow D.
    if ($TAILCALL == 1) then
        set TAILCALL = 0
        goto EVAL_COLL_SETUP
    endif
    @ D++
    set COLL_CALLER[$D] = "$CALLER"
EVAL_COLL_SETUP:
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
    set EVN[$D] = 0
    # A closure body whose split was cached at fn* time: copy it in.
    # Flat collections (no nesting, no strings) split in pure csh; anything
    # else goes through split2.awk (elements are ZZSP-encoded so a single
    # command substitution loads them exactly).  The delimiters are stripped
    # first, then the middle is checked for any remaining bracket or string.
    if ("$EOPEN[$D]" == "(") then
        set mid = "$E_AST:s/(//"
        set mid = "$mid:as/)//"
    else if ("$EOPEN[$D]" == "[") then
        set mid = "$E_AST:s/[//"
        set mid = "$mid:as/]//"
    else
        set mid = "$E_AST:s/{//"
        set mid = "$mid:as/}//"
    endif
    set tmp = "$mid:as/(//"
    if ("$tmp" == "$mid") then
        set tmp = "$mid:as/[//"
        if ("$tmp" == "$mid") then
            set tmp = "$mid:as/{//"
            if ("$tmp" == "$mid") then
                set tmp = "$mid:as/)//"
                if ("$tmp" == "$mid") then
                    set tmp = "$mid:as/]//"
                    if ("$tmp" == "$mid") then
                        set tmp = "$mid:as/}//"
                        if ("$tmp" == "$mid") then
                            set tmp = "$mid:as/ZZQ//"
                            if ("$tmp" == "$mid") goto SPLIT_FAST
                        endif
                    endif
                endif
            endif
        endif
    endif
    set SPL = (`echo "$E_AST" | awk -v mode=split2 -f $awkprog`)
    set SPN[$D] = $#SPL
    @ i = 1
    while ($i <= $SPN[$D])
        @ idx = ($D - 1) * 256 + $i
        set SPA[$idx] = "$SPL[$i]:as/ZZSP/ /"
        @ i++
    end
    goto EVAL_COLL_READY

SPLIT_FAST:
    set SPL = ($mid)
    set SPN[$D] = $#SPL
    @ i = 1
    while ($i <= $SPN[$D])
        @ idx = ($D - 1) * 256 + $i
        set SPA[$idx] = "$SPL[$i]"
        @ i++
    end

EVAL_COLL_READY:
    if ($SPN[$D] == 0) then
        set E_RESULT = "$EOPEN[$D]$ECLOSE[$D]"
        goto EVAL_RETURN
    endif
    if ("$EOPEN[$D]" != "(") goto EVAL_COLL_ELEMS
    @ idx = ($D - 1) * 256 + 1
    set FIRST = "$SPA[$idx]"
    if ("$FIRST" == "def!") goto EVAL_DEF
    if ("$FIRST" == "let*") goto EVAL_LET

EVAL_COLL_ELEMS:
    set EL_I[$D] = 0

EVAL_COLL_LOOP:
    @ EL_I[$D]++
    if ($EL_I[$D] > $SPN[$D]) goto EVAL_COLL_BUILD
    @ idx = ($D - 1) * 256 + $EL_I[$D]
    set ELEM = "$SPA[$idx]"
    # classify the element (pure csh)
    if ("$ELEM" =~ \(*) then
        set ec = "list"
    else if ("$ELEM" =~ [[]*) then
        set ec = "vector"
    else if ("$ELEM" =~ ZZQ*) then
        set ec = "string"
    else if ("$ELEM" =~ :*) then
        set ec = "keyword"
    else if ("$ELEM" =~ [0-9]* || "$ELEM" =~ -[0-9]*) then
        set ec = "number"
    else
        set tmp = "$ELEM:s/{//"
        if ("$tmp" != "$ELEM") then
            set ec = "hash"
        else
            set ec = "symbol"
        endif
    endif
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
    @ EVN[$D]++
    @ idx = ($D - 1) * 256 + $EVN[$D]
    set EVA[$idx] = "$E_RESULT"
    goto EVAL_COLL_LOOP

EVAL_COLL_BUILD:
    if ("$EOPEN[$D]" == "(") goto EVAL_APPLY
    set s = ""
    @ k = 1
    while ($k <= $EVN[$D])
        @ idx = ($D - 1) * 256 + $k
        if ($k == 1) then
            set s = "$EVA[$idx]"
        else
            set s = "$s $EVA[$idx]"
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
    @ idx = ($D - 1) * 256 + 2
    set DEFKEY[$D] = "$SPA[$idx]"
    @ idx = ($D - 1) * 256 + 3
    set E_AST = "$SPA[$idx]"
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
    @ idx = ($D - 1) * 256 + 2
    set bl = "$SPA[$idx]"
    # split the binding list (flat in practice; use the generic path)
    set mid = "$bl:s/(//"
    set mid = "$mid:as/)//"
    set tmp = "$mid:as/(//"
    if ("$tmp" == "$mid") then
        set tmp = "$mid:as/[//"
        if ("$tmp" == "$mid") then
            set tmp = "$mid:as/{//"
            if ("$tmp" == "$mid") then
                set tmp = "$mid:as/)//"
                if ("$tmp" == "$mid") then
                    set tmp = "$mid:as/]//"
                    if ("$tmp" == "$mid") then
                        set tmp = "$mid:as/}//"
                        if ("$tmp" == "$mid") then
                            set tmp = "$mid:as/ZZQ//"
                            if ("$tmp" == "$mid") goto LET_FAST
                        endif
                    endif
                endif
            endif
        endif
    endif
    set SPL = (`echo "$bl" | awk -v mode=split2 -f $awkprog`)
    set LB_N[$D] = $#SPL
    @ i = 1
    while ($i <= $LB_N[$D])
        @ idx = ($D - 1) * 64 + $i
        set LBSPA[$idx] = "$SPL[$i]:as/ZZSP/ /"
        @ i++
    end
    goto LET_READY
LET_FAST:
    set SPL = ($mid)
    set LB_N[$D] = $#SPL
    @ i = 1
    while ($i <= $LB_N[$D])
        @ idx = ($D - 1) * 64 + $i
        set LBSPA[$idx] = "$SPL[$i]"
        @ i++
    end
LET_READY:
    set LB_I[$D] = 0

EVAL_LET_LOOP:
    @ LB_I[$D]++
    if ($LB_I[$D] > $LB_N[$D]) goto EVAL_LET_BODY
    @ idx = ($D - 1) * 64 + $LB_I[$D]
    set LETK[$D] = "$LBSPA[$idx]"
    @ LB_I[$D]++
    @ idx = ($D - 1) * 64 + $LB_I[$D]
    set E_AST = "$LBSPA[$idx]"
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
    @ idx = ($D - 1) * 256 + 3
    set E_AST = "$SPA[$idx]"
    set E_ENV = "$LETENV[$D]"
    set CALLER = EVAL_RET
    goto EVAL

# ---- apply ----
EVAL_APPLY:
    @ idx = ($D - 1) * 256 + 1
    set FN = "$EVA[$idx]"
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

APPLY_ADD:
    @ idx = ($D - 1) * 256 + 2
    @ r = $EVA[$idx]
    @ k = 3
    while ($k <= $EVN[$D])
        @ idx = ($D - 1) * 256 + $k
        @ r = $r + $EVA[$idx]
        @ k++
    end
    set E_RESULT = "$r"
    goto EVAL_RETURN

APPLY_SUB:
    @ idx = ($D - 1) * 256 + 2
    @ r = $EVA[$idx]
    @ k = 3
    while ($k <= $EVN[$D])
        @ idx = ($D - 1) * 256 + $k
        @ r = $r - $EVA[$idx]
        @ k++
    end
    set E_RESULT = "$r"
    goto EVAL_RETURN

APPLY_MUL:
    @ idx = ($D - 1) * 256 + 2
    @ r = $EVA[$idx]
    @ k = 3
    while ($k <= $EVN[$D])
        @ idx = ($D - 1) * 256 + $k
        @ r = $r * $EVA[$idx]
        @ k++
    end
    set E_RESULT = "$r"
    goto EVAL_RETURN

APPLY_DIV:
    @ idx = ($D - 1) * 256 + 2
    @ r = $EVA[$idx]
    @ k = 3
    while ($k <= $EVN[$D])
        @ idx = ($D - 1) * 256 + $k
        @ r = $r / $EVA[$idx]
        @ k++
    end
    set E_RESULT = "$r"
    goto EVAL_RETURN

APPLY_LIST:
    set s = ""
    @ k = 2
    while ($k <= $EVN[$D])
        @ idx = ($D - 1) * 256 + $k
        if ($k == 2) then
            set s = "$EVA[$idx]"
        else
            set s = "$s $EVA[$idx]"
        endif
        @ k++
    end
    set E_RESULT = "($s)"
    goto EVAL_RETURN

APPLY_LISTP:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    if ("$a1" =~ \(*) then
        set E_RESULT = "true"
    else
        set E_RESULT = "false"
    endif
    goto EVAL_RETURN

# ---- scratch splitter ----
# Input: a1 (a collection string).  Output: SPL + SCNT.  Jumps to $SPLIT_CALLER.
# Uses only the SPL temp, never the depth-indexed SPA, so it is safe to call
# from core functions while a collection is being evaluated.
SPLIT_SCRATCH:
    if ("$a1" =~ \(*) then
        set mid = "$a1:s/(//"
        set mid = "$mid:as/)//"
    else if ("$a1" =~ [[]*) then
        set mid = "$a1:s/[//"
        set mid = "$mid:as/]//"
    else
        set tmp = "$a1:s/{//"
        if ("$tmp" != "$a1") then
            set mid = "$a1:s/{//"
            set mid = "$mid:as/}//"
        else
            # not a collection: zero elements
            set SCNT = 0
            goto $SPLIT_CALLER
        endif
    endif
    set tmp = "$mid:as/(//"
    if ("$tmp" == "$mid") then
        set tmp = "$mid:as/[//"
        if ("$tmp" == "$mid") then
            set tmp = "$mid:as/{//"
            if ("$tmp" == "$mid") then
                set tmp = "$mid:as/)//"
                if ("$tmp" == "$mid") then
                    set tmp = "$mid:as/]//"
                    if ("$tmp" == "$mid") then
                        set tmp = "$mid:as/}//"
                        if ("$tmp" == "$mid") then
                            set tmp = "$mid:as/ZZQ//"
                            if ("$tmp" == "$mid") goto SPLIT_SCRATCH_FAST
                        endif
                    endif
                endif
            endif
        endif
    endif
    set SPL = (`echo "$a1" | awk -v mode=split2 -f $awkprog`)
    set SCNT = $#SPL
    goto $SPLIT_CALLER
SPLIT_SCRATCH_FAST:
    set SPL = ($mid)
    set SCNT = $#SPL
    goto $SPLIT_CALLER

APPLY_EMPTYP:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    if ("$a1" == "nil") then
        set E_RESULT = "true"
        goto EVAL_RETURN
    endif
    set SPLIT_CALLER = EMPTYP_DONE
    goto SPLIT_SCRATCH
EMPTYP_DONE:
    if ($SCNT == 0) then
        set E_RESULT = "true"
    else
        set E_RESULT = "false"
    endif
    goto EVAL_RETURN

APPLY_COUNT:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    if ("$a1" == "nil") then
        set E_RESULT = "0"
        goto EVAL_RETURN
    endif
    set SPLIT_CALLER = COUNT_DONE
    goto SPLIT_SCRATCH
COUNT_DONE:
    set E_RESULT = "$SCNT"
    goto EVAL_RETURN

APPLY_EQ:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    @ idx = ($D - 1) * 256 + 3
    set a2 = "$EVA[$idx]"
    # Pure string equality is exact for atoms and for lists/vectors built
    # from canonical serialization.  Hash-maps and vectors need the
    # string-aware comparison in equal.awk (order-insensitive keys,
    # [..] vs (..) equivalence).
    set tmp = "$a1:as/[//"
    if ("$tmp" == "$a1") then
        set tmp = "$a1:as/{//"
        if ("$tmp" == "$a1") then
            set tmp = "$a2:as/[//"
            if ("$tmp" == "$a2") then
                set tmp = "$a2:as/{//"
                if ("$tmp" == "$a2") then
                    if ("$a1" == "$a2") then
                        set E_RESULT = "true"
                    else
                        set E_RESULT = "false"
                    endif
                    goto EVAL_RETURN
                endif
            endif
        endif
    endif
    echo "$a1" > "$T.eq"
    echo "$a2" >> "$T.eq"
    set E_RESULT = "`awk -v mode=equal -f $awkprog $T.eq`"
    goto EVAL_RETURN

APPLY_LT:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    @ idx = ($D - 1) * 256 + 3
    set a2 = "$EVA[$idx]"
    @ x = $a1
    @ y = $a2
    if ($x < $y) then
        set E_RESULT = "true"
    else
        set E_RESULT = "false"
    endif
    goto EVAL_RETURN

APPLY_LE:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    @ idx = ($D - 1) * 256 + 3
    set a2 = "$EVA[$idx]"
    @ x = $a1
    @ y = $a2
    if ($x <= $y) then
        set E_RESULT = "true"
    else
        set E_RESULT = "false"
    endif
    goto EVAL_RETURN

APPLY_GT:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    @ idx = ($D - 1) * 256 + 3
    set a2 = "$EVA[$idx]"
    @ x = $a1
    @ y = $a2
    if ($x > $y) then
        set E_RESULT = "true"
    else
        set E_RESULT = "false"
    endif
    goto EVAL_RETURN

APPLY_GE:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    @ idx = ($D - 1) * 256 + 3
    set a2 = "$EVA[$idx]"
    @ x = $a1
    @ y = $a2
    if ($x >= $y) then
        set E_RESULT = "true"
    else
        set E_RESULT = "false"
    endif
    goto EVAL_RETURN

# ---- pr-str / str / prn / println ----
# Dump the evaluated args to $T.elv.$D (echo is a csh builtin: no forks),
# then let the awk helpers do the string-aware joining/escaping.
APPLY_PRSTR:
    echo -n "" > "$T.elv.$D"
    @ k = 1
    while ($k <= $EVN[$D])
        @ idx = ($D - 1) * 256 + $k
        echo "$EVA[$idx]" >> "$T.elv.$D"
        @ k++
    end
    awk -v mode=join -v jmode=1 -f "$awkprog" "$T.elv.$D" > "$T.j"
    set E_RESULT = "`awk -v mode=wrap -v esc=1 -f $awkprog $T.j`"
    goto EVAL_RETURN

APPLY_STR:
    echo -n "" > "$T.elv.$D"
    @ k = 1
    while ($k <= $EVN[$D])
        @ idx = ($D - 1) * 256 + $k
        echo "$EVA[$idx]" >> "$T.elv.$D"
        @ k++
    end
    awk -v mode=join -v jmode=2 -f "$awkprog" "$T.elv.$D" > "$T.j"
    set E_RESULT = "`awk -v mode=wrap -v esc=0 -f $awkprog $T.j`"
    goto EVAL_RETURN

APPLY_PRN:
    echo -n "" > "$T.elv.$D"
    @ k = 1
    while ($k <= $EVN[$D])
        @ idx = ($D - 1) * 256 + $k
        echo "$EVA[$idx]" >> "$T.elv.$D"
        @ k++
    end
    awk -v mode=join -v jmode=1 -f "$awkprog" "$T.elv.$D" | awk -v mode=dec -f "$awkprog"
    set E_RESULT = "nil"
    goto EVAL_RETURN

APPLY_PRINTLN:
    echo -n "" > "$T.elv.$D"
    @ k = 1
    while ($k <= $EVN[$D])
        @ idx = ($D - 1) * 256 + $k
        echo "$EVA[$idx]" >> "$T.elv.$D"
        @ k++
    end
    awk -v mode=join -v jmode=3 -f "$awkprog" "$T.elv.$D" | awk -v mode=dec -f "$awkprog"
    set E_RESULT = "nil"
    goto EVAL_RETURN
