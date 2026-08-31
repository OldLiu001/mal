import subprocess, sys, time
here = r"d:\_PubCodes\mal\impls\batch"

def run_lines(lines, timeout=30):
    p = subprocess.Popen(
        ["cmd.exe", "/c", "step4_if_fn_do.bat", "READALL"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        cwd=here)
    p.stdin.write(("\n".join(lines) + "\n").encode("utf-8", "replace"))
    p.stdin.close()
    try:
        out = p.stdout.read()
        p.wait(timeout=timeout)
        return ("OK", out.decode("utf-8", "replace"))
    except subprocess.TimeoutExpired:
        p.kill()
        return ("TIMEOUT", "")

# read all test forms from the .mal file, with expected
test_file = r"d:\_PubCodes\mal\impls\tests\step4_if_fn_do.mal"
lines = open(test_file, encoding="utf-8", errors="replace").read().split("\n")
tests = []
i = 0
while i < len(lines):
    s = lines[i].strip()
    if not s or s.startswith(";"):
        i += 1; continue
    inp = lines[i].rstrip("\r"); i += 1
    expected = None
    while i < len(lines):
        es = lines[i].strip()
        if es.startswith(";=>") or (es.startswith(";/") and es.endswith("/")):
            expected = lines[i]; i += 1; break
        elif es == "" or es.startswith(";"):
            i += 1; continue
        else:
            break
    tests.append((inp, expected))

print("total tests", len(tests))
# run in batches of lines
batch = []
for n, (inp, exp) in enumerate(tests):
    batch.append(inp)
    if len(batch) >= 5:
        st, out = run_lines(batch)
        if st == "OK":
            batch = []
        else:
            # binary search which form hangs
            print(">> batch starting at test", n-4, "TIMEOUT, forms:")
            for b in batch: print("     ", repr(b))
            sys.exit(1)
if batch:
    st, out = run_lines(batch)
    if st == "TIMEOUT":
        print(">> last batch TIMEOUT")