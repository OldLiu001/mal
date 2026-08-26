import os, subprocess, sys, time, re
here = os.path.dirname(os.path.abspath(__file__))
step = sys.argv[1] if len(sys.argv) > 1 else "step1_read_print.bat"
test_file = sys.argv[2] if len(sys.argv) > 2 else "..\\tests\\step1_read_print.mal"
wtimeout = float(sys.argv[3]) if len(sys.argv) > 3 else 600.0
use_readall = "--readall" in sys.argv

bat = os.path.join(here, step)
test_path = test_file if os.path.isabs(test_file) else os.path.join(here, test_file)

# parse tests: sequence of (input, expected); every real line is an input,
# an immediately-following ;=>... or ;/regex/ line is its expectation.
tests = []
lines = [l.rstrip("\n") for l in open(test_path, encoding="utf-8", errors="replace")]
i = 0
while i < len(lines):
    ln = lines[i]
    s = ln.strip()
    if not s or s.startswith(";"):
        i += 1
        continue
    inp = ln.rstrip("\r")
    i += 1
    expected = None
    while i < len(lines):
        es = lines[i].strip()
        if es.startswith(";=>"):
            expected = lines[i]
            i += 1
            break
        elif es.startswith(";/"):
            expected = lines[i]
            i += 1
            break
        elif es == "" or es.startswith(";"):
            i += 1
            continue
        else:
            break
    tests.append((inp, expected))
print("[runall] parsed %d tests" % len(tests), flush=True)

# build stdin: each input form as a line, then close (EOF -> REPL exits)
forms = [inp.strip() for inp, _ in tests]
stdin_data = ("\n".join(forms) + "\n").encode("utf-8", "replace")

t0 = time.perf_counter()
cmd = ["cmd.exe", "/c", bat]
if use_readall:
    cmd.append("READALL")
p = subprocess.run(
    cmd, input=stdin_data,
    stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    cwd=here, timeout=wtimeout,
)
dt = time.perf_counter() - t0
raw = p.stdout.decode("utf-8", "replace")
if p.stderr:
    err_raw = p.stderr.decode("utf-8", "replace")
    print("[runall] stderr: %d bytes (cmd 层噪音/调试输出，不并入结果解析)" % len(p.stderr), flush=True)
    try:
        with open(os.path.join(here, "_runall_stderr.log"), "wb") as f:
            f.write(p.stderr)
    except OSError:
        pass
print("[runall] rc=%s wall=%.2fs" % (p.returncode, dt), flush=True)

if use_readall:
    # READALL mode: the batch emits "user> " before each form's REP, so split
    # on the prompt to group every form's output (prn/println side outputs +
    # the result line, DEBUG-EVAL traces included) into one result per form.
    PROMPT = "user> "
    results = []
    if PROMPT in raw:
        rest = raw[raw.find(PROMPT) + len(PROMPT):]
        for part in rest.split(PROMPT):
            results.append(part.replace("\r", "").strip("\n").strip())
        while results and results[-1] == "":
            results.pop()
    else:
        # fallback: one result per non-empty line (old per-line grouping)
        results = []
        buf = []
        for ln in raw.split("\n"):
            t = ln.rstrip("\r").strip()
            if t == "":
                continue
            if t.startswith("EVAL:"):
                buf.append(t)
            else:
                buf.append(t)
                results.append("\n".join(buf))
                buf = []
        if buf:
            results.append("\n".join(buf))
else:
    # parse output: split on prompt marker "user> "
    PROMPT = "user> "
    seg_start = 0
    idx = raw.find(PROMPT)
    if idx < 0:
        print("[runall] ERROR: no prompt found in output"); sys.exit(1)
    results = []
    rest = raw[idx + len(PROMPT):]
    parts = rest.split(PROMPT)
    for part in parts:
        results.append(part.replace("\r", "").strip("\n").strip())
    while results and results[-1] == "":
        results.pop()

pass_cnt = fail_cnt = 0
for n, (inp, exp) in enumerate(tests):
    if n >= len(results):
        out = "<MISSING>"
    else:
        out = results[n]
    if exp is None:
        ok = True
    else:
        if exp.startswith(";=>"):
            ok = (out == exp[3:].strip())
        else:
            body = exp[2:]
            if len(body) >= 2 and body.startswith("/") and body.endswith("/"):
                body = body[1:-1]
            ok = (re.search(body, out, re.DOTALL) is not None)
    if ok:
        pass_cnt += 1
    else:
        fail_cnt += 1
        print("  FAIL t%d in=%-20r exp=%r got=%r" % (n, inp.strip(), exp, out), flush=True)

print("PASS=%d FAIL=%d total=%d" % (pass_cnt, fail_cnt, len(tests)), flush=True)
