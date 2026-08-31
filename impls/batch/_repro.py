import subprocess, os
here = os.path.dirname(os.path.abspath(__file__))
p = subprocess.Popen(["cmd.exe", "/c", os.path.join(here, "_repro.bat")],
    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
out, _ = p.communicate(timeout=20)
print(out.decode("utf-8", "replace"))