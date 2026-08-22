import os, subprocess, sys, re, time
here = os.path.dirname(os.path.abspath(__file__))
step = sys.argv[1] if len(sys.argv) > 1 else "step1_read_print.bat"
test_file = sys.argv[2] if len(sys.argv) > 2 else "_seed_smoke.txt"

bat = os.path.join(here, step)
test_path = test_file if os.path.isabs(test_file) else os.path.join(here, test_file)

# parse test: sequence of (input, expected). handle ;=> and ;=>/regex forms
tests = []
lines = [l.rstrip("\n") for l in open(test_path, encoding="utf-8", errors="replace")]
i = 0
while i < len(lines):
    ln = lines[i]
    s = ln.strip()
    if not s or s.startswith(";;"):
        i += 1
        continue
    # input line (may have leading/trailing spaces that matter)
    inp = ln.rstrip("\r")
    # find following ;=> expect
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

print("[check] parsed %d tests" % len(tests))

proc = subprocess.Popen(
    ["cmd.exe", "/c", bat], bufsize=0,
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    cwd=here,
)

def read_until(buf, deadline):
    while time.perf_counter() < deadline:
        ch = proc.stdout.read(1)
        if not ch:
            return buf, True
        buf += ch.decode("utf-8", "replace")
        if buf.rstrip("\r\n").endswith("user>"):
            return buf, False
    return buf, True

_ = read_until("", time.perf_counter() + 20)

pass_cnt = fail_cnt = 0
timeout = float(sys.argv[3]) if len(sys.argv) > 3 else 20.0
results = []
for idx, (inp, exp) in enumerate(tests):
    fmt = inp.strip()
    proc.stdin.write((fmt + "\n").encode("utf-8", "replace"))
    proc.stdin.flush()
    buf = ""
    deadline = time.perf_counter() + timeout
    buf, _eof = read_until(buf, deadline)
    out = buf.replace("user>", "").replace("\r", "").strip()
    # extract expected value from ;=>EXPECT or ;=>/regex/
    if exp is None:
        ok = True  # no assertion
    else:
        expval = exp[3:]
        if expval == "":
            ok = (out == "")
        elif expval.startswith("/") and expval.endswith("/"):
            rx = expval[1:-1]
            ok = (re.search(rx, out) is not None)
        else:
            ok = (out == expval.strip())
    if not ok:
        fail_cnt += 1
        results.append((idx, fmt, exp, out))
    else:
        pass_cnt += 1

try:
    proc.stdin.write(b"\x04")
except Exception:
    pass
proc.kill()
proc.wait()

print("PASS=%d FAIL=%d total=%d" % (pass_cnt, fail_cnt, len(tests)))
for idx, fmt, exp, out in results:
    print("  FAIL t%d in=%-20r exp=%r got=%r" % (idx, fmt, exp, out))