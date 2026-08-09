# mal step2+ helper (awk).
# Reads ONE collection string (list "(...)", vector "[...]", or hash-map
# "{...}") on a single line and prints its TOP-LEVEL elements, one per line.
# Nested collections are kept intact as a single element. Empty collections
# produce no output (zero lines).
#
# Bracket-matching is required because elements may themselves be nested
# collections; classic csh cannot do this, so it lives here.

function split_toplevel(s,    i, depth, cur, n, ch, j, len, depth2, c2) {
    n = 0; depth = 0; cur = ""; len = length(s); i = 1
    while (i <= len) {
        ch = substr(s, i, 1)
        if (depth == 0 && (ch == " " || ch == "\t")) {
            if (cur != "") { TOK[++n] = cur; cur = "" }
            i++; continue
        }
        if (depth == 0 && (ch == "(" || ch == "[" || ch == "{")) {
            # a nested collection starting at this top-level position
            depth2 = 1; j = i + 1
            while (j <= len && depth2 > 0) {
                c2 = substr(s, j, 1)
                if (c2 == "(" || c2 == "[" || c2 == "{") depth2++
                else if (c2 == ")" || c2 == "]" || c2 == "}") depth2--
                j++
            }
            TOK[++n] = substr(s, i, j - i)
            i = j
            cur = ""
            continue
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
    first = substr(s, 1, 1)
    if (first == "(" || first == "[" || first == "{") {
        inner = substr(s, 2, length(s) - 2)
        n = split_toplevel(inner)
        for (k = 1; k <= n; k++) print TOK[k]
    }
}
