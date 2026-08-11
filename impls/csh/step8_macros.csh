#!/bin/csh -f
# mal step8: step7 + defmacro! / macroexpand / macro?
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

# ---- closures (up to 256) + cached param/body element arrays ----
set FNPAR = ($op:q)
set FNBODY = ($op:q)
set FNENV = ($op:q)
set FNISM = ($op:q)    # 1 when closure n is a macro
set FNPARN = ($op:q)   # param element count of closure n
set FNBB = ($op:q)     # body element count of closure n
set FNN = 0
# cached splits: stride 64 per closure
set FNA_P = (0)
set FNA_P = ($FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q)
set FNA_P = ($FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q)
set FNA_P = ($FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q)
set FNA_P = ($FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q)
set FNA_P = ($FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q $FNA_P:q)
set FNA_B = ($FNA_P:q)

# ---- quasiquote state stack (up to 64 levels) ----
set QQS_RES = ($op:q)
set QQS_CALLER = ($op:q)
set QQS_RR = ($op:q)

# ---- atoms (up to 512) ----
set ATMID = ($op:q)
set ATMV = ($op:q)
set ATOMN = 0

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
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "read-string"; set BVAL[$BN] = "__CORE_readstring__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "slurp";      set BVAL[$BN] = "__CORE_slurp__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "atom";       set BVAL[$BN] = "__CORE_atom__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "atom?";      set BVAL[$BN] = "__CORE_atomp__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "deref";      set BVAL[$BN] = "__CORE_deref__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "reset!";     set BVAL[$BN] = "__CORE_reset__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "swap!";      set BVAL[$BN] = "__CORE_swap__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "load-file";  set BVAL[$BN] = "__CORE_loadfile__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "eval";       set BVAL[$BN] = "__CORE_eval__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "cons";       set BVAL[$BN] = "__CORE_cons__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "concat";     set BVAL[$BN] = "__CORE_concat__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "vec";        set BVAL[$BN] = "__CORE_vec__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "macro?";     set BVAL[$BN] = "__CORE_macrop__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "nth";        set BVAL[$BN] = "__CORE_nth__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "first";      set BVAL[$BN] = "__CORE_first__"
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "rest";       set BVAL[$BN] = "__CORE_rest__"

