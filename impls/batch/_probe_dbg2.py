import subprocess, os, sys, time
here = r"d:\_PubCodes\mal\impls\batch"
bat = "step4_if_fn_do.bat"
forms = [
    "(def! a 6)",
    "a",
    "(def! b (fn* (x) (+ x 1)))",
    "(b 5)",
]
for f in forms:
    inp = f.encode("utf-8") + b"\n"
    t0 = time.time()
    try:
        p = subprocess.run(["cmd.exe", "/c", bat, "READALL"], input=inp, cwd=here,
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=90)
        dt = time.time() - t0
        out = p.stdout.decode("utf-8", "replace").strip()
        print("== %-30r -> rc=%s t=%.2fs\n    %r" % (f, p.returncode, dt, out[:600]), flush=True)
    except subprocess.TimeoutExpired:
        dt = time.time() - t0
        print("== %-30r -> TIMEOUT t=%.2fs" % (f, dt), flush=True)
