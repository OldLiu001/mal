import os, subprocess, sys, time
here = os.path.dirname(os.path.abspath(__file__))
bat = sys.argv[1] if len(sys.argv) > 1 else "step1_read_print.bat"
infile = sys.argv[2] if len(sys.argv) > 2 else None
data = "__EOF__" if infile is None else infile
# Clear each form timing using full-process model is what summary used.
proc = subprocess.Popen(
    ["cmd.exe", "/c", bat],
    cwd=here, stdin=subprocess.PIPE,
    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
)
t0 = time.perf_counter()
if infile:
    with open(infile, "r") as f:
        inp = f.read().replace("__EOF__", "\x04")
else:
    inp = data
try:
    out, _ = proc.communicate(inp.encode("utf-8", "replace"), timeout=200)
except subprocess.TimeoutExpired:
    proc.kill()
    out, _ = proc.communicate()
dt = time.perf_counter() - t0
print("EXIT=%d TIME=%.2f" % (proc.returncode, dt))
sys.stdout.write(out.decode("utf-8", "replace")[-400:])