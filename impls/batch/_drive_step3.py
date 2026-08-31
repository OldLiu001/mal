import subprocess, sys, time
here = "d:\\_PubCodes\\mal\\impls\\batch"
forms = [
    "(+ 1 2)",
    "(def! x 3)",
    "x",
    "(def! mynum 111)",
    "mynum",
    "(let* (z 9) z)",
    "(let* (z (+ 2 3)) (+ 1 z))",
    "(def! MYNUM 222)",
    "MYNUM",
]
p = subprocess.Popen(
    ["cmd.exe", "/c", "step3_env.bat"],
    cwd=here, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
)
# read until first prompt
def read_until(term):
    buf = b""
    while term not in buf:
        ch = p.stdout.read(1)
        if not ch:
            break
        buf += ch
    return buf
TERM=b"\r\nuser> "
out = read_until(b"user> ")
print(out.decode("utf-8", "replace"), end="")
for f in forms:
    p.stdin.write((f + "\n").encode("utf-8", "replace"))
    p.stdin.flush()
    out = read_until(TERM)
    print(out.decode("utf-8", "replace"), end="")
p.stdin.close()
try:
    p.wait(timeout=10)
except Exception:
    p.kill()