# mal implementation helper - single awk file for all character-level I/O.
#
# Dispatched with -v mode=<name>.  Modes:
#   tok       tokenize one line (stdin)                    -> tokens
#   filetok   tokenize a whole file (strings span lines)    -> tokens
#   split     split a collection into top-level elements    -> elements
#   split2    same but spaces inside elements become ZZSP   -> elements
#   dec       decode ZZQ/ZZB/ZZT back to raw characters     -> text
#   enc       encode raw text into a ZZQ string value       -> value
#   join      join call arguments (jmode=1/2/3)             -> text
#   wrap      wrap text into a ZZQ string value (esc=0/1)   -> value
#   equal     deep equality of two values (lines 1 and 2)   -> true/false
#   unread    fully un-escape a string value                -> raw text
#   unquote   strip delimiters and decode a string value    -> raw text
#   seq       string value -> one-character string values   -> values
#   stripwm   remove ZZWM<id> with-meta markers             -> value
#   strip     remove first and last character               -> text
#   atom      replace __ATM_<id>__ handles via afile table  -> text
#   count     print number of input lines                   -> count
#   nth       print line n (nth= variable)                  -> line
#   classify  classify one value                            -> kind
#   fnidx     closure id of __FNC_<n>__ on line 1           -> id
#
# Only POSIX awk features are used; no gawk/mawk extensions.

# ---------------- string library (was strlib.awk) ----------------

# Replace [ and ] by ( and ) outside of string literals, so that lists and
# vectors compare equal (mal `=` treats them as equivalent sequences).
function mal_norm(s,   out, i, n, c3, nx, c, instr) {
    out = ""; i = 1; n = length(s); instr = 0
    while (i <= n) {
        c3 = substr(s, i, 3)
        if (instr) {
            if (c3 == "ZZB") {
                nx = substr(s, i + 3, 3)
                if (nx == "ZZQ" || nx == "ZZB") { out = out c3 nx; i += 6 }
                else { out = out c3 substr(s, i + 3, 1); i += 4 }
                continue
            }
            if (c3 == "ZZQ") { out = out c3; instr = 0; i += 3; continue }
            out = out substr(s, i, 1); i++
            continue
        }
        if (c3 == "ZZQ") { out = out c3; instr = 1; i += 3; continue }
        c = substr(s, i, 1)
        if (c == "[") c = "("
        else if (c == "]") c = ")"
        out = out c; i++
    }
    return out
}

# Drop the delimiters of every string literal but keep the escape sequences.
function mal_stripq(s,   out, i, n, c3, nx, instr) {
    out = ""; i = 1; n = length(s); instr = 0
    while (i <= n) {
        c3 = substr(s, i, 3)
        if (instr) {
            if (c3 == "ZZB") {
                nx = substr(s, i + 3, 3)
                if (nx == "ZZQ" || nx == "ZZB") { out = out c3 nx; i += 6 }
                else { out = out c3 substr(s, i + 3, 1); i += 4 }
                continue
            }
            if (c3 == "ZZQ") { instr = 0; i += 3; continue }
            out = out substr(s, i, 1); i++
            continue
        }
        if (c3 == "ZZQ") { instr = 1; i += 3; continue }
        out = out substr(s, i, 1); i++
    }
    return out
}

# Fully un-escape: drop the delimiters and turn the escape sequences into
# the characters they denote; escapes stay in ZZ-encoded form so a final
# dec pass yields the raw text.
function mal_unread(s,   out, i, n, c3, nx, c, instr) {
    out = ""; i = 1; n = length(s); instr = 0
    while (i <= n) {
        c3 = substr(s, i, 3)
        if (instr) {
            if (c3 == "ZZB") {
                nx = substr(s, i + 3, 3)
                if (nx == "ZZQ") { out = out "ZZQ"; i += 6; continue }
                if (nx == "ZZB") { out = out "ZZB"; i += 6; continue }
                c = substr(s, i + 3, 1)
                if (c == "n") out = out "\n"
                else out = out c
                i += 4
                continue
            }
            if (c3 == "ZZQ") { instr = 0; i += 3; continue }
            out = out substr(s, i, 1); i++
            continue
        }
        if (c3 == "ZZQ") { instr = 1; i += 3; continue }
        out = out substr(s, i, 1); i++
    }
    return out
}

