import subprocess, os, sys, time
here = r"d:\_PubCodes\mal\impls\batch"
bat = "step4_if_fn_do.bat"
forms = [
    "(list)",
    "(list 1 2 3)",
    "(+ 1 2)",
    "(if true 7 8)",
    "(= 1 1)",
    "(> 2 1)",
    "( (fn* (a) a) 5)",
    "( (fn* (a b) (+ b a)) 3 4)",
    "( (fn* () 4) )",
]
for f in forms:
    inp = f.encode("utf-8") + b"\n"
    t0 = time.time()
    try:
        p = subprocess.run(["cmd.exe", "/c", bat, "READALL"], input=inp, cwd=here,
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=90)
        dt = time.time() - t0
        out = p.stdout.decode("utf-8", "replace").strip()
        print("== %-40r -> rc=%s t=%.2fs\n    %r" % (f, p.returncode, dt, out[:200]), flush=True)
    except subprocess.TimeoutExpired:
        dt = time.time() - t0
        print("== %-40r -> TIMEOUT t=%.2fs" % (f, dt), flush=True)
