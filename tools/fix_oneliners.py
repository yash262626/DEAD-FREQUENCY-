#!/usr/bin/env python3
"""GDScript 3 gotcha: `if c: a; b` executes b unconditionally. Expand such one-liners into blocks."""
import re, sys, glob
KW = re.compile(r'^(\t*)(if|elif|else|for|while|match)\b')
def scan(s, start, stop_chars):
    depth = 0; q = None; i = start
    while i < len(s):
        c = s[i]
        if q:
            if c == '\\': i += 1
            elif c == q: q = None
        elif c in '"\'': q = c
        elif c == '#': return -1
        elif c in '([{': depth += 1
        elif c in ')]}': depth -= 1
        elif depth == 0 and c in stop_chars:
            return i
        i += 1
    return -1
def split_top(s):
    out = []; start = 0
    while True:
        i = scan(s, start, ';')
        if i < 0: out.append(s[start:]); break
        out.append(s[start:i]); start = i + 1
    return [x.strip() for x in out if x.strip()]
n = 0
for path in sys.argv[1:]:
    lines = open(path).read().split('\n'); out = []
    for ln in lines:
        m = KW.match(ln)
        if m and ';' in ln:
            ind = m.group(1)
            # block colon: first top-level ':' followed by space/end, skipping ternary/dict colons inside brackets
            i = scan(ln, m.end(), ':')
            if i > 0 and ln[i+1:].strip():
                body = ln[i+1:]
                # keep trailing comment out of the split
                parts = split_top(body)
                if len(parts) > 1:
                    out.append(ln[:i+1])
                    for p in parts: out.append(ind + '\t' + p)
                    n += 1; continue
        out.append(ln)
    open(path, 'w').write('\n'.join(out))
print("expanded", n, "one-liners")
