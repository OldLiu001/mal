import subprocess, time
here = r"d:\_PubCodes\mal\impls\batch"
data = "(+ 1 2)\n(if true 7 8)\n"
p = subprocess.Popen(["cmd.exe","/c","set _G.DBG=1 && step4_if_fn_do.bat READALL 2>_pump_err.txt"],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, cwd=here)
try:
    out,_ = p.communicate(data.encode(), timeout=10)
    print("RC",p.returncode)
    print("OUT:",out.decode("utf-8","replace"))
except subprocess.TimeoutExpired:
    p.kill(); p.communicate(timeout=2); print("TIMEOUT")
print("===STDERR===")
print(open(r"d:\_PubCodes\mal\impls\batch\_pump_err.txt",encoding="utf-8",errors="replace").read())