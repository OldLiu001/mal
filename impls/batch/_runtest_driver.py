import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__))
bat = sys.argv[1] if len(sys.argv) > 1 else "step1_read_print.bat"
proc = subprocess.Popen(
    ["cmd.exe", "/c", bat],
    cwd=here,
    stdin=sys.stdin, stdout=sys.stdout, stderr=sys.stderr,
)
sys.exit(proc.wait())