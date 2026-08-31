import subprocess, sys, time
here = r"d:\_PubCodes\mal\impls\batch"

def run_form(form, timeout=15):
    p = subprocess.Popen(
        ["cmd.exe", "/c", "step4_if_fn_do.bat", "READALL"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        cwd=here)
    p.stdin.write(form.encode("utf-8", "replace"))
    p.stdin.close()
    try:
        out = p.stdout.read()
        p.wait(timeout=timeout)
        return ("OK", out.decode("utf-8", "replace").strip())
    except subprocess.TimeoutExpired:
        p.kill()
        return ("TIMEOUT", "")

forms = sys.argv[1:]
for f in forms:
    st, out = run_form(f)
    print("== %-40s %-8s [%s]" % (f, st, out.replace("\n", "|")))
    sys.stdout.flush()