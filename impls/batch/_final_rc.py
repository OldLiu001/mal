import os, sys, time
here = os.path.dirname(os.path.abspath(__file__))
step = sys.argv[1] if len(sys.argv) > 1 else "step5_tco.bat"
tfile = sys.argv[2] if len(sys.argv) > 2 else "_sum2_5.mal"
tmo = float(sys.argv[3]) if len(sys.argv) > 3 else 300.0

os.environ["_G.RCMODE"] = sys.argv[4] if len(sys.argv) > 4 else "1"
os.environ["_G.RECYCLE"] = sys.argv[5] if len(sys.argv) > 5 else "1"
os.environ["_G.NSPOBS"] = "1"

sys.path.insert(0, here)
import subprocess
cmd = [sys.executable, "_runall.py", step, tfile, str(int(tmo))]
t0 = time.perf_counter()
r = subprocess.run(cmd, cwd=here, capture_output=True, text=True, timeout=tmo + 30)
print(">>> %s rcmode=%s recycle=%s wall=%.1fs rc=%s" % (
    tfile, os.environ["_G.RCMODE"], os.environ["_G.RECYCLE"],
    time.perf_counter() - t0, r.returncode))
print(r.stdout[-900:])
