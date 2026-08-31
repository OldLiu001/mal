import sys, re, os

def strip_forvar(text):
    lines = text.splitlines(keepends=True)
    result = []
    # stack of frames: {'kind':'fvar'|'other', 'open':str, 'body':[str]}
    stack = []

    def render(frame):
        if frame['kind'] == 'fvar':
            out = [ln.replace('%%.', '_L[!_G.LEVEL!].') for ln in frame['body']]
            return out
        else:
            return [frame['open']] + frame['body'] + ["\t)%s" % (frame['tail'])]

    def emit_lines(lst):
        if stack:
            stack[-1]['body'].extend(lst)
        else:
            result.extend(lst)

    for ln in lines:
        stripped = ln.strip()
        m_do = re.search(r'\bdo\s*\(', stripped)
        if m_do and '(' == stripped.rstrip()[-1:]:
            kind = 'fvar' if stripped.startswith('for %%.') else 'other'
            # capture tail after ')': everything after the open paren content on open line
            # we just keep the open line as-is for 'other'
            tail = ''
            stack.append({'kind': kind, 'open': ln, 'body': [], 'tail': tail})
            continue
        if stripped == ')':
            # separate surrounding indent/newline: close current block
            if stack:
                frame = stack.pop()
                # include this close line for 'other' (as its own ) line)
                frame['tail'] = ''  # close is its own line; capture indent
                rendered = render(frame) if frame['kind'] == 'fvar' else ([frame['open']] + frame['body'] + [ln])
                if frame['kind'] == 'other':
                    emit_lines([frame['open']] + frame['body'] + [ln])
                else:
                    emit_lines(render(frame))
            else:
                result.append(ln)
            continue
        # ordinary line -> accumulate in current top frame or global
        emit_lines([ln])
    return ''.join(result)

if __name__ == '__main__':
    paths = sys.argv[1:]
    for path in paths:
        with open(path, 'r', encoding='utf-8') as f:
            txt = f.read()
        new = strip_forvar(txt)
        out = path + '.unfor'
        with open(out, 'w', encoding='utf-8', newline='\n') as f:
            f.write(new)
        print(path, 'lines', txt.count('\n'), '->', new.count('\n'))
        # sanity: no leftover standalone 'for %%.' wrappers
        leftovers = [l for l in new.splitlines() if l.strip().startswith('for %%.')]
        if leftovers:
            print('  WARNING leftovers for %%%%: %d' % len(leftovers))