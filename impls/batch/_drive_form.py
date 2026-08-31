import subprocess, sys, time, os
here = os.path.dirname(os.path.abspath(__file__))
step = sys.argv[1] if len(sys.argv) > 1 else "step1_read_print.bat"
test_file = sys.argv[2] if len(sys.argv) > 2 else "..\\tests\\step1_read_print.mal"
ptimeout = float(sys.argv[3]) if len(sys.argv) > 3 else 6.0

INIT = "user> "
TERM = "\r\nuser> "

# parse tests
lines = [l.rstrip("\n") for l in open(test_file, encoding="utf-8", errors="replace")]
tests = []
i = 0
while i < len(lines):
    s = lines[i].strip()
    if not s or s.startswith(";;"):
        i += 1
        continue
    inp = lines[i].rstrip("\r")
    j = i + 1
    expected = None
    while j < len(lines):
        es = lines[j].strip()
        if es.startswith(";=>"):
            expected = lines[j]
            break
        elif es == "" or es.startswith(";;"):
            j += 1
            continue
        else:
            break
    tests.append((inp, expected))
    i = j + 1

def run_one(form):
    t0 = time.perf_counter()
    p = subprocess.Popen(["cmd.exe", "/c", step], bufsize=0,
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, cwd=here)
    try:
        buf = p.stdout.read(1).decode("utf-8", "replace")
        if not buf:
            return "NOOUT", 0
        # consume until first user>  (no result yet)
        while True:
            buf += p.stdout.read(1).decode("utf-8", "replace")
            if buf.rstrip("\r\n ").endswith("user>"):
                break
        p.stdin.write((form + "\n").encode("utf-8", "replace"))
        p.stdin.flush()
        deadline = time.perf_counter() + ptimeout
        buf = ""
        only_init = True
        while time.perf_counter() < deadline:
            ch = p.stdout.read(1).decode("utf-8", "replace")
            if not ch:
                break
            buf += ch
            if buf == INIT and not buf.strip("\r\n"):
                only_init = True
                break
            if buf.endswith(("\r\n", "\n")) and buf.rstrip("\r\n ").endswith("user>"):
                only_init = False
                break
            if buf.rstrip("\r\n ").endswith("user>"):
                only_init = False
                break
        dt = time.perf_counter() - t0
        p.kill(); p.wait()
        if not buf:
            return "NOOUT", dt
        if only_init:
            return "", dt  # just prompt again -> empty result
        out = buf
        for term in (TERM, "\nuser> "):
            if out.endswith(term):
                out = out[: -len(term)]
                break
        out = out.replace(INIT, "").replace("\r", "").strip()
        return out, dt
    except Exception as e:
        p.kill(); p.wait()
        return "ERR:" + repr(e), time.perf_counter() - t0

for idx, (inp, exp) in enumerate(tests):
    form = inp.strip()
    out, dt = run_one(form)
    status = "OK" if (exp is None) else ("PASS" if out == exp[3:].strip() else "FAIL")
    print("%3d %-4s %5.2fs in=%-24r got=%r exp=%r" % (idx + 1, status, dt, form, out,
        None if exp is None else exp[3:].strip()), flush=True)