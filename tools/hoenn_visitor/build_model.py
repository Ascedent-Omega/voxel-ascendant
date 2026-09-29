"""Original Hoenn traveler on the project's shared Cobble Human rig."""
from pathlib import Path
import sys,json,copy
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent/'inputs'))
import base_rig as old, roster_shapes as shapes
OUT=ROOT/'assets/hoenn_visitor/model';OUT.mkdir(parents=True,exist_ok=True)
TMP=ROOT/'tools/hoenn_visitor/.build';TMP.mkdir(exist_ok=True)
old.OUT=TMP
shapes.old=old;shapes.base={n:old.build(n) for n in ['red','blue','green']}
p={'id':'hoenn-visitor','hair':'bob','haircolor':'50382c','top':'ba4939','bottom':'28394c','accent':'b68037','outfit':'shorts','accessory':''}
m=shapes.create(p);m['name']='Hoenn Visitor'
bones=m['geometry']['bones'];keys=list(old.PALETTE)
def cube(bone,material,center,size,rotation=None):
 i=keys.index(material)
 q={'origin':[center[j]-size[j]/2 for j in range(3)],'size':list(size),'uv':[i%8*128,i//8*128]}
 if rotation:q.update(rotation=rotation,pivot=list(center))
 next(b for b in bones if b['name']==bone)['cubes'].append(q)
# Ivory headband with a tied, folded kerchief behind the bob, never a hat brim.
cube('head','white',(0,41.1,1),(12,1,10))
cube('head','white',(0,43,1),(11,3,9))
cube('head','white',(0,40,6.3),(9,5,1))
cube('head','white',(-2,35,6.5),(3,5,1),(0,0,-25))
cube('head','white',(2,35.5,6.5),(3,4,1),(0,0,25))
# Satchel and strap are attached to the torso, so limbs remain independent.
cube('body','hairdark',(0,21,-3.8),(2,17,1),(0,0,-32))
cube('body','hairdark',(0,21,3.8),(2,17,1),(0,0,32))
cube('body','accent',(-6.2,16,-3),(5,6,4))
cube('body','gold',(-6.2,18,-5.1),(5,2,1))
cube('body','white',(-6.2,16.5,-5.7),(1,1,1))
# Same dark brown travel shoes in every visual style.
for b in bones:
 if b['name'].startswith('shin_'):
  for q in b['cubes']:
   if q['origin'][1] < 2.5:
    i=keys.index('hairdark');q['uv']=[i%8*128,i//8*128]
geo={'format_version':'1.12.0','minecraft:geometry':[m['geometry']]}
(OUT/'hoenn_visitor.geo.json').write_text(json.dumps(geo,indent=2))
clips={k.split('.')[-1]:v for k,v in shapes.base['blue']['animations'].items()}
(OUT/'hoenn_visitor.animation.json').write_text(json.dumps({'format_version':'1.8.0','animations':{'animation.ascendant_hoenn-visitor.'+k:v for k,v in clips.items()}},indent=2))
(OUT/'hoenn_visitor.poser.json').write_text((TMP/'ascendant_blue.poser.json').read_text().replace('ascendant_blue','ascendant_hoenn-visitor'))
palette=Image.new('RGB',(1024,1024))
for i,h in enumerate(m['palette']):palette.paste('#'+h,(i%8*128,i//8*128,i%8*128+128,i//8*128+128))
palette.save(OUT/'palette.png')
model={'id':'hoenn-visitor','colors':dict(zip(keys,m['palette'])),'bones':[]}
for b in bones:
 row=copy.deepcopy(b)
 # Resolve palette-indexed UV blocks to Baker materials.
 for q in row.get('cubes',[]):
  uv=q.pop('uv');q['material']=keys[int(uv[1]/128)*8+int(uv[0]/128)]
 model['bones'].append(row)
def lua(v):
 if isinstance(v,dict):return '{'+','.join('['+json.dumps(str(k))+']='+lua(x) for k,x in v.items())+'}'
 if isinstance(v,(list,tuple)):return '{'+','.join(lua(x) for x in v)+'}'
 if v is None:return 'nil'
 return json.dumps(v)
(OUT/'rig.lua').write_text('return '+lua(model)+'\n')
print('Built',len(bones),'bones;',sum(len(b.get('cubes',[])) for b in bones),'cuboids;',list(clips))
