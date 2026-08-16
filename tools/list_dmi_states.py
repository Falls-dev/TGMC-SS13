#!/usr/bin/env python3
import sys, zlib
from pathlib import Path

def get_states(path):
    data = Path(path).read_bytes()
    pos = 8
    while pos < len(data):
        ln = int.from_bytes(data[pos:pos+4], 'big'); pos += 4
        typ = data[pos:pos+4]; pos += 4
        chunk = data[pos:pos+ln]; pos += ln + 4
        if typ == b'zTXt':
            key, _, rest = chunk.partition(b'\x00')
            if key == b'Description':
                while rest[:1] == b'\x00':
                    rest = rest[1:]
                if rest[:2] in (b'x\x9c', b'x\xda'):
                    desc = zlib.decompress(rest).decode('utf-8', 'replace')
                    return [line.split('=')[1].strip().strip('"') for line in desc.splitlines() if line.startswith('state =')]
        if typ == b'IEND':
            break
    return []

if __name__ == '__main__':
    for p in sys.argv[1:]:
        states = get_states(p)
        pigs = [s for s in states if 'pig' in s.lower()]
        print(p, 'pig:', pigs, 'count', len(states))
