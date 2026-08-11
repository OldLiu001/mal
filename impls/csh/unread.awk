# mal step6 helper (awk): fully un-escape a string VALUE into its raw
# semantic text (strip delimiters, resolve ZBn -> newline etc.).  Use with
# strlib.awk:  awk -f strlib.awk -f unread.awk
{ print mal_unread($0) }
