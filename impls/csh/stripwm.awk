# mal stepA helper (awk): strip with-meta identity markers (ZZWM<id>)
# from a value.  with-meta returns the original value decorated with a
# marker so metadata can be non-mutating; every value operation that is
# visible (printing, equality, splitting) removes the marker first.
{ gsub(/ZZWM[0-9]+/, ""); print }
