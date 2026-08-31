import subprocess, time
here = r"d:\_PubCodes\mal\impls\batch"
def run(data, to=8):
    p = subprocess.Popen(["cmd.exe","/c","set _G.NOREP=1 && step4_if_fn_do.bat READALL 2>_dbg4.txt"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, cwd=here)
    try:
        out,_ = p.communicate(data.encode(), timeout=to)
        return "OK", out.decode()
    except subprocess.TimeoutExpired:
        p.kill(); p.communicate(timeout=2); return "TIMEOUT",""
    finally:
        try: dbg=open(r"d:\_PubCodes\mal\impls\batch\_dbg4.txt",encoding="utf-8",errors="replace").read()
        except: dbg="<<none>>"
        print("   DBG:", repr(dbg[:200]))

for d in [ "(+ 1 2)\n", "(if true 7 8)\n", "hello\n", "" ]:
    st,out = run(d)
    print(repr(d), "->", st, "OUT", repr(out))