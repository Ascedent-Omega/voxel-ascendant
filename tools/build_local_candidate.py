#!/usr/bin/env python3
"""Build and verify a complete local VASC candidate against its prior archive."""
import argparse, ctypes, hashlib, json, subprocess, zipfile
from pathlib import Path

p=argparse.ArgumentParser()
p.add_argument('--source',type=Path,required=True)
p.add_argument('--base',type=Path,required=True)
p.add_argument('--output',type=Path,required=True)
p.add_argument('--lua-library',type=Path,required=True)
a=p.parse_args();root=a.source.resolve();a.output.mkdir(parents=True,exist_ok=True)
sha=lambda b:hashlib.sha256(b).hexdigest()
encode=lambda o:(json.dumps(o,indent=2,ensure_ascii=False)+'\n').encode()
paths=subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z'],cwd=root).decode().split('\0')
files={n:(root/n).read_bytes()for n in paths if n and (root/n).is_file()}
manifest=json.loads(files['manifest.json']);version=manifest['version']
assert '-rc.' in version and manifest['experimental'] is True,'candidate identity required'
with zipfile.ZipFile(a.base)as z:
 names=[n for n in z.namelist()if not n.endswith('/')]
 prefix='' if 'manifest.json' in names else 'VOXEL_ASCENDANT/'
 assert not prefix or all(n.startswith(prefix)for n in names),'unexpected base archive layout'
 baseline={n[len(prefix):]:z.read(n)for n in names}
 assert not(set(baseline)-set(files)),'candidate unintentionally removes baseline files'
changed=[n for n,b in files.items()if baseline.get(n)!=b]
base_version=json.loads(baseline['manifest.json'])['version']
# Compile source with the target Lua runtime, without executing product code.
lib=ctypes.CDLL(str(a.lua_library));ptr=ctypes.c_void_p
lib.luaL_newstate.restype=ptr
lib.luaL_loadbuffer.argtypes=[ptr,ctypes.c_char_p,ctypes.c_size_t,ctypes.c_char_p]
lib.lua_tolstring.argtypes=[ptr,ctypes.c_int,ptr];lib.lua_tolstring.restype=ctypes.c_char_p
lib.lua_close.argtypes=[ptr]
syntax=0
for n,b in files.items():
 if n.endswith('.lua'):
  state=lib.luaL_newstate();error=lib.luaL_loadbuffer(state,b,len(b),n.encode())
  message=lib.lua_tolstring(state,-1,None)if error else None
  lib.lua_close(state);assert not error,(n,message);syntax+=1
index=json.loads(files['assets/cobblemon-prepared/index.json']);models=set()
for row in index['species'].values():
 for digest in row.values():
  if digest not in models:
   assert sha(files['assets/cobblemon-prepared/models/'+digest+'.json'])==digest,digest
   models.add(digest)
binary_index=files.get('assets/cobblemon-binary/index.json')
if binary_index:
 binary=json.loads(binary_index)
 assert binary['schema']==1 and binary['sourceIndexHash']==sha(files['assets/cobblemon-prepared/index.json']),'stale binary model index; rerun scripts/prepare_cobblemon_binary.py'
 assert set(binary['records'])==models,'incomplete binary model set'
 for source,digest in binary['records'].items():
  blob=files['assets/cobblemon-binary/'+source+'.bin']
  assert sha(blob)==digest and blob[:4]==b'CMB1' and blob[8:40].hex()==source,'invalid binary model: '+source
metrics=files.get('assets/cobblemon-binary/metrics.bin')
if metrics:
 sources=['gen2/lib/StadiumRig.lua','lib/CobblemonGeometry.lua','lib/CobblemonExpression.lua','lib/CobblemonSize.lua','lib/CobblemonOverworldSize.lua']
 stamp=hashlib.sha256(b''.join(hashlib.sha256(files[path]).digest() for path in sources)).digest()
 assert metrics[:4]==b'CMM1' and metrics[4:36]==stamp,'stale model metrics; rerun native rc32_bake_metrics'
 assert hashlib.sha256(metrics[72:]).digest()==metrics[36:68],'invalid model metrics checksum'
 assert len(metrics)==72+int.from_bytes(metrics[68:72],'little')*80,'invalid model metric length'
 keys=[metrics[at:at+32].hex()for at in range(72,len(metrics),80)]
 assert len(set(keys))==len(keys)and set(keys)<=models,'unknown/duplicate metric model'
for row in json.loads(files['integrated/terarrium/gyms/SOURCES.json']):
 assert sha(files['integrated/terarrium/'+row['file']])==row['sha256'],row['file']
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
for key in ('runtime-receipt.json','.modkit/pack.json'):
 d=json.loads(files[key]);d['version']=version
 if key=='runtime-receipt.json':
  d['manifest_sha256']=sha(files['manifest.json'])
  d['files']=[dict(path=n,size_bytes=len(b),sha256=sha(b))for n,b in sorted(files.items())if n not in ('runtime-receipt.json','.modkit/pack.json')]
  d['file_count']=len(d['files'])
 else:
  d['local_candidate']=True;d['source_commit']=commit;d['base_archive_sha256']=sha(a.base.read_bytes())
  d['files']=[dict(path=n,bytes=len(b),sha256=sha(b))for n,b in sorted(files.items())if n!=key]
  d['source_snapshot_sha256']=sha(json.dumps(d['files'],sort_keys=True).encode())
 files[key]=encode(d);(root/key).write_bytes(files[key])
archive=a.output/('Voxel-Ascendant-'+version+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6)as z:
 directories=sorted({str(parent)+'/' for name in files for parent in Path(name).parents if str(parent)!='.'})
 for name in directories:
  info=zipfile.ZipInfo(name,(2026,9,26,0,0,0));info.external_attr=(0o40755<<16)|0x10
  z.writestr(info,b'')
 for n,b in sorted(files.items()):
  info=zipfile.ZipInfo(n,(2026,9,26,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o100644<<16
  z.writestr(info,b)
with zipfile.ZipFile(archive)as z:
 assert z.testzip()is None
 for n,b in files.items():assert z.read(n)==b,n
 for key in ('runtime-receipt.json','.modkit/pack.json'):
  for row in json.loads(z.read(key))['files']:assert sha(z.read(row['path']))==row['sha256'],row['path']
checksum=sha(archive.read_bytes())
(a.output/(archive.name+'.sha256')).write_text(checksum+'  '+archive.name+'\n')
report=dict(archive=str(archive),version=version,base_version=base_version,source_commit=commit,local_candidate=True,
 sha256=checksum,bytes=archive.stat().st_size,files=len(files),lua_syntax_checked=syntax,prepared_models_verified=len(models),
 crc='PASS',source_equality='PASS',file_receipts='PASS',changed_or_added=sorted(changed))
(a.output/'verification.json').write_bytes(encode(report))
for n in ('RELEASE_NOTES.md','QA-REPORT.md','VIDEO_POLISH_PROGRESS.md','PERFORMANCE-TASK-STATUS.md'):(a.output/n).write_bytes(files[n])
print(json.dumps({k:v for k,v in report.items()if k!='changed_or_added'},indent=2),flush=True)
