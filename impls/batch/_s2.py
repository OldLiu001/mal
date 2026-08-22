import os, subprocess, sys, time
here = os.path.dirname(os.path.abspath(__file__))
bat = sys.argv[1] if len(sys.argv) > 1 else "step1_read_print.bat"
# Read forms from stdin: if a line is __EOF__ we send Ctrl-D and stop measuring
data = sys.stdin.read()
proc = subprocess.Popen(
    ["cmd.exe", "/c", bat],
    cwd=here, stdin=subprocess.PIPE,
    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
)
t0 = time.perf_counter()
out, _ = proc.communicate(data.replace("__EOF__", "\x04").encode("utf-8","replace"), timeout=120)
dt = time.perf_counter() - t0
print("EXIT=%d TIME=%.2f" % (proc.returncode, dt))