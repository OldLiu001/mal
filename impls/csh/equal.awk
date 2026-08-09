# Compare the two values held on line 1 and line 2 of the input file.
# Lists and vectors with equal contents are equal, so [ ] are normalised to
# ( ) outside of string literals.  Use together with strlib.awk.
NR == 1 { a = mal_norm($0) }
NR == 2 { b = mal_norm($0) }
END {
    if (a == b) print "true"
    else print "false"
}
