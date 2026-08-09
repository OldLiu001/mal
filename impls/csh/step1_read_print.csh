#!/bin/csh -f
# mal step1: read a form (tokenize via awk), parse into a canonical string
# representation, and print it. Pure classic csh for the structuring/printing
# logic; awk is used ONLY to scan characters into tokens (csh cannot do this)
# and to decode the printed result back to canonical form.
#
# Tokens are "encoded" by tok.awk so they contain no double-quote or backslash
# characters (which classic csh cannot hold safely inside double-quoted
# assignments); dec.awk restores them right before printing.
set histchars=
set dir = `dirname $0`
set tokprog = "$dir/tok.awk"
set decprog = "$dir/dec.awk"
set nthprog = "$dir/nth.awk"
set countprog = "$dir/count.awk"
set tmp = "/tmp/mal_csh_$$"

# Pre-allocate the parse-stack arrays. Classic csh cannot grow an array that
# starts empty, so we create a fixed frame of empty slots once, up front.
# 64 slots cover any nesting depth encountered in step1.
set op = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set buf = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set hd = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set wrap = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)
set wmeta = (`awk 'BEGIN{for(i=1;i<=64;i++)printf("\"\" ")}'`)

# csh cannot detect end of input: "$<" yields an empty string both for a
# blank line and at EOF, and $status stays 0 either way.  Re-read without
# re-prompting on an empty line and give up after a short run of them.
@ blank = 0

while (1)
    echo -n "user> "
    set line = ""
    while ("$line" == "")
        set line = "$<"
        if ("$line" == "") then
            @ blank++
            if ($blank >= 3) exit 0
        endif
    end
    @ blank = 0

    # Tokenize the whole line once into a temp file (encoded, one token/line).
    echo "$line" | awk -f "$tokprog" > "$tmp"
    set ntok = `awk -f $countprog $tmp`
    if ($ntok == 0) continue

    # parse stack, indexed by depth d (1 = topmost open frame)
    set d = 0
    set result = ""
    set err = ""

    @ i = 1
    while ($i <= $ntok)
        set tok = "`awk -v n=$i -f $nthprog $tmp`"

        if ("$tok" == "__MAL_STRERR__") then
            set err = "Error: end of input in string"
            break
        endif

        if ("$tok" == "(" || "$tok" == "[" || "$tok" == "{") then
            # open a normal collection frame
            @ d++
            set op[$d] = "$tok"
            set hd[$d] = ""
            set buf[$d] = ""
            set wrap[$d] = 0
            set wmeta[$d] = ""
        else if ("$tok" == ")" || "$tok" == "]" || "$tok" == "}") then
            if ($d < 1) then
                set err = "Error: unbalanced '$tok'"
                break
            endif
            set closed = "$op[$d]$buf[$d]$tok"
            @ d--
            set F = "$closed"
            # AUTO_CLOSE: fold completed form F into the new top frame
            while (1)
                if ($d == 0) then
                    set result = "$F"
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
            if ("$result" != "") break
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
            # AUTO_CLOSE: fold completed atom F into the top frame
            while (1)
                if ($d == 0) then
                    set result = "$F"
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
            if ("$result" != "") break
        endif
        @ i++
    end

    if ("$err" != "") then
        echo "$err"
    else if ("$result" == "") then
        echo "Error: unexpected end of input"
    else
        echo "$result" | awk -f "$decprog"
    endif
end
