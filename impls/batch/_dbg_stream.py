import subprocess, sys, time
here = r"d:\_PubCodes\mal\impls\batch"
bat = here + r"\step1_read_print.bat"
forms = ["(+ 1 2)", "(+ 1 (+ 2 3))", "(* 1 2)", "(** 1 2)", "abc"]
p = subprocess.Popen(["cmd.exe", "/c", bat], bufsize=0,
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    cwd=here)
datas = []
class R:
    def __init__(self, p): self.d = b""
    def readn(self, n):
        while len(self.d) < n:
            b = p.stdout.read(n - len(self.d))
            if not b: break
            self.d += b
        r, self.d = self.d[:n], self.d[n:]
        return r
r = R(p)
# read initial prompt
out0 = b""
while not out0.endswith(b"user> "):
    out0 += p.stdout.read(1)
print("INIT:", repr(out0))
for i, f in enumerate(forms):
    t0 = time.time()
    p.stdin.write((f + "\n").encode())
    p.stdin.flush()
    buf = b""
    while not buf.endswith(b"user> "):
        ch = p.stdout.read(1)
        if not ch: break
        buf += ch
    dt = time.time() - t0
    print("[%d] in=%r dt=%.2f out=%r" % (i, f, dt, buf.decode("utf-8","replace")))
p.stdin.write(b"\x04"); p.kill(); p.wait()