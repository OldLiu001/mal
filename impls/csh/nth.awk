# mal step1 helper (awk).
# Print the n-th line of the token file (1-indexed), used by the csh driver
# to fetch one token at a time without embedding single quotes inside a
# command substitution.
NR == n { print }
