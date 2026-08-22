import subprocess, os
# Reproduce readme §8.4.3.4 MORE faithfully: outer for uses _L[level].
# Inside, nested call bumps _G.LEVEL (as UTIL_Invoke does). Then outer reads
# !%%.X!.  Does the '.' loop var value stay "_L[1]." (captured at block open)
# even though a nested call changed _G.LEVEL ?  If yes -> no clobber.
script = (
    "@echo off\r\n"
    "setlocal ENABLEDELAYEDEXPANSION\r\n"
    "set _G.LEVEL=1\r\n"
    "call :OUTER\r\n"
    "echo OUTER_READ_AFTER=!OUTER_READ_AFTER!\r\n"
    "echo GLEVEL_FINAL=!_G.LEVEL!\r\n"
    "exit /b 0\r\n"
    "\r\n"
    ":OUTER\r\n"
    "for %%. in (_L[!_G.LEVEL!].) do (\r\n"
    "    set \"%%.X=OUTER_VALUE\"\r\n"
    "    call :INNER\r\n"
    "    set \"OUTER_READ_AFTER=!%%.X!\"\r\n"
    ")\r\n"
    "exit /b 0\r\n"
    "\r\n"
    ":INNER\r\n"
    "set /a \"_G.LEVEL+=1\"\r\n"
    "for %%. in (_L[!_G.LEVEL!].) do (\r\n"
    "    set \"%%.X=INNER_VALUE\"\r\n"
    "    set \"%%.Y=INNER_Y\"\r\n"
    ")\r\n"
    "exit /b 0\r\n"
)
with open("_poc_ff.bat", "wb") as f:
    f.write(script.encode("utf-8"))
r = subprocess.run([".\\_poc_ff.bat"], capture_output=True, text=True, encoding="utf-8", errors="replace")
print("STDOUT:\n", r.stdout)
print("STDERR:\n", r.stderr)
print("RC:", r.returncode)