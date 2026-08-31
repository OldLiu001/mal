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

# CRLF line endings, 1 and 2 lines
for nm, d in [("CRLF-1", "(+ 1 2)\r\n"),
              ("CRLF-2", "(+ 1 2)\r\n(+ 3 4)\r\n"),
              ("LF-1", "hello\n")]:
    st,rc,out = run(d)
    print(nm, repr(d), "->", st, "OUT", repr(out))