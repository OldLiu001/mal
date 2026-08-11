# mal step6 helper (awk): strip the ZZQ...ZZQ delimiters of a string VALUE
# and decode the csh-safe encodings (ZZT -> `, ZZB -> \, ZZQ -> "), giving
# the raw text content.  Mal-level escapes (ZZBn etc.) are left intact so
# the result can be re-read or used as a file path.
{
    s = $0
    if (s ~ /^ZZQ/ && s ~ /ZZQ$/) {
        s = substr(s, 4, length(s) - 6)
    }
    gsub(/ZZT/, "`", s)
    gsub(/ZZB/, "\\", s)
    gsub(/ZZQ/, "\"", s)
    print s
}
