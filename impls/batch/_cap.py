import os, subprocess, sys, time
here = os.path.dirname(os.path.abspath(__file__))
step = sys.argv[1] if len(sys.argv) > 1 else "step1_read_print.bat"
forms_file = sys.argv[2] if len(sys.argv) > 2 else "_seed_smoke.txt"
timeout = float(sys.argv[3]) if len(sys.argv) > 3 else 15.0

bat = os.path.join(here, step)
PY = r"C:\Program Files\AutoClaw\resources\python\python.exe"

with open(os.path.join(here, forms_file), "r", errors="replace") as f:
    forms = [ln.rstrip("\n") for ln in f if ln.strip()]

# Reuse _drive.py's REPL streaming logic by calling it directly with per-form echo disabled
import io, threading

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

_ = read_until("", time.perf_counter() + 10)
for idx, form in enumerate(forms):
    t0 = time.perf_counter()
    proc.stdin.write((form + "\n").encode("utf-8", "replace"))
    proc.stdin.flush()
    buf = ""
    deadline = time.perf_counter() + timeout
    buf, _eof = read_until(buf, deadline)
    # strip prompt; keep raw echoed output
    out = buf.replace("user>", "").replace("\r", "").strip()
    print("%d\t%s\t=>\t%s" % (idx+1, form, out))
    if time.perf_counter() - t0 > timeout:
        print("TIMEOUT at form %s" % form)
        break

try:
    proc.stdin.write(b"\x04")
except Exception:
    pass
proc.kill()
proc.wait()