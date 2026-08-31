import json
path = r"C:/Users/OldLi/.catpaw/projects/C--Users-OldLi--meituan-catpaw-3489106165-desk-default-workspace/511d2d69-dc74-4906-abc4-6e1c620ec4be.jsonl"
with open(path, encoding='utf-8', errors='replace') as f:
    lines = f.readlines()
cands = []
for n, line in enumerate(lines, 1):
    if 'NSUTIL_CloneBodyRC' not in line or 'nsutil.bat' not in line:
        continue
    try:
        obj = json.loads(line)
    except Exception:
        continue
    c = obj.get('message', {}).get('content', [])
    for blk in c:
        if not isinstance(blk, dict):
            continue
        if blk.get('type') != 'tool_use':
            continue
        tp = blk.get('toolParams')
        if not isinstance(tp, str):
            continue
        try:
            tpj = json.loads(tp)
        except Exception:
            continue
        if not isinstance(tpj, dict) or 'nsutil.bat' not in str(tpj.get('file_path', '')):
            continue
        ns = tpj.get('new_string', '')
        if not isinstance(ns, str):
            continue
        if 'NSUTIL_SetRC' in ns and 'NSUTIL_CloneBodyRC' in ns:
            has = dict(FreeRC='NSUTIL_FreeRC' in ns, SetDirectRC='NSUTIL_SetDirectRC' in ns,
                       Drain='NSUTIL_DrainDestroy' in ns, IncRef='NSUTIL_IncRef' in ns)
            cands.append((n, len(ns), ns, has))
for n, L, t, has in cands:
    print("LINE", n, "len", L, has)
if cands:
    best = max(cands, key=lambda x: x[1])
    open('_rc_block_recovered.txt', 'w', encoding='utf-8', newline='\n').write(best[2])
    print("SAVED line", best[0], "chars", best[1])
    print("head:", best[2][:120])
    print("tail:", repr(best[2][-120:]))