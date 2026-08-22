import subprocess, sys
r = subprocess.run([".\\_poc_ff.bat"], shell=False, capture_output=True, text=True, encoding="utf-8", errors="replace")
print("STDOUT:\n", r.stdout)
print("STDERR:\n", r.stderr)
print("RC:", r.returncode)