# ---- *ARGV*: the command-line arguments as a list of strings ----
set ARGVSTR = ""
@ ai = 1
while ($ai <= $#argv)
    set enc = "$argv[$ai]"
    set enc = "$enc:as/\\/ZZB/"
    set enc = "$enc:as/\"/ZZQ/"
    set enc = "$enc:as/\`/ZZT/"
    if ($ai == 1) then
        set ARGVSTR = "ZZQ$encZZQ"
    else
        set ARGVSTR = "$ARGVSTR ZZQ$encZZQ"
    endif
    @ ai++
end
@ BN++; set BENV[$BN] = 1; set BKEY[$BN] = "*ARGV*";     set BVAL[$BN] = "($ARGVSTR)"
set LD_STARTUP = 0

# ---- mal-defined core ----
set INIT_SRC = ("(def! not (fn* (a) (if a false true)))" \
"(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) nil) (cons 'cond (rest (rest xs)))))))")
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
    # with a file argument, load it first (like the official `run file`)
    if ($LD_STARTUP == 0 && $#argv > 0) then
        set LD_STARTUP = 1
        set TKA = (`awk -v mode=filetok -f $awkprog "$argv[1]"`)
        set ntok = $#TKA
        set TI = 1
        set RCALLER = LOAD_FORM_DONE
        if ($ntok > 0) goto PARSE_ONE
    endif
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
    if ("$E_RESULT" =~ *__ATM_*) then
        echo "$E_RESULT" | awk -v mode=atom -v afile="$T.atoms" -f $awkprog | awk -v mode=dec -f $awkprog
    else
        echo "$E_RESULT" | awk -v mode=dec -f $awkprog
    endif
    goto REPL_START

REPL_EXIT:
    exit 0

# ===================== READ subprogram =====================
# Entry: R_LINE.  Exit: read_result (or rerr); jumps to $RCALLER.
# All tokens are loaded into TKA with ONE awk invocation (tokens are
# ZZ-encoded and therefore contain no spaces, so word-splitting is exact).
# The parser is token-index based (TI/ntok) so load-file can parse and eval
# several forms from one token stream, one at a time.
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
    set TI = 1
    if ($ntok == 0) goto $RCALLER

PARSE_ONE:
    set read_result = ""
    set rerr = ""
    set d = 0
    while ($TI <= $ntok)
        set tok = "$TKA[$TI]"
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
        @ TI++
    end
    if ("$read_result" != "") @ TI++
    goto $RCALLER

# ===================== EVAL subprogram =====================
# Classify E_AST with pure-csh globs; the { opener cannot appear in a glob
# pattern, so a hash is detected with a :s contains-check (the tokenizer
# never lets { appear inside an atom, so this is unambiguous).
EVAL:
    if ("$E_AST" =~ __ATM_*) then
        set TCLASS = "atom"
        goto EVAL_SELF
    endif
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
            echo "$E_AST" | awk -v mode=dec -f $awkprog
        endif
    endif
    if ("$TCLASS" == "list" || "$TCLASS" == "vector" || "$TCLASS" == "hash") goto EVAL_COLL
    if ("$TCLASS" == "string" || "$TCLASS" == "keyword" || "$TCLASS" == "number") goto EVAL_SELF
    goto EVAL_SYM

EVAL_ABORT:
    set D = 0
    set TAILCALL = 0
    set BODYCACHE = 0
    goto $ERRTARGET

EVAL_SELF:
    set E_RESULT = "$E_AST"
    set TAILCALL = 0
    set BODYCACHE = 0
    goto $CALLER

EVAL_SYM:
    set TAILCALL = 0
    set BODYCACHE = 0
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
    if ($BODYCACHE > 0) then
        set fidx = $BODYCACHE
        set BODYCACHE = 0
        set SPN[$D] = $FNBB[$fidx]
        @ i = 1
        while ($i <= $SPN[$D])
            @ idx = ($fidx - 1) * 64 + $i
            @ sidx = ($D - 1) * 256 + $i
            set SPA[$sidx] = "$FNA_B[$idx]"
            @ i++
        end
        goto EVAL_COLL_READY
    endif
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
    # macro expansion: a list whose head resolves to a macro closure is
    # expanded (macro applied to the UNEVALUATED arguments) and the
    # expansion is evaluated in place
    if ("$FIRST" !~ [0-9]* && "$FIRST" !~ :* && "$FIRST" !~ ZZQ* && \
        "$FIRST" !~ \(* && "$FIRST" !~ [[]* && "$FIRST" != "nil" && \
        "$FIRST" != "true" && "$FIRST" != "false") then
        set ge = $COLL_ENV[$D]
        set mfound = 0
        while ($ge != 0)
            @ bi = $BN
            while ($bi > 0)
                if ("$BENV[$bi]" == "$ge" && "$BKEY[$bi]" == "$FIRST") then
                    set mval = "$BVAL[$bi]"
                    set mfound = 1
                    break
                endif
                @ bi--
            end
            if ($mfound == 1) break
            set ge = $ENV_OUTER[$ge]
        end
        if ($mfound == 1) then
            if ("$mval" =~ __FNC_*) then
                set fidx = "$mval:s/__FNC_//"
                set fidx = "$fidx:s/__//"
                @ fidx = $fidx
                if ($FNISM[$fidx] == 1) then
                    set mf = $fidx
                    goto EVAL_MACRO
                endif
            endif
        endif
    endif
    if ("$FIRST" == "def!") goto EVAL_DEF
    if ("$FIRST" == "let*") goto EVAL_LET
    if ("$FIRST" == "if") goto EVAL_IF
    if ("$FIRST" == "do") goto EVAL_DO
    if ("$FIRST" == "fn*") goto EVAL_FN
    if ("$FIRST" == "quote") goto EVAL_QUOTE
    if ("$FIRST" == "quasiquote") goto EVAL_QQ
    if ("$FIRST" == "defmacro!") goto EVAL_DEFMACRO
    if ("$FIRST" == "macroexpand") goto EVAL_MACROEXPAND

EVAL_COLL_ELEMS:
    set EL_I[$D] = 0

EVAL_COLL_LOOP:
    @ EL_I[$D]++
    if ($EL_I[$D] > $SPN[$D]) goto EVAL_COLL_BUILD
    @ idx = ($D - 1) * 256 + $EL_I[$D]
    set ELEM = "$SPA[$idx]"
    # classify the element (pure csh)
    if ("$ELEM" =~ __ATM_*) then
        set ec = "atom"
        goto EVAL_COLL_ATOM
    endif
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

EVAL_COLL_ATOM:
    set E_RESULT = "$ELEM"
    goto EVAL_COLL_STORE

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
    set TAILCALL = 1
    goto EVAL

# ---- special form: if ----
EVAL_IF:
    @ idx = ($D - 1) * 256 + 2
    set E_AST = "$SPA[$idx]"
    set E_ENV = "$COLL_ENV[$D]"
    set CALLER = EVAL_IF_TEST
    goto EVAL

EVAL_IF_TEST:
    if ($ERR == 1) goto EVAL_ABORT
    if ("$E_RESULT" == "nil" || "$E_RESULT" == "false") then
        if ($SPN[$D] < 4) then
            set E_RESULT = "nil"
            goto EVAL_RETURN
        endif
        @ idx = ($D - 1) * 256 + 4
        set E_AST = "$SPA[$idx]"
    else
        @ idx = ($D - 1) * 256 + 3
        set E_AST = "$SPA[$idx]"
    endif
    set E_ENV = "$COLL_ENV[$D]"
    set CALLER = EVAL_RET
    set TAILCALL = 1
    goto EVAL

# ---- special form: do ----
EVAL_DO:
    set EL_I[$D] = 1

EVAL_DO_LOOP:
    @ EL_I[$D]++
    if ($EL_I[$D] > $SPN[$D]) then
        set E_RESULT = "nil"
        goto EVAL_RETURN
    endif
    @ idx = ($D - 1) * 256 + $EL_I[$D]
    set E_AST = "$SPA[$idx]"
    set E_ENV = "$COLL_ENV[$D]"
    if ($EL_I[$D] == $SPN[$D]) then
        set CALLER = EVAL_RET
        set TAILCALL = 1
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
    @ idx = ($D - 1) * 256 + 2
    set FNPAR[$FNN] = "$SPA[$idx]"
    @ idx = ($D - 1) * 256 + 3
    set FNBODY[$FNN] = "$SPA[$idx]"
    set FNENV[$FNN] = "$COLL_ENV[$D]"
    # cache the param split (flat in practice; generic path for safety)
    set pstr = "$FNPAR[$FNN]"
    set mid = "$pstr:s/(//"
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
                            if ("$tmp" == "$mid") goto FNPAR_FAST
                        endif
                    endif
                endif
            endif
        endif
    endif
    set SPL = (`echo "$pstr" | awk -v mode=split2 -f $awkprog`)
    set FNPARN[$FNN] = $#SPL
    @ i = 1
    while ($i <= $FNPARN[$FNN])
        @ idx = ($FNN - 1) * 64 + $i
        set FNA_P[$idx] = "$SPL[$i]:as/ZZSP/ /"
        @ i++
    end
    goto FN_BODY
FNPAR_FAST:
    set SPL = ($mid)
    set FNPARN[$FNN] = $#SPL
    @ i = 1
    while ($i <= $FNPARN[$FNN])
        @ idx = ($FNN - 1) * 64 + $i
        set FNA_P[$idx] = "$SPL[$i]"
        @ i++
    end
FN_BODY:
    # cache the body split
    set bstr = "$FNBODY[$FNN]"
    set mid = "$bstr:s/(//"
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
                            if ("$tmp" == "$mid") goto FNBODY_FAST
                        endif
                    endif
                endif
            endif
        endif
    endif
    set SPL = (`echo "$bstr" | awk -v mode=split2 -f $awkprog`)
    set FNBB[$FNN] = $#SPL
    @ i = 1
    while ($i <= $FNBB[$FNN])
        @ idx = ($FNN - 1) * 64 + $i
        set FNA_B[$idx] = "$SPL[$i]:as/ZZSP/ /"
        @ i++
    end
    goto FN_DONE
FNBODY_FAST:
    set SPL = ($mid)
    set FNBB[$FNN] = $#SPL
    @ i = 1
    while ($i <= $FNBB[$FNN])
        @ idx = ($FNN - 1) * 64 + $i
        set FNA_B[$idx] = "$SPL[$i]"
        @ i++
    end
FN_DONE:
    set E_RESULT = "__FNC_${FNN}__"
    goto EVAL_RETURN

# ---- special form: defmacro! ----
EVAL_DEFMACRO:
    @ idx = ($D - 1) * 256 + 2
    set DEFKEY[$D] = "$SPA[$idx]"
    @ idx = ($D - 1) * 256 + 3
    set E_AST = "$SPA[$idx]"
    set E_ENV = "$COLL_ENV[$D]"
    set CALLER = EVAL_DEFMACRO_DONE
    goto EVAL
EVAL_DEFMACRO_DONE:
    if ($ERR == 1) goto EVAL_ABORT
    # the value must be a closure; it is CLONED so the original function
    # is not mutated into a macro, then the clone is marked and bound
    if ("$E_RESULT" !~ __FNC_*) then
        set E_RESULT = "Error: defmacro! value is not a function"
        set ERR = 1
        goto EVAL_ABORT
    endif
    set fidx = "$E_RESULT:s/__FNC_//"
    set fidx = "$fidx:s/__//"
    @ fidx = $fidx
    @ FNN++
    set FNPAR[$FNN] = "$FNPAR[$fidx]"
    set FNBODY[$FNN] = "$FNBODY[$fidx]"
    set FNENV[$FNN] = "$FNENV[$fidx]"
    set FNISM[$FNN] = 1
    set FNPARN[$FNN] = "$FNPARN[$fidx]"
    set FNBB[$FNN] = "$FNBB[$fidx]"
    @ i = 1
    while ($i <= 64)
        @ s1 = ($fidx - 1) * 64 + $i
        @ s2 = ($FNN - 1) * 64 + $i
        set FNA_P[$s2] = "$FNA_P[$s1]"
        set FNA_B[$s2] = "$FNA_B[$s1]"
        @ i++
    end
    set E_RESULT = "__FNC_${FNN}__"
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
    set E_RESULT = "$eval_v"
    goto EVAL_RETURN

# ---- macro expansion ----
# Entry: mf = the closure id, D = the call frame whose SPA holds the
# unevaluated arguments.  The macro is applied to the raw argument forms;
# the expansion is then evaluated in place.
EVAL_MACRO:
    @ pd = $D
    @ D++
    set COLL_CALLER[$D] = MACRO_EXPANDED
    set COLL_ENV[$D] = "$COLL_ENV[$pd]"
    set EVN[$D] = 0
    @ i = 1
    @ pn = $SPN[$pd]
    while ($i <= $pn)
        @ idx = ($D - 1) * 256 + $i
        @ sidx = ($pd - 1) * 256 + $i
        set EVA[$idx] = "$SPA[$sidx]"
        @ EVN[$D]++
        @ i++
    end
    set fidx = $mf
    goto APPLY_CLOSURE
MACRO_EXPANDED:
    if ($ERR == 1) goto EVAL_ABORT
    set E_AST = "$E_RESULT"
    set E_ENV = "$COLL_ENV[$D]"
    set CALLER = MACRO_RET
    goto EVAL
MACRO_RET:
    if ($ERR == 1) goto EVAL_ABORT
    goto EVAL_RETURN

# ---- special form: macroexpand ----
EVAL_MACROEXPAND:
    @ idx = ($D - 1) * 256 + 2
    set E_AST = "$SPA[$idx]"
    # only lists with a macro head are expanded; everything else is
    # returned unchanged
    if ("$E_AST" !~ \(*) then
        set E_RESULT = "$E_AST"
        goto EVAL_RETURN
    endif
    set a1 = "$E_AST"
    set SPLIT_CALLER = MEXP_SPLIT
    goto SPLIT_SCRATCH
MEXP_SPLIT:
    if ($SCNT == 0) then
        set E_RESULT = "$E_AST"
        goto EVAL_RETURN
    endif
    set MEXP_FIRST = "$SPL[1]"
    set ge = $COLL_ENV[$D]
    set mfound = 0
    while ($ge != 0)
        @ bi = $BN
        while ($bi > 0)
            if ("$BENV[$bi]" == "$ge" && "$BKEY[$bi]" == "$MEXP_FIRST") then
                set mval = "$BVAL[$bi]"
                set mfound = 1
                break
            endif
            @ bi--
        end
        if ($mfound == 1) break
        set ge = $ENV_OUTER[$ge]
    end
    if ($mfound == 0) then
        set E_RESULT = "$E_AST"
        goto EVAL_RETURN
    endif
    if ("$mval" !~ __FNC_*) then
        set E_RESULT = "$E_AST"
        goto EVAL_RETURN
    endif
    set fidx = "$mval:s/__FNC_//"
    set fidx = "$fidx:s/__//"
    @ fidx = $fidx
    if ($FNISM[$fidx] != 1) then
        set E_RESULT = "$E_AST"
        goto EVAL_RETURN
    endif
    # apply the macro to the raw argument forms; the result (the expansion)
    # is returned WITHOUT re-evaluating it
    set mf = $fidx
    @ pd = $D
    @ D++
    set COLL_CALLER[$D] = MEXP_APPLY_DONE
    set COLL_ENV[$D] = "$COLL_ENV[$pd]"
    set EVN[$D] = 0
    @ i = 1
    while ($i <= $SCNT)
        @ idx = ($D - 1) * 256 + $i
        set EVA[$idx] = "$SPL[$i]"
        @ EVN[$D]++
        @ i++
    end
    set fidx = $mf
    goto APPLY_CLOSURE
MEXP_APPLY_DONE:
    if ($ERR == 1) goto EVAL_ABORT
    goto EVAL_RETURN

# ---- special form: quote ----
EVAL_QUOTE:
    @ idx = ($D - 1) * 256 + 2
    set E_RESULT = "$SPA[$idx]"
    goto EVAL_RETURN

# ---- special form: quasiquote ----
# The standard algorithm, driven explicitly: each (qq x) sub-result is
# evaluated through the normal EVAL machinery (quote / cons / concat /
# unquote-value are all evaluated forms), and the recursion uses an
# explicit QQ stack instead of mal-level recursion.
EVAL_QQ:
    @ idx = ($D - 1) * 256 + 2
    set QQAST = "$SPA[$idx]"
    set QQCALLER = QQ_DONE
    set QQN = 0
    goto QQ_LOOP
QQ_DONE:
    goto EVAL_RETURN

QQ_LOOP:
    # vectors: process the elements as a list and wrap the result in vec
    if ("$QQAST" =~ [[]*) then
        echo "$QQAST" | awk -v mode=strip -f $awkprog > "$T.qqv"
        set tmp = "`cat $T.qqv`"
        @ QQN++
        set QQS_CALLER[$QQN] = "$QQCALLER"
        set QQAST = "($tmp)"
        set QQCALLER = QQ_VEC_INNER_DONE
        goto QQ_LOOP
    endif
    # not a list (atom, string, keyword, number, hash-map) -> (quote ast)
    set tmp = "$QQAST:as/(//"
    if ("$tmp" == "$QQAST") then
        set E_AST = "(quote $QQAST)"
        set CALLER = "$QQCALLER"
        goto EVAL
    endif
    set a1 = "$QQAST"
    set SPLIT_CALLER = QQ_SPLIT_DONE
    goto SPLIT_SCRATCH
QQ_SPLIT_DONE:
    if ($SCNT == 0) then
        set E_AST = "(quote ())"
        set CALLER = "$QQCALLER"
        goto EVAL
    endif
    set QQFIRST = "$SPL[1]"
    if ("$QQFIRST" == "unquote") then
        set E_AST = "$SPL[2]"
        set CALLER = "$QQCALLER"
        goto EVAL
    endif
    # splice-unquote at the head of this list: save the rest of THIS list
    # first (a scratch split of the head would clobber SPL), then extract
    # the splice value from the head
    if ("$QQFIRST" =~ "(splice-unquote"*) then
        set qrest = ""
        @ qi = 2
        while ($qi <= $SCNT)
            if ($qi == 2) then
                set qrest = "$SPL[$qi]"
            else
                set qrest = "$qrest $SPL[$qi]"
            endif
            @ qi++
        end
        set a1 = "$QQFIRST"
        set SPLIT_CALLER = QQ_HEAD_SPLIT
        goto SPLIT_SCRATCH
    endif
    goto QQ_CONS
QQ_HEAD_SPLIT:
    if ($SCNT < 2) then
        set E_RESULT = "Error: splice-unquote needs an argument"
        set ERR = 1
        goto EVAL_ABORT
    endif
    # (concat <evaluated-splice> (qq rest)): evaluate the splice argument
    # first, then qq the rest
    @ QQN++
    set QQS_RES[$QQN] = "$SPL[2]"
    set QQS_CALLER[$QQN] = "$QQCALLER"
    set E_AST = "$SPL[2]"
    set CALLER = QQ_SPLICE_EVAL_DONE
    goto EVAL
QQ_SPLICE_EVAL_DONE:
    if ($ERR == 1) goto EVAL_ABORT
    set QQS_RES[$QQN] = "$E_RESULT"
    set QQAST = "($qrest)"
    set QQCALLER = QQ_SPLICE_DONE
    goto QQ_LOOP

QQ_CONS:
    # (cons (qq first) (qq rest))
    @ QQN++
    set QQS_RES[$QQN] = "$QQFIRST"
    set QQS_CALLER[$QQN] = "$QQCALLER"
    set qrest = ""
    @ qi = 2
    while ($qi <= $SCNT)
        if ($qi == 2) then
            set qrest = "$SPL[$qi]"
        else
            set qrest = "$qrest $SPL[$qi]"
        endif
        @ qi++
    end
    set QQAST = "($qrest)"
    set QQCALLER = QQ_CONS_REST_DONE
    goto QQ_LOOP
QQ_SPLICE_DONE:
    set QQR = "$E_RESULT"
    set QQCALLER = "$QQS_CALLER[$QQN]"
    set QQSPL = "$QQS_RES[$QQN]"
    @ QQN--
    set E_AST = "(concat (quote $QQSPL) (quote $QQR))"
    set CALLER = "$QQCALLER"
    goto EVAL
QQ_CONS_REST_DONE:
    set QQS_RR[$QQN] = "$E_RESULT"
    set QQHEAD = "$QQS_RES[$QQN]"
    set QQAST = "$QQHEAD"
    set QQCALLER = QQ_CONS_HEAD_DONE
    goto QQ_LOOP
QQ_CONS_HEAD_DONE:
    set QQH = "$E_RESULT"
    set QQR = "$QQS_RR[$QQN]"
    set QQCALLER = "$QQS_CALLER[$QQN]"
    @ QQN--
    set E_AST = "(cons (quote $QQH) (quote $QQR))"
    set CALLER = "$QQCALLER"
    goto EVAL

# ---- apply ----
EVAL_APPLY:
    @ idx = ($D - 1) * 256 + 1
    set FN = "$EVA[$idx]"
    if ("$FN" =~ __FNC_*) then
        set fidx = "$FN:s/__FNC_//"
        set fidx = "$fidx:s/__//"
        @ fidx = $fidx
        goto APPLY_CLOSURE
    endif
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
    if ("$FN" == "__CORE_readstring__") goto APPLY_READSTRING
    if ("$FN" == "__CORE_slurp__") goto APPLY_SLURP
    if ("$FN" == "__CORE_atom__") goto APPLY_ATOM
    if ("$FN" == "__CORE_atomp__") goto APPLY_ATOMP
    if ("$FN" == "__CORE_deref__") goto APPLY_DEREF
    if ("$FN" == "__CORE_reset__") goto APPLY_RESET
    if ("$FN" == "__CORE_swap__") goto APPLY_SWAP
    if ("$FN" == "__CORE_loadfile__") goto APPLY_LOADFILE
    if ("$FN" == "__CORE_eval__") goto APPLY_EVAL
    if ("$FN" == "__CORE_cons__") goto APPLY_CONS
    if ("$FN" == "__CORE_concat__") goto APPLY_CONCAT
    if ("$FN" == "__CORE_vec__") goto APPLY_VEC
    if ("$FN" == "__CORE_macrop__") goto APPLY_MACROP
    if ("$FN" == "__CORE_nth__") goto APPLY_NTH
    if ("$FN" == "__CORE_first__") goto APPLY_FIRST
    if ("$FN" == "__CORE_rest__") goto APPLY_REST
    set E_RESULT = "Error: '$FN' is not a function"
    set ERR = 1
    goto EVAL_ABORT

APPLY_CLOSURE:
    # TCO: a tail call (the enclosing frame returns straight to a tail
    # position) reuses the current environment and frame instead of
    # allocating a new env and growing D.  Parameters are bound with
    # bind-or-overwrite so the reused env does not accumulate bindings.
    if ("$COLL_CALLER[$D]" == "EVAL_RET") then
        set nenv = "$COLL_ENV[$D]"
        set TAILCALL = 1
    else
        @ ENVN++
        set nenv = $ENVN
        set ENV_OUTER[$nenv] = "$FNENV[$fidx]"
    endif
    set pn = $FNPARN[$fidx]
    @ pi = 1
    @ ai = 2
    while ($pi <= $pn)
        @ pidx = ($fidx - 1) * 64 + $pi
        set pk = "$FNA_P[$pidx]"
        if ("$pk" == "&") then
            @ pi++
            @ pidx = ($fidx - 1) * 64 + $pi
            set pk = "$FNA_P[$pidx]"
            set rest = ""
            while ($ai <= $EVN[$D])
                @ aidx = ($D - 1) * 256 + $ai
                if ("$rest" == "") then
                    set rest = "$EVA[$aidx]"
                else
                    set rest = "$rest $EVA[$aidx]"
                endif
                @ ai++
            end
            set bval = "($rest)"
            @ bi = 0
            set bfound = 0
            while ($bi < $BN)
                @ bi++
                if ("$BENV[$bi]" == "$nenv" && "$BKEY[$bi]" == "$pk") then
                    set BVAL[$bi] = "$bval"
                    set bfound = 1
                    break
                endif
            end
            if ($bfound == 0) then
                @ BN++
                set BENV[$BN] = "$nenv"
                set BKEY[$BN] = "$pk"
                set BVAL[$BN] = "$bval"
            endif
            break
        endif
        @ aidx = ($D - 1) * 256 + $ai
        set bval = "$EVA[$aidx]"
        @ bi = 0
        set bfound = 0
        while ($bi < $BN)
            @ bi++
            if ("$BENV[$bi]" == "$nenv" && "$BKEY[$bi]" == "$pk") then
                set BVAL[$bi] = "$bval"
                set bfound = 1
                break
            endif
        end
        if ($bfound == 0) then
            @ BN++
            set BENV[$BN] = "$nenv"
            set BKEY[$BN] = "$pk"
            set BVAL[$BN] = "$bval"
        endif
        @ ai++
        @ pi++
    end
    set BODYCACHE = $fidx
    set E_AST = "$FNBODY[$fidx]"
    set E_ENV = $nenv
    set CALLER = EVAL_RET
    goto EVAL

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
    @ i = 1
    while ($i <= $SCNT)
        set SPL[$i] = "$SPL[$i]:as/ZZSP/ /"
        @ i++
    end
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
    awk -v mode=join -v jmode=1 -f $awkprog "$T.elv.$D" > "$T.j"
    if ("$T.j" =~ *__ATM_*) then
        awk -v mode=atom -v afile="$T.atoms" -f $awkprog "$T.j" > "$T.j2"
        set E_RESULT = "`awk -v mode=wrap -v esc=1 -f $awkprog $T.j2`"
    else
        set E_RESULT = "`awk -v mode=wrap -v esc=1 -f $awkprog $T.j`"
    endif
    goto EVAL_RETURN

APPLY_STR:
    echo -n "" > "$T.elv.$D"
    @ k = 1
    while ($k <= $EVN[$D])
        @ idx = ($D - 1) * 256 + $k
        echo "$EVA[$idx]" >> "$T.elv.$D"
        @ k++
    end
    awk -v mode=join -v jmode=2 -f $awkprog "$T.elv.$D" > "$T.j"
    if ("$T.j" =~ *__ATM_*) then
        awk -v mode=atom -v afile="$T.atoms" -f $awkprog "$T.j" > "$T.j2"
        set E_RESULT = "`awk -v mode=wrap -v esc=0 -f $awkprog $T.j2`"
    else
        set E_RESULT = "`awk -v mode=wrap -v esc=0 -f $awkprog $T.j`"
    endif
    goto EVAL_RETURN

APPLY_PRN:
    echo -n "" > "$T.elv.$D"
    @ k = 1
    while ($k <= $EVN[$D])
        @ idx = ($D - 1) * 256 + $k
        echo "$EVA[$idx]" >> "$T.elv.$D"
        @ k++
    end
    if ("$T.elv.$D" =~ *__ATM_*) then
        awk -v mode=join -v jmode=1 -f $awkprog "$T.elv.$D" | awk -v mode=atom -v afile="$T.atoms" -f $awkprog | awk -v mode=dec -f $awkprog
    else
        awk -v mode=join -v jmode=1 -f $awkprog "$T.elv.$D" | awk -v mode=dec -f $awkprog
    endif
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
    if ("$T.elv.$D" =~ *__ATM_*) then
        awk -v mode=join -v jmode=3 -f $awkprog "$T.elv.$D" | awk -v mode=atom -v afile="$T.atoms" -f $awkprog | awk -v mode=dec -f $awkprog
    else
        awk -v mode=join -v jmode=3 -f $awkprog "$T.elv.$D" | awk -v mode=dec -f $awkprog
    endif
    set E_RESULT = "nil"
    goto EVAL_RETURN

# ---- step6 core functions ----
APPLY_READSTRING:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    # fully un-escape the string VALUE to raw text (the file hop avoids
    # csh's nested-quote-in-backtick parse limitation), then tokenize with
    # the multi-line tokenizer (strings may contain real newlines) and
    # parse one form
    echo "$a1" | awk -v mode=unread -f $awkprog | awk -v mode=dec -f $awkprog > "$T.raw"
    set TKA = (`awk -v mode=filetok -f $awkprog "$T.raw"`)
    set ntok = $#TKA
    set TI = 1
    set RCALLER = READSTRING_DONE
    if ($ntok == 0) goto $RCALLER
    goto PARSE_ONE
READSTRING_DONE:
    if ("$rerr" != "") then
        set E_RESULT = "Error: $rerr"
        set ERR = 1
        goto EVAL_ABORT
    endif
    if ("$read_result" == "") then
        if ($ntok > 0) then
            set E_RESULT = "Error: unexpected end of input"
            set ERR = 1
            goto EVAL_ABORT
        endif
        set E_RESULT = "nil"
        goto EVAL_RETURN
    endif
    set E_RESULT = "$read_result"
    goto EVAL_RETURN

APPLY_SLURP:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    echo "$a1" | awk -v mode=unquote -f $awkprog > "$T.raw"
    set fpath = "`cat $T.raw`"
    set E_RESULT = "`awk -v mode=enc -f $awkprog "$fpath"`"
    goto EVAL_RETURN

APPLY_ATOM:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    @ ATOMN++
    set ATMID[$ATOMN] = "$ATOMN"
    set ATMV[$ATOMN] = "$a1"
    set ATOM_CALLER = ATOM_DONE
    goto ATOM_DUMP
ATOM_DONE:
    set E_RESULT = "__ATM_${ATOMN}__"
    goto EVAL_RETURN

APPLY_ATOMP:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    if ("$a1" =~ __ATM_*) then
        set E_RESULT = "true"
    else
        set E_RESULT = "false"
    endif
    goto EVAL_RETURN

APPLY_DEREF:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    if ("$a1" !~ __ATM_*) then
        set E_RESULT = "Error: not an atom"
        set ERR = 1
        goto EVAL_ABORT
    endif
    set aid = "$a1:s/__ATM_//"
    set aid = "$aid:s/__//"
    @ aid = $aid
    set E_RESULT = "$ATMV[$aid]"
    goto EVAL_RETURN

APPLY_RESET:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    @ idx = ($D - 1) * 256 + 3
    set a2 = "$EVA[$idx]"
    if ("$a1" !~ __ATM_*) then
        set E_RESULT = "Error: not an atom"
        set ERR = 1
        goto EVAL_ABORT
    endif
    set aid = "$a1:s/__ATM_//"
    set aid = "$aid:s/__//"
    @ aid = $aid
    set ATMV[$aid] = "$a2"
    set ATOM_CALLER = RESET_DONE
    goto ATOM_DUMP
RESET_DONE:
    set E_RESULT = "$a2"
    goto EVAL_RETURN

# swap!: (swap! a f args...) -> (reset! a (f (deref a) args...))
# The function is applied with the atom value as first argument.  Closure
# functions reuse the closure machinery; the arithmetic core functions are
# handled directly (the step6 tests use + with one or two extra args).
APPLY_SWAP:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    @ idx = ($D - 1) * 256 + 3
    set sf = "$EVA[$idx]"
    if ("$a1" !~ __ATM_*) then
        set E_RESULT = "Error: not an atom"
        set ERR = 1
        goto EVAL_ABORT
    endif
    set aid = "$a1:s/__ATM_//"
    set aid = "$aid:s/__//"
    @ aid = $aid
    set SWAP_AID = "$aid"
    set SWAP_DV = "$ATMV[$aid]"
    if ("$sf" =~ __FNC_*) then
        set fidx = "$sf:s/__FNC_//"
        set fidx = "$fidx:s/__//"
        @ fidx = $fidx
        # apply the closure to (deref a) + extra args, then reset the atom
        @ ENVN++
        set nenv = $ENVN
        set ENV_OUTER[$nenv] = "$FNENV[$fidx]"
        set pn = $FNPARN[$fidx]
        @ pi = 1
        @ ai = 4
        while ($pi <= $pn)
            @ pidx = ($fidx - 1) * 64 + $pi
            set pk = "$FNA_P[$pidx]"
            if ("$pk" == "&") then
                @ pi++
                @ pidx = ($fidx - 1) * 64 + $pi
                set pk = "$FNA_P[$pidx]"
                set rest = ""
                set rfirst = 1
                while ($ai <= $EVN[$D])
                    @ aidx = ($D - 1) * 256 + $ai
                    if ($rfirst == 1) then
                        set rest = "$EVA[$aidx]"
                        set rfirst = 0
                    else
                        set rest = "$rest $EVA[$aidx]"
                    endif
                    @ ai++
                end
                if ("$rest" == "") then
                    set bval = "()"
                else
                    set bval = "($rest)"
                endif
                @ bi = 0
                set bfound = 0
                while ($bi < $BN)
                    @ bi++
                    if ("$BENV[$bi]" == "$nenv" && "$BKEY[$bi]" == "$pk") then
                        set BVAL[$bi] = "$bval"
                        set bfound = 1
                        break
                    endif
                end
                if ($bfound == 0) then
                    @ BN++
                    set BENV[$BN] = "$nenv"
                    set BKEY[$BN] = "$pk"
                    set BVAL[$BN] = "$bval"
                endif
                break
            endif
            if ($pi == 1) then
                set bval = "$SWAP_DV"
            else
                @ aidx = ($D - 1) * 256 + $ai
                set bval = "$EVA[$aidx]"
                @ ai++
            endif
            @ bi = 0
            set bfound = 0
            while ($bi < $BN)
                @ bi++
                if ("$BENV[$bi]" == "$nenv" && "$BKEY[$bi]" == "$pk") then
                    set BVAL[$bi] = "$bval"
                    set bfound = 1
                    break
                endif
            end
            if ($bfound == 0) then
                @ BN++
                set BENV[$BN] = "$nenv"
                set BKEY[$BN] = "$pk"
                set BVAL[$BN] = "$bval"
            endif
            @ pi++
        end
        set BODYCACHE = $fidx
        set E_AST = "$FNBODY[$fidx]"
        set E_ENV = $nenv
        set CALLER = SWAP_RESET
        goto EVAL
    endif
    # arithmetic core functions
    if ("$sf" == "__CORE_add__" || "$sf" == "__CORE_sub__" || \
        "$sf" == "__CORE_mul__" || "$sf" == "__CORE_div__") then
        @ idx = ($D - 1) * 256 + 4
        set a2 = "$EVA[$idx]"
        if ("$sf" == "__CORE_add__") then
            @ sr = $SWAP_DV + $a2
        else if ("$sf" == "__CORE_sub__") then
            @ sr = $SWAP_DV - $a2
        else if ("$sf" == "__CORE_mul__") then
            @ sr = $SWAP_DV * $a2
        else
            @ sr = $SWAP_DV / $a2
        endif
        set ATMV[$aid] = "$sr"
        set ATOM_CALLER = SWAP_ARITH_DONE
        goto ATOM_DUMP
SWAP_ARITH_DONE:
        set E_RESULT = "$sr"
        goto EVAL_RETURN
    endif
    set E_RESULT = "Error: swap! unsupported function"
    set ERR = 1
    goto EVAL_ABORT

SWAP_RESET:
    if ($ERR == 1) goto EVAL_ABORT
    set ATMV[$SWAP_AID] = "$E_RESULT"
    set ATOM_CALLER = SWAP_RESET_DONE
    goto ATOM_DUMP
SWAP_RESET_DONE:
    goto EVAL_RETURN

APPLY_LOADFILE:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    echo "$a1" | awk -v mode=unquote -f $awkprog > "$T.raw"
    set fpath = "`cat $T.raw`"
    # tokenize the whole file (forms may span lines), then parse+eval each
    # form in turn in the current environment
    set TKA = (`awk -v mode=filetok -f $awkprog "$fpath"`)
    set ntok = $#TKA
    @ ti2 = 1
    while ($ti2 <= $ntok)
        set TKA[$ti2] = "$TKA[$ti2]:as/ZZSP/ /"
        @ ti2++
    end
    set TI = 1
    if ($ntok == 0) then
        set E_RESULT = "nil"
        goto EVAL_RETURN
    endif
    set RCALLER = LOAD_FORM_DONE
    goto PARSE_ONE
LOAD_FORM_DONE:
    if ("$rerr" != "") then
        set E_RESULT = "Error: $rerr"
        set ERR = 1
        goto EVAL_ABORT
    endif
    if ("$read_result" == "") then
        set E_RESULT = "Error: unexpected end of input"
        set ERR = 1
        goto EVAL_ABORT
    endif
    set E_AST = "$read_result"
    set E_ENV = "$COLL_ENV[$D]"
    set CALLER = LOAD_EVAL_DONE
    set ERR = 0
    goto EVAL
LOAD_EVAL_DONE:
    if ($TI > $ntok) then
        if ($LD_STARTUP == 1) then
            set LD_STARTUP = 2
            set D = 0
            goto REPL_START
        endif
        set E_RESULT = "nil"
        goto EVAL_RETURN
    endif
    set RCALLER = LOAD_FORM_DONE
    goto PARSE_ONE

# Dump the atom table to $T.atoms (echo is a builtin: zero forks).  Called
# after every atom creation / reset so the printer can render handles.
ATOM_DUMP:
    echo -n "" > "$T.atoms"
    @ ai = 1
    while ($ai <= $ATOMN)
        echo "$ATMID[$ai] $ATMV[$ai]" >> "$T.atoms"
        @ ai++
    end
    goto $ATOM_CALLER

APPLY_EVAL:
    @ idx = ($D - 1) * 256 + 2
    set E_AST = "$EVA[$idx]"
    set E_ENV = 1
    set CALLER = EVAL_RET
    goto EVAL

APPLY_CONS:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    @ idx = ($D - 1) * 256 + 3
    set a2 = "$EVA[$idx]"
    if ("$a2" == "nil") then
        set E_RESULT = "($a1)"
        goto EVAL_RETURN
    endif
    set cfirst = "$a1"
    set a1 = "$a2"
    set SPLIT_CALLER = CONS_SPLIT_DONE
    goto SPLIT_SCRATCH
CONS_SPLIT_DONE:
    set s = "$cfirst"
    @ k = 1
    while ($k <= $SCNT)
        set s = "$s $SPL[$k]"
        @ k++
    end
    set E_RESULT = "($s)"
    goto EVAL_RETURN

APPLY_CONCAT:
    set s = ""
    set started = 0
    @ k = 2
    while ($k <= $EVN[$D])
        @ idx = ($D - 1) * 256 + $k
        set a1 = "$EVA[$idx]"
        if ("$a1" != "nil") then
            set SPLIT_CALLER = CONCAT_SPLIT_DONE
            goto SPLIT_SCRATCH
        endif
        @ k++
    end
    set E_RESULT = "()"
    goto EVAL_RETURN
CONCAT_SPLIT_DONE:
    @ i2 = 1
    while ($i2 <= $SCNT)
        if ($started == 0) then
            set s = "$SPL[$i2]"
            set started = 1
        else
            set s = "$s $SPL[$i2]"
        endif
        @ i2++
    end
    @ k++
    while ($k <= $EVN[$D])
        @ idx = ($D - 1) * 256 + $k
        set a1 = "$EVA[$idx]"
        if ("$a1" != "nil") then
            set SPLIT_CALLER = CONCAT_SPLIT_DONE
            goto SPLIT_SCRATCH
        endif
        @ k++
    end
    set E_RESULT = "($s)"
    goto EVAL_RETURN

APPLY_VEC:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    if ("$a1" == "nil") then
        set E_RESULT = "[]"
        goto EVAL_RETURN
    endif
    set SPLIT_CALLER = VEC_SPLIT_DONE
    goto SPLIT_SCRATCH
VEC_SPLIT_DONE:
    set s = ""
    @ k = 1
    while ($k <= $SCNT)
        if ($k == 1) then
            set s = "$SPL[$k]"
        else
            set s = "$s $SPL[$k]"
        endif
        @ k++
    end
    set E_RESULT = "[$s]"
    goto EVAL_RETURN

QQ_VEC_INNER_DONE:
    set E_AST = "(vec (quote $E_RESULT))"
    set CALLER = "$QQS_CALLER[$QQN]"
    @ QQN--
    goto EVAL

APPLY_MACROP:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    if ("$a1" =~ __FNC_*) then
        set fidx = "$a1:s/__FNC_//"
        set fidx = "$fidx:s/__//"
        @ fidx = $fidx
        if ($FNISM[$fidx] == 1) then
            set E_RESULT = "true"
        else
            set E_RESULT = "false"
        endif
    else
        set E_RESULT = "false"
    endif
    goto EVAL_RETURN

APPLY_NTH:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    @ idx = ($D - 1) * 256 + 3
    set a2 = "$EVA[$idx]"
    @ n2 = $a2
    set SPLIT_CALLER = NTH_SPLIT
    goto SPLIT_SCRATCH
NTH_SPLIT:
    @ n3 = $n2 + 1
    if ($n3 > $SCNT) then
        set E_RESULT = "Error: nth index out of range"
        set ERR = 1
        goto EVAL_ABORT
    endif
    set E_RESULT = "$SPL[$n3]"
    goto EVAL_RETURN

APPLY_FIRST:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    if ("$a1" == "nil") then
        set E_RESULT = "nil"
        goto EVAL_RETURN
    endif
    set SPLIT_CALLER = FIRST_SPLIT
    goto SPLIT_SCRATCH
FIRST_SPLIT:
    if ($SCNT == 0) then
        set E_RESULT = "nil"
    else
        set E_RESULT = "$SPL[1]"
    endif
    goto EVAL_RETURN

APPLY_REST:
    @ idx = ($D - 1) * 256 + 2
    set a1 = "$EVA[$idx]"
    if ("$a1" == "nil") then
        set E_RESULT = "()"
        goto EVAL_RETURN
    endif
    set SPLIT_CALLER = REST_SPLIT
    goto SPLIT_SCRATCH
REST_SPLIT:
    if ($SCNT <= 1) then
        set E_RESULT = "()"
        goto EVAL_RETURN
    endif
    set s = ""
    @ k = 2
    while ($k <= $SCNT)
        if ($k == 2) then
            set s = "$SPL[$k]"
        else
            set s = "$s $SPL[$k]"
        endif
        @ k++
    end
    set E_RESULT = "($s)"
    goto EVAL_RETURN
