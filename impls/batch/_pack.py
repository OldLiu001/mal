import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
entry = sys.argv[1] if len(sys.argv) > 1 else "step1_read_print.bat"
out = sys.argv[2] if len(sys.argv) > 2 else "mal_packed.bat"
core = ["util.bat", "nsutil.bat", "reader.bat", "printer.bat", "str.bat",
        "types.bat", "env.bat", "io.bat"]
STD_MODS = {"util", "nsutil", "reader", "printer", "str", "types", "env", "io"}
# careful: io.bat's bare "call READLINE"/"call WRITEALL" (non-PACKED branches)
# must NOT be rewritten (they're external-file calls guarded by _G.PACKED).

def read(name):
    with open(os.path.join(HERE, name), "rb") as f:
        return f.read()

def forward_rewrite(text):
    # Packed single file: bare "call NSUTIL :X" / "call UTIL :X" must become the
    # same-file "call :X" (they'd otherwise spawn subprocess / not find the .bat).
    # Leave labels like :READLINE alone; only rewrite calls into known core mods.
    def rep(m):
        mod, fn = m.group(1).lower(), m.group(2)
        if mod in STD_MODS:
            return "call :%s" % fn
        return m.group(0)
    return re.sub(r'(?i)\bcall\s+(NSUTIL|UTIL)\s*:\s*([A-Za-z]\w*)', rep, text)

def module_text(name):
    return forward_rewrite(read(name).decode("utf-8", "replace"))

def wrap_as(module_file, label):
    # Sequential scripts (readline/writeall): strip BOM and a leading "@echo off"
    # line plus any trailing newline, BUT KEEP their own setlocal/endlocal and
    # everything else exactly as-authored (they are behavior-critical and we
    # must not perturb their logic).  Wrap under :<label> with a trailing exit /b.
    src = read(module_file).decode("utf-8", "replace")
    lines = src.splitlines()
    body = []
    for i, ln in enumerate(lines):
        if i == 0 and ("\ufeff" in ln or ln.strip().lower() == "@echo off"
                       or ln.strip().lower().startswith("@echo off &")):
            ln = ln[1:] if ln.startswith("\ufeff") else ln
            if ln.strip().lower() in ("", "@echo off"):
                continue
        body.append(ln)
    text = "\n".join(body).strip("\n")
    return ":%s\n%s\nexit /b 0\n" % (label, text)

entry_txt = read(entry).decode("utf-8", "replace")

# Header: PACKED on, external-module dispatch for readline/writeall, then init+run.
header = (
    "@echo off\n"
    "setlocal ENABLEDELAYEDEXPANSION\n"
    "set _G.PACKED=1\n"
    "\n"
    "if \"%~1\" equ \"CALL_READLINE\" call :READLINE & exit /b 0\n"
    "if \"%~1\" equ \"CALL_WRITEALL\"  call :WRITEALL & exit /b 0\n"
    "if \"%~1\" equ \"CALL_SELF\"      shift & goto :ENTRY_CALLER\n"
    "call :NSUTIL_Init %~n0\n"
    "call :MAIN_Main\n"
    "exit /b 0\n"
    "\n"
    ":ENTRY_CALLER\n"
    "call %1\n"
    "exit /b 0\n"
    "\n"
)

parts = [header, entry_txt, "\n"]
for m in core:
    p = os.path.join(HERE, m)
    if os.path.exists(p):
        parts.append(module_text(m))
        parts.append("\n")
parts.append("\n")
parts.append(wrap_as("readline.bat", "READLINE"))
parts.append("\n")
parts.append(wrap_as("writeall.bat", "WRITEALL"))

with open(os.path.join(HERE, out), "w", encoding="utf-8", newline="\n") as f:
    f.write("".join(parts))
print("built", out, "bytes=", os.path.getsize(os.path.join(HERE, out)))