# mal step7 helper (awk): strip the first and last character of a line
# (used to unwrap a canonical vector "[...]" whose inner brackets must stay
# untouched).
{ print substr($0, 2, length($0) - 2) }
