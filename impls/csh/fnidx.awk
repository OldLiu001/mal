# Print the numeric index of the closure handle on line 1 (__FNC_12__ -> 12),
# or 0 when line 1 is not a closure handle.
NR == 1 {
    if ($0 ~ /^__FNC_[0-9]+__$/) {
        s = $0
        gsub(/[^0-9]/, "", s)
        print s
    } else {
        print 0
    }
}
