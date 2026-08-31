import subprocess, time
here = r"d:\_PubCodes\mal\impls\batch"
def run(env, data, to=8):
    p = subprocess.Popen(["cmd.exe","/c","set %s=1 && step4_if_fn_do.bat READALL 2>_dbg3.txt"%env],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, cwd=here)
    try:
        out,_ = p.communicate(data.encode(), timeout=to)
        return "OK", out.decode()
    except subprocess.TimeoutExpired:
        p.kill(); p.communicate(timeout=2); return "TIMEOUT",""
    finally:
        try: dbg = open(r"d:\_PubCodes\mal\impls\batch\_dbg3.txt",encoding="utf-8",errors="replace").read()
        except: dbg=""
        print("  DBG:", dbg.replace("\n","|"))

print("NOREP mode, 2 lines:")
st,out = run("_G.NOREP", "(+ 1 2)\n(if true 7 8)\n")
print("  ", st, "OUT", repr(out))
print()
print("NOREP+DBG mode:")
st,out = run("_G.NOREP", "(+ 1 2)\n(if true 7 8)\n")
_ = st