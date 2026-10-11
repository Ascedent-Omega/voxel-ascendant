"""Private BPRD source-reference diagnostic; exports metadata, never artwork."""
import argparse, collections, hashlib, importlib.util, json, struct
from pathlib import Path

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--importer',type=Path,required=True)
p.add_argument('--rom',type=Path,required=True)
p.add_argument('--output',type=Path,required=True)
a=p.parse_args()
spec=importlib.util.spec_from_file_location('sevii_import',a.importer)
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
r=m.Rom(a.rom.read_bytes()) # Requires exact BPRD size and SHA-1.
configs={
 'flower':(0x3a722c,128,5,0x3a74ac,'3c104d93af7b7cc4fa3d45ed6fabfc577d2a2e561c03f59f5593399ba7cd1cbe'),
 'water':(0x3a74c0,1536,8,0x3aa4a0,'0803d7e31a62dab1dbe2d96b967d62cc46d2daf4db37046021e8802fa16da0a9'),
 'sand':(0x3aa4c0,576,8,0x3ab6c0,'dfc8c05d0903ee787b30d88474f948af8c95abefbd6dae5e309b8762df402acf'),
 'steam':(0x3ac044,256,4,0x3ac444,'762acbb677a161f647dcf81f83dc610a7527b1618c805e92750a7aa9c5738ba5'),
}
banks={}
code_references={'flower':0x7002c,'water':0x70054,'sand':0x7007c,'steam':0x701f8}
for kind,(base,stride,count,table,digest)in configs.items():
 pointers=b''.join(struct.pack('<I',0x8000000+base+i*stride)for i in range(count))
 assert r.data[table:table+len(pointers)]==pointers,kind
 assert hashlib.sha256(r.data[base:base+stride*count]).hexdigest()==digest,kind
 assert r.u32(code_references[kind])==0x8000000+table,kind
 banks[kind]={'base':hex(base),'stride':stride,'count':count,'pointerTable':hex(table),'codeReference':hex(code_references[kind]),'sha256':digest}
specs=json.loads(m.MANIFEST.read_text())['maps'];selected={(s['group'],s['number']):s for s in specs};rows=[]
for s in specs:
 src=m.decode_source(r,s,selected)
 primary=r.ptr(src['layout']+16);secondary=r.ptr(src['layout']+20)
 ca,cb=r.u32(primary+16),r.u32(secondary+16)
 pair=[r.tileset(primary),r.tileset(secondary)]
 references=dict(water=0,sand=0,flower=0,steam=0,otherSecondary=0)
 changed=dict(water=0,sand=0,flower=0,steam=0)
 visible_mids={}
 for mid,n in collections.Counter(v&1023 for v in src['cells']).items():
  ts=pair[mid>=640];idx=mid if mid<640 else mid-640
  kinds=set()
  for entry in struct.unpack_from('<8H',r.data,ts['metatiles']+idx*16):
   tile=entry&1023
   if ca==0x80700b9:
    for kind,start,end in [('water',416,464),('sand',464,482),('flower',508,512)]:
     if start<=tile<end:references[kind]+=n;kinds.add(kind)
   if cb==0x8070219 and 896<=tile<904:references['steam']+=n;kinds.add('steam')
   if cb not in(0,0x8070219):references['otherSecondary']+=n
  for kind in kinds:
   base,stride,count,_,_=configs[kind]
   start={'water':416,'sand':464,'flower':508,'steam':896}[kind]
   index=1 if kind=='steam'else 0;offset=(start-(640 if index else 0))*32
   images=[]
   for frame in (0,1):
    animated=[dict(t)for t in pair];raw=bytearray(animated[index]['raw'])
    raw[offset:offset+stride]=r.data[base+frame*stride:base+(frame+1)*stride]
    animated[index]['raw']=raw
    images.append(m.metatile(r,animated,mid)[0].tobytes())
   if images[0]!=images[1]:
    changed[kind]+=n;visible_mids.setdefault(mid,[]).append(kind)
 regions=[]
 for name,rect,_ in m.partitions(src):
  x0,y0,w,h=rect;counts=dict(water=0,sand=0,flower=0,steam=0)
  for y in range(y0,y0+h):
   for x in range(x0,x0+w):
    if x<src['spec']['width']and y<src['spec']['height']:
     for kind in visible_mids.get(src['cells'][y*src['spec']['width']+x]&1023,[]):counts[kind]+=1
  regions.append({'map':m.PREFIX+name,'visiblePhase01Cells':counts})
 rows.append({'source':s['source'],'primaryCallback':hex(ca),'secondaryCallback':hex(cb),'usedReferences':references,'visiblePhase01Cells':changed,'runtimeRegions':regions})
out={'romVerified':True,'source':'https://github.com/pret/pokefirered/blob/master/src/tileset_anims.c','banks':banks,
 'scope':'VRAM animation-range references in both source layers before static composition. Duplicate and occluded references are included; this is not visible pixel count. Other secondary callbacks require their own range analysis. No extracted artwork is exported.',
 'rows':rows,'sourceMapCount':len(rows),'affectedSourceCounts':{k:sum(v['usedReferences'][k]>0 for v in rows)for k in references},
 'visiblePhase01SourceCounts':{k:sum(v['visiblePhase01Cells'][k]>0 for v in rows)for k in changed}}
a.output.write_text(json.dumps(out,indent=2)+'\n')
print('SEVII_SOURCE_ANIMATION_INVENTORY_PASS',len(rows),out['affectedSourceCounts'],out['visiblePhase01SourceCounts'])
