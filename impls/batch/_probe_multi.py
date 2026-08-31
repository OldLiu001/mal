import subprocess, time
here = r"d:\_PubCodes\mal\impls\batch"
forms = [
 "(+ 1 2)",
 "(if true 7 8)",
 "(= 1 1)",
 "(if false (+ 1 7) (+ 1 8))",
 "(= 2 (+ 1 1))",
 "(let* (a 5) a)",
 "(> 2 1)",
]
data = "\n".join(forms) + "\n"
t0=time.time()
p = subprocess.Popen(
    ["cmd.exe","/c","step4_if_fn_do.bat","READALL"],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    cwd=here)
try:
    out,_ = p.communicate(data.encode("utf-8","replace"), timeout=25)
    print("ALL OK %.2fs rc=%s" % (time.time()-t0, p.returncode))
    print(out.decode("utf-8","replace"))
except subprocess.TimeoutExpired:
    p.kill(); p.communicate(timeout=3)
    print("TIMEOUT %.2fs" % (time.time()-t0))