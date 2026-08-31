# 解析 %TEMP%\\mal_nspo_<L>.txt 采样，输出 NSP 序列与每轮增量。
# dump 格式：`( set _G.NSPO[ ) > file` 生成形如  _G.NSPO[1]=246 的行。
import os, glob, sys, re

pat = re.compile(r"^_G\.NSPO\[(\d+)\]=(\d+)")
for path in sorted(glob.glob(os.path.join(os.environ["TEMP"], "mal_nspo_*.txt"))):
    seq = []
    with open(path, encoding="utf-8", errors="replace") as f:
        for ln in f:
            m = pat.match(ln.strip())
            if m:
                seq.append((int(m.group(1)), int(m.group(2))))
    if not seq:
        print("%s: (empty)" % path)
        continue
    vals = [v for _, v in sorted(seq)]
    deltas = [vals[i] - vals[i - 1] for i in range(1, len(vals))]
    nonneg = sum(1 for d in deltas if d > 0)
    maxd = max(deltas, default=0)
    avgd = sum(deltas) / len(deltas) if deltas else 0.0
    print("%s: n=%d first=%d last=%d max_delta=%d avg_delta=%.1f nonzero=%d/%d" %
          (os.path.basename(path), len(vals), vals[0], vals[-1], maxd, avgd, nonneg, len(deltas)))
    if not sys.stdout.isatty():
        print("  seq: %s" % ",".join(str(v) for v in vals))