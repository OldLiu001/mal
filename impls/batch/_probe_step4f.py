import subprocess, os, sys, time
here = r"d:\_PubCodes\mal\impls\batch"
bat = "step4_if_fn_do.bat"
forms = [
    "(+ 1 2)",
    "(def! a 5)",
    "a",
    "( (fn* (a) a) 5)",
    "(def! f (fn* (a) a))",
    "(f 5)",
    "( (fn* (a b) (+ b a)) 3 4)",
    "( (fn* () 4) )",
    "( (fn* (f x) (f x)) (fn* (a) (+ 1 a)) 7)",
    "( ( (fn* (a) (fn* (b) (+ a b))) 5) 7)",
    "(do (prn 101))",
    "(do (prn 102) 7)",
    "(do (def! a 6) 7 (+ a 8))",
]
for f in forms:
    inp = f.encode("utf-8") + b"\n"
    t0 = time.time()
    try:
        p = subprocess.run(["cmd.exe", "/c", bat, "READALL"], input=inp, cwd=here,
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
        dt = time.time() - t0
        out = p.stdout.decode("utf-8", "replace").strip()
        print("== %-46r -> rc=%s t=%.2fs\n    %r" % (f, p.returncode, dt, out[:300]), flush=True)
    except subprocess.TimeoutExpired:
        dt = time.time() - t0
        print("== %-46r -> TIMEOUT t=%.2fs" % (f, dt), flush=True)
