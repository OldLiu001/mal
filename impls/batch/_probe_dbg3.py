import subprocess, os, sys, time
here = r"d:\_PubCodes\mal\impls\batch"
bat = "step4_if_fn_do.bat"
forms = [
    "(def! a 6)",
    "a",
    "(def! b (fn* (x) (+ x 1)))",
    "(b 5)",
    "(def! c 7)",
    "c",
]
inp = ("\n".join(forms) + "\n").encode("utf-8")
t0 = time.time()
try:
    p = subprocess.run(["cmd.exe", "/c", bat, "READALL"], input=inp, cwd=here,
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
    dt = time.time() - t0
    out = p.stdout.decode("utf-8", "replace").strip()
    print("rc=%s t=%.2fs\n%s" % (p.returncode, dt, out[:2000]), flush=True)
except subprocess.TimeoutExpired:
    dt = time.time() - t0
    print("TIMEOUT t=%.2fs" % dt, flush=True)
