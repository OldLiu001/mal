import subprocess, os, sys, time
here = r"d:\_PubCodes\mal\impls\batch"
bat = "step4_if_fn_do.bat"
forms = [
    '"abc"',
    '""',
    '"abc  def"',
    '"\\\\"',
    '"abc\\\\def\\\\ghi"',
    '"abc\\ndef\\nghi"',
    ':abc',
    '(str "abc")',
    '(pr-str "abc")',
    '(pr-str "abc  def" "ghi jkl")',
    '(str 1 "abc" 3)',
    '(str (list 1 2 "abc"))',
    '(pr-str (list 1 2 "abc"))',
    '(prn "abc")',
    '(println "abc")',
    '(= "" "")',
    '(= "abc" "abc")',
    '(= "abc" "ABC")',
    '(= :abc :abc)',
    '(= :abc :def)',
    '(not false)',
    '(not nil)',
    '(not true)',
    '(not 0)',
    '(if "" 7 8)',
    '(if [] 7 8)',
]
inp = ("\n".join(forms) + "\n").encode("utf-8")
t0 = time.time()
try:
    p = subprocess.run(["cmd.exe", "/c", bat, "READALL"], input=inp, cwd=here,
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
    dt = time.time() - t0
    out = p.stdout.decode("utf-8", "replace").strip()
    print("rc=%s t=%.2fs" % (p.returncode, dt), flush=True)
    lines = out.split("\n")
    # pair each form with its output
    print("--- raw output ---")
    print(out[:3000], flush=True)
except subprocess.TimeoutExpired:
    dt = time.time() - t0
    print("TIMEOUT t=%.2fs" % dt, flush=True)
