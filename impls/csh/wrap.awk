# Wrap a text into a mal string value.
#   esc=1  the text is a readable rendering and must be escaped first (pr-str)
#   esc=0  the text is already an escaped body (str)
# Use together with strlib.awk.
{
    s = $0
    if (esc == 1) s = mal_esc(s)
    print "ZZQ" s "ZZQ"
}
