import subprocess, time
here = r"d:\_PubCodes\mal\impls\batch"
def run(data, to=8):
    p = subprocess.Popen(["cmd.exe","/c","step4_if_fn_do.bat READALL"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, cwd=here)
    try:
        out,_ = p.communicate(data.encode(), timeout=to)
        return "OK", p.returncode, out.decode()
    except subprocess.TimeoutExpired:
        p.kill(); p.communicate(timeout=2); return "TIMEOUT",None,""

for d in ["(+ 1 2)\n", "(+ 1 2)\n(+ 3 4)\n"]:
    st,rc,out = run(d)
    print(repr(d), "->", st, "rc", rc, "OUT", repr(out))
    print()