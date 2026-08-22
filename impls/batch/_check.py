import os, subprocess, sys, re, time, queue, threading
here = os.path.dirname(os.path.abspath(__file__))
LOG = open(os.path.join(here, "_chk_run.log"), "a", encoding="utf-8")
def slog(s=""):
    print(s, flush=True)
    LOG.write(s + "\n")
    LOG.flush()
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

slog("[check] parsed %d tests" % len(tests))

proc = subprocess.Popen(
    ["cmd.exe", "/c", bat], bufsize=0,
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    cwd=here,
)

outq = queue.Queue()
def _reader():
    while True:
        ch = proc.stdout.read(1)
        outq.put(ch if ch else None)
        if not ch:
            break
threading.Thread(target=_reader, daemon=True).start()

INIT_TERM = "user> "
TERM = "\r\nuser> "

def read_until(deadline):
    buf = ""
    while time.perf_counter() < deadline:
        try:
            ch = outq.get(timeout=0.2)
        except queue.Empty:
            continue
        if ch is None:
            return buf, True
        buf += ch.decode("utf-8", "replace")
        if buf.endswith(TERM) or buf == INIT_TERM:
            return buf, False
    return buf, True

_, _eof0 = read_until(time.perf_counter() + 20)

pass_cnt = fail_cnt = 0
timeout = float(sys.argv[3]) if len(sys.argv) > 3 else 20.0
t_wall = time.perf_counter()
results = []
for idx, (inp, exp) in enumerate(tests):
    fmt = inp.strip()
    proc.stdin.write((fmt + "\n").encode("utf-8", "replace"))
    proc.stdin.flush()
    deadline = time.perf_counter() + timeout
    buf, _eof = read_until(deadline)
    if buf == INIT_TERM:
        out = ""
    elif buf.endswith(TERM):
        out = buf[:-len(TERM)]
    else:
        out = buf
    out = out.replace(INIT_TERM, "").replace("\r", "").strip()
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
        slog("  FAIL t%d in=%-20r exp=%r got=%r" % (idx, fmt, exp, out))
    else:
        pass_cnt += 1

try:
    proc.stdin.write(b"\x04")
except Exception:
    pass
proc.kill()
proc.wait()

slog("PASS=%d FAIL=%d total=%d wall=%.1fs" % (pass_cnt, fail_cnt, len(tests), time.perf_counter() - t_wall))
for idx, fmt, exp, out in results:
    slog("  FAIL t%d in=%-20r exp=%r got=%r" % (idx, fmt, exp, out))
LOG.close()