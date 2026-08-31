import subprocess, sys
here = r"d:\_PubCodes\mal\impls\batch"

def run_form(form, timeout=12):
    p = subprocess.Popen(
        ["cmd.exe", "/c", "step4_if_fn_do.bat", "READALL"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        cwd=here)
    try:
        out, _ = p.communicate(form.encode("utf-8","replace"), timeout=timeout)
        return "OK", out.decode("utf-8","replace").strip()
    except subprocess.TimeoutExpired:
        p.kill()
        try: p.communicate(timeout=3)
        except Exception: pass
        return "TIMEOUT", ""

for f in sys.argv[1:]:
    st, out = run_form(f)
    print("== %-42s %-8s [%s]" % (f, st, out.replace("\n","|")))
    sys.stdout.flush()