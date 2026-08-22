import os, subprocess, sys, time
here = os.path.dirname(os.path.abspath(__file__))
bat = sys.argv[1] if len(sys.argv) > 1 else "step1_read_print.bat"
form = sys.argv[2] if len(sys.argv) > 2 else "(+ 1 2)"
proc = subprocess.Popen(
    ["cmd.exe", "/c", bat],
    cwd=here, stdin=subprocess.PIPE,
    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
)
t0 = time.perf_counter()
try:
    out, _ = proc.communicate((form + "\n\x04").encode("utf-8", "replace"), timeout=80)
except subprocess.TimeoutExpired:
    proc.kill()
    out, _ = proc.communicate()
dt = time.perf_counter() - t0
sys.stdout.write(out.decode("utf-8", "replace"))
print("\n[single] exit=%s time=%.2fs" % (proc.returncode, dt))