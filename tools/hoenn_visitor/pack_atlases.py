"""Pack three separately authored styles for the existing VASC 3x4 card API.
A common alpha union per style preserves size across directions and phases.
"""
from pathlib import Path
from PIL import Image
import json
from collections import deque
ROOT=Path(__file__).resolve().parents[2]
TARGET=ROOT/'integrated/ascendant_pokemon_overworld/assets/characters'
name='hoenn-visitor-kasc-hd-4x3-walk-sheet-v1.png'
report={}
for style,sub,source in [('hd','npcs','sources/hd_master.png'),('voxel','voxel-npcs','sources/voxel_master.png'),('cobble','cobble-npcs','cobble/preview.png')]:
 im=Image.open(ROOT/'assets/hoenn_visitor'/source).convert('RGBA')
 assert im.width%3==0 and im.height%4==0
 cw,ch=im.width//3,im.height//4
 cells=[im.crop((col*cw,row*ch,(col+1)*cw,(row+1)*ch)) for row in range(4) for col in range(3)]
 # Keep the connected figure; discard isolated transparent-background flecks.
 for cell in cells:
  alpha=cell.getchannel('A').point(lambda a:a if a>=96 else 0)
  pix=alpha.load();seen=set();largest=set()
  for yy in range(ch):
   for xx in range(cw):
    if not pix[xx,yy] or (xx,yy)in seen:continue
    component=set();q=[(xx,yy)];seen.add((xx,yy))
    while q:
     x,y=q.pop();component.add((x,y))
     for dx,dy in ((-1,0),(1,0),(0,-1),(0,1),(-1,-1),(-1,1),(1,-1),(1,1)):
      nx,ny=x+dx,y+dy
      if 0<=nx<cw and 0<=ny<ch and pix[nx,ny] and (nx,ny)not in seen:seen.add((nx,ny));q.append((nx,ny))
    if len(component)>len(largest):largest=component
  for yy in range(ch):
   for xx in range(cw):
    if (xx,yy)not in largest:pix[xx,yy]=0
  cell.putalpha(alpha)
 boxes=[cell.getbbox() for cell in cells];assert all(boxes)
 bounds=(min(b[0]for b in boxes),min(b[1]for b in boxes),max(b[2]for b in boxes),max(b[3]for b in boxes))
 w,h=bounds[2]-bounds[0],bounds[3]-bounds[1];scale=min(176/w,240/h)
 nw,nh=round(w*scale),round(h*scale)
 out=Image.new('RGBA',(576,1024));native=Image.new('RGBA',(16,96));packed=[]
 for i,cell in enumerate(cells):
  tile=Image.new('RGBA',(192,256))
  fit=cell.crop(bounds).resize((nw,nh),Image.Resampling.LANCZOS if style=='hd'else Image.Resampling.NEAREST)
  tile.alpha_composite(fit,((192-nw)//2,248-nh));packed.append(tile)
  out.alpha_composite(tile,((i%3)*192,(i//3)*256))
 for f,i in enumerate([0,6,3,1,7,4]):
  tile=packed[i].resize((12,16),Image.Resampling.LANCZOS)
  tile.putalpha(tile.getchannel('A').point(lambda a:255 if a>=100 else 0));native.paste(tile,(2,f*16))
 dest=TARGET/sub/name;dest.parent.mkdir(parents=True,exist_ok=True);out.save(dest)
 dest=TARGET/'runtime'/sub/name;dest.parent.mkdir(parents=True,exist_ok=True);native.save(dest)
 report[style]={'source':source,'sourceSize':im.size,'union':bounds,'atlasSize':out.size,'nativeSize':native.size,'frameHashes':len({c.tobytes()for c in packed})}
(ROOT/'assets/hoenn_visitor/packing.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
