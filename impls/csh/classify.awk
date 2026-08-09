# mal step2+ helper (awk).
# Classify a single mal value string (the normalized form produced by the
# reader) into one of: list / vector / hash / string / keyword / number /
# symbol. A string value is encoded as ZZQ...ZZQ by tok.awk, so it is detected
# by the ZZQ prefix rather than a leading double-quote. Kept in a file so the
# csh driver never has to embed a quoted awk program inside a backtick, and
# never has to pass a parenthesized value through `echo "..." | awk` (classic
# csh would mis-parse the parentheses as command grouping).
{
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
