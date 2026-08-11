# mal step6 helper (awk): replace atom handles (__ATM_<n>__) inside a value
# with their readable form "(atom <value>)" using the atom table file
# (one "id value" pair per line, values already normalized strings).
# Nested handles are expanded too.  Use:  awk -f atomprint.awk -v afile=FILE
BEGIN {
    while ((getline l < afile) > 0) {
        split(l, f, " ")
        tab[f[1]] = substr(l, index(l, " ") + 1)
    }
}
{
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
