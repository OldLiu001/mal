import re, os, glob
here = os.path.dirname(os.path.abspath(__file__))
# Map each file -> set of for-var prefixes (_T.XX. or _L[level].)
allpre = {}
for f in glob.glob(os.path.join(here, "*.bat")):
    name = os.path.basename(f)
    with open(f, encoding="utf-8", errors="replace") as fh:
        src = fh.read()
    pre = set(re.findall(r"for %%. in \((_[TL]\[[^)]*\]|[I_]T\.[A-Za-z]+)\.\)", src))
    # also capture _L[level]. style
    pre |= set(re.findall(r"for %%. in \((_L\[[^]]*\]\.)\)", src))
    pre |= set(re.findall(r"for %%. in \((_T\.[A-Z]+\.)\)", src))
    if pre:
        allpre[name] = sorted(pre)

# Build prefix->files
pf = {}
for fn, ps in allpre.items():
    for p in ps:
        pf.setdefault(p, []).append(fn)

print("=== 全局 for-var 前缀及使用文件 ===")
for p, files in sorted(pf.items()):
    print("%-16s <- %s" % (p, ", ".join(files)))