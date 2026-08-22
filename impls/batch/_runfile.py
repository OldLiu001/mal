import os, subprocess, sys, time
here = os.path.dirname(os.path.abspath(__file__))
bat = sys.argv[1] if len(sys.argv) > 1 else "step1_read_print.bat"
infile = sys.argv[2] if len(sys.argv) > 2 else "_smoke2.txt"
with open(os.path.join(here, infile), "rb") as fin:
    proc = subprocess.Popen(
        ["cmd.exe", "/c", bat],
        cwd=here, stdin=fin,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    t0 = time.perf_counter()
    out, err = proc.communicate(timeout=300)
    dt = time.perf_counter() - t0
sys.stdout.buffer.write(out)
if err:
    sys.stderr.buffer.write(err)
print(f"\n[exit={proc.returncode} time={dt:.2f}s]", file=sys.stderr)