# Escape a raw text so it can become the body of a string literal.
function mal_esc(s) {
    gsub(/ZZB/, "ZZBZZB", s)
    gsub(/ZZQ/, "ZZBZZQ", s)
    return s
}

# ---------------- collection splitting (was split.awk / split2.awk) ----

function split_toplevel(s, zzsp,    i, depth, cur, n, ch, len, c3, nx, instr) {
    n = 0; depth = 0; cur = ""; len = length(s); i = 1; instr = 0
    while (i <= len) {
        c3 = substr(s, i, 3)
        if (instr) {
            if (c3 == "ZZB") {
                nx = substr(s, i + 3, 3)
                if (nx == "ZZQ" || nx == "ZZB") { cur = cur c3 nx; i += 6 }
                else { cur = cur c3 substr(s, i + 3, 1); i += 4 }
                continue
            }
            if (c3 == "ZZQ") { cur = cur c3; instr = 0; i += 3; continue }
            cur = cur substr(s, i, 1); i++
            continue
        }
        if (c3 == "ZZQ") { cur = cur c3; instr = 1; i += 3; continue }
        ch = substr(s, i, 1)
        if (depth == 0 && (ch == " " || ch == "\t")) {
            if (cur != "") { TOK[++n] = cur; cur = "" }
            i++; continue
        }
        if (ch == "(" || ch == "[" || ch == "{") depth++
        else if (ch == ")" || ch == "]" || ch == "}") depth--
        cur = cur ch
        i++
    }
    if (cur != "") TOK[++n] = cur
    if (zzsp) for (k = 1; k <= n; k++) gsub(/ /, "ZZSP", TOK[k])
    return n
}

# ---------------- tokenizer (was tok.awk / loadfile.awk) ----------------

# Encode one token for csh-safe storage (spaces become ZZSP so a single
# command substitution loads the token list exactly).
function emit_tok(s) {
    gsub(/`/, "ZZT", s)
    gsub(/\\/, "ZZB", s)
    gsub(/"/, "ZZQ", s)
    gsub(/ /, "ZZSP", s)
    gsub(/\n/, "ZZBn", s)
    print s
}

# Tokenize a buffer (one line, or a whole file for filetok; the buffer may
# contain real newlines, which inside strings become the mal escape ZBn).
function tokenize(line,    n, i, c, buf, k, ch, ok, start, cc) {
    n = length(line)
    i = 1
    while (i <= n) {
        c = substr(line, i, 1)
        if (c == " " || c == "\t" || c == "\n" || c == "\r" || c == ",") { i++; continue }
        if (c == ";") {
            while (i <= n && substr(line, i, 1) != "\n") i++
            continue
        }
        if (c == "(" || c == ")" || c == "[" || c == "]" || c == "{" || c == "}") {
            emit_tok(c)
            i++
            continue
        }
        if (c == "\"") {
            buf = "\""
            k = i + 1
            ok = 0
            while (k <= n) {
                ch = substr(line, k, 1)
                if (ch == "\\") {
                    buf = buf ch substr(line, k + 1, 1)
                    k += 2
                    continue
                }
                if (ch == "\"") {
                    buf = buf "\""
                    k++
                    ok = 1
                    break
                }
                buf = buf ch
                k++
            }
            if (ok) {
                emit_tok(buf)
                i = k
                continue
            } else { emit_tok("__MAL_STRERR__"); i = n + 1; continue }
        }
        if (c == "'") { emit_tok("ZQ"); i++; continue }
        if (c == "`") { emit_tok("ZB"); i++; continue }
        if (c == "@") { emit_tok("ZA"); i++; continue }
        if (c == "^") { emit_tok("ZM"); i++; continue }
        if (c == "~") {
            if (substr(line, i + 1, 1) == "@") { emit_tok("ZS"); i += 2; continue }
            else { emit_tok("ZU"); i++; continue }
        }
        start = i
        while (i <= n) {
            cc = substr(line, i, 1)
            if (cc == " " || cc == "\t" || cc == "\n" || cc == "\r" || cc == ",") break
            if (cc == ";" || cc == "(" || cc == ")" || cc == "[" || cc == "]" ||
                cc == "{" || cc == "}" || cc == "\"" || cc == "'" || cc == "`" ||
                cc == "@" || cc == "^" || cc == "~") break
            i++
        }
        emit_tok(substr(line, start, i - start))
    }
}

# ---------------- seq helper (was seq.awk) ----------------

