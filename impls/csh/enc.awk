# mal step6 helper (awk): slurp a file and emit its content as a single mal
# string VALUE (ZZQ...ZZQ encoded).  Raw characters are escaped exactly like
# tok.awk does (" -> ZZQ, \ -> ZZB, ` -> ZZT) and real newlines become the
# mal escape ZBn (backslash-n), so the resulting value is one line of text.
{
    buf = buf $0 "\n"
}
END {
    if (nofinal == 1) sub(/\n$/, "", buf)
    gsub(/\\/, "ZZB", buf)
    gsub(/"/, "ZZBZZQ", buf)
    gsub(/`/, "ZZT", buf)
    gsub(/\n/, "ZZBn", buf)
    if (buf == "") print "ZZQZZQ"
    else print "ZZQ" buf "ZZQ"
}
