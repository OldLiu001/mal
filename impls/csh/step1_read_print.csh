#!/bin/csh -f
# mal step1: read and print (no evaluation).
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
    set E_RESULT = "$read_result"
    goto REPL_PRINT

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
