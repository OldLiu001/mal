import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
src = os.path.join(HERE, "mal_packed2.bat")
txt = open(src, encoding="utf-8").read()
# instrument NSUTIL_Get/Set/New entry to print args (only when empty NS path suspected)
# Instead: add a trace near the failing point. We insert debug into the packed reader ReadString.
# Print markers via a special env var turned on.
dbg = """
if defined _G.PKDBG (
  >&2 echo [NL] _G.LEVEL=!_G.LEVEL! _T.PrevLevel=!_T.PrevLevel!
  >&2 echo [GC] scanning _G.LEVEL[!_T.PrevLevel!]
)
"""
# Not editing for now — just show surrounding of the Invoke GC tail
open(os.path.join(HERE, "_pk_dbg_marker.txt"), "w").write("")
print("use _pk_run to run; add manual echo if needed")