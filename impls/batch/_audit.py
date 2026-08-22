import os, re, sys
f = os.path.join(os.path.dirname(os.path.abspath(__file__)), sys.argv[1] if len(sys.argv)>1 else "_packed_test.bat")
src = open(f, "r", errors="replace").read()
lines = src.splitlines()

def find_label(l):
    m = re.match(r'^\s*:([A-Za-z_][A-Za-z0-9_]*)', l)
    return m.group(1) if m else None

# collect inner labels (lowercased for case-insensitive goto match)
labels = {}
for l in lines:
    lab = find_label(l)
    if lab:
        labels.setdefault(lab.lower(), []).append(lab)

# collect all "call :foo" and "goto :foo" references (strip trailing modifiers)
refs = []
for i, l in enumerate(lines, 1):
    for m in re.finditer(r'(?i)\b(call|goto)\s+(%_G[^%]+%|:[A-Za-z_][A-Za-z0-9_]*)', l):
        refs.append((i, m.group(1).lower(), m.group(2)))

# bare cross-file calls: "call <word> :Word_xxx" where word is a known module or any name+colon
bare = re.findall(r'(?i)\bcall\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([A-Za-z_]+\w*)', src)

print("=== 裸跨文件调用 (call <name> :<fn>) 若存在则危险 ===")
for b in bare:
    if b[0].lower() not in ("set", "if", "for", "echo"):
        print("  ", b)

print("\n=== self-call 关键字检查 (%~s0 / %~0 / call %0) ===")
for i, l in enumerate(lines,1):
    if re.search(r'(%~s0|%~0|call\s+%0|\b%~f0)', l):
        print("  %d: %s" % (i, l.strip()))

print("\n=== 关键入口/包裹标签 ===")
for want in ["READLINE","WRITEALL","NSUTIL_Init","MAIN_Main","MAIN_REPL_Loop","UTIL_Init","UTIL_Invoke"]:
    found = want.lower() in labels
    loc = ",".join(labels.get(want.lower(), [])) if found else "MISSING"
    print("  %-16s -> %s" % (want, loc if not found else "OK@%s"%loc[:40]))

# unresolved :call refs
print("\n=== 未解析的 call :label 引用 ===")
missing = 0
for i, kw, r in refs:
    if r.startswith('%'):
        continue  # macro runtime; skip
    target = r[1:].lower()
    if target not in labels:
        print("  %d: %s -> NOT FOUND" % (i, r))
        missing += 1
print("  小计 missing: %d" % missing)

print("\n=== 总标签数 / 总行数 ===", len(labels), "/", len(lines))