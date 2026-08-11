# mal stepA helper (awk): turn an encoded string VALUE into a list of
# one-character string VALUES, one per line.  Spaces are emitted as ZZSP so
# the csh driver can word-split the output safely.  Use with strlib.awk:
#   awk -f strlib.awk -f seq.awk
function emit1(c,    e) {
    e = c
    gsub(/`/, "ZZT", e)
    gsub(/\\/, "ZZB", e)
    gsub(/"/, "ZZBZZQ", e)
    gsub(/ /, "ZZSP", e)
    gsub(/\n/, "ZZBn", e)
    print "ZZQ" e "ZZQ"
}
{
    s = mal_unread($0)
    n = length(s)
    for (i = 1; i <= n; i++) emit1(substr(s, i, 1))
}
