#!/usr/bin/env python3
"""Build deterministic data-only model accelerators from verified prepared JSON."""
import hashlib
import json
from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/cobblemon-prepared'
DEST = ROOT / 'assets/cobblemon-binary'

def encode(value):
    if value is None: return b'n'
    if value is True: return b't'
    if value is False: return b'f'
    if isinstance(value, (int, float)): return b'd' + struct.pack('<d', value)
    if isinstance(value, str):
        raw = value.encode('utf-8')
        return b's' + struct.pack('<I', len(raw)) + raw
    if isinstance(value, list):
        if value and all(type(v) in (int, float) for v in value):
            return b'v' + struct.pack('<I', len(value)) + struct.pack('<' + 'd' * len(value), *value)
        return b'a' + struct.pack('<I', len(value)) + b''.join(map(encode, value))
    if isinstance(value, dict):
        return b'o' + struct.pack('<I', len(value)) + b''.join(encode(k) + encode(value[k]) for k in sorted(value))
    raise TypeError(type(value))

def main():
    index_raw = (SOURCE / 'index.json').read_bytes()
    index = json.loads(index_raw)
    hashes = sorted({h for row in index['species'].values() for h in row.values()})
    DEST.mkdir(exist_ok=True)
    records = {}
    for h in hashes:
        raw = (SOURCE / 'models' / (h + '.json')).read_bytes()
        assert hashlib.sha256(raw).hexdigest() == h
        body = encode(json.loads(raw))
        assert len(body) <= 32 * 1024 * 1024
        blob = b'CMB1' + struct.pack('<I', len(body)) + bytes.fromhex(h) + zlib.compress(body, 6)
        (DEST / (h + '.bin')).write_bytes(blob)
        records[h] = hashlib.sha256(blob).hexdigest()
    (DEST / 'index.json').write_text(json.dumps({'schema': 1, 'sourceIndexHash': hashlib.sha256(index_raw).hexdigest(), 'records': records}, sort_keys=True, separators=(',', ':')) + '\n')
    print('Prepared', len(records), 'models;', sum(p.stat().st_size for p in DEST.glob('*.bin')), 'bytes')

if __name__ == '__main__': main()
