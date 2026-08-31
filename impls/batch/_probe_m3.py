import subprocess, time
here = r"d:\_PubCodes\mal\impls\batch"
def run(forms, to=12):
    data = "\n".join(forms) + "\n"
    p = subprocess.Popen(["cmd.exe","/c","step4_if_fn_do.bat","READALL"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, cwd=here)
    try:
        out,_ = p.communicate(data.encode("utf-8","replace"), timeout=to)
        return "OK", out.decode("utf-8","replace")
    except subprocess.TimeoutExpired:
        p.kill(); p.communicate(timeout=3)
        return "TIMEOUT",""

for fs in [ ["(+ 1 2)"], ["(+ 1 2)",""], [+1] ]:
    pass
# single line then empty then nothing
for fs in [ ["(+ 1 2)", ""], ["(+ 1 2)", "(+ 3 4)", ""] ]:
    st,out = run(fs)
    print(repr(fs), "->", st)
    if st=="OK": print("[%s]"%out.strip())
    print()