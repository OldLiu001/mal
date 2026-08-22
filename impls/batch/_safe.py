import os, subprocess, sys, time
# Safe single-run wrapper: strict short timeout, kills child on timeout/overflow.
here = os.path.dirname(os.path.abspath(__file__))
bat = sys.argv[1] if len(sys.argv) > 1 else "_packed_test.bat"
form = sys.argv[2] if len(sys.argv) > 2 else "_one.txt"
timeout = int(sys.argv[3]) if len(sys.argv) > 3 else 20

def count_cmd():
    try:
        p = subprocess.Popen(["tasklist", "/fi", "imagename eq cmd.exe", "/fo", "csv"],
                             stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        out, _ = p.communicate()
        return sum(1 for ln in out.splitlines() if "cmd.exe" in ln.lower()) - 1
    except Exception:
        return -1

before = count_cmd()
print("[safe] cmd-before=%d" % before, file=sys.stderr)

inp = os.path.join(here, form)
with open(inp, "r") as fin:
    proc = subprocess.Popen(["cmd.exe", "/c", bat], cwd=here,
                            stdin=fin, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    t0 = time.perf_counter()
    try:
        try:
            out, err = proc.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            proc.kill()
            print("[safe] TIMEOUT after %ds -- KILLED" % timeout, file=sys.stderr)
            out, err = proc.communicate()
            dt = time.perf_counter() - t0
            sys.stdout.write(out.decode("utf8", "replace"))
            if err:
                sys.stderr.write("[stderr]\n" + err.decode("utf8", "replace"))
            print("\n[safe] exit=%s time=%.2fs" % (proc.returncode, dt), file=sys.stderr)
            sys.exit(2)
        dt = time.perf_counter() - t0
    except Exception as e:
        print("[safe] error %r" % e, file=sys.stderr)
        sys.exit(3)

sys.stdout.write(out.decode("utf8", "replace"))
if err:
    sys.stderr.write("[stderr]\n" + err.decode("utf8", "replace"))
print("\n[safe] exit=%s time=%.2fs" % (proc.returncode, dt), file=sys.stderr)

# post-check: any runaway cmd children?
after = count_cmd()
print("[safe] cmd-after=%d" % after, file=sys.stderr)
if after - before > 5:
    print("[safe] WARNING process spike", file=sys.stderr)
    # attempt cleanup of non-self orphan cmd someone may have spawed is risky;
    # just report.  (caller can inspect)  sys.exit(1)