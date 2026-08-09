# Shared helpers for scanning an encoded mal value.
#
# Encoding (produced by tok.awk):  " -> ZZQ   \ -> ZZB   ` -> ZZT
# A mal string value therefore looks like  ZZQ<escaped body>ZZQ  where the
# body still holds mal escape sequences (ZZB followed by ZZQ, ZZB or a plain
# character such as n).  These helpers walk a value while keeping track of
# whether they are inside a string literal, so structural characters that
# happen to appear inside a string are never touched.

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

# Drop the delimiters of every string literal but keep the escape sequences
# untouched.  The result is still a valid "escaped body", ready to be wrapped
# into a new string value (this is what `str` needs).
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

# Fully un-escape: drop the delimiters and turn the escape sequences into the
# characters they denote (this is what `println` needs before printing).
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
