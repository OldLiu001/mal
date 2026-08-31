import subprocess, time, os
here = r"d:\_PubCodes\mal\impls\batch"
tmpf = os.path.join(os.environ["TEMP"], "_mal_feed.txt")
with open(tmpf, "w", encoding="utf-8", newline="") as fh:
    fh.write("(+ 1 2)\r\n(if true 7 8)\r\n")
def run(to=10):
    p = subprocess.Popen(
        ["cmd.exe","/c", "step4_if_fn_do.bat READALL < " + tmpf],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, cwd=here)
    try:
        out,_ = p.communicate(timeout=to)
        return "OK", p.returncode, out.decode()
    except subprocess.TimeoutExpired:
        p.kill(); p.communicate(timeout=2); return "TIMEOUT", None, ""

st,rc,out = run()
print(st, "rc", rc)
print("OUT:", repr(out))