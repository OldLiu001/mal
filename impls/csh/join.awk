# Join the arguments of a call (every line but the first, which holds the
# function itself) into a single text.
#   mode=1  readable, space separated      (pr-str / prn)
#   mode=2  string bodies unwrapped, no separator  (str)
#   mode=3  fully un-escaped, space separated      (println)
# Use together with strlib.awk:  awk -f strlib.awk -f join.awk -v mode=N file
NR > 1 {
    if (mode == 1)      v = $0
    else if (mode == 2) v = mal_stripq($0)
    else                v = mal_unread($0)
    if (started) {
        if (mode == 2) out = out v
        else           out = out " " v
    } else {
        out = v
        started = 1
    }
}
END { print out }
