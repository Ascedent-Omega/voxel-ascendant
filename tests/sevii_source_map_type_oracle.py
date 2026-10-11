#!/usr/bin/env python3
"""Export semantic original header metadata, never artwork or ROM banks."""
import argparse
import hashlib
import importlib.util
import json
import struct
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('--importer', type=Path, required=True)
p.add_argument('--rom', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
spec = importlib.util.spec_from_file_location('kasc_importer', a.importer)
imp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(imp)
data = a.rom.read_bytes()
assert len(data) == 0x1000000 and hashlib.sha1(data).hexdigest() == imp.SHA1

def pointer(at):
    value = struct.unpack_from('<I', data, at)[0] - 0x08000000
    assert 0 <= value < len(data)
    return value

rows = []
for entry in json.loads(imp.MANIFEST.read_text())['maps']:
    header = pointer(pointer(imp.GROUPS + entry['group'] * 4) + entry['number'] * 4)
    kind = data[header + 0x17]
    assert kind in (1, 3, 4, 8), (entry['source'], kind)
    rows.append({'source': entry['source'], 'type': kind,
                 'weather': data[header + 0x16],
                 'music': struct.unpack_from('<H', data, header + 0x10)[0],
                 'battleType': data[header + 0x1B]})
assert len(rows) == 135 and len({x['source'] for x in rows}) == 135
a.output.parent.mkdir(parents=True, exist_ok=True)
a.output.write_text(json.dumps(sorted(rows, key=lambda x: x['source']), indent=2) + '\n')
print('SEVII_SOURCE_MAP_TYPE_ORACLE_PASS', len(rows))
