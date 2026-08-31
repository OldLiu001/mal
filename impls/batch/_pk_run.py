import subprocess, os, sys, time
here = os.path.dirname(os.path.abspath(__file__))
step = sys.argv[1] if len(sys.argv) > 1 else "mal_packed2.bat"
t0 = time.perf_counter()
p = subprocess.Popen(["cmd.exe", "/c", step], bufsize=0,
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, cwd=here)
buf = [b""]
import threading
def runner():
    while True:
        ch = p.stdout.read(1)
        if not ch:
            break
        buf[0] += ch
t = threading.Thread(target=runner)
t.daemon = True
t.start()
t.join(6.0)  # wait for initial prompt
try:
    p.stdin.write(b"123\n"); p.stdin.flush()
except Exception as e:
    print("WRITE-ERR", e)
t.join(8.0)
p.kill(); p.wait()
dt = time.perf_counter() - t0
sys.stdout.buffer.write(b"[OUT]" + buf[0][:800])
print("\nTOTAL %.2fs len=%d" % (dt, len(buf[0])), flush=True)