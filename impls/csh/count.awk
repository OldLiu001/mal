# mal step1 helper (awk).
# Print the number of tokens (lines) in the token file. Kept in a file so the
# csh driver never has to embed a brace group { ... } on a shell line (classic
# csh would mis-parse the braces as command grouping).
END { print NR }
