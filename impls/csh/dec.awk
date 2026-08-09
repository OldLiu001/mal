# mal step1 decoder (awk).
# Restores the characters that tok.awk encoded. Order matters: decode the
# backtick first, then backslash, then double-quote, so a decoded character
# can never be re-matched by a later pattern.
{ gsub(/ZZT/, "`"); gsub(/ZZB/, "\\"); gsub(/ZZQ/, "\""); print }
