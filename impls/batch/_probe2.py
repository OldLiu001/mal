import subprocess, time
here = r"d:\_PubCodes\mal\impls\batch"
form = "(let* (a 5) a)"
t0=time.time()
p = subprocess.Popen(
    ["cmd.exe","/c","step4_if_fn_do.bat","READALL"],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    cwd=here)
try:
    out,err = p.communicate(form.encode("utf-8","replace"), timeout=10)
    print("RC",p.returncode,"OK %.2fs"%(time.time()-t0))
    print("STDOUT:",out.decode("utf-8","replace"))
    print("STDERR:",err.decode("utf-8","replace"))
except subprocess.TimeoutExpired:
    p.kill()
    p.communicate(timeout=3)
    print("TIMEOUT %.2fs stderr:"%(time.time()-t0))
    print((p.stderr.read() if p.stderr else b"").decode("utf-8","replace"))