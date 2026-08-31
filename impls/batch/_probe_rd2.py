import subprocess, time
here = r"d:\_PubCodes\mal\impls\batch"
# 1) readall RAW alone with mal forms
for data in [ "(+ 1 2)\n", "(+ 1 2)\n(if true 7 8)\n"]:
    p = subprocess.Popen(["cmd.exe","/c","readall.bat RAW"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, cwd=here)
    try:
        out,_ = p.communicate(data.encode(), timeout=8)
        print("readall", repr(data), "-> RC", p.returncode, "OUT", repr(out.decode()))
    except subprocess.TimeoutExpired:
        p.kill(); p.communicate(timeout=2); print("readall", repr(data), "-> TIMEOUT")
    print()
# 2) step4 with readall but no REP processing difference - just 2 simple words