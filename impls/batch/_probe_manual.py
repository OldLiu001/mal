import subprocess, time, threading
here = r"d:\_PubCodes\mal\impls\batch"
p = subprocess.Popen(["cmd.exe","/c","step4_if_fn_do.bat READALL"],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, cwd=here, bufsize=0)
chunks=[]
def pump():
    while True:
        b=p.stdout.read(1)
        if not b: break
        chunks.append(b)
def pump2():
    while True:
        try: b=p.stdout.read(65536)
        except Exception: break
        if not b: break
        chunks.append(b)
threading.Thread(target=pump, daemon=True).start()
t=time.time()
p.stdin.write(b"(+ 1 2)\r\n"); p.stdin.flush(); p.stdin.close()
# wait with timeout
deadline=time.time()+8
while time.time()<deadline and p.poll() is None:
    time.sleep(0.05)
alive = p.poll() is None
if alive:
    p.kill(); p.wait(timeout=2); print("TIMEOUT dt", round(time.time()-t,2))
else:
    print("OK rc", p.returncode, "dt", round(time.time()-t,2))
time.sleep(0.3)
print("out:", b"".join(chunks).decode("utf-8","replace"))