import zlib
from pathlib import Path

def get_desc(path):
    data = Path(path).read_bytes()
    pos = 8
    while pos < len(data):
        ln = int.from_bytes(data[pos:pos+4], 'big')
        pos += 4
        typ = data[pos:pos+4]
        pos += 4
        chunk = data[pos:pos+ln]
        pos += ln + 4
        if typ == b'zTXt':
            key, _, rest = chunk.partition(b'\x00')
            if key == b'Description':
                while rest[:1] == b'\x00':
                    rest = rest[1:]
                if rest[:2] in (b'x\x9c', b'x\xda'):
                    return zlib.decompress(rest).decode()
        if typ == b'IEND':
            break
    return ''

desc = get_desc(r'G:/Github/TGMC/icons/mob/animal.dmi.bak')
for name in ['pig', 'pig_dead', 'pig_mini', 'pig_mini_dead']:
    marker = f'state = "{name}"'
    i = desc.find(marker)
    print(desc[i:i+250])
    print('---')
