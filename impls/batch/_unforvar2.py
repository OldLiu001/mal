import sys, re

def paren_tokens(line):
    """Return list of ('('|')') ignoring parentheses inside double quotes."""
    toks = []
    inq = False
    for ch in line:
        if ch == '"':
            inq = not inq
        elif ch in '()' and not inq:
            toks.append(ch)
    return toks

def render_lines(lines, kind):
    if kind == 'fvar':
        return [l.replace('%%.', '_L[!_G.LEVEL!].') for l in lines]
    return list(lines)

def strip_forvar(text):
    lines = text.splitlines(keepends=False)
    stack = []          # frames: {'kind':..., 'open':str|None, 'body':[str]}
    output = []

    def emit(rendered):
        if stack:
            stack[-1]['body'].extend(rendered)
        else:
            output.extend(rendered)

    for L in lines:
        orig = L
        if re.match(r'^\s*for %%. in \(_L\[!_G\.LEVEL!\]\.\) do \(', L):
            stack.append({'kind': 'fvar', 'open': None, 'body': []})
            continue
        toks = paren_tokens(L)
        if not toks:
            # no parens -> ordinary line
            emit([L])
            continue
        # determine if line opens a block: last significant token '(' and no close after it
        last_open = False
        close_count = 0
        # we must process in order; a ')' pops, a '(' pushes
        # build desired: pop on ')', push on '('; but openline fragment tracking
        # First find the LAST ')' position (closing token) to split open_frag
        last_close_idx = -1
        for i, t in enumerate(toks):
            if t == ')':
                last_close_idx = i
        # count trailing structure: if the line's final token (last of toks) is '('
        # and there's any '(' after the last ')', then it opens.
        opens_new = False
        if toks and toks[-1] == '(':
            opens_new = True

        # Emit closes: pop frames for each ')' that is not re-opening
        # Simpler model: process tokens pairwise.
        # We only need: number of net pushes/pops within this line.
        depth_before = len(stack)
        # For 'other'-block frames nested logically we just maintain a local sim of pushes/pops
        # but emit() must happen at actual block closes -> do real push/pop on stack.
        sim = 0  # net depth delta
        i = 0
        n = len(toks)
        while i < n:
            t = toks[i]
            if t == '(':
                stack.append({'kind': 'other', 'open': None, 'body': []})
                sim += 1
                i += 1
            else:  # ')'
                # pop top
                if stack:
                    f = stack.pop()
                    if f['kind'] == 'fvar':
                        emit(render_lines(f['body'], 'fvar'))
                    else:
                        # close an 'other' frame: record a close line
                        emit([f['open']] + f['body'] + [')'])
                sim -= 1
                i += 1
        # Now handle the openline fragment if a block opened on this line and remains open
        if opens_new and stack:
            # top frame is the one opened by this line's trailing '('
            top = stack[-1]
            if last_close_idx >= 0:
                # open_frag = L from after the last closing ')' (exclusive of '(' part)
                open_frag = L[0:]  # approximate; refine below
                # Actually we need the substring starting after the last ')' token's char.
                # Recompute from the raw line by locating from the end.
                open_frag = split_after_last_close(L)
            else:
                open_frag = L
            top['open'] = open_frag
        elif not opens_new and last_close_idx >= 0 and stack:
            pass
    return '\n'.join(output) + ('\n' if lines else '')

def split_after_last_close(L):
    # find the LAST ')' (not in quotes) and return L[index+1:]
    inq = False
    last = -1
    for i, ch in enumerate(L):
        if ch == '"':
            inq = not inq
        elif ch == ')' and not inq:
            last = i
    if last < 0:
        return L
    return L[last + 1:]

if __name__ == '__main__':
    for path in sys.argv[1:]:
        txt = open(path, 'r', encoding='utf-8').read()
        new = strip_forvar(txt)
        open(path + '.unfor', 'w', encoding='utf-8', newline='\n').write(new)
        print(path, 'lines', txt.count('\n'), '->', new.count('\n'))
        leftovers = [l for l in new.splitlines() if l.strip().startswith('for %%.')]
        print('  leftover for-var wrappers:', len(leftovers))
        print('  leftover %%. refs:', len([l for l in new.splitlines() if '%%.' in l]))