# mal step5+ helper (awk).  Same as split.awk but every SPACE inside an
# emitted element is replaced by the placeholder ZZSP, so the csh driver can
# load the whole element list into an array with a single command
# substitution (whitespace word-splits the output into exactly one word per
# element) and then restore the spaces with a pure-csh :as substitution.
# A literal "ZZSP" written by the user would be corrupted by the restore;
# this is accepted and documented in the README (no mal test uses it).
#
# Reads ONE collection string (list "(...)", vector "[...]", or hash-map
# "{...}") on a single line and prints its TOP-LEVEL elements, one per line.
# Nested collections are kept intact as a single element.  Empty collections
# produce no output (zero lines).
#
# Bracket-matching is required because elements may themselves be nested
# collections; classic csh cannot do this, so it lives here.

function split_toplevel(s,    i, depth, cur, n, ch, len, c3, nx, instr) {
    n = 0; depth = 0; cur = ""; len = length(s); i = 1; instr = 0
    while (i <= len) {
        c3 = substr(s, i, 3)
        # inside a string literal nothing is structural
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
    return n
}

{
    s = $0
    gsub(/#WM[0-9]+/, "", s)
    first = substr(s, 1, 1)
    if (first == "(" || first == "[" || first == "{") {
        inner = substr(s, 2, length(s) - 2)
        n = split_toplevel(inner)
        for (k = 1; k <= n; k++) {
            e = TOK[k]
            gsub(/ /, "ZZSP", e)
            print e
        }
    }
}
