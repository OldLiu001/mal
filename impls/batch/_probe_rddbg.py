import subprocess, time, os
here = r"d:\_PubCodes\mal\impls\batch"
errf = os.path.join(here, "_rd_stderr.txt")
if os.path.exists(errf): os.remove(errf)
N = 9
p = subprocess.Popen(
    ["cmd.exe","/c", "set _G.DBG=1 && step4_if_fn_do.bat READALL 2>" + errf],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, cwd=here)
data = ("(+ 1 2)\r\n" * N).encode()
try:
    out,_ = p.communicate(data, timeout=12)
    print("ok rc", p.returncode, "stdout lines", len(out.splitlines()))
except subprocess.TimeoutExpired:
    p.kill(); p.communicate(timeout=2); print("TIMEOUT")
try:
    dbg = open(errf, encoding="utf-8", errors="replace").read()
except Exception as e:
    dbg = "ERR " + str(e)
print("=== RDALL DBG (%d markers) ===" % dbg.count("RD_"))
print(dbg)