function emit1(c,    e) {
    e = c
    gsub(/`/, "ZZT", e)
    gsub(/\\/, "ZZB", e)
    gsub(/"/, "ZZBZZQ", e)
    gsub(/ /, "ZZSP", e)
    gsub(/\n/, "ZZBn", e)
    print "ZZQ" e "ZZQ"
}

# ---------------- mode dispatch ----------------

mode == "tok" {
    tokenize($0)
}

mode == "filetok" {
    buf = buf $0 "\n"
}

mode == "split" || mode == "split2" {
    s = $0
    gsub(/ZZWM[0-9]+/, "", s)
    first = substr(s, 1, 1)
    if (first == "(" || first == "[" || first == "{") {
        inner = substr(s, 2, length(s) - 2)
        n = split_toplevel(inner, (mode == "split2"))
        for (k = 1; k <= n; k++) print TOK[k]
    }
}

mode == "dec" {
    gsub(/ZZT/, "`"); gsub(/ZZB/, "\\"); gsub(/ZZQ/, "\"")
    print
}

mode == "enc" {
    buf = buf $0 "\n"
}

mode == "join" && NR > 1 {
    if (jmode == 1) v = $0
    else if (jmode == 2) v = mal_stripq($0)
    else v = mal_unread($0)
    if (started) {
        if (jmode == 2) out = out v
        else out = out " " v
    } else {
        out = v
        started = 1
    }
}

mode == "wrap" {
    s = $0
    if (esc == 1) s = mal_esc(s)
    print "ZZQ" s "ZZQ"
}

mode == "equal" && NR == 1 { a = mal_norm($0); gsub(/ZZWM[0-9]+/, "", a) }
mode == "equal" && NR == 2 { b = mal_norm($0); gsub(/ZZWM[0-9]+/, "", b) }

mode == "unread" {
    print mal_unread($0)
}

mode == "unquote" {
    s = $0
    if (s ~ /^ZZQ/ && s ~ /ZZQ$/) s = substr(s, 4, length(s) - 6)
    gsub(/ZZT/, "`", s)
    gsub(/ZZB/, "\\", s)
    gsub(/ZZQ/, "\"", s)
    print s
}

mode == "seq" {
    s = mal_unread($0)
    n = length(s)
    for (i = 1; i <= n; i++) emit1(substr(s, i, 1))
}

mode == "stripwm" {
    gsub(/ZZWM[0-9]+/, "")
    print
}

mode == "strip" {
    print substr($0, 2, length($0) - 2)
}

mode == "atom" {
    s = $0
    while (s ~ /__ATM_[0-9]+__/) {
        id = s
        sub(/^.*__ATM_/, "", id)
        sub(/__.*$/, "", id)
        rep = (tab[id] != "") ? "(atom " tab[id] ")" : "(atom)"
        gsub(/&/, "\\\\&", rep)
        gsub("__ATM_" id "__", rep, s)
    }
    print s
}

mode == "count" {
    # count is line-based: END prints NR
}

mode == "nth" && NR == nth { print }

mode == "classify" {
    s = $0
    c = substr(s, 1, 1)
    if (c == "(") print "list"
    else if (c == "[") print "vector"
    else if (c == "{") print "hash"
    else if (s ~ /^ZZQ/) print "string"
    else if (c == ":") print "keyword"
    else if (s ~ /^-?[0-9]/) print "number"
    else print "symbol"
}

mode == "fnidx" && NR == 1 {
    if ($0 ~ /^__FNC_[0-9]+__$/) {
        s = $0
        gsub(/[^0-9]/, "", s)
        print s
    } else {
        print 0
    }
}

BEGIN {
    if (mode == "atom") {
        while ((getline l < afile) > 0) {
            split(l, f, " ")
            tab[f[1]] = substr(l, index(l, " ") + 1)
        }
    }
}

END {
    if (mode == "filetok") tokenize(buf)
    else if (mode == "enc") {
        if (nofinal == 1) sub(/\n$/, "", buf)
        gsub(/\\/, "ZZB", buf)
        gsub(/"/, "ZZBZZQ", buf)
        gsub(/`/, "ZZT", buf)
        gsub(/\n/, "ZZBn", buf)
        if (buf == "") print "ZZQZZQ"
        else print "ZZQ" buf "ZZQ"
    }
    else if (mode == "equal") {
        if (a == b) print "true"
        else print "false"
    }
    else if (mode == "join") print out
    else if (mode == "count") print NR
}
