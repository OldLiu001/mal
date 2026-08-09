# mal step1 tokenizer (awk).
# Scans a single mal form (one line) and prints one token per line.
# Tokens: ( ) [ ] { }  "string"  ' ` ~ ~@ @ ^  <atom>
# Comments (; ...) are skipped. Commas are whitespace.
# Unterminated string -> emit __MAL_STRERR__ so the csh parser can report it.
#
# ENCODING (critical for classic csh):
#   Classic csh cannot hold a literal double-quote, backslash, or backtick
#   safely inside a double-quoted assignment, and it treats a backtick as
#   command substitution even inside double quotes. So every emitted token is
#   scrubbed of those three characters:
#       "  -> ZZQ      \  -> ZZB      `  -> ZZT
#   and the special reader-macro characters are replaced by whole-word
#   placeholders that are safe to compare in csh (no quotes/backticks):
#       '  -> ZQ       `  -> ZB       ~@ -> ZS       ~ -> ZU       @ -> ZA       ^ -> ZM
#   dec.awk restores " \ ` right before printing; the Z* placeholders are
#   consumed by the csh parser and never appear in output.
function emit(s) {
    gsub(/`/, "ZZT", s)
    gsub(/\\/, "ZZB", s)
    gsub(/"/, "ZZQ", s)
    print s
}
{
    line = $0
    n = length(line)
    i = 1
    while (i <= n) {
        c = substr(line, i, 1)
        if (c == " " || c == "\t" || c == "\n" || c == "\r" || c == ",") { i++; continue }
        if (c == ";") { break }   # comment to end of line
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
        # atom: gather until a delimiter / whitespace / comment
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
