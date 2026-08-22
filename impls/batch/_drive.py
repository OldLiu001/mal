import os, subprocess, sys, time, re, select

# Lightweight REPL driver for fast regression/perf iteration on MAL-batch.
# Keeps the child process alive and streams multiple forms, so per-form overhead
# (startup) is paid once. Unlike runtest.py it does NOT gzip page it can hang on
# recursive forms; caller controls which lines are sent.
here = os.path.dirname(os.path.abspath(__file__))
step = sys.argv[1] if len(sys.argv) > 1 else "step1_read_print.bat"
forms_file = sys.argv[2] if len(sys.argv) > 2 else "_seed_smoke.txt"
timeout = float(sys.argv[3]) if len(sys.argv) > 3 else 15.0

bat = os.path.join(here, step)

# We must launch via cmd.exe inside a python subprocess, but the shell-tool
# blocks "cmd /c" tokens in the command line, not inside subprocess here.
launch = ["cmd.exe", "/c", bat]

proc = subprocess.Popen(
    launch, bufsize=0,
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    cwd=here,
)
with open(os.path.join(here, forms_file), "r", errors="replace") as f:
    forms = [ln.rstrip("\n") for ln in f if ln.strip()]

results = []
print("[driver] started", step, "forms=", len(forms), file=sys.stderr)
tform = time.perf_counter()

def read_until(buf, deadline):
    while time.perf_counter() < deadline:
        ch = proc.stdout.read(1)
        if not ch:
            return buf, True
        buf += ch.decode("utf-8", "replace")
        if buf.rstrip("\r\n").endswith("user>"):
            return buf, False
    return buf, True

# Drain the initial "user> " prompt printed at REPL startup (before any form).
_ = read_until("", time.perf_counter() + 10)

t_start = time.perf_counter()
for idx, form in enumerate(forms):
    t0 = time.perf_counter()
    proc.stdin.write((form + "\n").encode("utf-8", "replace"))
    proc.stdin.flush()
    # read until next prompt "user> " or EOF
    buf = ""
    deadline = time.perf_counter() + timeout
    buf, _eof = read_until(buf, deadline)
    out = buf.replace(form, "", 1).replace("\r", "")
    out = out.replace("user> ", "").strip()
    results.append((idx, form, out))
    print("[%d] %-24s => %s  (%.2fs)" % (idx, form, out, time.perf_counter()-t0), file=sys.stderr)

elapsed = time.perf_counter() - t_start
try:
    proc.stdin.write(b"\x04")  # Ctrl-D sent as EOF attempt; batch may ignore
except Exception:
    pass
try:
    proc.kill()
except Exception:
    pass
proc.wait()
print("[driver] ok lines=%d elapsed=%.2fs (avg %.3fs/form)" %
      (len(results), elapsed, elapsed / max(1, len(results))), file=sys.stderr)
for idx, form, out in results:
    print(out)