import subprocess, time, os
here = os.path.dirname(os.path.abspath(__file__))

def gen(name, body):
    p = os.path.join(here, name)
    open(p, 'w', encoding='utf-8').write(body.replace('{N}', str(N)))
    return p

def time_bat(name):
    t0 = time.perf_counter()
    subprocess.run(["cmd.exe", "/c", name], cwd=here, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return time.perf_counter() - t0

N = 5000

# same-file call :SUB
gen('_pf_a.bat', '@echo off\nsetlocal ENABLEDELAYEDEXPANSION\n:SUB\nset /a x += 1\nexit /b 0\nfor /l %%i in (1 1 {N}) do call :SUB\nexit /b 0\n')
# cross-file call other.bat :SUB
gen('_pf_b.bat', '@echo off\nsetlocal ENABLEDELAYEDEXPANSION\nfor /l %%i in (1 1 {N}) do call _pf_child.bat :SUB\nexit /b 0\n')
gen('_pf_child.bat', '@echo off\nsetlocal ENABLEDELAYEDEXPANSION\n:SUB\nset /a x += 1\nexit /b 0\n')
# for /f usebackq reading a temp file (no subprocess)
gen('_pf_c.bat', '@echo off\nsetlocal ENABLEDELAYEDEXPANSION\nfor /l %%i in (1 1 {N}) do (\n  ( set _pfvar ) > %TEMP%\\_pf_tmp.txt 2>nul\n  for /f "usebackq delims==" %%a in ("%TEMP%\\_pf_tmp.txt") do set "%%a="\n)\nexit /b 0\n')
# for /f 'command' (subprocess cmd.exe)
gen('_pf_d.bat', '@echo off\nsetlocal ENABLEDELAYEDEXPANSION\nfor /l %%i in (1 1 {N}) do (\n  for /f "delims==" %%a in (\'set _pfvar\') do set "%%a="\n)\nexit /b 0\n')
# bare set (baseline scalar op)
gen('_pf_e.bat', '@echo off\nsetlocal ENABLEDELAYEDEXPANSION\nset _pfvar=hello\nfor /l %%i in (1 1 {N}) do set "_pfvar2=!x!"\nexit /b 0\n')

for nm in ['_pf_a.bat','_pf_b.bat','_pf_c.bat','_pf_d.bat','_pf_e.bat']:
    r = [time_bat(nm) for _ in range(3)]
    mn = min(r)
    per = mn / N * 1000000  # us
    print("%-12s %d iters  min=%.3fs  per-op=%.1fus" % (nm, N, mn, per))