# mal step6 helper (awk): tokenize a whole FILE (multiple lines, comments,
# strings possibly spanning lines) and print one token per line using the
# same ZZ* encoding as tok.awk.  The tokenizer is the same as tok.awk but
# slurps the entire input into one buffer first, so a form may span lines
# and a comment runs to end-of-line.
function emit(s) {
    gsub(/`/, "ZZT", s)
    gsub(/\\/, "ZZB", s)
    gsub(/"/, "ZZQ", s)
    gsub(/ /, "ZZSP", s)
    gsub(/\n/, "ZZBn", s)
    print s
}
function toks(line,    n, i, c, buf, k, ch, ok, start, cc) {
    n = length(line)
    i = 1
    while (i <= n) {
        c = substr(line, i, 1)
        if (c == " " || c == "\t" || c == "\n" || c == "\r" || c == ",") { i++; continue }
        if (c == ";") {           # comment to end of line
            while (i <= n && substr(line, i, 1) != "\n") i++
            continue
        }
        if (c == "(" || c == ")" || c == "[" || c == "]" || c == "{" || c == "}") {
            emit(c)
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
            if (ok) { emit(buf); i = k; continue }
            else { emit("__MAL_STRERR__"); i = n + 1; continue }
        }
        if (c == "'") { emit("ZQ"); i++; continue }
        if (c == "`") { emit("ZB"); i++; continue }
        if (c == "@") { emit("ZA"); i++; continue }
        if (c == "^") { emit("ZM"); i++; continue }
        if (c == "~") {
            if (substr(line, i + 1, 1) == "@") { emit("ZS"); i += 2; continue }
            else { emit("ZU"); i++; continue }
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
        emit(substr(line, start, i - start))
    }
}
{
    buf = buf $0 "\n"
}
END {
    toks(buf)
}
