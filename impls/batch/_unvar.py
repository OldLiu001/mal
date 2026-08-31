import sys, re

FVAR_OPEN = re.compile(r'^\s*for %%. in \(_L\[!_G\.LEVEL!\]\.\) do \(')

def strip_forvar(text):
    lines = text.splitlines(keepends=True)
    output = []
    stack = []                 # frames: 'fvar' | 'other'
    buf = None                 # active fvar body buffer (list of raw text chunks)
    buf_emit = None

    def target():
        return buf if buf is not None else output

    def append(s):
        target().append(s)

    i = 0
    n = len(lines)
    while i < n:
        L = lines[i]
        if FVAR_OPEN.match(L):
            stack.append('fvar')
            buf = []
            i += 1
            continue
        # scan parens of this line (non-quoted), updating stack and choosing appends
        # We partition the line: chars up to and including a block-opening '(' belong to open;
        # a ')' that pops a fvar terminates the fvar.
        inq = False
        seg = ''
        j = 0
        m = len(L)
        # We'll repeatedly consume the line; a `)` that pops fvar flushes buffer & stops scanning.
        stop = False
        while j < m:
            ch = L[j]
            if ch == '"':
                inq = not inq
                seg += ch; j += 1; continue
            if ch in '()' and not inq:
                if ch == '(':
                    stack.append('other')
                    seg += ch; j += 1; continue
                else:  # ')'
                    if stack and stack[-1] == 'fvar':
                        # close of fvar: flush buffer, drop this ')', stop line
                        stack.pop()
                        # buffer now holds body text incl trailing; transform
                        body = ''.join(buf).replace('%%.', '_L[!_G.LEVEL!].')
                        output.append(body)
                        buf = None
                        # remainder of the line (after ')') is dropped (should be empty)
                        stop = True
                        break
                    else:
                        if stack:
                            stack.pop()
                        else:
                            # stray close outside any block -> keep literally
                            seg += ch; j += 1; continue
                        # a ')' closing an 'other' frame: keep it
                        seg += ch; j += 1; continue
            else:
                seg += ch; j += 1
        if stop:
            i += 1
            continue
        # end of line reached without closing fvar: append leftover seg
        if seg:
            append(seg)
        i += 1
    return ''.join(output)

if __name__ == '__main__':
    for path in sys.argv[1:]:
        txt = open(path, 'r', encoding='utf-8').read()
        new = strip_forvar(txt)
        out = path + '.unfor'
        open(out, 'w', encoding='utf-8', newline='\n').write(new)
        print(path, 'lines', txt.count('\n'), '->', new.count('\n'))
        print('  leftover for-var:', len([l for l in new.splitlines() if l.strip().startswith('for %%.')]))
        print('  leftover %%. refs:', len([l for l in new.splitlines() if '%%.' in l]))